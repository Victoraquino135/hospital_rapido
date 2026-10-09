# Frontend Usability Refinements Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Melhorar força da senha, navegação desktop do paciente, clareza dos horários, aproveitamento de espaço nos painéis da equipe, estados vazios/status e legibilidade da auditoria sem alterar backend ou banco.

**Architecture:** Componentes reutilizáveis concentram força da senha, modos de navegação ampla, cartões de horário, estados vazios e etiquetas. As telas existentes apenas escolhem o modo e fornecem os dados já retornados pela API; nenhuma regra de negócio ou contrato HTTP muda.

**Tech Stack:** Flutter/Dart, Material 3, Flutter Test.

**Spec:** `docs/superpowers/specs/2026-10-08-frontend-usability-refinements-design.md`

## Global Constraints

- Esta fase modifica somente o frontend Flutter.
- Não criar endpoint, campo persistente, migração ou filtro histórico simulado.
- Preservar suporte às escalas de fonte 100%, 115% e 130%.
- Preservar alto contraste, navegação por teclado e leitor de tela.
- Controles acionáveis devem ter pelo menos 48 px.
- O celular mantém a navegação atual do paciente.
- Alterações e commits devem preservar todas as modificações locais preexistentes; antes de cada commit, revisar o diff staged e nunca incluir mudanças não relacionadas.

## Review Focus

- Senha vazia deve mostrar somente orientação neutra, sem classificar como fraca; coberto na Task 1.
- Menu sobreposto deve fechar por seleção, barreira, voltar e `Esc` sem alterar seção quando cancelado; coberto na Task 2.
- `destinations` vazio nunca deve reservar os 260 px da navegação ampla, mesmo se o modo padrão for `persistentRail`; coberto na Task 2.
- Horário com `selectable == false` não pode chamar o callback, inclusive em alto contraste; coberto na Task 3.
- Metadados longos da auditoria não podem cortar nem sobrepor conteúdo com 130% de fonte e 360 px; coberto na Task 5.

---

### Task 1: Indicador reutilizável de força da senha

**Files:**
- Modify: `frontend/lib/widgets/password_rules.dart`
- Modify: `frontend/lib/screens/auth_pages.dart`
- Create: `frontend/test/password_strength_test.dart`

**Interfaces:**
- Produces: `enum PasswordStrength { weak, medium, strong }`
- Produces: `PasswordStrength passwordStrength(String password)`
- Produces: `PasswordStrengthIndicator({required String password})`
- Consumes: regra existente `strongPassword(String)` apenas para manter a validação do cadastro; o indicador não substitui o validador.

- [ ] **Step 1: Escrever testes falhando do cálculo e estado neutro**

Criar testes `empty_password_has_neutral_guidance`, `password_strength_has_three_levels` e `indicator_exposes_text_and_semantics`. Asserções literais: vazio não mostra `Fraca`; `abc` mostra `Fraca`; `Paciente1` mostra `Média`; `Paciente@123` mostra `Forte`; semântica anuncia `Força da senha: Forte`.

- [ ] **Step 2: Executar os testes e confirmar RED**

Run: `flutter test test/password_strength_test.dart`

Expected: FAIL porque `PasswordStrength`, `passwordStrength` e `PasswordStrengthIndicator` ainda não existem.

- [ ] **Step 3: Implementar cálculo e apresentação em `password_rules.dart`**

Implementar as interfaces acima. Pontuar comprimento mínimo, maiúscula, minúscula, número e símbolo; mapear 0–2 para `weak`, 3–4 para `medium` e 5 para `strong`, mas tratar vazio como orientação neutra. A barra, o texto e a semântica devem responder a alto contraste.

- [ ] **Step 4: Integrar no login e cadastro**

Adicionar listeners aos controladores de senha para reconstruir somente durante a vida da tela. Exibir o indicador abaixo do campo de senha nas duas telas; manter `passwordRule` no cadastro e validação de presença no login. Remover listener antes de `dispose`.

- [ ] **Step 5: Executar testes focados**

Run: `flutter test test/password_strength_test.dart test/auth_responsive_test.dart test/widget_test.dart`

Expected: PASS, incluindo login sem bloqueio por força e cadastro sem overflow em 360 px/130%.

- [ ] **Step 6: Revisar e registrar a tarefa**

Revisar `git diff` e staged diff para não incluir alterações anteriores de `auth_pages.dart`. Commit sugerido: `feat(frontend): mostra força da senha`.

---

### Task 2: Modos explícitos de navegação ampla

**Files:**
- Modify: `frontend/lib/widgets/responsive_shell.dart`
- Modify: `frontend/lib/screens/dashboards.dart`
- Modify: `frontend/lib/screens/staff_dashboard.dart`
- Modify: `frontend/test/responsive_shell_test.dart`
- Modify: `frontend/test/patient_dashboard_test.dart`
- Modify: `frontend/test/staff_profiles_test.dart`
- Modify: `frontend/test/admin_dashboard_test.dart`

**Interfaces:**
- Produces: `enum WideNavigationMode { persistentRail, overlayDrawer, contentOnly }`
- Produces: parâmetro `ResponsiveAppShell.wideNavigationMode`, padrão `WideNavigationMode.persistentRail`.
- Produces: chave `Key('wide-navigation-menu-button')` no botão do menu sobreposto.
- Consumes: `AppDestination`, `selectedIndex` e `onDestinationSelected` existentes.

- [ ] **Step 1: Escrever testes falhando dos três modos**

Em `responsive_shell_test.dart`, testar: `overlayDrawer` não mostra `NavigationRail` inicialmente, mostra o botão, abre um painel com destinos e fecha após seleção; `contentOnly` não mostra rail e posiciona o conteúdo principal antes de x=100 em uma janela de 1280 px; `destinations: []` força conteúdo integral; `persistentRail` mantém o comportamento administrativo.

Adicionar teste de cancelamento por barreira/voltar e teste com evento `LogicalKeyboardKey.escape` garantindo que o índice não muda.

- [ ] **Step 2: Executar testes do shell e confirmar RED**

Run: `flutter test test/responsive_shell_test.dart`

Expected: FAIL porque o enum, parâmetro e botão ainda não existem.

- [ ] **Step 3: Implementar os modos em `ResponsiveAppShell`**

Adicionar `WideNavigationMode`. No layout amplo:

- `persistentRail`: conservar coluna e `NavigationRail` quando houver destinos;
- `overlayDrawer`: renderizar conteúdo integral e botão que abre rota modal lateral com barreira descartável;
- `contentOnly` ou lista vazia: renderizar conteúdo integral, com marca no conteúdo e sem coluna vazia.

A rota modal deve fechar em seleção antes de chamar `onDestinationSelected`, aceitar voltar/`Esc` e não mudar o índice quando descartada.

- [ ] **Step 4: Configurar cada tela**

Em `PatientDashboard`, passar `WideNavigationMode.overlayDrawer`. Em `StaffDashboard`, passar `WideNavigationMode.contentOnly`. `AdminDashboard` permanece no padrão `persistentRail`. Não alterar a navegação compacta.

- [ ] **Step 5: Executar testes das telas e shell**

Run: `flutter test test/responsive_shell_test.dart test/patient_dashboard_test.dart test/staff_profiles_test.dart test/admin_dashboard_test.dart`

Expected: PASS; paciente mobile mantém `NavigationBar`, admin wide mantém um `NavigationRail`, equipe wide não mostra rail.

- [ ] **Step 6: Revisar e registrar a tarefa**

Revisar diffs e registrar apenas arquivos desta tarefa. Commit sugerido: `feat(frontend): ajusta navegacao ampla por perfil`.

---

### Task 3: Cartões acessíveis de disponibilidade e resumo do agendamento

**Files:**
- Modify: `frontend/lib/widgets/app_components.dart`
- Modify: `frontend/lib/screens/booking.dart`
- Modify: `frontend/test/patient_dashboard_test.dart`
- Create: `frontend/test/availability_slot_card_test.dart`

**Interfaces:**
- Produces: `AvailabilitySlotCard({required Slot slot, required bool selected, required VoidCallback? onPressed})`
- Produces: `AvailabilityLegend()`
- Consumes: `Slot.label`, `Slot.availability`, `Slot.selectable` e `Slot.scheduledAt`.

- [ ] **Step 1: Escrever testes falhando dos estados do cartão**

Criar testes `available_slot_is_actionable`, `unavailable_slot_never_invokes_callback`, `selected_slot_has_check_and_semantics` e `slot_states_survive_high_contrast`. Validar texto do horário, rótulos `Disponível`/`Indisponível`/`Selecionado`, ícones e ausência de callback no estado indisponível.

- [ ] **Step 2: Executar teste do componente e confirmar RED**

Run: `flutter test test/availability_slot_card_test.dart`

Expected: FAIL porque os componentes não existem.

- [ ] **Step 3: Implementar cartão e legenda**

Adicionar os componentes a `app_components.dart`. Usar texto, ícone, borda e preenchimento para diferenciar estados; não depender apenas de cor. Garantir altura mínima de 48 px e largura adaptável.

- [ ] **Step 4: Substituir `ChoiceChip` e organizar o resumo**

Em `booking.dart`, renderizar a legenda e os cartões em `Wrap`. O callback só define `chosen` para slots selecionáveis. Reformular o cartão `Resumo` com rótulos `Especialidade`, `Profissional`, `Data` e `Horário`, mantendo o botão de confirmação e o fluxo atual.

- [ ] **Step 5: Executar testes focados de agendamento**

Run: `flutter test test/availability_slot_card_test.dart test/patient_dashboard_test.dart`

Expected: PASS; agendamento e reagendamento ainda enviam uma única requisição.

- [ ] **Step 6: Revisar e registrar a tarefa**

Commit sugerido: `feat(frontend): esclarece disponibilidade de horarios`.

---

### Task 4: Estados vazios e etiquetas de status da equipe/administração

**Files:**
- Modify: `frontend/lib/widgets/app_components.dart`
- Modify: `frontend/lib/screens/staff_dashboard.dart`
- Modify: `frontend/lib/screens/admin_dashboard.dart`
- Modify: `frontend/test/staff_profiles_test.dart`
- Modify: `frontend/test/admin_dashboard_test.dart`

**Interfaces:**
- Produces: `AppEmptyState({required IconData icon, required String title, required String message, String? actionLabel, VoidCallback? onAction})`
- Produces: `enum StatusTone { neutral, info, success, warning, danger }`
- Produces: `AppStatusBadge({required String label, required StatusTone tone, String? semanticLabel})`
- Consumes: filtros e carregamento existentes de `StaffDashboard`; não cria chamadas novas.

- [ ] **Step 1: Escrever testes falhando dos componentes**

Testar área acionável, texto/semântica do badge e estado vazio com ação opcional. Em `staff_profiles_test.dart`, estender `FakeStaffApi` para capturar os parâmetros da última consulta, aplicar busca/status sem resultado, tocar `Limpar filtros` e validar na chamada seguinte que especialidade, profissional, situação, risco e busca são nulos/vazios enquanto a data permanece igual.

- [ ] **Step 2: Executar testes focados e confirmar RED**

Run: `flutter test test/design_system_test.dart test/staff_profiles_test.dart test/admin_dashboard_test.dart`

Expected: FAIL porque os componentes e a limpeza ainda não existem.

- [ ] **Step 3: Implementar componentes compartilhados**

Adicionar `AppEmptyState`, `StatusTone` e `AppStatusBadge` a `app_components.dart`, com alto contraste, texto e semântica.

- [ ] **Step 4: Integrar e implementar limpeza segura**

Substituir `_StaffEmpty` por `AppEmptyState`. Criar `_clearFilters()` em `StaffDashboard`: limpar `specialty`, `professionalId`, `status`, `risk` e `search`, preservar `day` e chamar `load()`. Mostrar a ação apenas se algum desses filtros estiver ativo.

Usar `AppStatusBadge` no cabeçalho de status de `_itemCard` em `StaffDashboard` e no status de cada item de `_AgendaAdminView` em `AdminDashboard`, preservando todos os textos existentes.

- [ ] **Step 5: Executar testes focados**

Run: `flutter test test/design_system_test.dart test/staff_profiles_test.dart test/admin_dashboard_test.dart`

Expected: PASS, inclusive 360 px/130% e alto contraste.

- [ ] **Step 6: Revisar e registrar a tarefa**

Commit sugerido: `feat(frontend): padroniza estados operacionais`.

---

### Task 5: Metadados responsivos da auditoria

**Files:**
- Modify: `frontend/lib/screens/admin_dashboard.dart`
- Modify: `frontend/test/admin_dashboard_test.dart`

**Interfaces:**
- Produces: widget privado `_AuditMetadata({required String createdAt})`.
- Consumes: `item['created_at']` existente, mantendo o formato `yyyy-MM-dd HH:mm`.

- [ ] **Step 1: Escrever teste falhando de legibilidade**

Adicionar `audit_metadata_is_16px_and_wraps_below_on_compact`. Em 1440 px, validar rótulo e data à direita com fonte efetiva de 16 px. Em 360 px e escala 1.30, validar ausência de overflow e metadados abaixo do texto principal.

- [ ] **Step 2: Executar teste e confirmar RED**

Run: `flutter test test/admin_dashboard_test.dart --plain-name "audit_metadata_is_16px_and_wraps_below_on_compact"`

Expected: FAIL porque `_AuditMetadata` e o layout responsivo ainda não existem.

- [ ] **Step 3: Implementar `_AuditMetadata` e layout adaptável**

Usar fonte base de 16 px para `Registrado` e data/hora. Em largura suficiente, manter à direita; em largura compacta ou com texto ampliado, posicionar após título/subtítulo. Não alterar os dados nem a ordem da auditoria.

- [ ] **Step 4: Executar testes administrativos**

Run: `flutter test test/admin_dashboard_test.dart`

Expected: PASS sem overflow em desktop, celular e fonte ampliada.

- [ ] **Step 5: Revisar e registrar a tarefa**

Commit sugerido: `fix(frontend): amplia metadados da auditoria`.

---

### Task 6: Verificação integrada do frontend

**Files:**
- Verify only; corrigir somente regressões causadas pelas Tasks 1–5.

**Interfaces:**
- Consumes: todos os componentes e comportamentos anteriores.
- Produces: frontend validado contra a especificação completa.

- [ ] **Step 1: Executar formatação nos arquivos alterados**

Run: `dart format lib/widgets/password_rules.dart lib/widgets/responsive_shell.dart lib/widgets/app_components.dart lib/screens/auth_pages.dart lib/screens/dashboards.dart lib/screens/booking.dart lib/screens/staff_dashboard.dart lib/screens/admin_dashboard.dart test/password_strength_test.dart test/responsive_shell_test.dart test/patient_dashboard_test.dart test/staff_profiles_test.dart test/admin_dashboard_test.dart test/availability_slot_card_test.dart`

Expected: exit 0.

- [ ] **Step 2: Executar toda a suíte Flutter**

Run: `flutter test`

Expected: todos os testes passam, sem exceções ou overflows.

- [ ] **Step 3: Executar análise estática**

Run: `flutter analyze`

Expected: `No issues found!`.

- [ ] **Step 4: Conferir escopo e diffs**

Comparar cada critério de aceite da especificação com os testes. Confirmar por `git diff --check` que não há erros de whitespace e por `git status --short` que nenhum arquivo de backend, banco ou segurança foi alterado por esta implementação.

- [ ] **Step 5: Registrar correções finais, se houver**

Se a verificação exigir correções, registrar somente os arquivos corrigidos em commit `test(frontend): valida refinamentos de usabilidade`. Se não houver mudança, não criar commit vazio.
