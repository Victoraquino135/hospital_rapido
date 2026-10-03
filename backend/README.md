# API UBS Rápida

FastAPI, SQLAlchemy, SQLite persistente, JWT e BCrypt. Configuração, execução, criação de equipe e testes em [ATUALIZACAO_INTEGRACAO.md](../docs/documentacao_projeto/ATUALIZACAO_INTEGRACAO.md).

As migrações são aditivas. Não apague `ubs_rapida.db`. Execute `setup_env.py` antes da primeira inicialização e configure o SMTP em `.env` para recuperação real por e-mail.

A documentação interativa fica em `http://127.0.0.1:8000/docs` quando a API está em execução.

## Primeiro administrador

Execute somente quando ainda não existir administrador:

```powershell
cd C:\ubs_Hospital_rapido\backend
.\venv\Scripts\python.exe .\criar_admin_inicial.py
```

O cadastro público permanece exclusivo para pacientes. Recepcionistas e profissionais são cadastrados pelo Painel Administrativo. O relatório completo está em [PAINEL_ADMINISTRATIVO.md](../docs/documentacao_projeto/PAINEL_ADMINISTRATIVO.md).
