"""Painéis operacionais protegidos da recepção e da enfermagem."""

from datetime import date, datetime, time, timedelta
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, Field
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import require_roles
from app.models import (
    Appointment,
    AppointmentStatusHistory,
    ProfessionalProfile,
    RiskClassification,
    User,
)

router = APIRouter(tags=["recepção e enfermagem"])

RISK_LABELS = {
    "muito_alto": "Muito alto",
    "alto": "Alto",
    "medio": "Médio",
    "baixo": "Baixo",
}
RISK_ORDER = {"muito_alto": 0, "alto": 1, "medio": 2, "baixo": 3}
LEGAL_PRIORITY_ORDER = {
    "gestante": 0,
    "idoso_60+": 1,
    "pcd": 2,
    "lactante": 3,
    "geral": 4,
}


class RiskInput(BaseModel):
    level: Literal["muito_alto", "alto", "medio", "baixo"]
    observation: str | None = Field(default=None, max_length=500)


def _day_limits(day: date) -> tuple[datetime, datetime]:
    start = datetime.combine(day, time.min)
    return start, start + timedelta(days=1)


def _risk_record(db: Session, appointment_id: int) -> RiskClassification | None:
    return db.scalar(
        select(RiskClassification).where(
            RiskClassification.consulta_id == appointment_id
        )
    )


def _appointment_payload(db: Session, row: Appointment) -> dict:
    risk = _risk_record(db, row.id)
    return {
        "id": row.id,
        "scheduled_at": row.data_horario,
        "patient": row.paciente.nome,
        "patient_document": _mask_cpf(row.paciente.cpf),
        "specialty": row.especialidade,
        "professional": row.medico.nome,
        "professional_id": row.medico_id,
        "status": row.status,
        "legal_priority": row.paciente.e_prioridade or "geral",
        "risk_classification": risk.nivel_risco if risk else row.classificacao_risco,
        "risk_label": RISK_LABELS.get(
            risk.nivel_risco if risk else row.classificacao_risco or ""
        ),
        "triage_observation": risk.observacao if risk else row.triagem_dados,
        "arrived_at": row.chegada_em,
        "missed_at": row.falta_em,
        "triaged_at": risk.classificado_em if risk else row.triagem_em,
        "called_at": row.chamado_em,
        "started_at": row.iniciado_em,
        "completed_at": row.concluido_em,
    }


def _mask_cpf(cpf: str) -> str:
    return f"***.***.***-{cpf[-2:]}" if len(cpf or "") == 11 else "***"


def _appointment_or_404(db: Session, appointment_id: int) -> Appointment:
    row = db.get(Appointment, appointment_id)
    if not row:
        raise HTTPException(404, "Agendamento não encontrado")
    return row


def _record_status(db: Session, row: Appointment, new_status: str, actor: User):
    previous = row.status
    row.status = new_status
    db.add(
        AppointmentStatusHistory(
            consulta_id=row.id,
            status_anterior=previous,
            status_novo=new_status,
            alterado_por=actor.id,
        )
    )


def _authorized_nurse(actor: User, db: Session) -> ProfessionalProfile:
    if actor.perfil != "enfermagem":
        raise HTTPException(403, "Somente a enfermagem pode registrar classificação de risco")
    profile = db.scalar(
        select(ProfessionalProfile).where(
            ProfessionalProfile.usuario_id == actor.id,
            ProfessionalProfile.ativo.is_(True),
        )
    )
    if not profile or not profile.autorizado_triagem:
        raise HTTPException(403, "Profissional de enfermagem sem autorização ativa")
    return profile


def _filtered_day_query(
    day: date,
    specialty: str | None,
    professional_id: int | None,
    status: str | None,
    patient: str | None,
):
    start, end = _day_limits(day)
    query = select(Appointment).where(
        Appointment.data_horario >= start, Appointment.data_horario < end
    )
    if specialty:
        query = query.where(func.lower(Appointment.especialidade) == specialty.lower())
    if professional_id:
        query = query.where(Appointment.medico_id == professional_id)
    if status:
        query = query.where(Appointment.status == status)
    if patient:
        term = patient.strip().lower()
        cpf = "".join(char for char in term if char.isdigit())
        query = query.join(Appointment.paciente).where(
            or_(
                func.lower(User.nome).contains(term),
                User.cpf.contains(cpf) if cpf else False,
            )
        )
    return query


@router.get("/recepcao/resumo")
def reception_summary(
    day: date = Query(default_factory=date.today),
    actor: User = Depends(require_roles("recepcao")),
    db: Session = Depends(get_db),
):
    start, end = _day_limits(day)
    counts = dict(
        db.execute(
            select(Appointment.status, func.count(Appointment.id))
            .where(Appointment.data_horario >= start, Appointment.data_horario < end)
            .group_by(Appointment.status)
        ).all()
    )
    return {
        "scheduled": counts.get("agendado", 0),
        "checked_in": counts.get("em_espera", 0) + counts.get("em_triagem", 0),
        "in_care": counts.get("em_atendimento", 0),
        "completed": counts.get("concluido", 0),
        "absent": counts.get("falta", 0),
    }


@router.get("/recepcao/agendamentos")
def reception_appointments(
    day: date = Query(default_factory=date.today),
    specialty: str | None = None,
    professional_id: int | None = None,
    status: str | None = None,
    patient: str | None = None,
    actor: User = Depends(require_roles("recepcao")),
    db: Session = Depends(get_db),
):
    query = _filtered_day_query(
        day, specialty, professional_id, status, patient
    ).order_by(Appointment.data_horario)
    return [_appointment_payload(db, row) for row in db.scalars(query).unique()]


@router.get("/recepcao/agendamentos/{appointment_id}")
def reception_details(
    appointment_id: int,
    actor: User = Depends(require_roles("recepcao")),
    db: Session = Depends(get_db),
):
    return _appointment_payload(db, _appointment_or_404(db, appointment_id))


@router.patch("/recepcao/agendamentos/{appointment_id}/check-in")
def reception_check_in(
    appointment_id: int,
    actor: User = Depends(require_roles("recepcao")),
    db: Session = Depends(get_db),
):
    row = _appointment_or_404(db, appointment_id)
    if row.data_horario.date() != date.today():
        raise HTTPException(409, "Check-in permitido somente no dia da consulta")
    if row.status != "agendado" or row.chegada_em:
        raise HTTPException(409, "Consulta já recebeu check-in ou possui status incompatível")
    row.chegada_em = datetime.now()
    row.chegada_por = actor.id
    _record_status(db, row, "em_espera", actor)
    db.commit()
    return _appointment_payload(db, row)


@router.patch("/recepcao/agendamentos/{appointment_id}/nao-compareceu")
def reception_absence(
    appointment_id: int,
    actor: User = Depends(require_roles("recepcao")),
    db: Session = Depends(get_db),
):
    row = _appointment_or_404(db, appointment_id)
    if row.data_horario.date() != date.today():
        raise HTTPException(409, "A ausência só pode ser registrada no dia da consulta")
    if row.status not in {"agendado", "em_espera"}:
        raise HTTPException(409, "Consulta em atendimento ou concluída não pode receber ausência")
    row.falta_em = datetime.now()
    _record_status(db, row, "falta", actor)
    db.commit()
    return _appointment_payload(db, row)


@router.get("/enfermagem/resumo")
def nursing_summary(
    day: date = Query(default_factory=date.today),
    actor: User = Depends(require_roles("enfermagem")),
    db: Session = Depends(get_db),
):
    _authorized_nurse(actor, db)
    start, end = _day_limits(day)
    rows = list(
        db.scalars(
            select(Appointment).where(
                Appointment.data_horario >= start,
                Appointment.data_horario < end,
                Appointment.chegada_em.is_not(None),
                Appointment.status.in_(["em_espera", "em_triagem"]),
            )
        ).unique()
    )
    risks = {key: 0 for key in RISK_LABELS}
    for row in rows:
        record = _risk_record(db, row.id)
        level = record.nivel_risco if record else row.classificacao_risco
        if level in risks:
            risks[level] += 1
    return {
        "awaiting_triage": sum(row.status == "em_espera" for row in rows),
        "in_care": 0,
        "completed": 0,
        "risk_counts": risks,
    }


@router.get("/enfermagem/fila")
def nursing_queue(
    day: date = Query(default_factory=date.today),
    specialty: str | None = None,
    status: str | None = None,
    risk: str | None = None,
    actor: User = Depends(require_roles("enfermagem")),
    db: Session = Depends(get_db),
):
    _authorized_nurse(actor, db)
    query = _filtered_day_query(day, specialty, None, status, None).where(
        Appointment.chegada_em.is_not(None),
        Appointment.status.in_(["em_espera", "em_triagem"]),
    )
    rows = list(db.scalars(query).unique())
    if risk:
        if risk not in RISK_LABELS:
            raise HTTPException(422, "Classificação de risco inválida")
        filtered = []
        for row in rows:
            record = _risk_record(db, row.id)
            level = record.nivel_risco if record else row.classificacao_risco
            if level == risk:
                filtered.append(row)
        rows = filtered

    def order(row: Appointment):
        record = _risk_record(db, row.id)
        level = record.nivel_risco if record else row.classificacao_risco
        return (
            RISK_ORDER.get(level or "", 4),
            LEGAL_PRIORITY_ORDER.get(row.paciente.e_prioridade or "geral", 4),
            row.chegada_em or row.data_horario,
        )

    return [_appointment_payload(db, row) for row in sorted(rows, key=order)]


@router.get("/enfermagem/agendamentos/{appointment_id}")
def nursing_details(
    appointment_id: int,
    actor: User = Depends(require_roles("enfermagem")),
    db: Session = Depends(get_db),
):
    _authorized_nurse(actor, db)
    row = _appointment_or_404(db, appointment_id)
    if not row.chegada_em:
        raise HTTPException(409, "Paciente ainda não realizou check-in")
    return _appointment_payload(db, row)


@router.patch("/enfermagem/agendamentos/{appointment_id}/classificacao-risco")
def classify_risk(
    appointment_id: int,
    payload: RiskInput,
    actor: User = Depends(require_roles("enfermagem")),
    db: Session = Depends(get_db),
):
    _authorized_nurse(actor, db)
    row = _appointment_or_404(db, appointment_id)
    if not row.chegada_em:
        raise HTTPException(409, "Não é possível classificar risco sem check-in")
    if row.status not in {"em_espera", "em_triagem"}:
        raise HTTPException(409, "Classificação incompatível com o status atual")
    now = datetime.now()
    record = _risk_record(db, row.id)
    if record:
        record.nivel_risco = payload.level
        record.observacao = payload.observation.strip() if payload.observation else None
        record.profissional_id = actor.id
        record.classificado_em = now
    else:
        db.add(
            RiskClassification(
                consulta_id=row.id,
                profissional_id=actor.id,
                nivel_risco=payload.level,
                observacao=payload.observation.strip() if payload.observation else None,
                classificado_em=now,
            )
        )
    row.classificacao_risco = payload.level
    row.triagem_dados = payload.observation.strip() if payload.observation else None
    row.triagem_por = actor.id
    row.triagem_em = now
    if row.status == "em_espera":
        _record_status(db, row, "em_triagem", actor)
    db.commit()
    return _appointment_payload(db, row)


@router.get("/profissional/fila")
def professional_queue(
    day: date = Query(default_factory=date.today),
    actor: User = Depends(require_roles("profissional", "medico")),
    db: Session = Depends(get_db),
):
    query = _filtered_day_query(day, None, actor.id, None, None).where(
        Appointment.status.in_(["em_triagem", "em_atendimento"])
    ).order_by(Appointment.data_horario)
    return [_appointment_payload(db, row) for row in db.scalars(query).unique()]


@router.get("/profissional/agendamentos/{appointment_id}")
def professional_details(
    appointment_id: int,
    actor: User = Depends(require_roles("profissional", "medico")),
    db: Session = Depends(get_db),
):
    row = _appointment_or_404(db, appointment_id)
    if row.medico_id != actor.id:
        raise HTTPException(403, "Acesso permitido apenas aos atendimentos atribuídos")
    return _appointment_payload(db, row)


@router.patch("/profissional/agendamentos/{appointment_id}/chamar")
def call_patient(
    appointment_id: int,
    actor: User = Depends(require_roles("profissional", "medico")),
    db: Session = Depends(get_db),
):
    row = _appointment_or_404(db, appointment_id)
    if row.medico_id != actor.id:
        raise HTTPException(403, "Acesso permitido apenas aos atendimentos atribuídos")
    if row.status != "em_triagem" or not row.classificacao_risco:
        raise HTTPException(409, "Paciente ainda não foi encaminhado pela triagem")
    row.chamado_em = datetime.now()
    db.commit()
    return _appointment_payload(db, row)


@router.patch("/profissional/agendamentos/{appointment_id}/iniciar-atendimento")
def start_care(
    appointment_id: int,
    actor: User = Depends(require_roles("profissional", "medico")),
    db: Session = Depends(get_db),
):
    row = _appointment_or_404(db, appointment_id)
    if row.medico_id != actor.id:
        raise HTTPException(403, "Acesso permitido apenas aos atendimentos atribuídos")
    if not row.chegada_em:
        raise HTTPException(409, "Não é possível iniciar atendimento sem check-in")
    if row.status != "em_triagem" or not row.classificacao_risco:
        raise HTTPException(409, "Conclua a classificação de risco antes do atendimento")
    row.iniciado_em = datetime.now()
    _record_status(db, row, "em_atendimento", actor)
    db.commit()
    return _appointment_payload(db, row)


@router.patch("/profissional/agendamentos/{appointment_id}/concluir-atendimento")
def complete_care(
    appointment_id: int,
    actor: User = Depends(require_roles("profissional", "medico")),
    db: Session = Depends(get_db),
):
    row = _appointment_or_404(db, appointment_id)
    if row.medico_id != actor.id:
        raise HTTPException(403, "Acesso permitido apenas aos atendimentos atribuídos")
    if row.status != "em_atendimento":
        raise HTTPException(409, "Somente consulta em atendimento pode ser concluída")
    row.concluido_em = datetime.now()
    _record_status(db, row, "concluido", actor)
    db.commit()
    return _appointment_payload(db, row)
