# Evidências de validação

Data da validação: 4 de outubro de 2026.

## Inicialização completa

- `INICIAR_TUDO.bat` executado com sucesso;
- backend FastAPI aberto em janela separada;
- Swagger respondeu HTTP 200 em `http://127.0.0.1:8000/docs`;
- aplicativo Flutter para Windows aberto e mantido em execução;
- o seed foi executado duas vezes em banco temporário isolado: criou 100 horários na primeira execução e zero duplicações na segunda.

## Perfis e direcionamento

- Administrador: autenticação aceita e perfil `admin` retornado;
- Recepção: autenticação aceita e perfil `recepcao` retornado;
- Enfermagem: acesso à triagem e bloqueio das ações administrativas e de atendimento;
- Profissional: autenticação aceita e perfil `profissional` retornado;
- Paciente: autenticação aceita e perfil `paciente` retornado;
- os testes de interface confirmaram o direcionamento e as ações próprias dos perfis.

Os CPFs e as senhas temporárias não são repetidos nesta documentação. O iniciador os apresenta somente no terminal local.

## Testes automatizados

- Backend: 76 testes aprovados, nenhum teste reprovado;
- Frontend: 31 testes aprovados, nenhum teste reprovado;
- `flutter analyze`: concluído com `No issues found`.

O Pytest apresentou avisos de descontinuação de bibliotecas e de `datetime.utcnow`, já existentes antes desta organização. Nenhum aviso representa falha de teste ou foi causado pela movimentação da documentação.

## Banco SQLite

- o seed completo foi validado em banco temporário para não alterar a base local durante os testes;
- nenhuma tabela ou registro do banco existente foi apagado durante a organização;
- o arquivo local permaneceu em `backend/ubs_rapida.db` e está ignorado pelo Git para evitar exposição de cadastros locais.

## Limpeza e segurança

- `app/` removida após confirmação de que era somente o contador padrão do Flutter e não possuía referências no projeto;
- `Nova pasta/` removida após confirmação de que estava vazia;
- ambientes virtuais, builds, caches, logs, `.env`, bancos locais, backups e pacotes compactados estão cobertos pelo `.gitignore`;
- documentação anterior foi preservada em `docs/documentacao_projeto/`.
