# Perfil Medico dedicado - especificacao de design

**Data:** 2026-10-08

## Objetivo

Adicionar ao UBS Rapida um perfil independente de Medico, autenticado pelo login unico por CPF e senha, com fila e fluxo de atendimento proprios. O trabalho deve preservar as funcionalidades atuais, os usuarios e dados existentes no SQLite, os vinculos de consultas e grades, e o funcionamento do `INICIAR_TUDO.bat`.

O sistema passa a apresentar cinco perfis canonicos: `paciente`, `recepcao`, `enfermagem`, `admin` e `medico`. O perfil legado `profissional` sera migrado para `medico` sem alterar os IDs dos usuarios ou dos registros relacionados.

## Escopo

O Medico atende exclusivamente pacientes atribuidos a ele que tenham check-in e triagem concluidos. Ele pode consultar os dados minimos necessarios, iniciar o atendimento, registrar um resumo simples obrigatorio e concluir o atendimento.

O escopo nao inclui prontuario eletronico completo, prescricao, exames, medicamentos, telemedicina nem dados reais de saude. Todos os dados novos de demonstracao serao ficticios.

## Compatibilidade e migracao

A migracao executada na inicializacao sera incremental e idempotente:

- Atualizara usuarios com `perfil = 'profissional'` para `perfil = 'medico'`.
- Mantera IDs, hashes de senha, agendamentos, grades, especialidades, perfis profissionais e historicos existentes.
- Adicionara somente as colunas e indices ausentes.
- Nao recriara tabelas, nao apagará o arquivo SQLite e nao substituirá dados existentes.
- Reconhecera `profissional` apenas como valor legado durante a transicao; respostas da API, JWTs e novas gravacoes usarao `medico`.

A tabela `consultas` recebera campos para o resumo simples do atendimento e para identificar o Medico que efetivamente iniciou o atendimento. Datas de inicio e conclusao existentes continuarao sendo usadas.

Uma restricao de banco impedira que um paciente possua mais de uma consulta simultaneamente com status `em_atendimento`. A API tambem validara essa regra dentro da transacao, produzindo uma resposta de conflito clara.

## Conta demonstrativa

O seed garantira, sem duplicacao por CPF, a conta ficticia:

- Nome: Dr. Victor Almeida
- CPF: `39053344705`
- Senha: `Medico@123`
- Perfil: `medico`
- Ativo: verdadeiro
- Especialidade: Clinica Geral

Como o modelo atual exige e-mail e registro profissional, o seed e a criacao administrativa usarao valores tecnicos internos, unicos e ficticios. Esses campos nao serao exibidos na lista administrativa de Medicos. A conta demonstrativa sera criada ou normalizada sem redefinir dados de outras contas.

## Autenticacao e autorizacao

O login publico continuara unico, sem seletor de perfil. A API identificara o usuario pelo CPF, verificara a senha com BCrypt e emitira JWT com o perfil canonico `medico`. Uma conta inativa nao podera entrar; a desativacao incrementara a versao de token para invalidar sessoes existentes.

O Medico tera somente permissoes para:

- Ler a propria fila de atendimento.
- Ver os dados minimos de consultas atribuidas a ele.
- Iniciar uma consulta elegivel.
- Concluir uma consulta iniciada por ele.

O Medico nao tera acesso a administracao, cadastro de vagas, grades, check-in, triagem, consultas de outro Medico ou dados de pacientes fora da propria fila.

## Fluxo de atendimento

O fluxo canonico sera:

`agendado -> em_espera -> em_triagem -> em_atendimento -> concluido`

1. A Recepcao registra o check-in, levando a consulta a `em_espera`.
2. A Enfermagem registra queixa principal, sinais vitais, observacao opcional e classificacao manual de risco, levando a consulta a `em_triagem`.
3. O Medico atribuido inicia o atendimento, levando a consulta a `em_atendimento`.
4. O mesmo Medico conclui o atendimento com um resumo simples obrigatorio, levando a consulta a `concluido`.

Antes de iniciar, a API confirmara que a consulta pertence ao Medico, possui check-in, possui triagem concluida e nao esta em atendimento com outro Medico. Antes de concluir, confirmara que a consulta esta em atendimento, foi iniciada pelo Medico autenticado e possui resumo nao vazio.

Cada transicao gravara o historico de status. Operacoes repetidas ou fora de ordem retornarao conflito sem alterar o registro.

## Fila medica

A fila exibira somente consultas do dia atribuidas ao Medico autenticado nos estados `em_triagem` e `em_atendimento`, desde que o check-in e a triagem estejam completos.

A ordenacao sera:

1. Classificacao de risco.
2. Prioridade legal.
3. Horario de chegada.
4. ID da consulta como desempate estavel.

Os dados retornados serao limitados a nome, idade calculada, horario, especialidade, prioridade, queixa principal, sinais vitais, observacao da triagem, classificacao de risco e status operacional. CPF completo, contato, credenciais e outros dados cadastrais nao farao parte desse contrato.

## API do Medico

Sera criado um roteador dedicado, documentado no Swagger:

- `GET /medico/fila`: retorna a fila autorizada e ordenada.
- `GET /medico/atendimentos/{id}`: retorna os dados minimos de uma consulta autorizada.
- `PATCH /medico/atendimentos/{id}/iniciar`: inicia uma consulta elegivel.
- `PATCH /medico/atendimentos/{id}/concluir`: exige o resumo e conclui a consulta.

Rotas medicas usarao schemas de entrada e saida dedicados. O endpoint de conclusao nunca aceitara campos de prontuario, prescricao ou outros dados fora do escopo.

## Administracao de Medicos

O painel do Administrador ganhara uma secao `Medicos`, com API dedicada ou filtros estritos sobre a gestao interna existente. O Administrador podera:

- Listar todos os Medicos.
- Pesquisar por nome ou CPF.
- Ver se existe ao menos um Medico ativo.
- Criar uma conta com nome completo, CPF valido e unico, senha segura e status.
- Editar nome, CPF e status.
- Ativar ou desativar a conta.

O perfil sera sempre `medico`. Novos Medicos receberao especialidade `Clinica Geral`, e-mail tecnico interno e registro tecnico interno. A API nao retornara senha nem hash. A alteracao de CPF verificara duplicidade antes de gravar.

## Flutter

O redirecionamento apos o login enviara `medico` ao novo `MedicalDashboard`. A tela sera compativel com Windows e Web, responsiva e navegavel por teclado.

O painel incluira:

- Cabecalho com nome do Medico e acao de sair.
- Contador de pacientes aguardando.
- Fila ordenada com nome, horario, prioridade, risco e status.
- Acao `Iniciar atendimento` apenas quando elegivel.
- Painel ou dialogo responsivo com os dados da triagem.
- Campo obrigatorio `Resumo do atendimento`.
- Acao `Concluir atendimento` com estado de carregamento e prevencao de envio duplicado.

Risco e status serao comunicados por texto e icone, alem de cor. A interface preservara azul `#005A9C`, verde `#1E824C`, fundo `#F8F9FA` e texto `#212529`, respeitando o sistema visual existente.

A fila e os status serao consultados automaticamente a cada quatro segundos e imediatamente apos iniciar ou concluir uma consulta. O temporizador sera encerrado ao sair da tela para evitar requisicoes residuais.

O painel administrativo tera uma secao dedicada a Medicos com pesquisa, indicador de disponibilidade, lista, formulario de criacao/edicao e controle de ativacao. CPF e senha terao validacao local coerente com o backend, sem substituir a validacao da API.

## Erros e concorrencia

A API usara respostas claras e consistentes:

- `401` para sessao invalida, expirada ou de conta desativada.
- `403` para perfil ou consulta fora da autorizacao do Medico.
- `404` quando o recurso autorizado nao existir.
- `409` para CPF duplicado, transicao invalida, atendimento concorrente ou operacao repetida.
- `422` para campos invalidos ou resumo ausente.

As mutacoes de inicio e conclusao serao transacionais. A restricao parcial no SQLite sera a ultima camada contra dois atendimentos simultaneos do mesmo paciente.

## Inicializacao e documentacao

O mecanismo de seed existente sera ampliado para criar a conta demonstrativa de forma idempotente. O iniciador exibira, apos a verificacao do seed:

```text
MEDICO
CPF: 39053344705
Senha: Medico@123
```

O README e a documentacao do projeto descreverao o novo perfil, suas permissoes, o fluxo Recepcao -> Enfermagem/Triagem -> Medico -> Concluida, as credenciais ficticias e os comandos de teste.

## Estrategia de testes

Os testes do backend cobrirao:

- Migracao idempotente de `profissional` para `medico` sem perda de vinculos.
- Seed idempotente da conta demonstrativa.
- Login de Medico ativo e bloqueio de Medico inativo.
- Negacao das rotas administrativas, de agenda e de triagem.
- Fila limitada ao Medico e ordenada por risco, prioridade e chegada.
- Inicio e conclusao validos.
- Bloqueio sem check-in, sem triagem, fora da fila, fora de ordem e sem resumo.
- Exclusividade do paciente em atendimento e repeticao concorrente.
- Gestao administrativa, CPF valido e unico, ativacao e desativacao.

Os testes Flutter cobrirao:

- Redirecionamento do login para o painel Medico.
- Renderizacao responsiva da fila e dos estados vazios, de erro e carregamento.
- Exibicao textual de prioridade, risco e status.
- Validacao do resumo obrigatorio.
- Inicio, conclusao, atualizacao automatica e saida.
- Listagem, pesquisa, criacao, edicao e ativacao administrativa.

A verificacao final executara a suite FastAPI, a suite Flutter, a validacao do inicializador e um fluxo manual completo com dados ficticios. Testes que precisem de banco usarao banco temporario ou copia isolada; o SQLite real do projeto nao sera apagado nem substituido.

## Criterios de aceite

O trabalho estara concluido quando:

- Todos os perfis existentes continuarem funcionais.
- Contas legadas `profissional` forem preservadas e apresentadas como `medico`.
- O login do Medico redirecionar para sua tela dedicada.
- O Medico acessar somente a propria fila triada e completar o fluxo permitido.
- O Administrador administrar Medicos sem exposicao de senhas.
- O Paciente observar as mudancas de status em ate cinco segundos.
- O seed e o iniciador forem idempotentes e preservarem o SQLite existente.
- Testes automatizados e verificacoes manuais relevantes estiverem aprovados.
