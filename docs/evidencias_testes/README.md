# Evidências de validação

Data da validação: 3 de outubro de 2026.

## Inicialização completa

- `INICIAR_TUDO.bat` executado com sucesso;
- backend FastAPI aberto em janela separada;
- Swagger respondeu HTTP 200 em `http://127.0.0.1:8000/docs`;
- aplicativo Flutter para Windows aberto e mantido em execução;
- as quatro contas de demonstração já existiam e não foram duplicadas ou alteradas.

## Perfis e direcionamento

- Administrador: autenticação aceita e perfil `admin` retornado;
- Recepção: autenticação aceita e perfil `recepcao` retornado;
- Profissional: autenticação aceita e perfil `profissional` retornado;
- Paciente: autenticação aceita e perfil `paciente` retornado;
- o teste automatizado `direcionamento reconhece os quatro perfis` confirmou a seleção do painel correto no Flutter.

Os CPFs e as senhas temporárias não são repetidos nesta documentação. O iniciador os apresenta somente no terminal local.

## Testes automatizados

- Backend: 73 testes aprovados, nenhum teste reprovado;
- Frontend: 28 testes aprovados, nenhum teste reprovado;
- `flutter analyze`: concluído com `No issues found`.

O Pytest apresentou avisos de descontinuação de bibliotecas e de `datetime.utcnow`, já existentes antes desta organização. Nenhum aviso representa falha de teste ou foi causado pela movimentação da documentação.

## Banco SQLite

- `PRAGMA integrity_check`: `ok`;
- usuários: 18;
- consultas: 10;
- horários de agenda: 210;
- nenhuma tabela foi apagada ou recriada durante a organização;
- o arquivo local permaneceu em `backend/ubs_rapida.db` e está ignorado pelo Git para evitar exposição de cadastros locais.

## Limpeza e segurança

- `app/` removida após confirmação de que era somente o contador padrão do Flutter e não possuía referências no projeto;
- `Nova pasta/` removida após confirmação de que estava vazia;
- ambientes virtuais, builds, caches, logs, `.env`, bancos locais, backups e pacotes compactados estão cobertos pelo `.gitignore`;
- documentação anterior foi preservada em `docs/documentacao_projeto/`.
