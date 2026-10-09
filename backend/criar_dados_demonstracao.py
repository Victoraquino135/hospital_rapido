"""Cria somente as contas fictícias de demonstração que ainda não existem."""

from dataclasses import dataclass
from datetime import date, datetime, time, timedelta

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError

from app.core.config import check_config
from app.core.database import SessionLocal
from app.core.security import pwd
from app.main import migrate_database
from app.models import (
    Appointment,
    ProfessionalProfile,
    RiskClassification,
    Specialty,
    User,
)


@dataclass(frozen=True)
class DemoAccount:
    role: str
    name: str
    cpf: str
    password: str
    email: str


DEMO_ACCOUNTS = (
    DemoAccount("admin", "Admin UBS Rápida", "12345678909", "Admin@123", "admin.demo@ubs-rapida.local"),
    DemoAccount("recepcao", "Recepção UBS Rápida", "98765432100", "Recepcao@123", "recepcao.demo@ubs-rapida.local"),
    DemoAccount("profissional", "Profissional UBS Rápida", "11144477735", "Profissional@123", "profissional.demo@ubs-rapida.local"),
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
    observation: str | None = None


WORKFLOW_CASES = (
    WorkflowCase("70000000159", "Paciente Fictício Agendado", "Clínica Geral", 7, "agendado"),
    WorkflowCase("70000000230", "Paciente Fictício Check-in", "Pediatria", 8, "em_espera"),
    WorkflowCase("70000000310", "Paciente Fictício Triagem", "Clínica Geral", 9, "em_triagem", "medio", "Observação fictícia para demonstração."),
    WorkflowCase("70000000400", "Paciente Fictício Atendimento", "Pediatria", 10, "em_atendimento", "alto", "Observação fictícia para demonstração."),
    WorkflowCase("70000000582", "Paciente Fictício Concluído", "Clínica Geral", 11, "concluido", "baixo", "Observação fictícia para demonstração."),
    WorkflowCase("70000000663", "Paciente Fictício Ausente", "Pediatria", 13, "falta"),
)


def _available_email(db, preferred: str, cpf: str) -> str:
    """Evita conflito com e-mail legado sem tocar na conta que já o utiliza."""
    if not db.scalar(select(User.id).where(func.lower(User.email) == preferred.lower())):
        return preferred
    local, domain = preferred.split("@", 1)
    candidate = f"{local}.{cpf}@{domain}"
    suffix = 2
    while db.scalar(select(User.id).where(func.lower(User.email) == candidate.lower())):
        candidate = f"{local}.{cpf}.{suffix}@{domain}"
        suffix += 1
    return candidate


def _general_specialty(db) -> Specialty:
    specialty = db.scalar(
        select(Specialty).where(func.lower(Specialty.nome) == "clínica geral")
    )
    if specialty:
        return specialty
    specialty = Specialty(nome="Clínica Geral", ativo=True)
    db.add(specialty)
    db.flush()
    return specialty


def ensure_demo_accounts() -> list[tuple[DemoAccount, str]]:
    check_config()
    migrate_database()
    results: list[tuple[DemoAccount, str]] = []

    with SessionLocal() as db:
        for account in DEMO_ACCOUNTS:
            existing = db.scalar(select(User).where(User.cpf == account.cpf))
            if existing:
                results.append((account, "já existia; nenhum dado foi alterado"))
                continue

            user = User(
                nome=account.name,
                cpf=account.cpf,
                email=_available_email(db, account.email, account.cpf),
                senha_hash=pwd.hash(account.password),
                perfil=account.role,
                ativo=True,
                email_verificado=True,
                data_nascimento=(datetime(1990, 1, 1) if account.role == "paciente" else None),
                e_prioridade="geral" if account.role == "paciente" else None,
                e_menor_idade=False,
            )
            try:
                db.add(user)
                db.flush()
                if account.role == "profissional":
                    specialty = _general_specialty(db)
                    db.add(
                        ProfessionalProfile(
                            usuario_id=user.id,
                            registro_profissional=f"DEMO-UBS-{account.cpf}",
                            especialidade_id=specialty.id,
                            autorizado_triagem=True,
                            ativo=True,
                        )
                    )
                db.commit()
                results.append((account, "criada"))
            except IntegrityError:
                db.rollback()
                raise RuntimeError(
                    f"Não foi possível criar a conta fictícia de CPF {account.cpf} "
                    "por conflito com um registro existente. Nenhum registro foi substituído."
                )
    return results


def ensure_demo_workflow() -> list[tuple[WorkflowCase, str]]:
    """Inclui uma única consulta por caso fictício, sem alterar registros existentes."""
    results: list[tuple[WorkflowCase, str]] = []
    with SessionLocal() as db:
        professional = db.scalar(select(User).where(User.cpf == "11144477735"))
        reception = db.scalar(select(User).where(User.cpf == "98765432100"))
        if not professional or not reception:
            raise RuntimeError(
                "As contas fictícias de recepção e profissional são necessárias "
                "para preparar o fluxo de demonstração."
            )
        base = datetime.combine(date.today(), time.min)
        for index, case in enumerate(WORKFLOW_CASES, start=1):
            patient = db.scalar(select(User).where(User.cpf == case.cpf))
            if not patient:
                patient = User(
                    nome=case.name,
                    cpf=case.cpf,
                    email=_available_email(
                        db, f"paciente.fluxo{index}@ubs-rapida.local", case.cpf
                    ),
                    senha_hash=pwd.hash("PacienteFluxo@123"),
                    perfil="paciente",
                    ativo=True,
                    email_verificado=True,
                    data_nascimento=datetime(1990, 1, index),
                    e_prioridade="idoso_60+" if index == 4 else "geral",
                    e_menor_idade=False,
                )
                db.add(patient)
                db.flush()
            existing = db.scalar(
                select(Appointment).where(Appointment.paciente_id == patient.id)
            )
            if existing:
                results.append((case, "já existia; nenhum dado foi alterado"))
                continue

            scheduled_at = base.replace(hour=case.hour)
            arrival = scheduled_at - timedelta(minutes=10)
            row = Appointment(
                paciente_id=patient.id,
                medico_id=professional.id,
                especialidade=case.specialty,
                data_horario=scheduled_at,
                status=case.status,
                chegada_em=(
                    arrival
                    if case.status
                    in {"em_espera", "em_triagem", "em_atendimento", "concluido"}
                    else None
                ),
                chegada_por=(
                    reception.id
                    if case.status
                    in {"em_espera", "em_triagem", "em_atendimento", "concluido"}
                    else None
                ),
                falta_em=scheduled_at + timedelta(minutes=20)
                if case.status == "falta"
                else None,
                classificacao_risco=case.risk,
                triagem_dados=case.observation,
                triagem_por=professional.id if case.risk else None,
                triagem_em=arrival + timedelta(minutes=5) if case.risk else None,
                iniciado_em=scheduled_at
                if case.status in {"em_atendimento", "concluido"}
                else None,
                concluido_em=scheduled_at + timedelta(minutes=30)
                if case.status == "concluido"
                else None,
            )
            db.add(row)
            db.flush()
            if case.risk:
                db.add(
                    RiskClassification(
                        consulta_id=row.id,
                        profissional_id=professional.id,
                        nivel_risco=case.risk,
                        observacao=case.observation,
                        classificado_em=row.triagem_em,
                    )
                )
            results.append((case, "criada"))
        db.commit()
    return results


def main() -> int:
    # Mantém compatibilidade com atalhos antigos usando o seed completo atual.
    from seed_demonstracao import main as seed_main

    return seed_main()


if __name__ == "__main__":
    raise SystemExit(main())
