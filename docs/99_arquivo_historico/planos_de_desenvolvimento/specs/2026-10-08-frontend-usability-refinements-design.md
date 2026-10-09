# Refinamentos de usabilidade do frontend

**Data:** 08/10/2026

**Projeto:** UBS Rápida

**Escopo desta fase:** somente frontend Flutter

## Objetivo

Melhorar a clareza, a organização e a acessibilidade das telas de autenticação, paciente, agendamento, equipe e administração sem alterar regras de negócio, banco de dados, segurança ou contratos do backend nesta fase.

## Escopo

### 1. Indicador de força da senha

Criar um componente reutilizável para login e cadastro. Ele deve:

- acompanhar a digitação em tempo real;
- apresentar barra visual e texto com os níveis `Fraca`, `Média` e `Forte`;
- combinar cor, texto e semântica, sem depender apenas da cor;
- considerar tamanho, letras maiúsculas e minúsculas, número e símbolo;
- ser apenas informativo no login;
- manter no cadastro a validação forte já exigida pelo sistema;
- respeitar alto contraste, ampliação de fonte e leitor de tela.

O componente exibirá abaixo da barra os requisitos da senha. Com o campo vazio, mostrará estado neutro e somente os requisitos; após a primeira digitação, mostrará também o nível calculado.

### 2. Navegação do paciente no desktop

Na versão desktop do painel do paciente, substituir o menu lateral permanentemente aberto por um botão de três barras no cabeçalho.

- O menu começa fechado.
- Ao acionar o botão, abre um painel lateral sobre o conteúdo.
- Selecionar uma seção fecha o painel e navega para o conteúdo escolhido.
- O painel pode ser fechado pelo botão, pela ação de voltar, pela tecla `Esc` e por toque/clique fora dele.
- O comportamento compacto existente no celular permanece inalterado.
- O painel administrativo mantém a navegação lateral permanente, pois possui várias seções.

O `ResponsiveAppShell` receberá uma configuração explícita para o modo de navegação ampla, evitando condicionais baseadas no nome ou perfil da tela.

### 3. Horários do agendamento

Substituir os chips atuais por cartões de horário com estados inequívocos:

- **Disponível:** verde, ícone de confirmação e ação habilitada.
- **Indisponível:** cinza, ícone de bloqueio e ação desabilitada.
- **Selecionado:** azul, marca de seleção e destaque de borda/fundo.

A área deve incluir uma legenda textual dos estados. Cada cartão deve expor ao leitor de tela o horário e a disponibilidade. O layout deve reorganizar os cartões conforme a largura e continuar utilizável com fonte ampliada.

O resumo anterior à confirmação será apresentado em um cartão destacado, com rótulos separados para especialidade, profissional, data e horário. Nenhuma disponibilidade será inferida no frontend: os estados continuarão vindo do modelo `Slot` fornecido pela API atual.

### 4. Remoção de menus vazios da equipe

Quando `ResponsiveAppShell.destinations` estiver vazio, o layout amplo não deve reservar a coluna lateral de 260 px.

Isso se aplica aos painéis de:

- recepção;
- enfermagem;
- profissional de saúde.

O conteúdo ocupará a largura útil central, preservando o limite máximo, o cabeçalho, os controles de acessibilidade e as ações de atualizar e sair. A marca será exibida no conteúdo quando não houver navegação lateral.

### 5. Legibilidade da auditoria administrativa

Na lista de histórico e auditoria:

- aumentar a fonte de `Registrado` e da data/hora;
- manter hierarquia entre o rótulo e o valor;
- alinhar os metadados à direita em telas largas;
- mover os metadados para baixo do conteúdo quando faltar largura;
- impedir corte ou sobreposição com ampliação de fonte.

### 6. Estados vazios e etiquetas de status

Padronizar estados vazios afetados por esta entrega com:

- ícone identificável;
- título curto;
- explicação do resultado vazio;
- botão `Limpar filtros` quando existirem filtros ativos e houver ação segura para restaurá-los.

Padronizar etiquetas visuais de status nas listas de consultas da equipe e da administração alteradas nesta fase. As etiquetas devem ter texto, contraste suficiente e descrição semântica; cor sozinha não comunica o estado.

## Componentes e responsabilidades

### `PasswordStrengthIndicator`

Calcula somente a apresentação da força a partir da senha recebida. Não altera a regra de autenticação nem substitui o validador de cadastro.

### `ResponsiveAppShell`

Passa a aceitar um modo amplo explícito:

- `persistentRail`: navegação administrativa existente;
- `overlayDrawer`: menu do paciente acionado pelo botão;
- `contentOnly`: telas da equipe sem coluna vazia.

O comportamento compacto atual continua sendo definido pelas mesmas quebras responsivas.

### `AvailabilitySlotCard` e legenda

Apresentam os estados existentes de `Slot` e notificam a seleção apenas quando `selectable` for verdadeiro.

### Estado vazio reutilizável

Concentra ícone, título, descrição e ação opcional. A adoção ficará limitada às telas tocadas por esta fase.

### Metadados da auditoria

Componente responsivo local ao painel administrativo para rótulo e data/hora, evitando aumentar o escopo de refatoração.

## Fluxo de dados

- A senha digitada atualiza o indicador por estado local da tela.
- A navegação do paciente mantém o índice de destino existente; somente a forma de apresentação muda.
- Os horários continuam vindo dos endpoints atuais e preservam `label`, `availability` e `selectable`.
- Os painéis da equipe continuam usando as consultas e filtros atuais.
- A auditoria continua usando os dados atuais; apenas a apresentação muda.

Nenhum novo endpoint, campo persistente ou migração será criado nesta fase.

## Acessibilidade e responsividade

- Preservar suporte a 100%, 115% e 130% de escala de fonte.
- Preservar o modo de alto contraste.
- Garantir áreas acionáveis com pelo menos 48 px.
- Manter ordem de foco coerente e foco visível.
- Fornecer rótulos semânticos para força da senha, botão do menu, estados dos horários e etiquetas.
- Validar larguras compactas e desktop, incluindo os limites responsivos existentes.

## Erros e estados transitórios

- O indicador de senha nunca deve bloquear o login.
- Horários indisponíveis não podem disparar seleção.
- Durante carregamento ou salvamento, as ações existentes continuam desabilitadas.
- O menu sobreposto deve fechar sem alterar a seção caso o usuário cancele a interação.
- A ausência de destinos não deve gerar navegação vazia nem espaço reservado.

## Testes

Adicionar ou ajustar testes de widget para verificar:

- níveis e semântica da força da senha no login e cadastro;
- validação forte preservada no cadastro;
- menu do paciente fechado inicialmente no desktop, abertura, seleção e fechamento;
- navegação compacta do paciente inalterada;
- painel administrativo ainda com navegação persistente;
- painéis da equipe sem `NavigationRail` e sem largura lateral reservada;
- três estados visuais e semânticos dos horários;
- horário indisponível sem ação;
- resumo do agendamento organizado;
- auditoria legível em desktop, celular e fonte ampliada;
- estado vazio da equipe com ação de limpar os filtros ativos de especialidade, profissional, situação, risco e busca, preservando a data selecionada;
- ausência de overflow nas larguras já cobertas pela suíte responsiva.

Ao final, executar `flutter test` e `flutter analyze`.

## Fora do escopo desta fase

Ficam para uma etapa posterior, tratada em conjunto com backend, banco de dados e segurança:

- filtro por intervalo de datas em administrador, recepção e enfermagem;
- exibição conjunta de consultas e horários livres;
- filtro por consultas reagendadas;
- histórico persistente de cada reagendamento, com data anterior e nova;
- novos endpoints e regras de autorização associados;
- migrações de banco e testes de permissão desses filtros.

Não será criado no frontend um filtro incompleto ou simulado antes que esses dados existam de forma confiável no backend.

## Critérios de aceite

- As seis melhorias de frontend descritas funcionam sem regressão nos fluxos existentes.
- Celular mantém a navegação atual do paciente.
- Desktop do paciente usa menu sobreposto fechado inicialmente.
- Painéis da equipe não exibem a coluna lateral vazia.
- Disponibilidade de horários é compreensível por texto, ícone e cor.
- Login e cadastro exibem força da senha sem mudar a regra de autenticação.
- Auditoria permanece legível com fonte ampliada.
- Nenhum contrato do backend ou esquema do banco é alterado.
- Todos os testes Flutter passam e a análise estática não apresenta problemas.
