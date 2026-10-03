"""API da UBS Rápida: autenticação, RBAC e agendamentos."""

from datetime import date, datetime, timedelta, timezone
import os
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy import func, inspect, select, text, update
from sqlalchemy.orm import Session
from app.core.database import Base, SessionLocal, engine, get_db
from app.models import Appointment, ProfessionalSchedule, User
from app.schemas import (
    AppointmentCreate,
    AppointmentResponse,
    AvailableSlot,
    CalendarSlot,
    LoginRequest,
    PasswordRecoveryVerify,
    PasswordReset,
    PatientRegistration,
    RescheduleRequest,
    TokenResponse,
    UserResponse,
    PatientProfile,
    PatientSummary,
)

from app.core.config import ORIGINS

app = FastAPI(title="UBS Rápida API", version="2.0.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=ORIGINS,
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)
from app.core.security import (
    pwd,
    current_user,
    require_roles,
    make_token,
    throttle,
    DUMMY_HASH,
    canonical_role,
    permissions_for,
)
from app.core.config import check_config, ORIGINS
from app.models import Guardian, PatientGuardian, Specialty
from fastapi import Request
from sqlalchemy.exc import IntegrityError
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


@app.exception_handler(RequestValidationError)
async def validation_error(request, exc):
    # Não devolver valores de entrada (especialmente senhas) em respostas de erro.
    if any(e["loc"][-1] == "guardian_email" for e in exc.errors()):
        return JSONResponse(
            status_code=422,
            content={
                "detail": {
                    "field": "guardian_email",
                    "message": "Informe o e-mail válido do responsável legal.",
                }
            },
        )
    errors = [
        {"loc": e["loc"], "msg": "Confira o campo informado", "type": e["type"]}
        for e in exc.errors()
    ]
    return JSONResponse(status_code=422, content={"detail": errors})


@app.exception_handler(IntegrityError)
async def integrity_error(request, exc):
    return JSONResponse(
        status_code=409,
        content={
            "detail": "Registro duplicado ou conflito de atualização. Confira os dados."
        },
    )


PRIORITIES, STAFF = {"geral", "idoso_60+", "pcd", "gestante", "lactante"}, {
    "recepcao",
    "profissional",
    "enfermagem",
    "medico",
    "admin",
}


def digits(value: str) -> str:
    return "".join(char for char in value if char.isdigit())


def valid_cpf(value: str) -> bool:
    cpf = digits(value)
    if not cpf.isascii() or len(cpf) != 11 or len(set(cpf)) == 1:
        return False
    for pos in (9, 10):
        if (
            (sum(int(cpf[i]) * (pos + 1 - i) for i in range(pos)) * 10) % 11
        ) % 10 != int(cpf[pos]):
            return False
    return True


def is_minor(birth_date: date) -> bool:
    today = date.today()
    return (
        today.year
        - birth_date.year
        - ((today.month, today.day) < (birth_date.month, birth_date.day))
        < 18
    )


def valid_password(value: str) -> bool:
    return (
        8 <= len(value) <= 32
        and len(value.encode()) <= 72
        and any(c.isupper() for c in value)
        and any(c.islower() for c in value)
        and any(c.isdigit() for c in value)
        and any(not c.isalnum() for c in value)
    )


def valid_name(value: str) -> bool:
    import re

    return (
        bool(re.fullmatch(r"[^\W\d_]+(?:[- ][^\W\d_]+)+", value.strip()))
        and 3 <= len(value.strip()) <= 80
    )


def as_user(user: User) -> UserResponse:
    return UserResponse(id=user.id, name=user.nome, role=canonical_role(user.perfil), permissions=permissions_for(user))


def as_appointment(item: Appointment, include_risk: bool = False) -> AppointmentResponse:
    return AppointmentResponse(
        id=item.id,
        specialty=item.especialidade,
        professional=item.medico.nome,
        doctor_id=item.medico_id,
        scheduled_at=item.data_horario,
        status=item.status,
        risk_classification=item.classificacao_risco if include_risk else None,
    )


def as_patient(user: User) -> PatientProfile:
    cpf = user.cpf or ""
    return PatientProfile(
        name=user.nome,
        masked_cpf=f"***.***.***-{cpf[-2:]}" if len(cpf) == 11 else "***",
        cns=user.cns,
        birth_date=user.data_nascimento.date() if user.data_nascimento else None,
        email=user.email,
        phone=user.telefone,
    )


def protected_name(value: str) -> str:
    parts = value.split()
    return parts[0] + (f" {parts[-1][0]}." if len(parts) > 1 else "")


def migrate_database() -> None:
    Base.metadata.create_all(engine)
    existing = {column["name"] for column in inspect(engine).get_columns("usuarios")}
    fields = {
        "ativo": "BOOLEAN DEFAULT 1",
        "token_version": "INTEGER DEFAULT 0",
        "criado_em": "DATETIME",
        "atualizado_em": "DATETIME",
        "data_nascimento": "DATETIME",
        "cns": "VARCHAR(15)",
        "telefone": "VARCHAR(11)",
        "e_menor_idade": "BOOLEAN DEFAULT 0",
        "nome_responsavel": "VARCHAR(120)",
        "cpf_responsavel": "VARCHAR(11)",
        "data_nascimento_responsavel": "DATETIME",
        "parentesco_responsavel": "VARCHAR(40)",
        "outro_parentesco_responsavel": "VARCHAR(80)",
        "telefone_responsavel": "VARCHAR(11)",
        "email_responsavel": "VARCHAR(120)",
        "criado_por": "INTEGER",
        "ultima_alteracao_por": "INTEGER",
    }
    with engine.begin() as connection:
        for name, definition in fields.items():
            if name not in existing:
                connection.execute(
                    text(f"ALTER TABLE usuarios ADD COLUMN {name} {definition}")
                )
    with engine.begin() as connection:
        for table, columns in {
            "consultas": {
                "chegada_em": "DATETIME",
                "chegada_por": "INTEGER",
                "triagem_por": "INTEGER",
                "triagem_dados": "VARCHAR(2000)",
            },
            "agendas_profissionais": {
                "especialidade": "VARCHAR(80) DEFAULT 'Clínica geral'"
            },
        }.items():
            known = {c["name"] for c in inspect(engine).get_columns(table)}
            for name, definition in columns.items():
                if name not in known:
                    connection.execute(
                        text(f"ALTER TABLE {table} ADD COLUMN {name} {definition}")
                    )
    with engine.begin() as connection:
        known = {c["name"] for c in inspect(engine).get_columns("responsaveis")}
        if "email" not in known:
            connection.execute(
                text("ALTER TABLE responsaveis ADD COLUMN email VARCHAR(120)")
            )
        specialty_columns = {c["name"] for c in inspect(engine).get_columns("especialidades")}
        if "ativo" not in specialty_columns:
            connection.execute(text("ALTER TABLE especialidades ADD COLUMN ativo BOOLEAN DEFAULT 1"))
        # A única vaga ativa por profissional/horário também fica protegida no SQLite.
        connection.execute(text(
            "CREATE UNIQUE INDEX IF NOT EXISTS uq_consulta_vaga_ativa "
            "ON consultas(medico_id, data_horario) WHERE status != 'cancelado'"
        ))
        connection.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_consulta_paciente_status_data "
            "ON consultas(paciente_id, status, data_horario)"
        ))
        connection.execute(text(
            "CREATE INDEX IF NOT EXISTS ix_agenda_especialidade_data "
            "ON agendas_profissionais(especialidade, data_horario)"
        ))
    with SessionLocal() as db:
        db.execute(
            update(User)
            .where(User.criado_em.is_(None))
            .values(criado_em=datetime.utcnow(), atualizado_em=datetime.utcnow())
        )
        if not db.scalar(select(Specialty).where(Specialty.nome == "Clínica geral")):
            db.add(Specialty(nome="Clínica geral"))
        for user in db.scalars(select(User).where(User.cpf_responsavel.is_not(None))):
            if not user.nome_responsavel:
                continue
            guardian = db.scalar(
                select(Guardian).where(Guardian.cpf == user.cpf_responsavel)
            )
            if not guardian:
                guardian = Guardian(
                    nome=user.nome_responsavel,
                    cpf=user.cpf_responsavel,
                    telefone=user.telefone_responsavel,
                    email=user.email_responsavel,
                )
                db.add(guardian)
                db.flush()
            if not guardian.email and user.email_responsavel:
                guardian.email = user.email_responsavel.strip().lower()
            if not db.get(PatientGuardian, (user.id, guardian.id)):
                db.add(
                    PatientGuardian(
                        paciente_id=user.id,
                        responsavel_id=guardian.id,
                        parentesco=user.parentesco_responsavel or "Responsável legal",
                    )
                )
        db.commit()


def seed(db: Session) -> None:
    if db.scalar(select(func.count(User.id))):
        return
    admin = User(
        nome="Administrador UBS",
        cpf="11144477735",
        email="admin@ubs.local",
        senha_hash=pwd.hash("Admin@123"),
        perfil="admin",
    )
    patient = User(
        nome="Paciente Demonstração",
        cpf="52998224725",
        data_nascimento=datetime(1955, 1, 1),
        email="paciente@ubs.local",
        senha_hash=pwd.hash("Paciente@123"),
        perfil="paciente",
        e_prioridade="idoso_60+",
    )
    receptionist = User(
        nome="Recepção UBS",
        cpf="12345678909",
        email="recepcao@ubs.local",
        senha_hash=pwd.hash("Recepcao@123"),
        perfil="recepcao",
    )
    ana = User(
        nome="Dra. Ana Paula",
        cpf="16899535009",
        email="ana@ubs.local",
        senha_hash=pwd.hash("Medico@123"),
        perfil="medico",
    )
    bruno = User(
        nome="Dr. Bruno Lima",
        cpf="39053344705",
        email="bruno@ubs.local",
        senha_hash=pwd.hash("Medico@123"),
        perfil="medico",
    )
    db.add_all([admin, patient, receptionist, ana, bruno])
    db.flush()
    base = datetime.now().replace(minute=0, second=0, microsecond=0) + timedelta(days=3)
    for day in range(7):
        for doctor in (ana, bruno):
            for hour in (8, 9, 10, 14, 15):
                db.add(
                    ProfessionalSchedule(
                        medico_id=doctor.id,
                        data_horario=base + timedelta(days=day, hours=hour),
                    )
                )
    db.add(
        Appointment(
            paciente_id=patient.id,
            medico_id=ana.id,
            especialidade="Clínica geral",
            data_horario=base + timedelta(hours=9),
            status="agendado",
        )
    )
    db.commit()


GENERAL_SPECIALTY = "Clínica Geral"
GENERAL_HOURS = (7, 8, 9, 10, 11, 13, 14, 15, 16, 17)


def ensure_future_general_schedule(db: Session) -> int:
    """Completa, sem duplicar, os próximos 14 dias úteis da agenda do MVP."""
    from app.models import Specialty

    now = datetime.now()
    scheduled_doctor_id = db.scalar(
        select(ProfessionalSchedule.medico_id).where(
            func.lower(ProfessionalSchedule.especialidade)
            == GENERAL_SPECIALTY.lower(),
            ProfessionalSchedule.data_horario > now,
        ).order_by(ProfessionalSchedule.data_horario)
    )
    doctor = db.get(User, scheduled_doctor_id) if scheduled_doctor_id else None
    if not doctor or not doctor.ativo:
        doctor = db.scalar(
            select(User)
            .where(
                User.perfil.in_(["profissional", "medico"]),
                User.ativo.is_(True),
            )
            .order_by(User.id)
        )
    if not doctor:
        return 0
    if not db.scalar(
        select(Specialty).where(
            func.lower(Specialty.nome) == GENERAL_SPECIALTY.lower()
        )
    ):
        db.add(Specialty(nome=GENERAL_SPECIALTY))
    created = 0
    day = now.date() + timedelta(days=1)
    weekdays = 0
    end = day + timedelta(days=24)
    existing = {
        row.data_horario
        for row in db.scalars(
            select(ProfessionalSchedule).where(
                ProfessionalSchedule.medico_id == doctor.id,
                ProfessionalSchedule.data_horario >= datetime.combine(day, datetime.min.time()),
                ProfessionalSchedule.data_horario < datetime.combine(end, datetime.min.time()),
            )
        )
    }
    while weekdays < 14:
        if day.weekday() < 5:
            for hour in GENERAL_HOURS:
                at = datetime.combine(day, datetime.min.time()).replace(hour=hour)
                if at in existing:
                    continue
                db.add(
                    ProfessionalSchedule(
                        medico_id=doctor.id,
                        especialidade=GENERAL_SPECIALTY,
                        data_horario=at,
                    )
                )
                existing.add(at)
                created += 1
            weekdays += 1
        day += timedelta(days=1)
    db.commit()
    return created


@app.on_event("startup")
def startup() -> None:
    check_config()
    migrate_database()
    db = SessionLocal()
    try:
        if os.getenv("SEED_DEMO_DATA", "false").lower() == "true":
            seed(db)
        if os.getenv("SEED_FUTURE_SCHEDULE", "true").lower() == "true":
            ensure_future_general_schedule(db)
    finally:
        db.close()


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/auth/login", response_model=TokenResponse)
def login(payload: LoginRequest, request: Request, db: Session = Depends(get_db)):
    document = digits(payload.document)
    throttle(db, request, "login", document)
    valid = valid_cpf(document)
    if any(c not in "0123456789.- " for c in payload.document):
        valid = False
    user = db.scalar(select(User).where(User.cpf == document)) if valid else None
    matches = pwd.verify(payload.password, user.senha_hash if user else DUMMY_HASH)
    if not user or not matches or not user.ativo:
        raise HTTPException(401, "CPF ou senha inválidos")
    permissions = permissions_for(user)
    return TokenResponse(access_token=make_token(user), user=as_user(user), permissions=permissions)


@app.post("/auth/register", response_model=UserResponse, status_code=201)
@app.post("/patients/register", response_model=UserResponse, status_code=201)
def register(
    payload: PatientRegistration, request: Request, db: Session = Depends(get_db)
):
    throttle(
        db, request, "register", request.client.host if request.client else "local", 20
    )
    db.execute(text("BEGIN IMMEDIATE"))
    cpf, phone = digits(payload.cpf), digits(payload.phone)
    minor, guardian_cpf = is_minor(payload.birth_date), digits(
        payload.guardian_cpf or ""
    )
    if not valid_name(payload.name):
        raise HTTPException(
            422,
            "Nome completo deve ter 3 a 80 caracteres e conter apenas letras e espaços",
        )
    if payload.birth_date > date.today() or payload.birth_date < date(1900, 1, 1):
        raise HTTPException(422, "Data de nascimento inválida")
    if any(c not in "0123456789.- " for c in payload.cpf) or not valid_cpf(cpf):
        raise HTTPException(422, "CPF inválido")
    if not valid_password(payload.password):
        raise HTTPException(
            422,
            "Senha deve ter 8 a 32 caracteres, maiúscula, minúscula, número e caractere especial",
        )
    if any(c not in "0123456789 ()-" for c in payload.phone) or len(phone) not in {
        10,
        11,
    }:
        raise HTTPException(422, "Telefone deve ter DDD e 10 ou 11 dígitos")
    if payload.priority and payload.priority not in PRIORITIES:
        raise HTTPException(422, "Perfil prioritário inválido")
    if (
        payload.guardian_birth_date
        and not date(1900, 1, 1) <= payload.guardian_birth_date <= date.today()
    ):
        raise HTTPException(422, "Data de nascimento do responsável inválida")
    if minor and any(c not in "0123456789 ()-" for c in (payload.guardian_phone or "")):
        raise HTTPException(422, "Telefone do responsável inválido")
    if minor:
        from app.core.identity import validate_guardian

        validate_guardian(payload)
    if db.scalar(select(User).where(User.cpf == cpf)):
        raise HTTPException(409, {"field": "cpf", "message": "CPF já cadastrado"})
    if db.scalar(select(User).where(User.email == str(payload.email).lower())):
        raise HTTPException(409, {"field": "email", "message": "E-mail já cadastrado"})
    priority = (
        "idoso_60+"
        if date.today().year
        - payload.birth_date.year
        - (
            (date.today().month, date.today().day)
            < (payload.birth_date.month, payload.birth_date.day)
        )
        >= 60
        else (payload.priority or "geral")
    )
    user = User(
        nome=payload.name.strip(),
        cpf=cpf,
        data_nascimento=payload.birth_date,
        email=str(payload.email).lower(),
        telefone=phone,
        senha_hash=pwd.hash(payload.password),
        perfil="paciente",
        e_prioridade=priority,
        e_menor_idade=minor,
        nome_responsavel=(
            payload.guardian_name.strip() if payload.guardian_name else None
        ),
        cpf_responsavel=guardian_cpf or None,
        data_nascimento_responsavel=payload.guardian_birth_date,
        parentesco_responsavel=payload.guardian_relationship,
        outro_parentesco_responsavel=payload.guardian_other_relationship,
        telefone_responsavel=digits(payload.guardian_phone or "") or None,
        email_responsavel=(
            str(payload.guardian_email).lower() if payload.guardian_email else None
        ),
    )
    db.add(user)
    try:
        db.flush()
        if minor:
            guardian = db.scalar(select(Guardian).where(Guardian.cpf == guardian_cpf))
            if not guardian:
                guardian = Guardian(
                    nome=payload.guardian_name.strip(),
                    cpf=guardian_cpf,
                    telefone=digits(payload.guardian_phone),
                    email=str(payload.guardian_email).lower(),
                )
                db.add(guardian)
                db.flush()
            elif guardian.email and guardian.email.strip().casefold() != str(
                payload.guardian_email
            ).strip().casefold():
                raise HTTPException(
                    422,
                    {
                        "field": "guardian_email",
                        "message": "Os dados do responsável não conferem.",
                    },
                )
            elif not guardian.email:
                guardian.email = str(payload.guardian_email).strip().lower()
            db.add(
                PatientGuardian(
                    paciente_id=user.id,
                    responsavel_id=guardian.id,
                    parentesco=payload.guardian_other_relationship
                    or payload.guardian_relationship,
                )
            )
        db.commit()
    except IntegrityError:
        db.rollback()
        raise HTTPException(409, "CPF ou e-mail já cadastrado")
    db.refresh(user)
    return as_user(user)


@app.get("/auth/me", response_model=UserResponse)
@app.get("/me", response_model=UserResponse)
def me(user: User = Depends(current_user)):
    return as_user(user)


@app.get("/patients/me", response_model=PatientProfile, response_model_exclude_none=True)
def patient_me(user: User = Depends(require_roles("paciente"))):
    return as_patient(user)


@app.get("/patients/me/summary", response_model=PatientSummary, response_model_exclude_none=True)
def patient_summary(
    user: User = Depends(require_roles("paciente")), db: Session = Depends(get_db)
):
    next_item = db.scalar(
        select(Appointment)
        .where(
            Appointment.paciente_id == user.id,
            Appointment.data_horario > datetime.now(),
            Appointment.status.not_in(["cancelado", "concluido", "falta"]),
        )
        .order_by(Appointment.data_horario)
        .limit(1)
    )
    return PatientSummary(
        patient=as_patient(user),
        next_appointment=as_appointment(next_item) if next_item else None,
    )


@app.get("/appointments", response_model=list[AppointmentResponse])
def appointments(user: User = Depends(current_user), db: Session = Depends(get_db)):
    query = (
        select(Appointment).join(Appointment.medico).order_by(Appointment.data_horario)
    )
    if user.perfil == "paciente":
        query = query.where(Appointment.paciente_id == user.id)
    elif canonical_role(user.perfil) == "profissional":
        query = query.where(Appointment.medico_id == user.id)
    return [as_appointment(item, user.perfil != "paciente") for item in db.scalars(query).unique()]


@app.get("/appointments/me", response_model=list[AppointmentResponse], response_model_exclude_none=True)
def patient_appointments(
    user: User = Depends(require_roles("paciente")), db: Session = Depends(get_db)
):
    return [
        as_appointment(item)
        for item in db.scalars(
            select(Appointment)
            .where(Appointment.paciente_id == user.id)
            .order_by(Appointment.data_horario)
        )
    ]


@app.get("/queue")
def queue(user: User = Depends(require_roles(*STAFF)), db: Session = Depends(get_db)):
    from app.services.appointments import mark_overdue_absences, queue_sort_key
    mark_overdue_absences(db, user)
    query = (
        select(Appointment)
        .where(Appointment.status.in_(["em_espera", "em_triagem", "em_atendimento"]))
        .order_by(Appointment.data_horario)
    )
    ordered = sorted(db.scalars(query).unique(), key=queue_sort_key)
    return [
        {
            "position": position,
            "id": item.id,
            "patient": protected_name(item.paciente.nome),
            "professional": item.medico.nome,
            "specialty": item.especialidade,
            "status": item.status,
            "risk_classification": item.classificacao_risco,
            "legal_priority": item.paciente.e_prioridade or "geral",
            "scheduled_at": item.data_horario,
            "arrived_at": item.chegada_em,
        }
        for position, item in enumerate(ordered, start=1)
    ]


@app.get("/available-slots", response_model=list[AvailableSlot])
@app.get("/appointments/available", response_model=list[AvailableSlot])
def available(
    specialty: str,
    doctor_id: int | None = None,
    user: User = Depends(current_user),
    db: Session = Depends(get_db),
):
    query = (
        select(ProfessionalSchedule)
        .join(ProfessionalSchedule.medico)
        .where(
            ProfessionalSchedule.especialidade == specialty,
            ProfessionalSchedule.bloqueado.is_(False),
            ProfessionalSchedule.data_horario > datetime.now(),
        )
    )
    if doctor_id:
        query = query.where(ProfessionalSchedule.medico_id == doctor_id)
    result = []
    for item in db.scalars(query.order_by(ProfessionalSchedule.data_horario)).unique():
        if not db.scalar(
            select(Appointment).where(
                Appointment.medico_id == item.medico_id,
                Appointment.data_horario == item.data_horario,
                Appointment.status != "cancelado",
            )
        ):
            result.append(
                AvailableSlot(
                    doctor_id=item.medico_id,
                    doctor_name=item.medico.nome,
                    specialty=specialty,
                    scheduled_at=item.data_horario,
                )
            )
    return result


@app.get("/availability/dates", response_model=list[date])
def available_dates(
    specialty: str,
    doctor_id: int,
    user: User = Depends(require_roles("paciente")),
    db: Session = Depends(get_db),
):
    return sorted({slot.scheduled_at.date() for slot in available(specialty, doctor_id, user, db)})


@app.get("/availability/times", response_model=list[AvailableSlot])
def available_times(
    specialty: str,
    doctor_id: int,
    day: date,
    user: User = Depends(require_roles("paciente")),
    db: Session = Depends(get_db),
):
    return [
        slot for slot in available(specialty, doctor_id, user, db)
        if slot.scheduled_at.date() == day
    ]


@app.get("/availability/calendar-dates", response_model=list[date])
def calendar_dates(
    specialty: str,
    doctor_id: int,
    user: User = Depends(require_roles("paciente")),
    db: Session = Depends(get_db),
):
    if specialty.strip().casefold() != GENERAL_SPECIALTY.casefold():
        return []
    rows = db.scalars(
        select(ProfessionalSchedule).where(
            ProfessionalSchedule.medico_id == doctor_id,
            func.lower(ProfessionalSchedule.especialidade)
            == GENERAL_SPECIALTY.lower(),
            ProfessionalSchedule.data_horario > datetime.now(),
        )
    )
    return sorted(
        {
            row.data_horario.date()
            for row in rows
            if row.data_horario.weekday() < 5
            and row.data_horario.hour in GENERAL_HOURS
            and row.data_horario.minute == 0
        }
    )


@app.get("/availability/calendar-times", response_model=list[CalendarSlot])
def calendar_times(
    specialty: str,
    doctor_id: int,
    day: date,
    user: User = Depends(require_roles("paciente")),
    db: Session = Depends(get_db),
):
    if (
        specialty.strip().casefold() != GENERAL_SPECIALTY.casefold()
        or day < date.today()
        or day.weekday() >= 5
    ):
        return []
    start = datetime.combine(day, datetime.min.time())
    end = start + timedelta(days=1)
    schedules = list(
        db.scalars(
            select(ProfessionalSchedule)
            .where(
                ProfessionalSchedule.medico_id == doctor_id,
                func.lower(ProfessionalSchedule.especialidade)
                == GENERAL_SPECIALTY.lower(),
                ProfessionalSchedule.data_horario >= start,
                ProfessionalSchedule.data_horario < end,
                ProfessionalSchedule.data_horario > datetime.now(),
            )
            .order_by(ProfessionalSchedule.data_horario)
        )
    )
    result = []
    for schedule in schedules:
        at = schedule.data_horario
        if at.hour not in GENERAL_HOURS or at.minute != 0:
            continue
        appointment = db.scalar(
            select(Appointment).where(
                Appointment.medico_id == doctor_id,
                Appointment.data_horario == at,
                Appointment.status != "cancelado",
            )
        )
        if schedule.bloqueado:
            availability, label, selectable = "unavailable", "Indisponível", False
        elif appointment and appointment.paciente_id == user.id:
            availability, label, selectable = (
                "already_scheduled",
                "Já agendado",
                False,
            )
        elif appointment:
            availability, label, selectable = "unavailable", "Indisponível", False
        else:
            availability, label, selectable = "available", "Disponível", True
        result.append(
            CalendarSlot(
                doctor_id=doctor_id,
                doctor_name=schedule.medico.nome,
                specialty=GENERAL_SPECIALTY,
                scheduled_at=at,
                availability=availability,
                label=label,
                selectable=selectable,
            )
        )
    return result


@app.get("/appointments/{appointment_id}", response_model=AppointmentResponse, response_model_exclude_none=True)
def appointment_detail(
    appointment_id: int,
    user: User = Depends(require_roles("paciente")),
    db: Session = Depends(get_db),
):
    return as_appointment(owned(db, appointment_id, user))


def slot_free(db: Session, doctor_id: int, at: datetime, specialty: str) -> None:
    if at.tzinfo is not None or at <= datetime.now():
        raise HTTPException(422, "Informe um horário local futuro")
    if at.weekday() >= 5:
        raise HTTPException(422, "Atendimento permitido somente de segunda a sexta")
    if at.minute != 0 or at.second != 0 or at.microsecond != 0 or at.hour not in GENERAL_HOURS:
        raise HTTPException(422, "Horário permitido: 07h–11h ou 13h–17h")
    slot = db.scalar(
        select(ProfessionalSchedule).where(
            func.lower(ProfessionalSchedule.especialidade)
            == specialty.strip().lower(),
            ProfessionalSchedule.medico_id == doctor_id,
            ProfessionalSchedule.data_horario == at,
            ProfessionalSchedule.bloqueado.is_(False),
        )
    )
    used = db.scalar(
        select(Appointment).where(
            Appointment.medico_id == doctor_id,
            Appointment.data_horario == at,
            Appointment.status != "cancelado",
        )
    )
    if not slot or used:
        raise HTTPException(409, "Horário não está disponível.")


@app.post("/appointments", response_model=AppointmentResponse, response_model_exclude_none=True, status_code=201)
def create_appointment(
    payload: AppointmentCreate,
    user: User = Depends(require_roles("paciente")),
    db: Session = Depends(get_db),
):
    db.execute(text("BEGIN IMMEDIATE"))
    if payload.scheduled_at.tzinfo:
        raise HTTPException(422, "Informe horário local sem fuso")
    if user.e_menor_idade and not db.scalar(
        select(PatientGuardian).where(PatientGuardian.paciente_id == user.id)
    ):
        raise HTTPException(409, "Menor deve possuir responsável vinculado")
    duplicate = db.scalar(
        select(Appointment).where(
            Appointment.paciente_id == user.id,
            func.lower(Appointment.especialidade) == payload.specialty.strip().lower(),
            func.date(Appointment.data_horario) == payload.scheduled_at.date(),
            Appointment.status.not_in(["cancelado", "concluido", "falta"]),
        )
    )
    if duplicate:
        raise HTTPException(
            409, "Já existe consulta ativa desta especialidade para o paciente (RN01)"
        )
    slot_free(db, payload.doctor_id, payload.scheduled_at, payload.specialty)
    item = Appointment(
        paciente_id=user.id,
        medico_id=payload.doctor_id,
        especialidade=payload.specialty,
        data_horario=payload.scheduled_at,
        status="agendado",
    )
    db.add(item)
    db.commit()
    db.refresh(item)
    return as_appointment(item)


def owned(db: Session, appointment_id: int, user: User) -> Appointment:
    item = db.get(Appointment, appointment_id)
    if not item:
        raise HTTPException(404, "Consulta não encontrada")
    if user.perfil == "paciente" and item.paciente_id != user.id:
        raise HTTPException(403, "Acesso permitido apenas às próprias consultas")
    return item


@app.put("/appointments/{appointment_id}/cancel", response_model=AppointmentResponse, response_model_exclude_none=True)
@app.post("/appointments/{appointment_id}/cancel", response_model=AppointmentResponse, response_model_exclude_none=True)
def cancel(
    appointment_id: int,
    user: User = Depends(require_roles("paciente")),
    db: Session = Depends(get_db),
):
    item = owned(db, appointment_id, user)
    if item.status != "agendado":
        raise HTTPException(
            409, "Somente consultas agendadas podem ser canceladas ou reagendadas"
        )
    if item.data_horario - datetime.now() < timedelta(hours=24):
        raise HTTPException(
            409, "Cancelamento permitido apenas com 24 horas de antecedência."
        )
    item.status = "cancelado"
    db.commit()
    db.refresh(item)
    result = as_appointment(item)
    result.message = "Consulta cancelada. O horário está disponível novamente."
    return result


@app.put(
    "/appointments/{appointment_id}/reschedule", response_model=AppointmentResponse, response_model_exclude_none=True
)
@app.post(
    "/appointments/{appointment_id}/reschedule", response_model=AppointmentResponse, response_model_exclude_none=True
)
def reschedule(
    appointment_id: int,
    payload: RescheduleRequest,
    user: User = Depends(require_roles("paciente")),
    db: Session = Depends(get_db),
):
    item = owned(db, appointment_id, user)
    if item.status != "agendado":
        raise HTTPException(
            409, "Somente consultas agendadas podem ser canceladas ou reagendadas"
        )
    db.execute(text("BEGIN IMMEDIATE"))
    if payload.scheduled_at.tzinfo:
        raise HTTPException(422, "Informe horário local sem fuso")
    if item.data_horario - datetime.now() < timedelta(
        hours=12
    ) or payload.scheduled_at - datetime.now() < timedelta(hours=12):
        raise HTTPException(
            409, "Reagendamento exige antecedência mínima de 12 horas (RN03)"
        )
    duplicate = db.scalar(
        select(Appointment).where(
            Appointment.id != item.id,
            Appointment.paciente_id == item.paciente_id,
            Appointment.especialidade == item.especialidade,
            func.date(Appointment.data_horario) == payload.scheduled_at.date(),
            Appointment.status.not_in(["cancelado", "concluido", "falta"]),
        )
    )
    if duplicate:
        raise HTTPException(409, "Já existe consulta ativa desta especialidade para o paciente")
    slot_free(db, payload.doctor_id, payload.scheduled_at, item.especialidade)
    item.medico_id, item.data_horario, item.status = (
        payload.doctor_id,
        payload.scheduled_at,
        "agendado",
    )
    db.commit()
    db.refresh(item)
    return as_appointment(item)


@app.patch("/schedules/{schedule_id}/block")
def block(
    schedule_id: int,
    blocked: bool = True,
    user: User = Depends(require_roles("admin")),
    db: Session = Depends(get_db),
):
    item = db.get(ProfessionalSchedule, schedule_id)
    if not item:
        raise HTTPException(404, "Agenda não encontrada")
    item.bloqueado = blocked
    db.commit()
    return {"id": item.id, "blocked": item.bloqueado}


from app.routes.recovery import router as recovery_router

app.include_router(recovery_router)
from app.routes.operations import router as operations_router

app.include_router(operations_router)
from app.routes.admin import router as admin_router

app.include_router(admin_router)
