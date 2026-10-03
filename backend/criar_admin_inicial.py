"""Cria exclusivamente o primeiro administrador, sem alterar contas existentes."""
from getpass import getpass
from sqlalchemy import func, or_, select
from sqlalchemy.exc import IntegrityError
from pydantic import EmailStr, TypeAdapter, ValidationError

from app.core.config import check_config
from app.core.database import SessionLocal
from app.core.security import pwd
from app.main import digits, migrate_database, valid_cpf, valid_name, valid_password
from app.models import User


def create_initial_admin(name: str, cpf_value: str, email_value: str, password: str,
                         confirmation: str, allow_additional: bool = False) -> User:
    name = " ".join(name.split())
    cpf = digits(cpf_value)
    email = email_value.strip().lower()
    if not valid_name(name):
        raise ValueError("Informe nome e sobrenome usando apenas letras, espaços, hífen e acentos.")
    if any(c not in "0123456789.- " for c in cpf_value) or not valid_cpf(cpf):
        raise ValueError("CPF inválido.")
    try:
        TypeAdapter(EmailStr).validate_python(email)
    except ValidationError as exc:
        raise ValueError("E-mail inválido.") from exc
    if not valid_password(password):
        raise ValueError("A senha deve ter 8 a 32 caracteres, maiúscula, minúscula, número e símbolo.")
    if password != confirmation:
        raise ValueError("As senhas não coincidem.")
    migrate_database()
    with SessionLocal() as db:
        if (db.scalar(select(func.count(User.id)).where(User.perfil == "admin"))
                and not allow_additional):
            raise ValueError("Já existe administrador cadastrado. Nenhuma conta foi criada.")
        if db.scalar(select(User.id).where(or_(User.cpf == cpf, func.lower(User.email) == email))):
            raise ValueError("CPF ou e-mail já cadastrado. Nenhum registro foi alterado.")
        user = User(nome=name, cpf=cpf, email=email, senha_hash=pwd.hash(password),
                    perfil="admin", ativo=True)
        try:
            db.add(user); db.commit(); db.refresh(user)
        except IntegrityError as exc:
            db.rollback()
            raise ValueError("CPF ou e-mail já cadastrado. Nenhuma conta foi criada.") from exc
        return user


def main() -> int:
    try:
        check_config()
        migrate_database()
        with SessionLocal() as db:
            has_admin = bool(db.scalar(select(func.count(User.id)).where(User.perfil == "admin")))
        allow_additional = False
        if has_admin:
            answer = input(
                "Já existe Administrador. Deseja criar outro? Digite SIM para continuar: "
            ).strip().casefold()
            if answer != "sim":
                print("Operação cancelada. Nenhum dado foi alterado.")
                return 0
            allow_additional = True
        name = input("Nome completo: ").strip()
        cpf = input("CPF: ").strip()
        email = input("E-mail: ").strip()
        password = getpass("Senha: ")
        confirmation = getpass("Confirme a senha: ")
        user = create_initial_admin(
            name, cpf, email, password, confirmation,
            allow_additional=allow_additional,
        )
        print(f"Administrador criado com segurança (ID {user.id}).")
        return 0
    except (RuntimeError, ValueError) as exc:
        print(f"Erro: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
