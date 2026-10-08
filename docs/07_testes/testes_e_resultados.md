# Testes e resultados

Data da verificação: 07/10/2026 (America/Sao_Paulo).

## Backend

Comando principal:

```powershell
cd backend
.\venv\Scripts\python.exe -m pytest tests -q --basetemp=.pytest_frontend_regression
```

Resultado final após o redesign: **88 testes aprovados, 0 falhas**.

- A suíte foi executada com `--basetemp` dentro do projeto porque o `TEMP` global do Windows negava acesso ao diretório do Pytest.
- Foi acrescentada cobertura explícita para ordem por risco, pessoa idosa, PCD, gestante, lactante e chegada, além dos campos da triagem e da migração aditiva.
- Os testes cobrem cadastro/login, confirmação de e-mail, recuperação, persistência/migração, agenda, concorrência de vaga, cancelamento/reagendamento, recepção, check-in, enfermagem, classificação manual, profissional, conclusão, administração e permissões.
- Avisos relevantes: uso legado de `datetime.utcnow()`, `FastAPI.on_event` e alias `anyio.abc.BlockingPortal`. São depreciações; não causaram falhas.

O envio SMTP foi simulado pelos testes; nenhuma mensagem real foi enviada e nenhum segredo foi exibido.

## Flutter

```powershell
cd frontend
flutter test
flutter analyze
```

- `flutter test`: **68 testes aprovados, 0 falhas**;
- `flutter analyze`: **nenhum problema encontrado**.
- `flutter build windows --release`: **aprovado**; executável gerado em `frontend/build/windows/x64/runner/Release/ubs_saude.exe`.
- `flutter build apk --debug`: **não concluído por ambiente**. O Gradle Wrapper tentou baixar a distribuição e o Java recusou o certificado com `PKIX path building failed`. Nenhuma dependência foi adicionada e não houve erro de código Flutter identificado antes dessa etapa.

Os testes incluem login único, cadastro, confirmação de e-mail, recuperação, paciente/agendamento, recepção, enfermagem, triagem com queixa/sinais vitais, profissional, administrador, proteção contra toque duplo, textos longos, larguras de 360 a 1440 px, fonte ampliada, semântica e alto contraste.

## Inicialização, API e banco

- `INICIAR_TUDO.bat -Validar`: aprovado; ambiente `backend\venv`, Flutter e seed identificados;
- API FastAPI: inicialização aprovada em `127.0.0.1:8000`;
- `GET /health`: `200`, status `ok`;
- Swagger `/docs`: `200`;
- SQLite: `PRAGMA integrity_check = ok`, 15 tabelas, dados preservados;
- logins fictícios: paciente, recepção, enfermagem, profissional e administrador retornaram os perfis esperados;
- redirecionamento: mapeamento por perfil confirmado no código e nos testes Flutter;
- agendamento, check-in, classificação e atendimento: fluxos aprovados nos testes integrados sem alterar os dados reais de demonstração.

## Observação de ambiente

No sandbox restrito, `TestClient` e Flutter aguardavam sockets/processos locais. As validações finais foram executadas com autorização fora dessa restrição. Isso não representa falha do projeto.

A inspeção visual automatizada da aba local não pôde ser repetida ao final porque o controlador de interface falhou ao criar os recursos do kernel (`os error 3`). A cobertura de layout permaneceu validada pelos testes de widget em celular e Windows; essa limitação não foi registrada como aprovação visual interativa.
