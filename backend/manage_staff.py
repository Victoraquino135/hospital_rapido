"""Cadastro local de equipe, sem endpoint público de promoção de perfil."""
import argparse
from getpass import getpass
from sqlalchemy import select
from app.main import migrate_database, valid_cpf, valid_name, valid_password
from app.models import User
from app.core.database import SessionLocal
from app.core.security import pwd
from app.core.config import check_config

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Cadastrar profissional ou administrador da UBS')
    parser.add_argument('--role', choices=['admin', 'recepcao', 'enfermagem', 'medico'], required=True)
    args = parser.parse_args()
    check_config()
    name = input('Nome completo: ').strip()
    cpf = input('CPF (11 números): ').strip()
    email = input('E-mail: ').strip().lower()
    password = getpass('Senha: ')
    from pydantic import TypeAdapter, EmailStr
    TypeAdapter(EmailStr).validate_python(email)
    if not valid_name(name) or not valid_cpf(cpf) or not valid_password(password):
        raise SystemExit('Dados inválidos; nada foi gravado.')
    if getpass('Confirme a senha: ') != password:
        raise SystemExit('Senhas diferentes; nada foi gravado.')
    migrate_database()
    with SessionLocal() as db:
        if db.scalar(select(User).where((User.cpf == cpf) | (User.email == email))):
            raise SystemExit('CPF ou e-mail já cadastrado; nada foi alterado.')
        db.add(User(nome=name, cpf=cpf, email=email, senha_hash=pwd.hash(password), perfil=args.role))
        db.commit()
    print('Cadastro da equipe concluído.')
