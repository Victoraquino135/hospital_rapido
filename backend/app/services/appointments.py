"""Regras compartilhadas do fluxo presencial de consultas."""
from datetime import date, datetime, timedelta

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models import Appointment, AppointmentStatusHistory, AuditLog, User


RISK_ORDER = {
    "muito_alto": 0,
    "vermelho": 0,
    "alto": 1,
    "laranja": 1,
    "medio": 2,
    "amarelo": 2,
    "baixo": 3,
    "verde": 3,
    "azul": 4,
}
LEGAL_PRIORITY_ORDER = {
    "idoso_60+": 0,
    "pcd": 1,
    "gestante": 2,
    "lactante": 3,
    "geral": 4,
}
LEGAL_PRIORITY_LABELS = {
    "idoso_60+": "Pessoa idosa (60 anos ou mais)",
    "pcd": "Pessoa com deficiência (PCD)",
    "gestante": "Gestante",
    "lactante": "Lactante",
    "geral": "Sem prioridade legal",
}


def legal_priority_code(patient: User, today: date | None = None) -> str:
    if patient.e_prioridade in LEGAL_PRIORITY_ORDER and patient.e_prioridade != "geral":
        return patient.e_prioridade
    if not patient.data_nascimento:
        return "geral"
    today = today or date.today()
    born = patient.data_nascimento.date()
    age = today.year - born.year - ((today.month, today.day) < (born.month, born.day))
    return "idoso_60+" if age >= 60 else "geral"


def is_legal_priority(patient: User, today: date | None = None) -> bool:
    return legal_priority_code(patient, today) != "geral"


def legal_priority_label(patient: User, today: date | None = None) -> str:
    return LEGAL_PRIORITY_LABELS[legal_priority_code(patient, today)]


def queue_sort_key(item: Appointment):
    priority = legal_priority_code(item.paciente)
    return (
        RISK_ORDER.get(item.classificacao_risco, len(RISK_ORDER)),
        LEGAL_PRIORITY_ORDER[priority],
        item.chegada_em or datetime.max,
        item.id,
    )


def mark_overdue_absences(db: Session, actor: User, now: datetime | None = None) -> int:
    """Marca como falta consultas sem chegada 15 minutos após o horário.

    A alteração fica vinculada ao usuário interno que provocou a atualização,
    preservando a trilha de auditoria sem criar uma credencial de sistema.
    """
    now = now or datetime.now()
    limit = now - timedelta(minutes=15)
    rows = list(db.scalars(select(Appointment).where(
        Appointment.status == "agendado",
        Appointment.chegada_em.is_(None),
        Appointment.data_horario <= limit,
    )))
    for row in rows:
        row.status = "falta"
        db.add(AppointmentStatusHistory(
            consulta_id=row.id,
            status_anterior="agendado",
            status_novo="falta",
            alterado_por=actor.id,
        ))
        db.add(AuditLog(
            usuario_id=actor.id,
            acao="falta_automatica",
            tipo_registro="consulta",
            registro_id=row.id,
            detalhes='{"regra":"atraso_superior_15_minutos"}',
        ))
    if rows:
        db.commit()
    return len(rows)
