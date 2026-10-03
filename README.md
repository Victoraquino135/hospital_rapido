# UBS Rápida

MVP acadêmico para reduzir filas presenciais de agendamento em Unidades Básicas de Saúde. O sistema reúne cadastro e acesso por CPF, agendamento, acompanhamento do atendimento e painéis operacionais por perfil.

Todos os dados usados na demonstração devem ser fictícios. O projeto não é um sistema de produção e não substitui os sistemas oficiais de saúde.

## Tecnologias

- Flutter para as interfaces Windows e Web;
- FastAPI e Python no backend;
- SQLAlchemy com SQLite persistente;
- autenticação JWT e senhas protegidas com BCrypt;
- Pytest e Flutter Test para testes automatizados.

## Estrutura principal

- `backend/app/`: API, regras de negócio, modelos, rotas e segurança;
- `backend/tests/`: testes automatizados do servidor;
- `frontend/lib/`: interface Flutter;
- `frontend/test/`: testes da interface;
- `docs/documentacao_projeto/`: documentação funcional e histórico acadêmico;
- `docs/banco_de_dados/`: explicação do SQLite e dos relacionamentos;
- `docs/evidencias_testes/`: resultados de validação;
- `INICIAR_TUDO.bat`: inicialização completa no Windows.

## Como executar no Windows

1. Instale Python 3 e Flutter com suporte a aplicações Windows.
2. Execute `INICIAR_TUDO.bat` na raiz do projeto.
3. Aguarde a preparação do ambiente, do banco e da interface.
4. Use os acessos fictícios apresentados no terminal do iniciador.

O iniciador localiza a pasta do projeto, prepara o ambiente virtual, cria apenas as contas fictícias que estiverem faltando, inicia o backend e abre o Flutter. Contas já existentes não são modificadas.

Com o backend ativo, a documentação Swagger fica disponível em `http://127.0.0.1:8000/docs`.

## Perfis

- **Paciente:** cadastro público, consulta de horários, agendamento e acompanhamento;
- **Recepção:** check-in e acompanhamento da fila;
- **Profissional:** triagem autorizada e andamento do atendimento;
- **Administrador:** usuários internos, especialidades, agendas e auditoria.

O login público usa somente CPF e senha e direciona automaticamente para o painel correspondente. O cadastro público cria exclusivamente pacientes.

## Funcionalidades do MVP

- cadastro e autenticação de pacientes;
- recuperação e alteração de senha;
- controle de acesso por perfil;
- gestão de profissionais, especialidades e agendas;
- agendamento, cancelamento e reagendamento;
- check-in, fila, triagem e conclusão do atendimento;
- acessibilidade com fonte ampliada e alto contraste;
- documentação interativa da API.

## Fora do escopo

Não fazem parte deste MVP: medicamentos, vacinação, pagamentos, telemedicina, prontuário completo, integrações reais com SUS ou e-SUS, WhatsApp, SMS e inteligência artificial para triagem.

## Banco de dados e privacidade

O arquivo usado localmente é `backend/ubs_rapida.db`. Ele não é versionado porque a cópia de desenvolvimento pode conter cadastros locais que não devem ser publicados. Em uma nova instalação, o próprio iniciador cria a estrutura e os perfis fictícios necessários.

As senhas são armazenadas somente como hashes BCrypt. Não publique `backend/.env`, tokens, credenciais SMTP ou cópias locais do SQLite. Consulte [a documentação do banco](docs/banco_de_dados/README.md).

## Testes

Backend:

```powershell
cd backend
.\.venv-integracao\Scripts\python.exe -m pytest -q
```

Frontend:

```powershell
cd frontend
flutter test
flutter analyze
```

Os resultados da validação desta entrega estão em [docs/evidencias_testes](docs/evidencias_testes/README.md).

## Documentação adicional

- [Backend](backend/README.md)
- [Frontend](frontend/README.md)
- [Documentação do projeto](docs/documentacao_projeto/)
- [Banco de dados](docs/banco_de_dados/README.md)

## Licença

Este projeto acadêmico é distribuído sob a licença MIT. Consulte [LICENSE](LICENSE).
