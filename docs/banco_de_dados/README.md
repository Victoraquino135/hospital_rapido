# Banco de dados do UBS Rápida

## Arquivo utilizado

O backend usa `backend/ubs_rapida.db` quando a variável `DATABASE_URL` não é definida. O caminho é calculado pelo próprio backend e não depende da pasta em que o comando foi executado.

O banco local existente é preservado pelas migrações aditivas. O iniciador não apaga tabelas, consultas, horários ou usuários. A cópia local não é enviada ao GitHub porque pode conter cadastros de desenvolvimento; uma nova instalação cria a estrutura automaticamente e adiciona somente os perfis fictícios ausentes.

## Estrutura principal

- `usuarios`: chave primária `id`; reúne CPF único, identificação, hash BCrypt, perfil e estado da conta;
- `perfis_profissionais`: chave primária `id`; `usuario_id` referencia `usuarios.id` e `especialidade_id` referencia `especialidades.id`;
- `especialidades`: chave primária `id`; catálogo de especialidades ativas;
- `agendas_profissionais`: chave primária `id`; `medico_id` referencia `usuarios.id` e cada registro representa um horário disponível ou bloqueado;
- `consultas`: chave primária `id`; `paciente_id` e `medico_id` referenciam `usuarios.id`;
- `grades_atendimento`: chave primária `id`; relaciona profissional, especialidade, data e quantidade de vagas;
- `bloqueios_agenda`: chave primária `id`; registra períodos indisponíveis do profissional;
- `responsaveis` e `pacientes_responsaveis`: armazenam responsáveis legais e a relação com pacientes menores;
- `historico_status_consultas`: registra mudanças de estado das consultas;
- `auditoria_administrativa`: registra ações administrativas sem armazenar senhas ou tokens;
- `recuperacao_senha` e `limites_tentativas`: apoiam a recuperação de acesso e a proteção contra tentativas excessivas.

O SQLite ativa chaves estrangeiras por conexão com `PRAGMA foreign_keys=ON`. CPF, e-mail, registro profissional e combinações críticas de agenda possuem restrições ou índices para evitar duplicidade.

## Relações resumidas

Um usuário possui um perfil de acesso. Pacientes e profissionais se relacionam por meio de consultas. Um profissional pode possuir um perfil profissional vinculado a uma especialidade e vários horários de agenda. Uma consulta ocupa um horário e referencia exatamente um paciente e um profissional. Pacientes menores podem se relacionar com um responsável legal.

## Demonstração

Execute `INICIAR_TUDO.bat`. Antes de abrir a API, o script `backend/criar_dados_demonstracao.py` verifica os CPFs fictícios e cria somente as contas ausentes. Contas existentes não são alteradas. Os acessos temporários aparecem apenas no terminal local do iniciador.

Para inspecionar a API e os modelos após iniciar o sistema, abra `http://127.0.0.1:8000/docs`.

## Segurança

- senhas ficam armazenadas como hash BCrypt;
- o arquivo `.env` e o SQLite local são ignorados pelo Git;
- não use dados reais na demonstração;
- não envie cópias de backup do banco ao repositório.
