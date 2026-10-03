"""Cria somente as contas fictícias de demonstração que ainda não existem."""

from dataclasses import dataclass
from datetime import datetime

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError

from app.core.config import check_config
from app.core.database import SessionLocal
from app.core.security import pwd
from app.main import migrate_database
from app.models import ProfessionalProfile, Specialty, User


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


def main() -> int:
    try:
        print("Contas fictícias de demonstração:")
        for account, status in ensure_demo_accounts():
            print(f"- {account.name} ({account.cpf}): {status}.")
        return 0
    except (RuntimeError, IntegrityError) as exc:
        print(f"Erro: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
