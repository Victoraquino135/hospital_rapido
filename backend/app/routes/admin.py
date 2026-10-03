"""Administração, agenda diária e auditoria com autorização no servidor."""
from datetime import date, datetime, time, timedelta
import json
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel, EmailStr, Field
from sqlalchemy import func, or_, select, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import canonical_role, current_user, pwd, require_roles
from app.models import (
    Appointment, AppointmentStatusHistory, AuditLog, ProfessionalProfile,
    ProfessionalSchedule, ScheduleBlock, ScheduleGrid, Specialty, User,
)
from app.schemas import AccessReset, InternalUserCreate, InternalUserResponse, InternalUserUpdate
from app.services.appointments import mark_overdue_absences

router = APIRouter(prefix="/admin", tags=["administração"])


def audit(db: Session, actor: User, action: str, kind: str, record_id: int | None, details: dict | None = None):
    safe = details or {}
    for key in list(safe):
        if any(word in key.casefold() for word in ("senha", "password", "hash", "token", "cpf")):
            safe.pop(key)
    db.add(AuditLog(usuario_id=actor.id, acao=action, tipo_registro=kind,
                    registro_id=record_id, detalhes=json.dumps(safe, ensure_ascii=False) if safe else None))


def mask_cpf(cpf: str) -> str:
    return f"***.***.***-{cpf[-2:]}" if len(cpf or "") == 11 else "***"


def internal_response(db: Session, user: User) -> InternalUserResponse:
    profile = db.scalar(select(ProfessionalProfile).where(ProfessionalProfile.usuario_id == user.id))
    return InternalUserResponse(
        id=user.id, name=user.nome, masked_cpf=mask_cpf(user.cpf), email=user.email,
        role=canonical_role(user.perfil), active=user.ativo, created_at=user.criado_em,
        updated_at=user.atualizado_em,
        professional_registration=(profile.registro_profissional if profile and
                                   not profile.registro_profissional.startswith("SEM-REGISTRO-") else None),
        specialty_id=profile.especialidade_id if profile else None,
        specialty=profile.especialidade.nome if profile else None,
        can_triage=profile.autorizado_triagem if profile else user.perfil == "enfermagem",
    )


def validate_identity(name: str, cpf: str, password: str | None = None):
    from app.main import digits, valid_cpf, valid_name, valid_password
    normalized = digits(cpf)
    if not valid_name(name):
        raise HTTPException(422, {"field": "name", "message": "Informe nome e sobrenome, apenas letras, espaços e acentos."})
    if any(c not in "0123456789.- " for c in cpf) or not valid_cpf(normalized):
        raise HTTPException(422, {"field": "cpf", "message": "CPF inválido."})
    if password is not None and not valid_password(password):
        raise HTTPException(422, {"field": "password", "message": "A senha deve ter 8 a 32 caracteres, maiúscula, minúscula, número e símbolo."})
    return normalized


def ensure_professional_fields(db: Session, role: str, registration: str | None, specialty_id: int | None):
    if role != "profissional":
        return None
    specialty = db.get(Specialty, specialty_id) if specialty_id else None
    if not specialty or not specialty.ativo:
        raise HTTPException(422, {"field": "specialty_id", "message": "Selecione uma especialidade ativa."})
    if specialty.nome.strip().casefold() != "Clínica Geral".casefold():
        raise HTTPException(422, {"field": "specialty_id", "message": "No MVP, selecione somente Clínica Geral."})
    return specialty


@router.get("/users", response_model=list[InternalUserResponse])
def list_users(q: str | None = None, role: str | None = None, active: bool | None = None,
               actor: User = Depends(require_roles("admin")), db: Session = Depends(get_db)):
    query = select(User).where(User.perfil != "paciente")
    if q:
        query = query.where(func.lower(User.nome).contains(q.strip().lower()))
    if role:
        values = [role] if role != "profissional" else ["profissional", "medico", "enfermagem"]
        query = query.where(User.perfil.in_(values))
    if active is not None:
        query = query.where(User.ativo.is_(active))
    return [internal_response(db, row) for row in db.scalars(query.order_by(User.nome))]


@router.post("/users", response_model=InternalUserResponse, status_code=201)
def create_user(payload: InternalUserCreate, actor: User = Depends(require_roles("admin")),
                db: Session = Depends(get_db)):
    cpf = validate_identity(payload.name, payload.cpf, payload.password)
    if payload.password != payload.password_confirmation:
        raise HTTPException(422, {"field": "password_confirmation", "message": "As senhas não coincidem."})
    ensure_professional_fields(db, payload.role, payload.professional_registration, payload.specialty_id)
    email = str(payload.email).strip().lower()
    if db.scalar(select(User.id).where(or_(User.cpf == cpf, func.lower(User.email) == email))):
        field = "cpf" if db.scalar(select(User.id).where(User.cpf == cpf)) else "email"
        raise HTTPException(409, {"field": field, "message": "CPF já cadastrado." if field == "cpf" else "E-mail já cadastrado."})
    user = User(nome=payload.name.strip(), cpf=cpf, email=email, senha_hash=pwd.hash(payload.password),
                perfil=payload.role, ativo=payload.active, criado_por=actor.id, ultima_alteracao_por=actor.id)
    try:
        db.add(user); db.flush()
        if payload.role == "profissional":
            registration = (payload.professional_registration or "").strip() or f"SEM-REGISTRO-{user.id}"
            db.add(ProfessionalProfile(usuario_id=user.id,
                registro_profissional=registration,
                especialidade_id=payload.specialty_id, autorizado_triagem=payload.can_triage,
                ativo=payload.active))
        audit(db, actor, "usuario_criado", "usuario", user.id,
              {"perfil": payload.role, "ativo": payload.active})
        db.commit(); db.refresh(user)
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "CPF, e-mail ou registro profissional já cadastrado")
    return internal_response(db, user)


@router.put("/users/{user_id}", response_model=InternalUserResponse)
def update_user(user_id: int, payload: InternalUserUpdate,
                actor: User = Depends(require_roles("admin")), db: Session = Depends(get_db)):
    user = db.get(User, user_id)
    if not user or user.perfil == "paciente":
        raise HTTPException(404, "Usuário interno não encontrado")
    if user.id == actor.id and payload.role and payload.role != canonical_role(user.perfil):
        raise HTTPException(409, "O administrador não pode retirar o próprio perfil")
    if user.perfil == "admin" and payload.role:
        raise HTTPException(409, "Administradores são gerenciados pela ação protegida específica")
    role = payload.role or canonical_role(user.perfil)
    if payload.name is not None:
        validate_identity(payload.name, user.cpf)
        user.nome = payload.name.strip()
    if payload.email is not None:
        email = str(payload.email).strip().lower()
        if db.scalar(select(User.id).where(func.lower(User.email) == email, User.id != user.id)):
            raise HTTPException(409, {"field": "email", "message": "E-mail já cadastrado."})
        user.email = email
    profile = db.scalar(select(ProfessionalProfile).where(ProfessionalProfile.usuario_id == user.id))
    if role == "profissional":
        registration = ((payload.professional_registration or "").strip()
                        or (profile.registro_profissional if profile else None)
                        or f"SEM-REGISTRO-{user.id}")
        specialty_id = payload.specialty_id or (profile.especialidade_id if profile else None)
        ensure_professional_fields(db, role, registration, specialty_id)
        if profile is None:
            profile = ProfessionalProfile(usuario_id=user.id, registro_profissional=registration,
                especialidade_id=specialty_id, autorizado_triagem=bool(payload.can_triage), ativo=user.ativo)
            db.add(profile)
        else:
            profile.registro_profissional = registration
            profile.especialidade_id = specialty_id
            if payload.can_triage is not None:
                profile.autorizado_triagem = payload.can_triage
    elif profile:
        profile.ativo = False
    previous_role = canonical_role(user.perfil)
    user.perfil = role
    user.ultima_alteracao_por = actor.id
    if previous_role != role:
        user.token_version += 1
    audit(db, actor, "usuario_alterado", "usuario", user.id,
          {"perfil_anterior": previous_role, "perfil_novo": role})
    try:
        db.commit(); db.refresh(user)
    except IntegrityError:
        db.rollback(); raise HTTPException(409, "E-mail ou registro profissional já cadastrado")
    return internal_response(db, user)


def change_active(user_id: int, active: bool, actor: User, db: Session):
    user = db.get(User, user_id)
    if not user or user.perfil == "paciente":
        raise HTTPException(404, "Usuário interno não encontrado")
    if not active and user.perfil == "admin":
        active_admins = db.scalar(select(func.count(User.id)).where(User.perfil == "admin", User.ativo.is_(True)))
        if active_admins <= 1:
            raise HTTPException(409, "O último administrador ativo não pode ser desativado")
    if not active and user.id == actor.id:
        raise HTTPException(409, "Você não pode desativar a própria conta")
    user.ativo = active
    user.token_version += 1
    user.ultima_alteracao_por = actor.id
    profile = db.scalar(select(ProfessionalProfile).where(ProfessionalProfile.usuario_id == user.id))
    if profile: profile.ativo = active
    audit(db, actor, "usuario_ativado" if active else "usuario_desativado", "usuario", user.id,
          {"ativo": active})
    db.commit()
    return internal_response(db, user)


@router.post("/users/{user_id}/activate", response_model=InternalUserResponse)
def activate_user(user_id: int, actor: User = Depends(require_roles("admin")), db: Session = Depends(get_db)):
    return change_active(user_id, True, actor, db)


@router.post("/users/{user_id}/deactivate", response_model=InternalUserResponse)
def deactivate_user(user_id: int, actor: User = Depends(require_roles("admin")), db: Session = Depends(get_db)):
    return change_active(user_id, False, actor, db)


@router.post("/users/{user_id}/reset-access", status_code=204)
def reset_access(user_id: int, payload: AccessReset, actor: User = Depends(require_roles("admin")),
                 db: Session = Depends(get_db)):
    user = db.get(User, user_id)
    if not user or user.perfil == "paciente": raise HTTPException(404, "Usuário interno não encontrado")
    validate_identity(user.nome, user.cpf, payload.password)
    if payload.password != payload.password_confirmation:
        raise HTTPException(422, {"field": "password_confirmation", "message": "As senhas não coincidem."})
    user.senha_hash = pwd.hash(payload.password); user.token_version += 1
    user.ultima_alteracao_por = actor.id
    audit(db, actor, "acesso_redefinido", "usuario", user.id)
    db.commit()


@router.get("/summary")
def summary(day: date = Query(default_factory=date.today), actor: User = Depends(require_roles("admin")),
            db: Session = Depends(get_db)):
    mark_overdue_absences(db, actor)
    start, end = datetime.combine(day, time.min), datetime.combine(day + timedelta(days=1), time.min)
    rows = db.execute(select(Appointment.status, func.count(Appointment.id)).where(
        Appointment.data_horario >= start, Appointment.data_horario < end).group_by(Appointment.status)).all()
    counts = dict(rows)
    available = db.scalar(select(func.count(ProfessionalSchedule.id)).where(
        ProfessionalSchedule.data_horario >= start,
        ProfessionalSchedule.data_horario < end,
        ProfessionalSchedule.bloqueado.is_(False),
        ~select(Appointment.id).where(
            Appointment.medico_id == ProfessionalSchedule.medico_id,
            Appointment.data_horario == ProfessionalSchedule.data_horario,
            Appointment.status != "cancelado",
        ).exists(),
    )) or 0
    return {"scheduled": counts.get("agendado", 0), "checked_in": counts.get("em_espera", 0),
            "waiting": counts.get("em_espera", 0) + counts.get("em_triagem", 0),
            "in_care": counts.get("em_atendimento", 0), "completed": counts.get("concluido", 0),
            "cancelled": counts.get("cancelado", 0), "available": available,
            "absent": counts.get("falta", 0)}


@router.get("/appointments")
def agenda(day: date = Query(default_factory=date.today), specialty: str | None = None,
           professional_id: int | None = None, status: str | None = None, patient: str | None = None,
           actor: User = Depends(require_roles("admin", "recepcao", "profissional")), db: Session = Depends(get_db)):
    mark_overdue_absences(db, actor)
    start, end = datetime.combine(day, time.min), datetime.combine(day + timedelta(days=1), time.min)
    query = select(Appointment).where(Appointment.data_horario >= start, Appointment.data_horario < end)
    if canonical_role(actor.perfil) == "profissional": query = query.where(Appointment.medico_id == actor.id)
    if specialty: query = query.where(Appointment.especialidade == specialty)
    if professional_id: query = query.where(Appointment.medico_id == professional_id)
    if status: query = query.where(Appointment.status == status)
    if patient:
        term = patient.strip().lower()
        cpf = "".join(c for c in term if c.isdigit())
        if len(term) == 5 and term[2] == ":" and term.replace(":", "").isdigit():
            query = query.where(func.strftime("%H:%M", Appointment.data_horario) == term)
        else:
            query = query.join(Appointment.paciente).where(or_(
                func.lower(User.nome).contains(term),
                User.cpf.contains(cpf) if cpf else False,
            ))
    return [{"id": x.id, "scheduled_at": x.data_horario, "patient": x.paciente.nome,
             "patient_document": mask_cpf(x.paciente.cpf), "specialty": x.especialidade,
             "professional": x.medico.nome, "professional_id": x.medico_id, "status": x.status,
             "legal_priority": x.paciente.e_prioridade or "geral", "risk_classification": x.classificacao_risco,
             "arrived_at": x.chegada_em} for x in db.scalars(query.order_by(Appointment.data_horario)).unique()]


@router.post("/appointments/{appointment_id}/check-in")
def check_in(appointment_id: int, actor: User = Depends(require_roles("admin", "recepcao")), db: Session = Depends(get_db)):
    row = db.get(Appointment, appointment_id)
    if not row: raise HTTPException(404, "Agendamento não encontrado")
    if row.status == "cancelado": raise HTTPException(409, "Consulta cancelada não pode receber check-in")
    if row.status != "agendado" or row.chegada_em: raise HTTPException(409, "A chegada já foi confirmada ou o status é incompatível")
    if row.data_horario.date() != date.today(): raise HTTPException(409, "A chegada só pode ser confirmada no dia da consulta")
    previous = row.status; row.status = "em_espera"; row.chegada_em = datetime.now(); row.chegada_por = actor.id
    db.add(AppointmentStatusHistory(consulta_id=row.id, status_anterior=previous,
                                    status_novo=row.status, alterado_por=actor.id))
    audit(db, actor, "chegada_confirmada", "consulta", row.id)
    db.commit()
    return {"id": row.id, "status": row.status, "arrived_at": row.chegada_em}


@router.post("/appointments/{appointment_id}/absence")
def register_absence(appointment_id: int, actor: User = Depends(require_roles("admin", "recepcao")),
                     db: Session = Depends(get_db)):
    row = db.get(Appointment, appointment_id)
    if not row: raise HTTPException(404, "Agendamento não encontrado")
    if row.status != "agendado": raise HTTPException(409, "Somente consulta agendada pode receber falta")
    if row.data_horario.date() != date.today():
        raise HTTPException(409, "A falta manual só pode ser registrada no dia da consulta")
    row.status = "falta"
    db.add(AppointmentStatusHistory(consulta_id=row.id, status_anterior="agendado",
                                    status_novo="falta", alterado_por=actor.id))
    audit(db, actor, "falta_registrada", "consulta", row.id)
    db.commit()
    return {"id": row.id, "status": row.status}


@router.get("/appointments/{appointment_id}")
def appointment_details(appointment_id: int,
                        actor: User = Depends(require_roles("admin", "recepcao", "profissional")),
                        db: Session = Depends(get_db)):
    row = db.get(Appointment, appointment_id)
    if not row: raise HTTPException(404, "Agendamento não encontrado")
    if canonical_role(actor.perfil) == "profissional" and row.medico_id != actor.id:
        raise HTTPException(403, "Acesso permitido apenas às consultas atribuídas")
    return {"id": row.id, "scheduled_at": row.data_horario, "patient": row.paciente.nome,
            "patient_document": mask_cpf(row.paciente.cpf), "specialty": row.especialidade,
            "professional": row.medico.nome, "status": row.status,
            "legal_priority": row.paciente.e_prioridade or "geral",
            "risk_classification": row.classificacao_risco, "arrived_at": row.chegada_em}


@router.get("/audit")
def audit_history(limit: int = Query(100, ge=1, le=500), actor: User = Depends(require_roles("admin")),
                  db: Session = Depends(get_db)):
    rows = db.scalars(select(AuditLog).order_by(AuditLog.criado_em.desc()).limit(limit))
    result = []
    for row in rows:
        who = db.get(User, row.usuario_id)
        result.append({"id": row.id, "actor": who.nome if who else "Usuário removido", "action": row.acao,
                       "record_type": row.tipo_registro, "record_id": row.registro_id,
                       "details": json.loads(row.detalhes) if row.detalhes else None, "created_at": row.criado_em})
    return result


class SpecialtyInput(BaseModel):
    name: str = Field(min_length=3, max_length=80)


@router.get("/specialties")
def list_specialties(actor: User = Depends(require_roles("admin")), db: Session = Depends(get_db)):
    return [{"id": row.id, "name": row.nome, "active": row.ativo}
            for row in db.scalars(select(Specialty).where(
                func.lower(Specialty.nome) == "clínica geral").order_by(Specialty.nome))]


class AdminCreate(BaseModel):
    name: str = Field(min_length=3, max_length=80)
    cpf: str = Field(min_length=11, max_length=32)
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)
    password_confirmation: str = Field(min_length=8, max_length=128)


@router.post("/admins", response_model=InternalUserResponse, status_code=201)
def create_admin(payload: AdminCreate, actor: User = Depends(require_roles("admin")),
                 db: Session = Depends(get_db)):
    cpf = validate_identity(payload.name, payload.cpf, payload.password)
    if payload.password != payload.password_confirmation:
        raise HTTPException(422, {"field": "password_confirmation", "message": "As senhas não coincidem."})
    email = str(payload.email).strip().lower()
    if db.scalar(select(User.id).where(or_(User.cpf == cpf, func.lower(User.email) == email))):
        raise HTTPException(409, "CPF ou e-mail já cadastrado")
    user = User(nome=payload.name.strip(), cpf=cpf, email=email, senha_hash=pwd.hash(payload.password),
                perfil="admin", ativo=True, criado_por=actor.id, ultima_alteracao_por=actor.id)
    try:
        db.add(user); db.flush()
        audit(db, actor, "administrador_criado", "usuario", user.id, {"perfil": "admin"})
        db.commit(); db.refresh(user)
    except IntegrityError:
        db.rollback(); raise HTTPException(409, "CPF ou e-mail já cadastrado")
    return internal_response(db, user)


@router.post("/specialties", status_code=201)
def create_specialty(payload: SpecialtyInput, actor: User = Depends(require_roles("admin")), db: Session = Depends(get_db)):
    name = " ".join(payload.name.split())
    if name.casefold() != "Clínica Geral".casefold():
        raise HTTPException(422, "No MVP, a única especialidade permitida é Clínica Geral")
    if db.scalar(select(Specialty.id).where(func.lower(Specialty.nome) == name.lower())):
        raise HTTPException(409, "Especialidade já cadastrada")
    row = Specialty(nome=name, ativo=True); db.add(row); db.flush()
    audit(db, actor, "especialidade_criada", "especialidade", row.id, {"nome": name}); db.commit()
    return {"id": row.id, "name": row.nome, "active": row.ativo}


@router.put("/specialties/{specialty_id}")
def update_specialty(specialty_id: int, payload: SpecialtyInput,
                     actor: User = Depends(require_roles("admin")), db: Session = Depends(get_db)):
    row = db.get(Specialty, specialty_id)
    if not row: raise HTTPException(404, "Especialidade não encontrada")
    name = " ".join(payload.name.split())
    if name.casefold() != "Clínica Geral".casefold():
        raise HTTPException(422, "No MVP, a única especialidade permitida é Clínica Geral")
    if db.scalar(select(Specialty.id).where(func.lower(Specialty.nome) == name.lower(),
                                             Specialty.id != row.id)):
        raise HTTPException(409, "Especialidade já cadastrada")
    old = row.nome
    row.nome = name
    audit(db, actor, "especialidade_alterada", "especialidade", row.id,
          {"nome_anterior": old, "nome_novo": name})
    db.commit()
    return {"id": row.id, "name": row.nome, "active": row.ativo}


@router.post("/specialties/{specialty_id}/{action}")
def set_specialty_active(specialty_id: int, action: Literal["activate", "deactivate"],
                         actor: User = Depends(require_roles("admin")), db: Session = Depends(get_db)):
    row = db.get(Specialty, specialty_id)
    if not row: raise HTTPException(404, "Especialidade não encontrada")
    row.ativo = action == "activate"
    audit(db, actor, "especialidade_ativada" if row.ativo else "especialidade_desativada",
          "especialidade", row.id, {"ativo": row.ativo})
    db.commit()
    return {"id": row.id, "name": row.nome, "active": row.ativo}


class GridInput(BaseModel):
    professional_id: int
    specialty_id: int
    day: date
    start_time: time
    end_time: time
    duration_minutes: int = Field(gt=0, le=480)
    capacity: int = Field(ge=1, le=20)
    break_start: time | None = None
    break_end: time | None = None


def build_slots(payload: GridInput):
    if payload.day < date.today(): raise HTTPException(422, "Não é permitido cadastrar grade em data passada")
    if payload.day.weekday() >= 5: raise HTTPException(422, "Atendimento permitido somente de segunda a sexta")
    if is_holiday(payload.day): raise HTTPException(422, "Não é permitido cadastrar grade em feriado nacional")
    if payload.duration_minutes != 60: raise HTTPException(422, "Cada consulta deve durar exatamente 60 minutos")
    if payload.capacity != 1: raise HTTPException(422, "Cada profissional possui uma vaga por horário")
    start = datetime.combine(payload.day, payload.start_time); end = datetime.combine(payload.day, payload.end_time)
    if end <= start: raise HTTPException(422, "O horário final deve ser posterior ao inicial")
    if (payload.break_start is None) != (payload.break_end is None): raise HTTPException(422, "Informe o início e o fim do intervalo")
    break_start = datetime.combine(payload.day, payload.break_start) if payload.break_start else None
    break_end = datetime.combine(payload.day, payload.break_end) if payload.break_end else None
    if break_start and (break_end <= break_start or break_start < start or break_end > end):
        raise HTTPException(422, "Intervalo fora dos limites da grade")
    slots, cursor = [], start
    allowed = {time(hour, 0) for hour in (7, 8, 9, 10, 11, 13, 14, 15, 16, 17)}
    while cursor + timedelta(minutes=payload.duration_minutes) <= end:
        slot_end = cursor + timedelta(minutes=payload.duration_minutes)
        in_break = break_start and not (slot_end <= break_start or cursor >= break_end)
        if not in_break:
            if cursor.time() not in allowed:
                raise HTTPException(422, "Use somente os horários permitidos entre 07:00 e 17:00, exceto 12:00")
            slots.append(cursor)
        cursor = slot_end
    if not slots: raise HTTPException(422, "A grade deve gerar pelo menos um horário válido")
    return start, end, slots


def easter_sunday(year: int) -> date:
    a, b, c = year % 19, year // 100, year % 100
    d, e, f = b // 4, b % 4, (b + 8) // 25
    g = (b - f + 1) // 3
    h = (19 * a + b - d - g + 15) % 30
    i, k = c // 4, c % 4
    l = (32 + 2 * e + 2 * i - h - k) % 7
    m = (a + 11 * h + 22 * l) // 451
    month = (h + l - 7 * m + 114) // 31
    return date(year, month, (h + l - 7 * m + 114) % 31 + 1)


def is_holiday(day: date) -> bool:
    fixed = {(1, 1), (4, 21), (5, 1), (9, 7), (10, 12), (11, 2),
             (11, 15), (11, 20), (12, 25)}
    easter = easter_sunday(day.year)
    return (day.month, day.day) in fixed or day in {easter - timedelta(days=2), easter + timedelta(days=60)}


@router.get("/grids")
def list_grids(actor: User = Depends(require_roles("admin")), db: Session = Depends(get_db)):
    return [{"id": x.id, "professional_id": x.profissional_id, "professional": x.profissional.nome,
             "specialty_id": x.especialidade_id, "specialty": x.especialidade.nome,
             "day": x.data.date(), "start_time": x.horario_inicio, "end_time": x.horario_fim,
             "duration_minutes": x.duracao_minutos, "capacity": x.quantidade_vagas,
             "break_start": x.intervalo_inicio, "break_end": x.intervalo_fim, "active": x.ativo}
            for x in db.scalars(select(ScheduleGrid).order_by(ScheduleGrid.data.desc())).unique()]


@router.post("/grids", status_code=201)
def create_grid(payload: GridInput, actor: User = Depends(require_roles("admin")), db: Session = Depends(get_db)):
    start, end, slots = build_slots(payload)
    professional = db.get(User, payload.professional_id); specialty = db.get(Specialty, payload.specialty_id)
    if not professional or not professional.ativo or canonical_role(professional.perfil) != "profissional":
        raise HTTPException(422, "Profissional inválido")
    if not specialty or not specialty.ativo: raise HTTPException(422, "Especialidade inválida")
    overlap = db.scalar(select(ScheduleGrid.id).where(ScheduleGrid.profissional_id == professional.id,
        ScheduleGrid.ativo.is_(True), ScheduleGrid.data == datetime.combine(payload.day, time.min),
        ScheduleGrid.horario_inicio < payload.end_time.strftime("%H:%M"),
        ScheduleGrid.horario_fim > payload.start_time.strftime("%H:%M")))
    if overlap: raise HTTPException(409, "A grade se sobrepõe a outro período do profissional")
    grid = ScheduleGrid(profissional_id=professional.id, especialidade_id=specialty.id,
        data=datetime.combine(payload.day, time.min), horario_inicio=payload.start_time.strftime("%H:%M"),
        horario_fim=payload.end_time.strftime("%H:%M"), duracao_minutos=payload.duration_minutes,
        quantidade_vagas=payload.capacity, intervalo_inicio=payload.break_start.strftime("%H:%M") if payload.break_start else None,
        intervalo_fim=payload.break_end.strftime("%H:%M") if payload.break_end else None, criado_por=actor.id)
    db.add(grid); db.flush()
    for at in slots:
        for _ in range(payload.capacity):
            if not db.scalar(select(ProfessionalSchedule.id).where(ProfessionalSchedule.medico_id == professional.id,
                    ProfessionalSchedule.data_horario == at)):
                db.add(ProfessionalSchedule(medico_id=professional.id, especialidade=specialty.nome,
                                            data_horario=at, bloqueado=False))
                break
    audit(db, actor, "grade_criada", "grade", grid.id, {"data": payload.day.isoformat(), "vagas": len(slots)})
    db.commit()
    return {"id": grid.id, "slots": len(slots)}


@router.delete("/grids/{grid_id}", status_code=204)
def remove_grid(grid_id: int, actor: User = Depends(require_roles("admin")), db: Session = Depends(get_db)):
    grid = db.get(ScheduleGrid, grid_id)
    if not grid: raise HTTPException(404, "Grade não encontrada")
    day_start = grid.data
    day_end = day_start + timedelta(days=1)
    occupied = db.scalar(select(Appointment.id).where(
        Appointment.medico_id == grid.profissional_id,
        Appointment.data_horario >= day_start,
        Appointment.data_horario < day_end,
        Appointment.status != "cancelado",
    ))
    if occupied: raise HTTPException(409, "A grade possui consultas vinculadas; desative o profissional ou preserve os horários")
    grid.ativo = False
    for slot in db.scalars(select(ProfessionalSchedule).where(
            ProfessionalSchedule.medico_id == grid.profissional_id,
            ProfessionalSchedule.data_horario >= day_start,
            ProfessionalSchedule.data_horario < day_end)):
        slot.bloqueado = True
    audit(db, actor, "grade_desativada", "grade", grid.id)
    db.commit()


class BlockInput(BaseModel):
    professional_id: int
    start: datetime
    end: datetime
    reason: Literal["intervalo", "folga", "indisponibilidade", "outro"]


@router.post("/blocks", status_code=201)
def block_period(payload: BlockInput, actor: User = Depends(require_roles("admin")), db: Session = Depends(get_db)):
    if payload.start.tzinfo or payload.end.tzinfo or payload.end <= payload.start or payload.start < datetime.now():
        raise HTTPException(422, "Período de bloqueio inválido")
    if not db.get(User, payload.professional_id): raise HTTPException(422, "Profissional inválido")
    occupied = db.scalar(select(Appointment.id).where(Appointment.medico_id == payload.professional_id,
        Appointment.data_horario >= payload.start, Appointment.data_horario < payload.end,
        Appointment.status != "cancelado"))
    if occupied: raise HTTPException(409, "O período possui agendamento e não pode ser bloqueado")
    row = ScheduleBlock(profissional_id=payload.professional_id, inicio=payload.start, fim=payload.end,
                        motivo=payload.reason, criado_por=actor.id)
    db.add(row)
    for slot in db.scalars(select(ProfessionalSchedule).where(ProfessionalSchedule.medico_id == payload.professional_id,
            ProfessionalSchedule.data_horario >= payload.start, ProfessionalSchedule.data_horario < payload.end)):
        slot.bloqueado = True
    db.flush(); audit(db, actor, "periodo_bloqueado", "bloqueio", row.id, {"motivo": payload.reason}); db.commit()
    return {"id": row.id}
