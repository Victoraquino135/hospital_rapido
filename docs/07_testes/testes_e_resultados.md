# Testes e resultados

Data da verificação: 09/10/2026 (America/Sao_Paulo).

## Backend

Comando principal:

```powershell
cd backend
.\venv\Scripts\python.exe -m pytest tests -q --basetemp=<diretório temporário>
```

Resultado final: **101 testes aprovados, 0 falhas**.

- Foi acrescentada cobertura explícita para ordem por risco, pessoa idosa, PCD, gestante, lactante e chegada, além dos campos da triagem e da migração aditiva.
- Os testes cobrem cadastro/login imediato, rotas auxiliares de confirmação de e-mail, recuperação, persistência/migração, agenda, concorrência de vaga, cancelamento/reagendamento, recepção, check-in, enfermagem, classificação manual, fila Médica, resumo obrigatório, atendimento exclusivo, administração, especialidades e permissões.
- Foram emitidos **943 avisos de depreciação**, principalmente por `datetime.utcnow()`, `FastAPI.on_event` e alias `anyio.abc.BlockingPortal`. Não causaram falhas e devem ser tratados em evolução controlada para não alterar datas nem inicialização.

O envio SMTP foi simulado pelos testes; nenhuma mensagem real foi enviada e nenhum segredo foi exibido.

## Flutter

```powershell
cd frontend
flutter test
flutter analyze
```

- `flutter test`: **93 testes aprovados, 0 falhas**;
- `flutter analyze`: **nenhum problema encontrado**.
- `flutter build windows --release`: **aprovado**; executável gerado em `frontend/build/windows/x64/runner/Release/ubs_saude.exe`.

Os testes incluem login único, cadastro, fluxo auxiliar de confirmação, recuperação, paciente/agendamento, recepção, enfermagem, triagem com queixa/sinais vitais, painel Médico, resumo obrigatório, administração de Médicos e especialidades, proteção contra toque duplo, textos longos, larguras de 360 a 1440 px, fonte ampliada, semântica e alto contraste.

## Inicialização, API e banco

- `INICIAR_TUDO.bat -Validar -SemPausa`: aprovado; ambiente `backend\venv`, Flutter e seed identificados;
- teste automatizado do iniciador: aprovado;
- API FastAPI: inicialização isolada aprovada;
- `GET /health`: `200`, status `ok`;
- Swagger `/docs`: `200`;
- OpenAPI: título `UBS Rápida API`;
- SQLite real: tamanho e data de modificação preservados durante os testes;
- redirecionamento por perfil confirmado nos testes Flutter.

## Observações

- O envio SMTP foi simulado; a entrega real depende da configuração local em `backend/.env`.
- O `.env`, SQLite local, ambientes virtuais, caches, logs e builds permanecem fora do controle de versão.
