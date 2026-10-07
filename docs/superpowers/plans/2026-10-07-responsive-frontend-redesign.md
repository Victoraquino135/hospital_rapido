# Redesenho responsivo do frontend — Plano de implementação

> **Para agentes executores:** SUB-SKILL OBRIGATÓRIA: usar `superpowers:subagent-driven-development` (recomendado quando autorizado) ou `superpowers:executing-plans` para executar este plano tarefa por tarefa. As etapas usam caixas de seleção (`- [ ]`) para acompanhamento.

**Objetivo:** Redesenhar todas as telas Flutter do UBS Rápida para Windows e celular, preservando identidade, paleta, fluxos, contratos de API e acessibilidade.

**Arquitetura:** A implementação será incremental. Primeiro serão criados fundamentos visuais e um shell responsivo compartilhado; depois cada grupo funcional migrará para esses componentes sem alterar suas regras. Cada grupo termina com testes próprios e um commit isolado.

**Stack:** Flutter/Dart, Material 3, `flutter_test`, `SharedPreferences`, componentes e estado de acessibilidade já existentes.

**Especificação:** `docs/superpowers/specs/2026-10-07-responsive-frontend-redesign-design.md`

## Restrições globais

- Manter a paleta existente: `blue = Color(0xFF005A9C)`, `green = Color(0xFF1E824C)` e `pageBackgroundColor = Color(0xFFF8F9FA)`.
- Usar o `BrandMark` existente; não substituir a marca por JPG ou nova ilustração.
- Manter “Preferências de acessibilidade” no canto superior direito no Windows e como controle compacto com `Semantics` no celular.
- Todo botão principal e alvo interativo relevante deve ter no mínimo 48 × 48 px.
- Preservar alto contraste, escala de fonte, leitor de tela, teclado e foco visível.
- Não alterar backend, banco, endpoints, payloads, papéis, permissões ou regras de negócio.
- Não adicionar dependências de design sem necessidade.
- O frontend deve permanecer executável e testável ao fim de cada tarefa.

## Foco da revisão

- Largura de 360 px com escala de fonte máxima: nenhuma ação, formulário ou diálogo deve apresentar overflow; coberto nas Tarefas 1, 3, 4, 5 e 6.
- Larguras próximas aos breakpoints: navegação e conteúdo não podem desaparecer nem ser renderizados duas vezes; coberto nas Tarefas 1 e 2.
- Nomes, especialidades e mensagens longas: o texto deve quebrar ou limitar linhas sem empurrar ações para fora da tela; coberto nas Tarefas 4, 5 e 6.
- Operações assíncronas e toque repetido: somente a ação em andamento fica bloqueada e não pode haver envio duplo; coberto nas Tarefas 3 e 4.
- Alto contraste: risco, estado e ação não podem depender somente de cor; coberto nas Tarefas 1, 5 e 6.

---

## Estrutura de arquivos

### Novos arquivos

- `frontend/lib/config/design_system.dart`: tokens de tamanho, espaçamento, raios e breakpoints.
- `frontend/lib/widgets/responsive_shell.dart`: shell adaptativo, cabeçalhos e navegação por largura.
- `frontend/lib/widgets/app_components.dart`: botões, seções, cartões e estados compartilhados.
- `frontend/test/design_system_test.dart`: contrato dos tokens, dimensões mínimas e alto contraste.
- `frontend/test/responsive_shell_test.dart`: breakpoints, marca e posição da acessibilidade.
- `frontend/test/auth_responsive_test.dart`: acesso, cadastro, verificação e recuperação em Windows/celular.

### Arquivos modificados

- `frontend/lib/main.dart`: registrar novos arquivos `part`, consolidar tema e aumentar alvos para 48 px.
- `frontend/lib/widgets/shared_widgets.dart`: integrar `AppPage`, `AccessibilityMenu`, `AuthLayout` e campos ao novo sistema.
- `frontend/lib/widgets/brand_mark.dart`: preservar desenho e semântica; apenas permitir dimensionamento adequado ao shell.
- `frontend/lib/screens/auth_pages.dart`: login, cadastro e responsável.
- `frontend/lib/screens/email_verification_page.dart`: verificação/correção de e-mail.
- `frontend/lib/screens/recovery_email_page.dart`: recuperação e redefinição.
- `frontend/lib/screens/dashboards.dart`: painel e consultas do paciente.
- `frontend/lib/screens/booking.dart`: fluxo de agendamento.
- `frontend/lib/screens/staff_dashboard.dart`: recepção, enfermagem e profissional.
- `frontend/lib/screens/admin_dashboard.dart`: todos os módulos administrativos.
- Testes existentes em `frontend/test/`: adaptar somente expectativas visuais afetadas, preservando expectativas funcionais.
- `docs/07_testes/testes_e_resultados.md`: registrar a validação final realmente executada.

## Task 1: Fundamentos visuais e componentes compartilhados

**Arquivos:**
- Criar: `frontend/lib/config/design_system.dart`
- Criar: `frontend/lib/widgets/app_components.dart`
- Criar: `frontend/test/design_system_test.dart`
- Modificar: `frontend/lib/main.dart:9-105`

**Interfaces:**
- Produz: `AppBreakpoints.compact = 700.0`, `AppBreakpoints.wide = 1100.0`.
- Produz: `AppSpacing.xs/sm/md/lg/xl`, `AppSizes.minTouchTarget = 48.0`, `AppSizes.contentMaxWidth = 1320.0`.
- Produz: `ScreenClass screenClassOf(BuildContext context)` com valores `compact`, `medium` e `wide`.
- Produz: `AppActionButton`, `AppSectionHeader`, `AppSurfaceCard`, `AppEmptyState`, `AppErrorState`.
- Consome: `accessibility`, `blue`, `green`, `pageBackgroundColor` e `Theme.of(context)`.

- [ ] **Etapa 1: escrever testes inicialmente falhos para tokens e breakpoints**

Adicionar testes com os nomes `uses_48px_minimum_touch_target`, `classifies_699_as_compact_and_700_as_medium` e `classifies_1100_as_wide`. Asserções: `AppSizes.minTouchTarget == 48`, 699 → `compact`, 700 → `medium`, 1100 → `wide`.

- [ ] **Etapa 2: executar os testes e confirmar a falha esperada**

Executar: `flutter test test/design_system_test.dart`

Esperado: falha de compilação porque tokens, enum e componentes ainda não existem.

- [ ] **Etapa 3: criar tokens e classificação responsiva**

Adicionar `part 'config/design_system.dart';` a `main.dart`. Implementar `enum ScreenClass`, classes abstratas finais de tokens e `screenClassForWidth(double width) -> ScreenClass`; `screenClassOf` deve delegar para essa função pura.

- [ ] **Etapa 4: escrever testes inicialmente falhos para componentes e contraste**

Adicionar `primary_button_is_at_least_48px`, `long_empty_state_wraps_at_360px` e `high_contrast_surface_uses_border_and_text_label`. O último deve confirmar borda visível e rótulo textual, sem validar somente cor.

- [ ] **Etapa 5: implementar os componentes compartilhados mínimos**

Adicionar `part 'widgets/app_components.dart';`. `AppActionButton` recebe `label`, `icon`, `onPressed`, `busy`, `destructive` e `expand`; `busy` impede novo acionamento. Os estados vazio/erro recebem mensagem e ação opcional. Todos consomem o tema atual.

- [ ] **Etapa 6: consolidar o tema global sem trocar cores**

Em `main.dart`, alterar os mínimos de `FilledButton`, `OutlinedButton` e `TextButton` de 44 para 48 px, adicionar foco visível e padronizar raio/altura pelos tokens. Não mudar `ColorScheme` nem cores de alto contraste.

- [ ] **Etapa 7: verificar a tarefa**

Executar: `flutter test test/design_system_test.dart && flutter analyze`

Esperado: testes aprovados e `No issues found!`.

- [ ] **Etapa 8: criar commit isolado**

```text
git add frontend/lib/main.dart frontend/lib/config/design_system.dart frontend/lib/widgets/app_components.dart frontend/test/design_system_test.dart
git commit -m "feat(frontend): adiciona fundamentos visuais responsivos"
```

## Task 2: Shell responsivo, marca e acessibilidade global

**Arquivos:**
- Criar: `frontend/lib/widgets/responsive_shell.dart`
- Criar: `frontend/test/responsive_shell_test.dart`
- Modificar: `frontend/lib/main.dart:9-18`
- Modificar: `frontend/lib/widgets/shared_widgets.dart:3-106,160-194`
- Modificar: `frontend/lib/widgets/brand_mark.dart:6-49`

**Interfaces:**
- Consome: tokens e componentes da Tarefa 1.
- Produz: `ResponsiveAppShell({required Widget body, required String title, String? subtitle, List<AppDestination> destinations, int selectedIndex, ValueChanged<int>? onDestinationSelected})`.
- Produz: `AppDestination({required IconData icon, required String label})`.
- Produz: `ResponsivePageHeader({required String title, String? subtitle, Widget? primaryAction})`.
- Mantém: `AppPage`, `AccessibilityMenu`, `AuthLayout`, `BrandMark` e suas semânticas públicas.

- [ ] **Etapa 1: escrever testes inicialmente falhos do shell**

Adicionar `wide_shell_shows_sidebar_once`, `compact_shell_shows_compact_navigation_once`, `brand_mark_is_present_on_both_widths` e `accessibility_button_is_top_right_on_windows`.

- [ ] **Etapa 2: incluir testes dos limites de breakpoint**

Adicionar `shell_keeps_navigation_at_699_700_1099_1100`. Em cada largura deve existir exatamente uma navegação utilizável e exatamente um `AccessibilityMenu`.

- [ ] **Etapa 3: executar e confirmar falha**

Executar: `flutter test test/responsive_shell_test.dart`

Esperado: falha porque `ResponsiveAppShell` e `AppDestination` não existem.

- [ ] **Etapa 4: implementar o shell adaptativo**

Adicionar `part 'widgets/responsive_shell.dart';`. Em `wide`, usar navegação lateral; em `compact`, navegação compacta/inferior; em `medium`, escolher a variante que não comprima conteúdo. Limitar conteúdo por `AppSizes.contentMaxWidth`.

- [ ] **Etapa 5: integrar marca e acessibilidade**

Manter `BrandMark` como marca única. No Windows, renderizar o botão textual “Preferências de acessibilidade” no canto superior direito. Em `compact`, manter ícone, tooltip, rótulo semântico e alvo de 48 × 48 px. O painel aberto deve caber em 360 px com fonte máxima.

- [ ] **Etapa 6: atualizar `AppPage` e `AuthLayout`**

Remover posicionamentos que possam cobrir conteúdo com fonte ampliada. Reservar espaço superior para acessibilidade, manter fundo e tornar o cartão de autenticação fluido entre 360 px e 560 px.

- [ ] **Etapa 7: verificar shell, acessibilidade e regressão básica**

Executar: `flutter test test/responsive_shell_test.dart test/high_contrast_global_test.dart test/accessibility_recovery_test.dart && flutter analyze`

Esperado: todos aprovados e análise limpa.

- [ ] **Etapa 8: criar commit isolado**

```text
git add frontend/lib/main.dart frontend/lib/widgets/responsive_shell.dart frontend/lib/widgets/shared_widgets.dart frontend/lib/widgets/brand_mark.dart frontend/test/responsive_shell_test.dart
git commit -m "feat(frontend): cria shell adaptativo e acessível"
```

## Task 3: Acesso, cadastro, verificação e recuperação

**Arquivos:**
- Criar: `frontend/test/auth_responsive_test.dart`
- Modificar: `frontend/lib/screens/auth_pages.dart`
- Modificar: `frontend/lib/screens/email_verification_page.dart`
- Modificar: `frontend/lib/screens/recovery_email_page.dart`
- Modificar: `frontend/lib/widgets/password_rules.dart`
- Modificar quando necessário: `frontend/test/widget_test.dart`, `frontend/test/email_verification_test.dart`, `frontend/test/accessibility_recovery_test.dart`

**Interfaces:**
- Consome: `AuthLayout`, `AppActionButton`, `AppSurfaceCard`, tokens e estados da Tarefa 1; acessibilidade da Tarefa 2.
- Mantém: construtores públicos `LoginPage`, `RegisterPage`, `ResponsiblePage`, `EmailVerificationPage` e `RecoveryPage`.
- Mantém: chamadas e payloads atuais de `ApiService`.

- [ ] **Etapa 1: escrever testes responsivos inicialmente falhos**

Adicionar `login_matches_compact_and_wide_hierarchy`, `registration_wraps_at_360_with_max_text_scale`, `recovery_keeps_primary_action_visible` e `email_verification_keeps_code_semantics`.

- [ ] **Etapa 2: escrever teste de toque repetido**

Adicionar `login_disables_only_submit_while_request_is_pending`; disparar dois toques rápidos e afirmar uma única chamada ao serviço, campos ainda legíveis e ação ocupada.

- [ ] **Etapa 3: executar e confirmar falhas visuais/comportamentais**

Executar: `flutter test test/auth_responsive_test.dart`

Esperado: pelo menos os novos seletores/componentes ausentes falham antes da migração.

- [ ] **Etapa 4: redesenhar login e cadastro**

Usar `BrandMark`, hierarquia de título/subtítulo, campos existentes e `AppActionButton`. Em largura ampla, limitar e centralizar; em compacta, usar uma coluna. Manter validação, foco em erro e conteúdo digitado.

- [ ] **Etapa 5: redesenhar responsável, verificação e recuperação**

Padronizar passos, mensagens, reenvio, regras de senha e ações. Temporizadores e estados assíncronos permanecem funcionalmente iguais. Nenhuma mensagem segura da API deve ser reescrita.

- [ ] **Etapa 6: verificar o grupo de acesso**

Executar: `flutter test test/auth_responsive_test.dart test/widget_test.dart test/email_verification_test.dart test/accessibility_recovery_test.dart`

Esperado: todos aprovados, inclusive 360 px com fonte máxima e sem overflow.

- [ ] **Etapa 7: criar commit isolado**

```text
git add frontend/lib/screens/auth_pages.dart frontend/lib/screens/email_verification_page.dart frontend/lib/screens/recovery_email_page.dart frontend/lib/widgets/password_rules.dart frontend/test/auth_responsive_test.dart frontend/test/widget_test.dart frontend/test/email_verification_test.dart frontend/test/accessibility_recovery_test.dart
git commit -m "feat(frontend): moderniza acesso e recuperação responsivos"
```

## Task 4: Paciente, consultas e agendamento

**Arquivos:**
- Modificar: `frontend/lib/screens/dashboards.dart:3-848`
- Modificar: `frontend/lib/screens/booking.dart`
- Modificar: `frontend/test/patient_dashboard_test.dart`

**Interfaces:**
- Consome: `ResponsiveAppShell`, `ResponsivePageHeader`, `AppActionButton`, `AppSectionHeader`, `AppSurfaceCard`, `AppEmptyState` e `AppErrorState`.
- Mantém: `PatientDashboard`, `BookingPanel`, `StatusTimeline` e chamadas atuais do `ApiService`.
- Produz internamente: cartões responsivos para próxima consulta, consulta e etapa de agendamento, sem expor nova API fora do arquivo.

- [ ] **Etapa 1: ampliar testes antes da mudança**

Adicionar `patient_wide_layout_prioritizes_next_appointment`, `patient_compact_layout_keeps_booking_action_48px`, `long_professional_and_specialty_wrap_without_overflow` e `max_text_scale_keeps_status_and_action_visible`.

- [ ] **Etapa 2: testar proteção contra envio duplo no agendamento**

Adicionar `booking_submits_once_while_request_is_pending`; dois toques devem gerar uma chamada e manter o indicador de progresso apenas na ação.

- [ ] **Etapa 3: executar e confirmar falhas**

Executar: `flutter test test/patient_dashboard_test.dart`

Esperado: novos critérios visuais falham antes do redesign; expectativas funcionais antigas continuam passando.

- [ ] **Etapa 4: migrar o painel do paciente**

Usar shell adaptativo. Priorizar saudação, próxima consulta e ação “Agendar consulta”. Reduzir cartões decorativos e manter status textual. Em compacta, empilhar; em ampla, usar espaço horizontal sem exceder largura máxima.

- [ ] **Etapa 5: migrar consultas, detalhes e timeline**

Padronizar estado vazio, erro, cancelamento, reagendamento e detalhes. `StatusTimeline` deve continuar comunicando cada estado por texto/ícone, não somente cor.

- [ ] **Etapa 6: migrar o agendamento**

Manter sequência especialidade → profissional → data → horário → confirmação. No celular, uma coluna com ação larga; no Windows, passos e resumo podem ocupar colunas distintas. Manter tratamento de indisponibilidade e tentar novamente.

- [ ] **Etapa 7: verificar paciente e agendamento**

Executar: `flutter test test/patient_dashboard_test.dart test/high_contrast_global_test.dart && flutter analyze`

Esperado: testes aprovados, sem overflow e análise limpa.

- [ ] **Etapa 8: criar commit isolado**

```text
git add frontend/lib/screens/dashboards.dart frontend/lib/screens/booking.dart frontend/test/patient_dashboard_test.dart
git commit -m "feat(frontend): redesenha jornada responsiva do paciente"
```

## Task 5: Recepção, enfermagem e profissional

**Arquivos:**
- Modificar: `frontend/lib/screens/staff_dashboard.dart`
- Modificar: `frontend/test/staff_profiles_test.dart`

**Interfaces:**
- Consome: shell, tokens, cabeçalhos, cartões, botões e estados das Tarefas 1 e 2.
- Mantém: `StaffDashboard`, permissões por perfil e todos os métodos atuais do `ApiService`.
- Mantém: quatro níveis manuais de risco e regras atuais de transição de atendimento.

- [ ] **Etapa 1: ampliar testes de recepção antes da mudança**

Adicionar `reception_wide_uses_filter_and_results_regions`, `reception_compact_collapses_filters_without_hiding_checkin` e `long_patient_name_does_not_hide_actions`.

- [ ] **Etapa 2: ampliar testes clínicos e de acessibilidade**

Adicionar `risk_level_has_text_and_semantics_in_high_contrast`, `clinical_queue_survives_max_text_scale_at_360` e `professional_actions_remain_in_workflow_order`.

- [ ] **Etapa 3: executar e confirmar falhas**

Executar: `flutter test test/staff_profiles_test.dart`

Esperado: novos critérios de layout/semântica falham; regras funcionais antigas continuam protegidas.

- [ ] **Etapa 4: redesenhar recepção**

Usar resumo e filtros horizontais em ampla; filtros recolhíveis em compacta. Check-in, ausência e detalhes permanecem textualmente explícitos e com confirmação apropriada.

- [ ] **Etapa 5: redesenhar enfermagem**

Dar hierarquia a chegada, prioridade legal, risco, queixa e sinais vitais. Exibir rótulo e ícone além da cor. Diálogo de risco deve caber em 360 px e ser navegável por teclado.

- [ ] **Etapa 6: redesenhar profissional**

Preservar ordem chamar → iniciar → concluir. Ações indisponíveis devem explicar o estado. Informações longas devem quebrar antes das ações.

- [ ] **Etapa 7: verificar os três perfis**

Executar: `flutter test test/staff_profiles_test.dart test/admin_dashboard_test.dart && flutter analyze`

Esperado: testes aprovados e análise limpa.

- [ ] **Etapa 8: criar commit isolado**

```text
git add frontend/lib/screens/staff_dashboard.dart frontend/test/staff_profiles_test.dart
git commit -m "feat(frontend): moderniza painéis responsivos da equipe"
```

## Task 6: Administração responsiva

**Arquivos:**
- Modificar: `frontend/lib/screens/admin_dashboard.dart`
- Modificar: `frontend/test/admin_dashboard_test.dart`

**Interfaces:**
- Consome: shell e componentes compartilhados.
- Mantém: `AdminDashboard`, módulos, formulários, permissões e chamadas atuais do `ApiService`.
- Mantém: auditoria sem exposição de CPF completo, senha, hash ou token.

- [ ] **Etapa 1: ampliar testes de navegação e resumo**

Adicionar `admin_wide_shows_navigation_and_content_without_overlap`, `admin_compact_shows_one_module_at_a_time` e `admin_summary_survives_max_text_scale`.

- [ ] **Etapa 2: ampliar testes de listas, textos longos e diálogos**

Adicionar `long_internal_user_and_specialty_wrap_without_hiding_actions`, `admin_dialogs_fit_360px` e `audit_status_is_not_color_only`.

- [ ] **Etapa 3: executar e confirmar falhas**

Executar: `flutter test test/admin_dashboard_test.dart`

Esperado: novos critérios responsivos falham antes da migração.

- [ ] **Etapa 4: migrar shell e resumo administrativo**

Usar navegação lateral no Windows e navegação compacta no celular. Cards de resumo devem reorganizar sem largura fixa e manter rótulos legíveis.

- [ ] **Etapa 5: migrar usuários, profissionais e especialidades**

Em ampla, usar listas/tabelas legíveis; em compacta, cartões sem rolagem horizontal obrigatória para ações. Diálogos devem usar conteúdo rolável e ações de 48 px.

- [ ] **Etapa 6: migrar consultas, grades e auditoria**

Padronizar filtros, estados vazios, detalhes e confirmações. Auditoria deve manter conteúdo protegido e estado textual.

- [ ] **Etapa 7: verificar administração**

Executar: `flutter test test/admin_dashboard_test.dart test/high_contrast_global_test.dart && flutter analyze`

Esperado: testes aprovados, nenhuma exposição adicional e análise limpa.

- [ ] **Etapa 8: criar commit isolado**

```text
git add frontend/lib/screens/admin_dashboard.dart frontend/test/admin_dashboard_test.dart
git commit -m "feat(frontend): torna administração totalmente responsiva"
```

## Task 7: Regressão completa, builds e evidências

**Arquivos:**
- Modificar somente se os resultados mudarem: `docs/07_testes/testes_e_resultados.md`
- Modificar somente para correções encontradas: arquivos das Tarefas 1–6 e seus testes.

**Interfaces:**
- Consome: toda a implementação anterior.
- Produz: frontend validado para Windows e celular, documentação de resultados coerente com a execução real.

- [ ] **Etapa 1: executar formatação e confirmar diff limitado ao frontend planejado**

Executar: `dart format lib test`

Depois executar: `git status --short` e confirmar que arquivos não relacionados não foram incluídos nem sobrescritos.

- [ ] **Etapa 2: executar análise estática e suíte Flutter completa**

Executar: `flutter analyze`

Esperado: `No issues found!`.

Executar: `flutter test`

Esperado: todos os testes aprovados, incluindo novos testes responsivos.

- [ ] **Etapa 3: validar build Windows**

Executar: `flutter build windows --release`

Esperado: executável criado em `frontend/build/windows/x64/runner/Release/ubs_saude.exe`.

- [ ] **Etapa 4: validar alvo móvel sem depender de publicação**

Executar: `flutter build apk --debug` quando o SDK/Gradle local permitir.

Esperado: APK debug concluído. Se o ambiente bloquear download ou certificado, registrar exatamente a limitação e manter `flutter test`/`flutter analyze` como evidência de código, sem declarar a build aprovada.

- [ ] **Etapa 5: executar regressão backend sem modificar backend**

No diretório `backend`, executar: `.\venv\Scripts\python.exe -m pytest tests -q --basetemp=.pytest_frontend_regression`

Esperado: todos os testes funcionais aprovados; advertências de depreciação podem permanecer, mas nenhuma falha pode ser atribuída ao frontend.

- [ ] **Etapa 6: atualizar evidências com números reais**

Registrar em `docs/07_testes/testes_e_resultados.md` data, comandos, total de testes e limitações ambientais observadas. Não copiar contagens antigas.

- [ ] **Etapa 7: revisar critérios da especificação manualmente**

Verificar login, paciente, recepção, enfermagem, profissional e administração em largura de celular e Windows; ativar alto contraste, fonte máxima e navegação por teclado em cada shell principal.

- [ ] **Etapa 8: criar commit final de validação**

```text
git add frontend docs/07_testes/testes_e_resultados.md
git commit -m "test(frontend): valida redesign responsivo completo"
```

