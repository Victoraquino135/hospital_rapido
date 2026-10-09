# Implementacao do perfil Medico dedicado

**Especificacao:** `docs/superpowers/specs/2026-10-08-medical-profile-design.md`

## Objetivo

Implementar o perfil `medico` de ponta a ponta sem apagar ou recriar o SQLite existente e sem incorporar alteracoes locais nao relacionadas.

## Etapa 1 - Contratos e migracao do backend

**Arquivos:**

- `backend/app/models/__init__.py`
- `backend/app/schemas/__init__.py`
- `backend/app/core/security.py`
- `backend/app/main.py`
- `backend/tests/test_medical_profile.py`

1. Criar testes para perfil canonico `medico`, migracao idempotente de `profissional`, novas colunas de atendimento e indice parcial de exclusividade.
2. Executar os testes novos e confirmar a falha esperada.
3. Adicionar `resumo_atendimento` e `atendimento_medico_id` ao modelo e a migracao incremental.
4. Migrar somente valores legados `profissional` para `medico`.
5. Trocar permissoes e JWTs para o papel canonico `medico`, mantendo leitura transitoria do valor legado durante a migracao.
6. Criar schemas dedicados de fila, detalhes e conclusao.
7. Executar testes focados e a suite existente do backend.

## Etapa 2 - API medica e regras de fluxo

**Arquivos:**

- `backend/app/routes/medical.py`
- `backend/app/routes/__init__.py`
- `backend/app/main.py`
- `backend/app/services/appointments.py`
- `backend/tests/test_medical_profile.py`

1. Criar testes de fila autorizada, ordenacao, dados minimos e bloqueio de consultas alheias.
2. Criar testes de inicio, conclusao com resumo, repeticao, ordem invalida e atendimento concorrente.
3. Executar os testes e confirmar as falhas esperadas.
4. Implementar `GET /medico/fila` e `GET /medico/atendimentos/{id}`.
5. Implementar inicio transacional com validacao de check-in, triagem, vinculo e exclusividade.
6. Implementar conclusao transacional exigindo resumo e o mesmo Medico iniciador.
7. Registrar historico de status em todas as transicoes.
8. Remover o acesso do Medico a rotas administrativas, grades, check-in e triagem.
9. Manter aliases antigos apenas quando necessarios para compatibilidade interna, sem anunciar `profissional` no login ou UI.
10. Executar testes focados e suite completa do backend.

## Etapa 3 - Administracao e seed

**Arquivos:**

- `backend/app/routes/admin.py`
- `backend/seed_demonstracao.py`
- `backend/criar_dados_demonstracao.py`
- `backend/manage_staff.py`
- `backend/tests/test_medical_profile.py`

1. Criar testes para listar, pesquisar, criar, editar, ativar e desativar Medicos.
2. Cobrir CPF invalido/duplicado, senha insegura, resposta sem credenciais e login bloqueado apos desativacao.
3. Implementar contratos administrativos dedicados com perfil fixo `medico`.
4. Gerar e-mail e registro tecnicos unicos e associar Clinica Geral.
5. Implementar seed idempotente do Dr. Victor Almeida sem alterar outras contas.
6. Executar o seed duas vezes contra banco temporario e verificar uma unica conta.
7. Executar testes focados e suite completa do backend.

## Etapa 4 - Cliente Flutter e painel Medico

**Arquivos:**

- `frontend/lib/models/api_models.dart`
- `frontend/lib/services/api_service.dart`
- `frontend/lib/main.dart`
- `frontend/lib/screens/medical_dashboard.dart`
- `frontend/lib/screens/staff_dashboard.dart`
- `frontend/test/medical_dashboard_test.dart`
- `frontend/test/widget_test.dart`

1. Criar testes de redirecionamento para `MedicalDashboard`, fila, estados vazios/erro/carregamento e layout responsivo.
2. Criar testes de resumo obrigatorio, inicio, conclusao e atualizacao automatica.
3. Executar os testes e confirmar as falhas esperadas.
4. Adicionar modelos e chamadas aos endpoints `/medico`.
5. Implementar painel responsivo com cabecalho, contador, fila ordenada e dialogo/painel de atendimento.
6. Exibir risco, prioridade e status com texto e icone, mantendo a paleta e os componentes existentes.
7. Atualizar a cada quatro segundos, apos mutacoes e cancelar o temporizador no descarte.
8. Redirecionar exclusivamente o papel `medico` para o painel novo.
9. Executar formatacao, analise e testes Flutter focados.

## Etapa 5 - Secao Medicos no Administrador

**Arquivos:**

- `frontend/lib/services/api_service.dart`
- `frontend/lib/models/api_models.dart`
- `frontend/lib/screens/admin_dashboard.dart`
- `frontend/test/admin_dashboard_test.dart`
- `frontend/test/medical_admin_test.dart`

1. Criar testes da secao, pesquisa, indicador de disponibilidade, formulario e ativacao.
2. Executar os testes e confirmar as falhas esperadas.
3. Implementar secao `Medicos` separada da lista generica de usuarios internos.
4. Implementar criacao com nome, CPF, senha, confirmacao e status; edicao com nome, CPF e status.
5. Garantir navegacao por teclado, mensagens claras, estados de carregamento e ausencia de senha em listas.
6. Executar formatacao, analise e testes Flutter focados.

## Etapa 6 - Inicializador e documentacao

**Arquivos:**

- `INICIAR_TUDO.bat`
- `iniciar.ps1`
- `README.md`
- `backend/README.md`
- `docs/README.md`
- documentacao existente em `docs/02_perfis`, `docs/04_fluxos` e `docs/06_api`
- `tests/test_iniciar_tudo.ps1`

1. Atualizar testes do inicializador para exigir a exibicao das credenciais ficticias do Medico.
2. Atualizar o resumo de inicializacao sem expor segredos reais.
3. Documentar perfil, permissoes, fluxo, credenciais e comandos de teste.
4. Validar links, comandos e consistencia dos nomes de status.

## Etapa 7 - Verificacao final

1. Executar toda a suite `pytest` do backend.
2. Executar `flutter analyze` e toda a suite `flutter test`.
3. Executar a validacao automatizada do `INICIAR_TUDO.bat`/`iniciar.ps1`.
4. Executar o backend com banco de teste isolado e verificar Swagger e endpoints.
5. Realizar o fluxo manual com contas ficticias: login, check-in, triagem, inicio, conclusao, atualizacao do Paciente, criacao e desativacao de Medico.
6. Conferir `git diff --check` e revisar somente os arquivos alterados para esta funcionalidade.
7. Registrar os testes executados, arquivos modificados e credenciais ficticias de todos os perfis documentados.
