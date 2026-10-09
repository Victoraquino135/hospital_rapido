# Painel Administrativo e usuários internos

## Entrega

Esta etapa adiciona o painel administrativo, painéis separados para recepção e profissional, autorização no backend, gestão de usuários internos, especialidades, grades, check-in, fila, histórico de status e auditoria. O cadastro público continua criando exclusivamente pacientes.

O banco original foi preservado. Antes da migração foi criada a cópia `backend/ubs_rapida.pre_admin.bak`. A migração é aditiva e pode ser executada mais de uma vez.

## Arquivos principais

- `backend/app/models/__init__.py`: campos de rastreabilidade e modelos de perfil profissional, grade, bloqueio, histórico e auditoria.
- `backend/app/schemas/__init__.py`: respostas seguras e contratos de usuários internos.
- `backend/app/core/security.py`: perfil canônico, permissões, JWT versionado e invalidação de sessões.
- `backend/app/main.py`: migração aditiva, login com permissões, proteção de dados e compatibilidade.
- `backend/app/routes/admin.py`: usuários, administradores, resumo, agenda, check-in, especialidades, grades, bloqueios e auditoria.
- `backend/app/routes/operations.py`: transições de atendimento por perfil e autorização de triagem.
- `backend/criar_admin_inicial.py`: criação interativa e exclusiva do primeiro administrador.
- `backend/tests/test_integration.py`: testes administrativos e de segurança.
- `frontend/lib/main.dart`: direcionamento automático por perfil.
- `frontend/lib/models/api_models.dart`: modelos administrativos e permissões da sessão.
- `frontend/lib/services/api_service.dart`: integração com as rotas administrativas.
- `frontend/lib/screens/admin_dashboard.dart`: painel administrativo responsivo.
- `frontend/lib/screens/dashboards.dart`: painéis operacionais de recepção e profissional.
- `frontend/test/admin_dashboard_test.dart`: responsividade, alto contraste, A+ e roteamento.

## Modelos e migração

Novas tabelas: `perfis_profissionais`, `grades_atendimento`, `bloqueios_agenda`, `historico_status_consultas` e `auditoria_administrativa`.

Novos campos em `usuarios`: `criado_por` e `ultima_alteracao_por`.

Novo campo em `consultas`: `chegada_por`.

Novo campo em `especialidades`: `ativo`.

Após a migração foram preservados 9 usuários, 5 consultas, 70 horários, 2 responsáveis e 2 vínculos de responsáveis existentes.

## Endpoints

- `POST /auth/login` e `GET /auth/me`: retornam perfil canônico e permissões.
- `GET/POST /admin/users`: lista e cadastra recepção/profissional.
- `PUT /admin/users/{id}`: altera dados permitidos e invalida sessão ao trocar perfil.
- `POST /admin/users/{id}/activate` e `/deactivate`: ativação lógica.
- `POST /admin/users/{id}/reset-access`: troca somente o hash BCrypt.
- `POST /admin/admins`: ação separada para outro administrador.
- `GET /admin/summary`: resumo real do dia.
- `GET /admin/appointments`: agenda filtrável e CPF protegido.
- `POST /admin/appointments/{id}/check-in`: chegada presencial idempotentemente protegida.
- `GET /queue`: fila ordenada no backend.
- `GET/POST /admin/grids`: consulta e criação de grades.
- `POST /admin/blocks`: bloqueios, folgas e indisponibilidades sem apagar consultas.
- `POST /admin/specialties`: cadastro de especialidades.
- `GET /admin/audit`: histórico sem senhas, hashes, tokens ou CPF completo.
- Endpoints anteriores de paciente foram mantidos.

## Matriz de permissões

- Paciente: cadastro público, login, próprio perfil, disponibilidade e próprios agendamentos.
- Administrador: usuários internos, ação separada para administradores, profissionais, especialidades, grades, agenda, check-in, fila, resumo e auditoria. Não registra triagem sem perfil profissional autorizado.
- Recepção: agenda do dia, pesquisa, check-in, fila e estados permitidos. Não gerencia usuários nem triagem.
- Profissional: agenda atribuída, fila, triagem quando autorizado, início e conclusão de atendimento. Não gerencia usuários ou grades.

## Execução no Windows

Backend:

```powershell
cd C:\ubs_Hospital_rapido\backend
.\venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 127.0.0.1 --port 8000
```

Flutter Windows:

```powershell
cd C:\ubs_Hospital_rapido\frontend
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Flutter Android (emulador ou dispositivo conectado):

```powershell
cd C:\ubs_Hospital_rapido\frontend
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Primeiro administrador:

```powershell
cd C:\ubs_Hospital_rapido\backend
.\venv\Scripts\python.exe .\criar_admin_inicial.py
```

O script recusa a operação se já existir qualquer administrador.

## Resultado individual dos 47 testes solicitados

1. Aprovado automaticamente: cadastro público cria somente paciente.
2. Aprovado por teste e interface: cadastro público não oferece perfil; entrada extra não promove a conta.
3. Aprovado automaticamente: primeiro administrador único, CPF/e-mail/senha validados e BCrypt.
4. Aprovado automaticamente no Flutter: paciente abre o painel do paciente.
5. Aprovado automaticamente no Flutter: administrador abre o painel administrativo.
6. Aprovado automaticamente no Flutter: recepção abre o painel operacional.
7. Aprovado automaticamente no Flutter: profissional abre o painel operacional.
8. Aprovado automaticamente: administrador cadastra recepcionista.
9. Aprovado automaticamente: administrador cadastra profissional com registro e especialidade.
10. Aprovado automaticamente: recepção recebe HTTP 403 ao cadastrar usuário.
11. Aprovado automaticamente: profissional recebe HTTP 403 ao cadastrar usuário.
12. Aprovado automaticamente: paciente recebe HTTP 403 em usuários internos.
13. Aprovado automaticamente: CPF inválido é recusado.
14. Aprovado automaticamente: CPF duplicado é recusado.
15. Aprovado automaticamente: e-mail duplicado é recusado.
16. Aprovado automaticamente: confirmação de senha interna diferente é recusada.
17. Aprovado automaticamente: senhas usam BCrypt.
18. Aprovado automaticamente: senha e hash não aparecem nas respostas.
19. Aprovado automaticamente: usuário desativado não entra.
20. Aprovado automaticamente: administrador não desativa a própria conta.
21. Aprovado automaticamente: último administrador ativo não é desativado.
22. Aprovado pela implementação e auditoria; troca de perfil invalida tokens. O cenário isolado de troca de perfil não possui teste dedicado.
23. Aprovado automaticamente: desativação mantém o registro.
24. Aprovado automaticamente: redefinição substitui o hash.
25. Aprovado automaticamente: senha antiga deixa de funcionar.
26. Aprovado automaticamente: senha nova permite login.
27. Aprovado automaticamente: recepção e administrador confirmam chegada.
28. Aprovado automaticamente: check-in duplicado é recusado.
29. Aprovado automaticamente: consulta cancelada não recebe check-in.
30. Aprovado automaticamente: profissional autorizado registra triagem.
31. Aprovado automaticamente: administrador sem autorização recebe HTTP 403 na triagem.
32. Implementado no backend por risco, prioridade legal e chegada. A suíte atual não possui cenário dedicado com múltiplos pacientes para cada critério.
33. Aprovado automaticamente: grade válida é salva.
34. Aprovado automaticamente: sobreposição de grade é recusada.
35. Aprovado automaticamente para intervalo de almoço; bloqueios usam a mesma fonte de disponibilidade, mas não há teste dedicado de todos os motivos.
36. Aprovado automaticamente: consultas sobrevivem ao reinício da API; o SQLite real foi verificado após migração.
37. Aprovado automaticamente: token ausente é recusado.
38. Aprovado automaticamente: token inválido ou vencido é recusado.
39. Aprovado automaticamente no painel administrativo: alto contraste liga e restaura o tema.
40. Aprovado automaticamente: A−, A e A+ persistem; A+ foi testado em 390 px sem overflow.
41. Aprovado automaticamente para TAB e Shift+TAB; os controles usam Semantics, foco visível e ativação nativa por teclado. A suíte não percorre todas as combinações possíveis de ENTER/ESPAÇO em cada tela.
42. Aprovado em testes Flutter de 390 px e 1280 px e na compilação Windows. Não foi gerado APK nesta execução.
43. Aprovado: 65 testes do backend.
44. Aprovado: 27 testes do Flutter.
45. Aprovado: `flutter analyze` sem problemas.
46. Aprovado: executável Windows gerado em `frontend/build/windows/x64/runner/Release/ubs_saude.exe`.
47. Aprovado: testes existentes do painel, agendamento, cancelamento, reagendamento e acessibilidade do paciente continuam passando.

## Limitações explícitas

- A alteração obrigatória da senha provisória no primeiro acesso não foi criada, para não entregar um fluxo incompleto.
- Recuperação de senha pública já existia no projeto e foi preservada para não remover funcionalidade do paciente; a gestão interna não envia senhas nem códigos.
- A grade mantém compatibilidade com a tabela de horários unitários existente; capacidade maior que um é registrada na grade, mas o esquema legado de agendamentos ainda protege uma consulta ativa por profissional/horário.
- Não houve teste manual em dispositivo Android físico nem teste automatizado integral de navegação por teclado.

## Roteiro de vídeo com dados fictícios

1. Mostrar o login único e entrar como administrador fictício.
2. Abrir Visão geral e destacar os indicadores vindos da API.
3. Cadastrar `Rita Recepção` com CPF fictício válido e senha provisória.
4. Cadastrar `Paula Profissional`, registro `COREN-FICT-123`, especialidade fictícia e autorização de triagem.
5. Sair e entrar com cada perfil para demonstrar o direcionamento automático.
6. Como administrador, cadastrar uma especialidade e uma grade com intervalo.
7. Como paciente fictício, escolher especialidade, profissional, data e horário e confirmar o agendamento.
8. Como recepção, localizar a consulta e confirmar a chegada.
9. Como profissional autorizado, registrar triagem fictícia, iniciar e concluir atendimento.
10. Reiniciar o backend e mostrar que usuários, grade e consulta permanecem.
11. Tentar acessar usuários com paciente/recepção e mostrar o bloqueio do backend.
12. Demonstrar desativação com confirmação, redefinição de acesso e auditoria sem dados sensíveis.
13. Demonstrar A−, A, A+, alto contraste, navegação responsiva e foco por teclado.
