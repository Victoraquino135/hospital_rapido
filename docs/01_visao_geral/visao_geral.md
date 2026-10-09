# Visão geral

O UBS Rápida é um MVP acadêmico para organizar o agendamento e o fluxo presencial de uma UBS. O Flutter consome uma API FastAPI; a API aplica autenticação e autorização e persiste os dados em SQLite.

## Arquitetura

```text
Flutter para Windows
        |
        | HTTP + JWT
        v
FastAPI / SQLAlchemy
        |
        v
backend/ubs_rapida.db
```

O frontend ativo está em `frontend/lib/`, com entrada em `frontend/lib/main.dart`. O backend ativo está em `backend/app/`, com aplicação em `backend/app/main.py`. O arquivo `backend/main.py` apenas reexporta a aplicação para compatibilidade.

## Perfis e navegação

O login é único. O usuário informa CPF e senha, a API devolve um JWT e o perfil, e `homeForRole()` abre `PatientDashboard`, `StaffDashboard`, `MedicalDashboard` ou `AdminDashboard`. Não existem botões públicos para escolher perfil.

## Limites

O sistema usa apenas dados fictícios e não implementa prontuário completo, prescrição, exames, vacinação, pagamentos, telemedicina, integrações governamentais, mensageria ou diagnóstico automatizado.
