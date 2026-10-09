# API UBS Rápida

FastAPI, SQLAlchemy, SQLite persistente, JWT e BCrypt. Consulte o [índice da API](../docs/06_api/endpoints.md), a [estrutura do banco](../docs/05_banco_de_dados/estrutura_banco.md) e os [resultados de testes](../docs/07_testes/testes_e_resultados.md).

As migrações são aditivas. Não apague `ubs_rapida.db`. Execute `setup_env.py` antes da primeira inicialização e configure o SMTP em `.env` para a recuperação real por e-mail e para as rotas auxiliares de verificação. O cadastro atual permite login imediato e não depende do SMTP. Use uma senha de aplicativo do Gmail, nunca a senha normal da conta. Os códigos de 6 dígitos são armazenados somente como hash, expiram em 10 minutos e têm uso único.

A documentação interativa fica em `http://127.0.0.1:8000/docs` quando a API está em execução.

## Primeiro administrador

Execute somente quando ainda não existir administrador:

```powershell
cd C:\ubs_Hospital_rapido\backend
.\venv\Scripts\python.exe .\criar_admin_inicial.py
```

O cadastro público permanece exclusivo para pacientes. Recepcionistas, Enfermagem e Médicos são cadastrados pelo Painel Administrativo. Médicos usam as rotas `/medico/*`, acessam apenas a própria fila triada e concluem o atendimento com resumo obrigatório. O relatório original do painel foi preservado no [arquivo histórico](../docs/99_arquivo_historico/acervo_documentacao_projeto/PAINEL_ADMINISTRATIVO.md).

Conta Médica fictícia idempotente: CPF `39053344705`, senha `Medico@123`. O seed preserva o SQLite e converte o perfil legado `profissional` para `medico` sem alterar IDs ou vínculos.
