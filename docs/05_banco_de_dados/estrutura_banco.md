# Estrutura do banco de dados

## Banco ativo

- Caminho: `backend/ubs_rapida.db`;
- Tecnologia: SQLite acessado com SQLAlchemy;
- Integridade verificada em 06/10/2026: `PRAGMA integrity_check = ok`;
- Total identificado: 15 tabelas;
- Política: o banco local é ignorado pelo Git e não é apagado na inicialização.

As contagens variam com a demonstração. Nenhum valor de senha, token, código ou hash é reproduzido nesta documentação.

## Tabelas

### `usuarios`

Identidades de pacientes e equipe. PK `id`. Campos principais: `nome`, `cpf`, `cns`, `data_nascimento`, `email`, `email_verificado`, `telefone`, `senha_hash` — senha protegida com BCrypt, `perfil`, `ativo`, `token_version`, prioridade e dados legados de responsável. `criado_por` e `ultima_alteracao_por` referenciam logicamente usuários. Usada por todos os perfis.

### `responsaveis`

Responsáveis legais reutilizáveis. PK `id`; campos `nome`, `cpf`, `telefone`, `email`. Usada no cadastro de pacientes menores.

### `pacientes_responsaveis`

Associação N:N. PK composta `paciente_id` + `responsavel_id`; FKs para `usuarios.id` e `responsaveis.id`; campo `parentesco`.

### `especialidades`

Catálogo administrável. PK `id`; `nome` único e `ativo`. Consultada por paciente, equipe e administrador.

### `perfis_profissionais`

Dados funcionais internos. PK `id`; FKs `usuario_id -> usuarios.id` e `especialidade_id -> especialidades.id`; `registro_profissional`, `autorizado_triagem`, `ativo`. Usada por administração, enfermagem e profissionais.

### `agendas_profissionais`

Slots disponíveis. PK `id`; FK `medico_id -> usuarios.id`; `data_horario`, `bloqueado`, `especialidade`. Há unicidade por profissional/horário. Usada em agendamento e administração.

### `consultas`

Agendamentos e estado presencial. PK `id`; FKs `paciente_id`, `medico_id` e `atendimento_medico_id` para `usuarios.id`; campos `especialidade`, `data_horario`, `status`, classificação, chegada, falta, triagem, chamada, início, conclusão e `resumo_atendimento`. `chegada_por` e `triagem_por` guardam usuários responsáveis, embora o SQLite atual não exponha FKs para todos os campos adicionados por migração. O índice parcial `uq_paciente_em_atendimento` impede dois atendimentos simultâneos do mesmo paciente quando os dados existentes permitem sua criação segura. Usada por todos os perfis.

### `historico_status_consultas`

Trilha de mudanças. PK `id`; FKs `consulta_id -> consultas.id` e `alterado_por -> usuarios.id`; `status_anterior`, `status_novo`, `criado_em`. Usada pelos fluxos operacionais e auditoria.

### `classificacoes_risco`

Triagem e classificação manual. PK `id`; FKs `consulta_id -> consultas.id` e `profissional_id -> usuarios.id`; `nivel_risco`, `queixa_principal`, `sinais_vitais`, `observacao`, `classificado_em`. Usada pela enfermagem e lida pelo Médico. Os campos são adicionados por migração aditiva e não removem registros existentes.

### `grades_atendimento`

Definição de períodos e geração de slots. PK `id`; FKs para profissional, especialidade e criador; data, início/fim, duração, capacidade, intervalo, situação e timestamps. Administrador.

### `bloqueios_agenda`

Bloqueios de períodos. PK `id`; FKs `profissional_id` e `criado_por` para `usuarios.id`; início, fim, motivo e criação. Administrador.

### `auditoria_administrativa`

Eventos administrativos. PK `id`; FK `usuario_id -> usuarios.id`; ação, tipo/id do registro, detalhes JSON e data. Administrador.

### `recuperacao_senha`

Solicitações temporárias. PK `id`; FK `usuario_id -> usuarios.id`; `codigo_hash`, validade, tentativas, indicadores de uso/verificação e criação. Usuário em recuperação; conteúdo sensível não deve ser exibido.

### `verificacoes_email`

Códigos de confirmação. PK `id`; FK `usuario_id -> usuarios.id`; `codigo_hash`, validade, tentativas, uso e criação. Cadastro público.

### `limites_tentativas`

Controle de abuso. PK textual `key`; `attempts` e `expires_at`. Usada internamente pela API.

## Evolução

Não há Alembic. `backend/app/main.py` executa criação de tabelas e migrações aditivas/compatíveis no startup. Essas rotinas adicionam estruturas ausentes e preservam linhas existentes; não devem ser substituídas por recriação destrutiva do banco.
