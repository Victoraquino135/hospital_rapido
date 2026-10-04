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
- `backend/seed_demonstracao.py`: seed fictício e idempotente;
- `backend/tests/`: testes automatizados do servidor;
- `frontend/lib/`: interface Flutter;
- `frontend/test/`: testes da interface;
- `docs/documentacao_projeto/`: documentação funcional e histórico acadêmico;
- `docs/banco_de_dados/`: explicação do SQLite e dos relacionamentos;
- `docs/evidencias_testes/`: resultados de validação;
- `docs/ROTEIRO_DEMONSTRACAO.md`: roteiro completo para apresentação;
- `INICIAR_TUDO.bat`: inicialização completa no Windows;
- `ATUALIZAR_E_INICIAR_TUDO.bat`: recompila a interface e inicia todo o sistema.

## Como executar no Windows

1. Instale Python 3 e Flutter com suporte a aplicações Windows.
2. Execute `INICIAR_TUDO.bat` na raiz do projeto.
3. Aguarde a preparação do ambiente, do banco e da interface.
4. Use os acessos fictícios apresentados no terminal do iniciador.

O iniciador localiza a pasta do projeto, prepara o ambiente virtual, cria apenas as contas fictícias que estiverem faltando, inicia o backend e abre o Flutter. Contas já existentes não são modificadas.

Depois de alterações no código, use `ATUALIZAR_E_INICIAR_TUDO.bat` para forçar uma nova compilação do Flutter antes da abertura. Os dois atalhos preservam o SQLite existente.

Com o backend ativo, a documentação Swagger fica disponível em `http://127.0.0.1:8000/docs`.

## Perfis

- **Paciente:** cadastro público, consulta de horários, agendamento e acompanhamento;
- **Recepção:** check-in e acompanhamento da fila;
- **Enfermagem:** pacientes com check-in e classificação manual de risco;
- **Profissional de saúde:** chamada, início e conclusão dos atendimentos atribuídos;
- **Administrador:** usuários internos, especialidades, agendas e auditoria.

O login público usa somente CPF e senha e direciona automaticamente para o painel correspondente. O cadastro público cria exclusivamente pacientes.

## Contas fictícias de demonstração

| Perfil | CPF | Senha |
|---|---|---|
| Administrador | `12345678909` | `Admin@123` |
| Recepção | `98765432100` | `Recepcao@123` |
| Enfermagem | `39053344705` | `Enfermagem@123` |
| Profissional — Clínica Geral | `11144477735` | `Profissional@123` |
| Profissional — Pediatria | `16899535009` | `Pediatria@123` |
| Paciente | `52998224725` | `Paciente@123` |

Essas credenciais são exclusivas para demonstração acadêmica e não devem ser reutilizadas em ambientes reais.

## Funcionalidades do MVP

- cadastro e autenticação de pacientes;
- recuperação e alteração de senha;
- controle de acesso por perfil;
- gestão de profissionais, especialidades e agendas;
- agendamento, cancelamento e reagendamento;
- check-in, fila, triagem e conclusão do atendimento;
- acessibilidade com fonte ampliada e alto contraste;
- documentação interativa da API.

## Roteiro curto de demonstração

1. Entre como paciente e agende uma consulta em Clínica Geral ou Pediatria.
2. Mostre o reagendamento e o cancelamento com liberação da vaga.
3. Entre como recepção e confirme o check-in.
4. Entre como enfermagem e registre uma classificação fictícia de risco.
5. Entre como o profissional atribuído, chame o paciente, inicie e conclua o atendimento.
6. Retorne ao paciente e confirme o status atualizado.
7. Mostre no painel administrativo usuários, especialidades, profissionais e horários.

O roteiro detalhado e os pontos para prints estão em [docs/ROTEIRO_DEMONSTRACAO.md](docs/ROTEIRO_DEMONSTRACAO.md).

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

Na validação de 4 de outubro de 2026 foram aprovados 76 testes do backend e 31 testes Flutter; `flutter analyze` não encontrou problemas.

## Documentação adicional

- [Backend](backend/README.md)
- [Frontend](frontend/README.md)
- [Documentação do projeto](docs/documentacao_projeto/)
- [Banco de dados](docs/banco_de_dados/README.md)
- [Roteiro de demonstração](docs/ROTEIRO_DEMONSTRACAO.md)

## Licença

Este projeto acadêmico é distribuído sob a licença MIT. Consulte [LICENSE](LICENSE).
