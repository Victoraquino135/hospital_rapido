"""Prepara um cenário acadêmico fictício sem apagar ou duplicar dados existentes."""

from dataclasses import dataclass
from datetime import date, datetime, time, timedelta

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError

from app.core.config import check_config
from app.core.database import SessionLocal
from app.core.security import pwd
from app.main import migrate_database
from app.models import (
    Appointment, AppointmentStatusHistory, ProfessionalProfile,
    ProfessionalSchedule, RiskClassification, Specialty, User,
)


@dataclass(frozen=True)
class DemoAccount:
    role: str
    name: str
    cpf: str
    password: str
    email: str
    specialty: str | None = None
    registration: str | None = None


DEMO_ACCOUNTS = (
    DemoAccount("admin", "Ana Administração Fictícia", "12345678909", "Admin@123", "admin.demo@ubs-rapida.local"),
    DemoAccount("recepcao", "Rita Recepção Fictícia", "98765432100", "Recepcao@123", "recepcao.demo@ubs-rapida.local"),
    DemoAccount("enfermagem", "Enf. Helena Triagem Fictícia", "45678912364", "Enfermagem@123", "enfermagem.demo@ubs-rapida.local", "Clínica Geral", "COREN-DEMO-001"),
    DemoAccount("medico", "Dr. Victor Almeida", "39053344705", "Medico@123", "victor.medico@ubs-rapida.local", "Clínica Geral", "CRM-DEMO-001"),
    DemoAccount("medico", "Dra. Lívia Pediatria Fictícia", "16899535009", "Pediatria@123", "pediatria.demo@ubs-rapida.local", "Pediatria", "CRM-DEMO-002"),
    DemoAccount("paciente", "Paciente Demonstração", "52998224725", "Paciente@123", "paciente.demo@ubs-rapida.local"),
)


@dataclass(frozen=True)
class WorkflowCase:
    cpf: str
    name: str
    specialty: str
    hour: int
    status: str
    risk: str | None = None
    rescheduled: bool = False


WORKFLOW_CASES = (
    WorkflowCase("70000000159", "Carlos Agendado Fictício", "Clínica Geral", 7, "agendado"),
    WorkflowCase("70000000230", "Bianca Cancelada Fictícia", "Pediatria", 8, "cancelado"),
    WorkflowCase("70000000310", "Marina Reagendada Fictícia", "Clínica Geral", 9, "agendado", rescheduled=True),
    WorkflowCase("70000000400", "Lucas Check-in Fictício", "Pediatria", 10, "em_espera"),
    WorkflowCase("70000000582", "Joana Triagem Fictícia", "Clínica Geral", 11, "em_triagem", "medio"),
    WorkflowCase("70000000663", "Rafael Atendimento Fictício", "Pediatria", 13, "em_atendimento", "alto"),
    WorkflowCase("70000000744", "Camila Concluída Fictícia", "Clínica Geral", 14, "concluido", "baixo"),
)


def _available_email(db, preferred: str, cpf: str) -> str:
    if not db.scalar(select(User.id).where(func.lower(User.email) == preferred.lower())):
        return preferred
    local, domain = preferred.split("@", 1)
    candidate = f"{local}.{cpf}@{domain}"
    suffix = 2
    while db.scalar(select(User.id).where(func.lower(User.email) == candidate.lower())):
        candidate = f"{local}.{cpf}.{suffix}@{domain}"
        suffix += 1
    return candidate


def _specialty(db, name: str) -> Specialty:
    row = db.scalar(select(Specialty).where(func.lower(Specialty.nome) == name.lower()))
    if row:
        return row
    row = Specialty(nome=name, ativo=True)
    db.add(row)
    db.flush()
    return row


def _next_weekday(start: date, amount: int = 1) -> date:
    day, found = start, 0
    while found < amount:
        day += timedelta(days=1)
        if day.weekday() < 5:
            found += 1
    return day


def ensure_demo_accounts() -> list[tuple[DemoAccount, str]]:
    check_config()
    migrate_database()
    results: list[tuple[DemoAccount, str]] = []
    with SessionLocal() as db:
        specialties = {name: _specialty(db, name) for name in ("Clínica Geral", "Pediatria")}
        db.commit()
        for account in DEMO_ACCOUNTS:
            user = db.scalar(select(User).where(User.cpf == account.cpf))
            if user:
                results.append((account, "já existia; nenhum dado pessoal foi alterado"))
            else:
                user = User(
                    nome=account.name, cpf=account.cpf,
                    email=_available_email(db, account.email, account.cpf),
                    senha_hash=pwd.hash(account.password), perfil=account.role, ativo=True,
                    email_verificado=True,
                    data_nascimento=datetime(1990, 1, 1) if account.role == "paciente" else None,
                    e_prioridade="geral" if account.role == "paciente" else None,
                    e_menor_idade=False,
                )
                db.add(user)
                db.flush()
                results.append((account, "criada"))
            if account.specialty and not db.scalar(select(ProfessionalProfile).where(
                ProfessionalProfile.usuario_id == user.id
            )):
                db.add(ProfessionalProfile(
                    usuario_id=user.id, registro_profissional=account.registration,
                    especialidade_id=specialties[account.specialty].id,
                    autorizado_triagem=account.role == "enfermagem", ativo=True,
                ))
            db.commit()
    return results


def ensure_demo_schedules() -> int:
    created = 0
    with SessionLocal() as db:
        for account in (item for item in DEMO_ACCOUNTS if item.role == "medico"):
            user = db.scalar(select(User).where(User.cpf == account.cpf))
            if not user:
                continue
            for day_number in range(1, 6):
                day = _next_weekday(date.today(), day_number)
                for hour in (7, 8, 9, 10, 11, 13, 14, 15, 16, 17):
                    at = datetime.combine(day, time(hour))
                    exists = db.scalar(select(ProfessionalSchedule.id).where(
                        ProfessionalSchedule.medico_id == user.id,
                        ProfessionalSchedule.data_horario == at,
                    ))
                    if not exists:
                        db.add(ProfessionalSchedule(
                            medico_id=user.id, especialidade=account.specialty,
                            data_horario=at, bloqueado=False,
                        ))
                        created += 1
        db.commit()
    return created


def ensure_demo_workflow() -> list[tuple[WorkflowCase, str]]:
    results: list[tuple[WorkflowCase, str]] = []
    with SessionLocal() as db:
        reception = db.scalar(select(User).where(User.cpf == "98765432100"))
        nurse = db.scalar(select(User).where(User.cpf == "45678912364"))
        professionals = {
            "Clínica Geral": db.scalar(select(User).where(User.cpf == "39053344705")),
            "Pediatria": db.scalar(select(User).where(User.cpf == "16899535009")),
        }
        if not reception or not nurse or any(value is None for value in professionals.values()):
            raise RuntimeError("As contas internas fictícias não puderam ser preparadas.")
        today = datetime.combine(date.today(), time.min)
        future = datetime.combine(_next_weekday(date.today()), time.min)
        for index, case in enumerate(WORKFLOW_CASES, start=1):
            patient = db.scalar(select(User).where(User.cpf == case.cpf))
            if not patient:
                patient = User(
                    nome=case.name, cpf=case.cpf,
                    email=_available_email(db, f"paciente.fluxo{index}@ubs-rapida.local", case.cpf),
                    senha_hash=pwd.hash("PacienteFluxo@123"), perfil="paciente", ativo=True,
                    email_verificado=True,
                    data_nascimento=datetime(1985, 1, index),
                    e_prioridade="idoso_60+" if index == 5 else "geral",
                    e_menor_idade=False,
                )
                db.add(patient)
                db.flush()
            existing = db.scalar(select(Appointment).where(
                Appointment.paciente_id == patient.id,
                Appointment.especialidade == case.specialty,
            ))
            if existing:
                results.append((case, "já existia; nenhum dado foi alterado"))
                continue
            scheduled_at = (future if case.status in {"agendado", "cancelado"} else today).replace(hour=case.hour)
            arrival, triaged_at = scheduled_at - timedelta(minutes=10), scheduled_at - timedelta(minutes=5)
            in_flow = case.status in {"em_espera", "em_triagem", "em_atendimento", "concluido"}
            row = Appointment(
                paciente_id=patient.id, medico_id=professionals[case.specialty].id,
                especialidade=case.specialty, data_horario=scheduled_at, status=case.status,
                chegada_em=arrival if in_flow else None, chegada_por=reception.id if in_flow else None,
                classificacao_risco=case.risk,
                triagem_dados="Observação fictícia para demonstração." if case.risk else None,
                triagem_por=nurse.id if case.risk else None,
                triagem_em=triaged_at if case.risk else None,
                chamado_em=scheduled_at if case.status in {"em_atendimento", "concluido"} else None,
                iniciado_em=scheduled_at if case.status in {"em_atendimento", "concluido"} else None,
                concluido_em=scheduled_at + timedelta(minutes=30) if case.status == "concluido" else None,
                atendimento_medico_id=(
                    professionals[case.specialty].id
                    if case.status in {"em_atendimento", "concluido"}
                    else None
                ),
                resumo_atendimento=(
                    "Resumo fictício do atendimento concluído."
                    if case.status == "concluido"
                    else None
                ),
            )
            db.add(row)
            db.flush()
            if case.risk:
                db.add(RiskClassification(
                    consulta_id=row.id, profissional_id=nurse.id,
                    nivel_risco=case.risk,
                    queixa_principal="Queixa principal fictícia.",
                    sinais_vitais="Sinais vitais fictícios estáveis.",
                    observacao=row.triagem_dados,
                    classificado_em=triaged_at,
                ))
            if case.rescheduled:
                db.add(AppointmentStatusHistory(
                    consulta_id=row.id, status_anterior="agendado",
                    status_novo="reagendado", alterado_por=patient.id,
                ))
            results.append((case, "criada"))
        db.commit()
    return results


def main() -> int:
    try:
        print("Contas fictícias de demonstração:")
        for account, status in ensure_demo_accounts():
            print(f"- {account.role}: {account.name} | CPF {account.cpf} | {status}.")
        print(f"Horários futuros criados: {ensure_demo_schedules()} (depois, somente os ausentes).")
        print("Cenários fictícios:")
        for case, status in ensure_demo_workflow():
            label = "reagendado" if case.rescheduled else case.status
            print(f"- {case.name}: {label} | {status}.")
        print("Swagger: http://127.0.0.1:8000/docs")
        return 0
    except (RuntimeError, IntegrityError) as exc:
        print(f"Erro: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
