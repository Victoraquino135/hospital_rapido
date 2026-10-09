# Relatório de integração — tela principal do paciente

## Arquivos alterados

- `frontend/lib/screens/dashboards.dart`: tela principal responsiva, próxima consulta, atalhos, lista, detalhes, acompanhamento, perfil, confirmação de cancelamento, saída e polling a cada cinco segundos. O painel da equipe foi preservado.
- `frontend/lib/screens/booking.dart`: seleção encadeada de especialidade, profissional, data e horário; resumo; confirmação somente após sucesso da API; mensagens de indisponibilidade e conexão.
- `frontend/lib/services/api_service.dart`: leitura do perfil, resumo, detalhes, profissionais e disponibilidade; uso de `/appointments/me`; tratamento de sessão expirada e mensagem de cancelamento.
- `frontend/lib/models/api_models.dart`: modelos para perfil, resumo, local opcional e mensagem da API.
- `frontend/test/patient_dashboard_test.dart`: testes de desktop, celular, agendamento, polling, reconexão e sessão expirada.
- `backend/app/main.py`: perfil e resumo por JWT, detalhes com verificação de propriedade, lista do paciente, datas e horários disponíveis, índices aditivos e resposta de cancelamento.
- `backend/app/schemas/__init__.py`: modelos Pydantic de perfil, resumo e catálogo.
- `backend/app/routes/operations.py`: modelos de resposta para especialidades e profissionais.
- `backend/tests/test_integration.py`: testes de propriedade, disponibilidade, conflito, concorrência, limites exatos de tempo e token vencido.
- `docs/documentacao_projeto/ATUALIZACAO_INTEGRACAO.md`: descrição atualizada da autenticação, painel e migração.
- `backend/ubs_rapida.db`: somente três índices novos; nenhuma tabela ou coluna removida.

## API

Endpoints novos: `GET /patients/me`, `GET /patients/me/summary`, `GET /appointments/{appointment_id}`, `GET /availability/dates` e `GET /availability/times`.

Endpoints ajustados: `GET /appointments/me` agora exige paciente e lista somente suas consultas; `POST` e `PUT /appointments/{appointment_id}/cancel` e `/reschedule` exigem paciente; `GET /specialties` e `/professionals` declaram modelos de resposta. As rotas antigas `/appointments`, `/available-slots` e `/appointments/available` continuam disponíveis.

O paciente é obtido do JWT, sem ID enviado pelo Flutter. A leitura, o cancelamento e o reagendamento verificam a propriedade da consulta. O índice único e a transação `BEGIN IMMEDIATE` protegem a vaga durante gravações concorrentes. O perfil expõe CPF oculto e não inclui hash ou token.

## Banco existente

SQLite em `backend/ubs_rapida.db`. Estruturas reaproveitadas: `usuarios`, `especialidades`, `agendas_profissionais`, `consultas` e vínculos de responsáveis. Cada linha de agenda representa uma vaga. Não existe coluna de unidade/local; por isso o campo é opcional na API e omitido na interface quando ausente.

Migração aditiva e idempotente aplicada:

- `uq_consulta_vaga_ativa`: índice único parcial em `consultas(medico_id, data_horario)` para status diferente de `cancelado`.
- `ix_consulta_paciente_status_data`: índice em `consultas(paciente_id, status, data_horario)`.
- `ix_agenda_especialidade_data`: índice em `agendas_profissionais(especialidade, data_horario)`.

Antes e depois da migração e da inicialização da API, as contagens eram as mesmas: 6 usuários, 1 consulta, 70 horários e 1 especialidade. Nenhum registro foi apagado.

## Ligação entre as camadas

O login mantém o JWT apenas na sessão ativa do Flutter. O painel solicita `/patients/me/summary` e `/appointments/me` em paralelo e atualiza a cada cinco segundos enquanto está montado. O agendamento lê catálogo, profissionais, datas e horários pela API; a gravação confirma a vaga outra vez no backend. Após agendar, cancelar ou reagendar, o painel recarrega os dados. O banco permanece acessível somente ao backend.

## Verificações

- Backend: **60 testes passaram**, incluindo persistência de agendamento após reiniciar a aplicação FastAPI. Resultado individual em `output/testes_backend_paciente.txt`.
- Flutter: **18 testes passaram**. Resultado individual em `output/testes_flutter_paciente.txt`.
- `flutter analyze`: nenhum problema.
- `flutter build windows --dart-define=API_BASE_URL=http://127.0.0.1:8000`: executável gerado em `frontend/build/windows/x64/runner/Release/ubs_saude.exe`.
- API iniciada com o SQLite existente: `/health` respondeu `ok` e `/docs` respondeu HTTP 200.

Limites da verificação: o APK Android não pôde ser compilado porque o Gradle falhou na validação do certificado HTTPS ao baixar a distribuição 9.1.0. Os testes de layout móvel passaram no Flutter, mas não substituem a execução em aparelho físico. Não foi realizado um teste automatizado de ponta a ponta com a interface Flutter conectada a um processo FastAPI real; o fluxo da API foi testado com `TestClient` e a interface com serviço simulado. Não foi testado um leitor de tela físico.

## Executar no Windows

Em um terminal PowerShell:

```powershell
cd C:\ubs_Hospital_rapido\backend
.\venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Em outro terminal, para Windows:

```powershell
cd C:\ubs_Hospital_rapido\frontend
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Para emulador Android, use `flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8000` após resolver a instalação do Gradle. Em aparelho físico, substitua `10.0.2.2` pelo endereço local do computador. A documentação interativa fica em <http://127.0.0.1:8000/docs> enquanto a API estiver rodando.

Para demonstração, use contas fictícias de paciente e de equipe criadas pelo cadastro e por `backend/manage_staff.py`, além de uma especialidade, um profissional vinculado e horários futuros cadastrados pelo perfil administrador. Não é necessário expor senhas, tokens ou CPF completo no relatório.
