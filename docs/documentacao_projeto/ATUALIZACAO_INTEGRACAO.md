# UBS Rápida — integração e execução

A aplicação existente foi atualizada em `frontend` (Flutter) e `backend` (FastAPI). A pasta `app` continua preservada como exemplo antigo. As cores normais, logo, ondas, cartões e dashboards foram mantidos. O banco permanece exclusivamente no servidor.

## O que mudou

- Login exclusivo por CPF válido, com máscara, senha visível/oculta e mensagens genéricas.
- Cadastro com CPF obrigatório e CNS opcional, nome com acentos/hífen, calendário em português e dados do responsável exibidos automaticamente para menores. E-mail do responsável obrigatório. Responsáveis compartilhados por CPF, com vínculo por paciente.
- BCrypt com salt, JWT de 8 horas, rejeição de usuários inativos e revogação das sessões após troca de senha. Windows/Android usam armazenamento seguro do sistema. Na Web, o token fica somente na memória: recarregar a página exige novo login. Preferências visuais continuam locais.
- Código de recuperação enviado por SMTP, 6 números, 10 minutos, hash HMAC no banco, até 5 erros, verificação e redefinição de uso único. Limites persistentes por IP/documento. Token de recuperação não autentica endpoints comuns.
- Catálogo e horários persistentes, filtros de especialidade e profissional, proteção por perfil, cancelamento de 24h, reagendamento de 12h e restrições de status. Cada horário de profissional representa uma vaga.
- Check-in pela recepção/admin no dia; triagem somente por enfermagem com avaliação registrada; início/conclusão pelo médico responsável. Fila por risco Manchester, prioridade e chegada. APIs disponíveis em `/docs`; o painel existente continua preservado.
- A tela principal do paciente apresenta seu primeiro nome, próxima consulta ativa, atalhos, lista de consultas, detalhes, acompanhamento e perfil com CPF oculto. O agendamento seleciona especialidade, profissional, data e horário livre antes da confirmação. Cancelamento solicita confirmação. O status é consultado automaticamente a cada 5 segundos enquanto a tela do paciente está aberta.
- A atualização em até 5 segundos depende de API e rede respondendo normalmente. O painel da equipe mantém sua própria atualização a cada 2 segundos.
- O banco SQLite existente recebe três índices aditivos e idempotentes: `uq_consulta_vaga_ativa` (único para profissional/horário enquanto a consulta não está cancelada), `ix_consulta_paciente_status_data` e `ix_agenda_especialidade_data`. Não há novas tabelas, colunas removidas nem substituição dos registros.
- Controles A−, A e A+ globais, preferências persistentes, contraste preto no login e nas demais telas, seletores ajustados para celular com fonte máxima.

## Instalar e configurar (PowerShell)

Requer Python 3 e Flutter no PATH. Use dois terminais.

```powershell
cd C:\ubs_Hospital_rapido\backend
py -3 -m venv .venv-integracao
.\.venv-integracao\Scripts\python.exe -m pip install -r requirements.txt
.\.venv-integracao\Scripts\python.exe setup_env.py
```

`setup_env.py` cria `backend/.env` a partir do exemplo, gera uma chave JWT aleatória e não sobrescreve um arquivo existente. Já foi executado neste workspace. Não divulgue nem versione esse arquivo. `.gitignore` exclui `.env`, bancos, ambientes virtuais e arquivos temporários.

Preencha no `.env` local:

```dotenv
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=email_do_projeto@gmail.com
SMTP_APP_PASSWORD=senha_de_app_do_google
SMTP_FROM_NAME=UBS Rápida
DEV_SHOW_RECOVERY_CODE=false
SEED_DEMO_DATA=false
ALLOWED_ORIGINS=http://localhost:8080,http://127.0.0.1:8080
```

Mantenha a `JWT_SECRET_KEY` aleatória criada pelo instalador. `DATABASE_URL` pode ser omitida: o padrão é o arquivo persistente `backend/ubs_rapida.db`, independentemente do diretório de execução. Não exclua esse banco para atualizar o projeto.

### Senha de app do Gmail

1. Na conta do projeto, ative a Verificação em duas etapas.
2. Abra https://myaccount.google.com/apppasswords e crie uma senha de app para “UBS Rápida”.
3. Cole essa senha exclusivamente em `SMTP_APP_PASSWORD` no `.env` local. Não use a senha normal da conta.
4. Reinicie a API. Políticas de contas institucionais ou Proteção Avançada podem impedir a criação de senhas de app.

Referência oficial: https://support.google.com/accounts/answer/185833?hl=pt-BR

Para apresentação sem Gmail, é possível habilitar explicitamente `DEV_SHOW_RECOVERY_CODE=true`. Somente nesse modo o código aparece no terminal; vem desativado. Isso não comprova envio de e-mail. Nenhuma senha, token ou destinatário é registrado nos logs de recuperação.

## Executar

Servidor:

```powershell
cd C:\ubs_Hospital_rapido\backend
.\.venv-integracao\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Flutter Windows:

```powershell
cd C:\ubs_Hospital_rapido\frontend
flutter pub get
flutter run -d windows --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Flutter Web (porta fixa compatível com o CORS):

```powershell
cd C:\ubs_Hospital_rapido\frontend
flutter pub get
flutter run -d chrome --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Android emulador:

```powershell
cd C:\ubs_Hospital_rapido\frontend
flutter run -d android --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Se houver mais de um dispositivo, use o identificador retornado por `flutter devices` em vez de `android`. No aparelho físico, substitua a URL pelo IP do computador na mesma rede, por exemplo `http://192.168.1.10:8000`; libere a porta 8000 no firewall para a rede de desenvolvimento. Para distribuição, use HTTPS. A versão Android de depuração permite HTTP local; a versão de produção mantém a política segura padrão.

O iniciador `INICIAR_TUDO.bat` / `iniciar.ps1` foi ajustado para o novo ambiente e para usar porta Web fixa. A API é iniciada em segundo plano.

### Equipe e administrador

O cadastro público cria somente pacientes. Para criar uma conta da equipe no servidor:

```powershell
cd C:\ubs_Hospital_rapido\backend
.\.venv-integracao\Scripts\python.exe manage_staff.py --role admin
```

Também aceita `recepcao`, `enfermagem` e `medico`. Os dados são solicitados no terminal e a senha não é exibida. As antigas contas demonstrativas com CPF matematicamente inválido não podem mais fazer login; seus registros foram preservados. Cadastre uma conta válida da equipe. O modo de dados de demonstração é opcional (`SEED_DEMO_DATA=true`) e atua somente em banco vazio; não o habilite em um ambiente com usuários reais.

## Verificar

```powershell
cd C:\ubs_Hospital_rapido\backend
.\.venv-integracao\Scripts\python.exe -m pytest -q -p no:cacheprovider --disable-warnings
cd C:\ubs_Hospital_rapido\frontend
flutter analyze
flutter test
flutter build web --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Os testes usam banco separado; não cadastram pacientes no banco existente. A cópia de segurança anterior às alterações está em `tmp/antes-integracao`. O teste de migração usa essa cópia quando disponível e não apaga usuários.

### Validação realizada

- 21 testes do servidor: adulto/menor, responsável reutilizado, campos inválidos, duplicidades de CPF/CNS/e-mail, login CPF/CNS, senha incorreta, bloqueio de e-mail no login, tentativas repetidas, recuperação incorreta/expirada/usada, nova senha e revogação de sessão, autorização, cancelamento, fluxo presencial, CORS e migração preservando usuários.
- 4 testes Flutter: validações, seletor CPF/CNS, fonte global/A−/A/A+, contraste e navegação, login em tela de 360 pixels com fonte máxima.
- Envio SMTP testado com transporte simulado, incluindo TLS, autenticação e mensagem. Entrega real no Gmail ainda depende do preenchimento das credenciais SMTP e de uma caixa de e-mail de teste; não foi declarada como testada.
- `flutter analyze`: sem problemas. Compilações Web (JavaScript) e Windows concluídas com sucesso. A versão WebAssembly não foi habilitada; o plugin de armazenamento usado pelas plataformas nativas ainda gera avisos no diagnóstico Wasm. Android não foi compilado nem executado em aparelho nesta sessão.
- Banco local migrado após validar a cópia de segurança, preservando os usuários.
- Conferência automática: as cores originais continuam presentes e o arquivo da logo permanece idêntico.

Para validar o Gmail: cadastre um paciente fictício usando uma caixa de e-mail controlada por você, solicite recuperação pelo aplicativo, confirme o recebimento, troque a senha e faça login. Não compartilhe a senha de app na conversa.

## Arquivos criados ou alterados

Criados:

- `.gitignore`
- `ATUALIZACAO_INTEGRACAO.md`
- `backend/.env` (local, ignorado, sem credenciais SMTP preenchidas)
- `backend/setup_env.py`
- `backend/manage_staff.py`
- `backend/app/core/config.py`
- `backend/app/core/security.py`
- `backend/app/services/mailer.py`
- `backend/app/routes/recovery.py`
- `backend/app/routes/operations.py`
- `backend/tests/test_integration.py`
- `frontend/lib/config/accessibility.dart`
- `frontend/lib/screens/auth_pages.dart`
- `frontend/lib/screens/dashboards.dart`
- `frontend/lib/screens/recovery_page.dart`
- `frontend/lib/screens/booking.dart`

Alterados:

- `README.md`, `backend/README.md`, `frontend/README.md`, `iniciar.ps1`
- `backend/.env.example`, `backend/requirements.txt`
- `backend/app/core/database.py`, `backend/app/models/__init__.py`, `backend/app/schemas/__init__.py`, `backend/app/main.py`
- `frontend/lib/main.dart`, `frontend/lib/services/api_service.dart`
- `frontend/pubspec.yaml`, `frontend/pubspec.lock`, `frontend/analysis_options.yaml`
- `frontend/test/widget_test.dart`
- `frontend/android/app/src/main/AndroidManifest.xml`, `frontend/android/app/src/debug/AndroidManifest.xml`
- `frontend/windows/flutter/generated_plugin_registrant.cc`, `frontend/windows/flutter/generated_plugins.cmake`, `frontend/linux/flutter/generated_plugin_registrant.cc`, `frontend/linux/flutter/generated_plugins.cmake`, `frontend/macos/Flutter/GeneratedPluginRegistrant.swift` (gerados automaticamente pelo Flutter).
- `backend/ubs_rapida.db` (migração aditiva; cópia anterior preservada).

O arquivo `docs/documentacao_projeto/historico/main_backup_18-09.dart` foi preservado fora do aplicativo por ser uma cópia histórica, sem participação na execução. Arquivos de cache, ambiente virtual, cópias de segurança e produtos de compilação são gerados localmente e não integram o código-fonte.


## Organização das pastas

As telas estão em `frontend/lib/screens`, os componentes em `widgets`, a comunicação HTTP em `services`, os modelos de resposta em `models` e as configurações em `config`. O endereço da API fica em `frontend/lib/config/api_config.dart`.

No servidor, `backend/main.py` permite executar `uvicorn main:app`. O comando anterior `uvicorn app.main:app` continua válido. As configurações, o banco e a autenticação ficam em `app/core`; entidades e validações em `app/models` e `app/schemas`; rotas específicas em `app/routes`; envio de e-mail em `app/services`. Algumas rotas existentes continuam em `app/main.py`, permitindo separação progressiva.

A pasta virtual existente `.venv-integracao` foi mantida; renomear ambientes virtuais pode quebrar seus caminhos internos. O banco e o `.env` permanecem diretamente em `backend`, sem alterações de conteúdo por esta reorganização.

O PDF de referência está em `docs/documentacao_projeto/UBS_Rapida_Documentacao.pdf`. Materiais antigos ficam em `docs/documentacao_projeto/referencias` e a cópia histórica do Flutter em `docs/documentacao_projeto/historico`. A pasta duplicada `app` foi removida após confirmação de que continha apenas o contador padrão do Flutter e não era usada pelo sistema. As saídas `output` e as cópias `tmp` permanecem somente no computador e são ignoradas pelo Git.

O ZIP `UBS_Rapida_Projeto.zip` contém o projeto Flutter completo (incluindo plataformas, imagens e dependências declaradas), o código do servidor, documentação e iniciadores. Não contém `.env`, banco de pacientes, ambientes virtuais, caches, compilados, logs, configurações locais da máquina ou arquivos de assinatura. O banco é criado no primeiro início da API; configure o Gmail localmente após extrair.

Para abrir no VS Code, use Arquivo > Abrir Pasta > `C:\ubs_Hospital_rapido`.
