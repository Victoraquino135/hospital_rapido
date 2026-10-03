"""Catálogo, gestão de horários e fluxo presencial por perfil."""
from datetime import datetime, date, time
from typing import Literal
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.models import User, Specialty, ProfessionalSchedule, Appointment, ProfessionalProfile, AppointmentStatusHistory
from app.core.security import canonical_role, current_user, require_roles
from app.schemas import CatalogItem

router = APIRouter()
GENERAL_SPECIALTY = 'Clínica Geral'


def is_general_specialty(value: str) -> bool:
    return value.strip().casefold() == GENERAL_SPECIALTY.casefold()

class ScheduleInput(BaseModel):
    doctor_id: int
    specialty: str = Field(min_length=3, max_length=80)
    scheduled_at: datetime
    blocked: bool = False

class StatusInput(BaseModel):
    status: Literal['em_espera', 'em_triagem', 'em_atendimento', 'concluido', 'falta']
    risk: Literal['vermelho', 'laranja', 'amarelo', 'verde', 'azul'] | None = None
    triage: str | None = Field(default=None, max_length=2000)

@router.get('/specialties', response_model=list[CatalogItem])
def specialties(user=Depends(current_user), db: Session = Depends(get_db)):
    row = db.scalar(select(Specialty).where(
        func.lower(Specialty.nome) == GENERAL_SPECIALTY.lower(),
        Specialty.ativo.is_(True),
    ))
    return [{'id': row.id, 'name': GENERAL_SPECIALTY}] if row else []

@router.get('/professionals', response_model=list[CatalogItem])
def professionals(specialty: str | None = None, user=Depends(current_user), db: Session = Depends(get_db)):
    query = select(User).where(User.perfil.in_(['profissional', 'medico', 'enfermagem']), User.ativo.is_(True))
    if specialty:
        if not is_general_specialty(specialty):
            return []
        query = query.join(ProfessionalSchedule, ProfessionalSchedule.medico_id == User.id).where(
            func.lower(ProfessionalSchedule.especialidade) == GENERAL_SPECIALTY.lower())
    return [{'id': x.id, 'name': x.nome} for x in db.scalars(query).unique()]

@router.get('/schedules')
def schedules(user=Depends(require_roles('admin')), db: Session = Depends(get_db)):
    return [{'id': x.id, 'doctor_id': x.medico_id, 'specialty': x.especialidade, 'scheduled_at': x.data_horario, 'blocked': x.bloqueado} for x in db.scalars(select(ProfessionalSchedule).order_by(ProfessionalSchedule.data_horario))]

def validate_schedule(payload, db):
    from app.routes.admin import is_holiday
    professional = db.get(User, payload.doctor_id)
    if not professional or not professional.ativo or canonical_role(professional.perfil) != 'profissional':
        raise HTTPException(422, 'Profissional inválido')
    if payload.scheduled_at.tzinfo or payload.scheduled_at <= datetime.now():
        raise HTTPException(422, 'Informe uma data local futura')
    if payload.scheduled_at.weekday() >= 5 or is_holiday(payload.scheduled_at.date()):
        raise HTTPException(422, 'Atendimento permitido apenas em dia útil não feriado')
    if payload.scheduled_at.time().replace(second=0, microsecond=0) not in {
        time(hour, 0) for hour in (7, 8, 9, 10, 11, 13, 14, 15, 16, 17)
    }:
        raise HTTPException(422, 'Horário inválido; use 07:00–11:00 ou 13:00–17:00')
    if not is_general_specialty(payload.specialty):
        raise HTTPException(422, 'No MVP, a única especialidade disponível é Clínica Geral')
    if not db.scalar(select(Specialty).where(func.lower(Specialty.nome) == GENERAL_SPECIALTY.lower())):
        db.add(Specialty(nome=GENERAL_SPECIALTY))

@router.post('/schedules', status_code=201)
def create_schedule(payload: ScheduleInput, user=Depends(require_roles('admin')), db: Session = Depends(get_db)):
    validate_schedule(payload, db)
    if db.scalar(select(ProfessionalSchedule).where(ProfessionalSchedule.medico_id == payload.doctor_id, ProfessionalSchedule.data_horario == payload.scheduled_at)):
        raise HTTPException(409, 'Horário já cadastrado')
    row = ProfessionalSchedule(medico_id=payload.doctor_id, especialidade=GENERAL_SPECIALTY, data_horario=payload.scheduled_at, bloqueado=payload.blocked)
    db.add(row); db.commit()
    return {'id': row.id}

@router.put('/schedules/{schedule_id}')
def edit_schedule(schedule_id: int, payload: ScheduleInput, user=Depends(require_roles('admin')), db: Session = Depends(get_db)):
    row = db.get(ProfessionalSchedule, schedule_id)
    if not row: raise HTTPException(404, 'Horário não encontrado')
    validate_schedule(payload, db)
    if db.scalar(select(Appointment).where(Appointment.medico_id == row.medico_id, Appointment.data_horario == row.data_horario, Appointment.status != 'cancelado')):
        raise HTTPException(409, 'Horário ocupado não pode ser alterado')
    if db.scalar(select(ProfessionalSchedule).where(ProfessionalSchedule.id != row.id, ProfessionalSchedule.medico_id == payload.doctor_id, ProfessionalSchedule.data_horario == payload.scheduled_at)):
        raise HTTPException(409, 'Horário já cadastrado')
    row.medico_id, row.especialidade, row.data_horario, row.bloqueado = payload.doctor_id, GENERAL_SPECIALTY, payload.scheduled_at, payload.blocked
    db.commit()
    return {'id': row.id}

@router.put('/appointments/{appointment_id}/status')
def change_status(appointment_id: int, payload: StatusInput, user=Depends(require_roles('recepcao', 'profissional', 'enfermagem', 'medico', 'admin')), db: Session = Depends(get_db)):
    row = db.get(Appointment, appointment_id)
    if not row: raise HTTPException(404, 'Consulta não encontrada')
    previous_by_status = {'em_espera': {'agendado'}, 'falta': {'agendado'}, 'em_triagem': {'em_espera'}, 'em_atendimento': {'em_triagem'}, 'concluido': {'em_atendimento'}}
    previous = previous_by_status[payload.status]
    role = canonical_role(user.perfil)
    profile = db.scalar(select(ProfessionalProfile).where(ProfessionalProfile.usuario_id == user.id, ProfessionalProfile.ativo.is_(True)))
    can_triage = user.perfil == 'enfermagem' or bool(profile and profile.autorizado_triagem)
    authorized = ((payload.status in {'em_espera', 'falta'} and role in {'recepcao', 'admin'}) or
                  (payload.status == 'em_triagem' and role == 'profissional' and can_triage) or
                  (payload.status in {'em_atendimento', 'concluido'} and role == 'profissional' and row.medico_id == user.id))
    if not authorized:
        raise HTTPException(403, 'Perfil não autorizado para esta etapa')
    if row.status not in previous: raise HTTPException(409, 'Transição de status inválida')
    if payload.status in {'em_espera', 'falta'} and row.data_horario.date() != date.today():
        raise HTTPException(409, 'Registre a presença ou ausência no dia da consulta')
    old_status = row.status
    if payload.status == 'em_espera':
        if row.chegada_em: raise HTTPException(409, 'A chegada já foi confirmada')
        row.chegada_em = datetime.now()
        row.chegada_por = user.id
    if payload.status == 'em_triagem':
        if not row.chegada_em or not payload.risk or not payload.triage:
            raise HTTPException(422, 'Registre a avaliação presencial e a classificação de risco')
        row.classificacao_risco, row.triagem_dados, row.triagem_por = payload.risk, payload.triage, user.id
    elif payload.risk or payload.triage:
        raise HTTPException(403, 'Somente profissional autorizado pode registrar a triagem')
    row.status = payload.status
    db.add(AppointmentStatusHistory(consulta_id=row.id, status_anterior=old_status,
                                    status_novo=row.status, alterado_por=user.id))
    db.commit()
    return {'id': row.id, 'status': row.status}
