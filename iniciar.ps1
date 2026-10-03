param(
    [ValidateSet('windows', 'chrome', 'edge')]
    [string]$Dispositivo = 'windows',
    [switch]$Validar,
    [switch]$SemPausa
)

$ErrorActionPreference = 'Stop'
$pastaProjeto = $PSScriptRoot
$pastaBackend = Join-Path $pastaProjeto 'backend'
$pastaFrontend = Join-Path $pastaProjeto 'frontend'
$arquivoBackend = Join-Path $pastaBackend 'app\main.py'
$arquivoFlutter = Join-Path $pastaFrontend 'pubspec.yaml'
$scriptDemonstracao = Join-Path $pastaBackend 'criar_dados_demonstracao.py'
$scriptBackend = Join-Path $pastaBackend 'iniciar_backend.ps1'
$executavelWindows = Join-Path $pastaFrontend 'build\windows\x64\runner\Release\ubs_saude.exe'
$marcaBuildWindows = Join-Path $pastaFrontend 'build\windows\x64\runner\Release\native_assets.json'
$pythonPrincipal = Join-Path $pastaBackend 'venv\Scripts\python.exe'
$pythonAlternativo = Join-Path $pastaBackend '.venv-integracao\Scripts\python.exe'
$requirements = Join-Path $pastaBackend 'requirements.txt'
$setupEnv = Join-Path $pastaBackend 'setup_env.py'

function Obter-Flutter {
    $candidatos = @()
    $comando = Get-Command flutter -ErrorAction SilentlyContinue
    if ($comando) { $candidatos += $comando.Source }
    if ($env:FLUTTER_ROOT) {
        $candidatos += (Join-Path $env:FLUTTER_ROOT 'bin\flutter.bat')
    }
    $candidatos += @(
        'C:\src\flutter_windows_3.44.6-stable\flutter\bin\flutter.bat',
        'C:\src\flutter\bin\flutter.bat',
        'C:\flutter\bin\flutter.bat'
    )
    foreach ($candidato in ($candidatos | Select-Object -Unique)) {
        if (Test-Path -LiteralPath $candidato) { return $candidato }
    }
    return $null
}

function Obter-PythonFuncional {
    param([string[]]$Candidatos)
    foreach ($candidato in $Candidatos) {
        if (-not (Test-Path -LiteralPath $candidato)) { continue }
        try {
            & $candidato --version *> $null
            if ($LASTEXITCODE -eq 0) { return $candidato }
        } catch { }
    }
    return $null
}

function Testar-Api {
    try {
        $resposta = Invoke-RestMethod -Uri 'http://127.0.0.1:8000/health' -TimeoutSec 2
        return $resposta.status -eq 'ok'
    } catch { return $false }
}

function Parar-BackendAnterior {
    $conexao = Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue |
        Select-Object -First 1
    if (-not $conexao) { return }
    $processo = Get-CimInstance Win32_Process -Filter "ProcessId=$($conexao.OwningProcess)" -ErrorAction SilentlyContinue
    if (-not $processo -or [string]$processo.CommandLine -notlike "*$pastaBackend*" -or
        [string]$processo.CommandLine -notmatch 'uvicorn') {
        throw 'A porta 8000 está sendo usada por outro programa. Feche-o e tente novamente.'
    }
    Write-Host 'Reiniciando o backend deste projeto...' -ForegroundColor Yellow
    Stop-Process -Id $conexao.OwningProcess -Force
    for ($i = 0; $i -lt 20; $i++) {
        Start-Sleep -Milliseconds 250
        if (-not (Get-NetTCPConnection -LocalPort 8000 -State Listen -ErrorAction SilentlyContinue)) { return }
    }
    throw 'Não foi possível liberar a porta 8000 para reiniciar o backend.'
}

function Parar-AplicativoAnterior {
    if (-not (Test-Path -LiteralPath $executavelWindows)) { return }
    $esperado = [System.IO.Path]::GetFullPath($executavelWindows)
    $processos = Get-CimInstance Win32_Process -Filter "Name='ubs_saude.exe'" -ErrorAction SilentlyContinue |
        Where-Object {
            $_.ExecutablePath -and
            [System.IO.Path]::GetFullPath([string]$_.ExecutablePath) -eq $esperado
        }
    foreach ($processo in $processos) {
        Write-Host 'Fechando a versão anterior do aplicativo...' -ForegroundColor Yellow
        Stop-Process -Id $processo.ProcessId -Force
    }
    if ($processos) { Start-Sleep -Milliseconds 500 }
}

function Testar-AplicativoAtualizado {
    if (-not (Test-Path -LiteralPath $executavelWindows) -or
        -not (Test-Path -LiteralPath $marcaBuildWindows)) { return $false }
    $fontes = @(
        Get-ChildItem -LiteralPath (Join-Path $pastaFrontend 'lib') -Recurse -File
        Get-ChildItem -LiteralPath (Join-Path $pastaFrontend 'assets') -Recurse -File -ErrorAction SilentlyContinue
        Get-ChildItem -LiteralPath (Join-Path $pastaFrontend 'windows') -Recurse -File |
            Where-Object {
                $_.FullName -notmatch '\\flutter\\ephemeral\\' -and
                $_.Name -notmatch '^generated_plugin'
            }
        Get-Item -LiteralPath $arquivoFlutter
        Get-Item -LiteralPath (Join-Path $pastaFrontend 'pubspec.lock') -ErrorAction SilentlyContinue
    ) | Where-Object { $null -ne $_ }
    $maisRecente = ($fontes | Measure-Object -Property LastWriteTimeUtc -Maximum).Maximum
    return (Get-Item -LiteralPath $marcaBuildWindows).LastWriteTimeUtc -ge $maisRecente
}

foreach ($arquivo in @($arquivoBackend, $arquivoFlutter, $scriptDemonstracao, $scriptBackend, $setupEnv)) {
    if (-not (Test-Path -LiteralPath $arquivo)) {
        throw "Arquivo obrigatório não encontrado: $arquivo"
    }
}

$pythonAmbiente = Obter-PythonFuncional @($pythonPrincipal, $pythonAlternativo)
$flutter = Obter-Flutter
if (-not $pythonAmbiente) {
    $pythonSistema = Get-Command python -ErrorAction SilentlyContinue
    if (-not $pythonSistema) { throw 'Python 3 não foi encontrado.' }
    Write-Host 'Preparando o ambiente do backend pela primeira vez...' -ForegroundColor Cyan
    $pastaNovoAmbiente = Join-Path $pastaBackend '.venv-integracao'
    & $pythonSistema.Source -m venv $pastaNovoAmbiente
    $pythonAmbiente = $pythonAlternativo
    & $pythonAmbiente -m pip install -r $requirements
    if ($LASTEXITCODE -ne 0) { throw 'Não foi possível instalar as dependências do backend.' }
}

& $pythonAmbiente $setupEnv
if ($LASTEXITCODE -ne 0) { throw 'Não foi possível validar a configuração do backend.' }

if ($Validar) {
    Write-Host 'INICIAR_TUDO validado com sucesso.' -ForegroundColor Green
    Write-Host "Python: $pythonAmbiente"
    Write-Host "Flutter: $(if ($flutter) { $flutter } else { 'não localizado' })"
    Write-Host "Script de demonstração: $scriptDemonstracao"
    exit 0
}

Parar-BackendAnterior
Parar-AplicativoAnterior

Write-Host ''
Write-Host 'Verificando contas fictícias de demonstração...' -ForegroundColor Cyan
Push-Location $pastaBackend
try {
    & $pythonAmbiente $scriptDemonstracao
    if ($LASTEXITCODE -ne 0) { throw 'A preparação das contas de demonstração falhou.' }
} finally { Pop-Location }

Write-Host ''
Write-Host 'Abrindo o backend FastAPI em uma janela separada...' -ForegroundColor Cyan
$argumentosBackend = @(
    '-NoLogo', '-NoProfile', '-ExecutionPolicy', 'Bypass',
    '-File', ('"{0}"' -f $scriptBackend),
    '-PythonPath', ('"{0}"' -f $pythonAmbiente)
)
Start-Process -FilePath 'powershell.exe' -ArgumentList $argumentosBackend `
    -WorkingDirectory $pastaBackend -WindowStyle Normal

$apiPronta = $false
for ($tentativa = 0; $tentativa -lt 40; $tentativa++) {
    Start-Sleep -Milliseconds 500
    if (Testar-Api) { $apiPronta = $true; break }
}
if (-not $apiPronta) { throw 'O backend não respondeu em http://127.0.0.1:8000.' }
$swagger = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:8000/docs' -TimeoutSec 5
if ($swagger.StatusCode -ne 200) { throw 'A documentação Swagger não ficou disponível.' }

if (-not $flutter -and ($Dispositivo -ne 'windows' -or -not (Testar-AplicativoAtualizado))) {
    throw 'Flutter não foi encontrado e a interface precisa ser compilada.'
}

if ($Dispositivo -eq 'windows') {
    if (-not (Testar-AplicativoAtualizado)) {
        Write-Host 'Compilando a interface Flutter atualizada...' -ForegroundColor Cyan
        Push-Location $pastaFrontend
        try {
            & $flutter pub get
            if ($LASTEXITCODE -ne 0) { throw 'Falha ao restaurar as dependências do Flutter.' }
            & $flutter build windows --release --dart-define=API_BASE_URL=http://127.0.0.1:8000
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $executavelWindows)) {
                throw 'Falha ao compilar o aplicativo Flutter para Windows.'
            }
        } finally { Pop-Location }
    }
    Write-Host 'Abrindo o frontend Flutter para Windows...' -ForegroundColor Cyan
    Start-Process -FilePath $executavelWindows -WorkingDirectory (Split-Path $executavelWindows)
} else {
    $comandoFlutter = '& "{0}" run -d {1} --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:8000' -f $flutter, $Dispositivo
    Start-Process -FilePath 'powershell.exe' `
        -ArgumentList @('-NoLogo', '-NoProfile', '-Command', $comandoFlutter) `
        -WorkingDirectory $pastaFrontend -WindowStyle Normal
}

Write-Host ''
Write-Host 'UBS Rápida iniciado com sucesso.' -ForegroundColor Green
Write-Host ''
Write-Host 'Backend: http://127.0.0.1:8000/docs'
Write-Host 'Frontend Flutter: iniciado no Windows'
Write-Host ''
Write-Host 'Acessos de demonstração:' -ForegroundColor Cyan
Write-Host 'Administrador - CPF: 12345678909 - Senha: Admin@123'
Write-Host 'Recepção      - CPF: 98765432100 - Senha: Recepcao@123'
Write-Host 'Profissional  - CPF: 11144477735 - Senha: Profissional@123'
Write-Host 'Paciente      - CPF: 52998224725 - Senha: Paciente@123'
Write-Host ''
Write-Host 'Faça login pelo CPF. O sistema abrirá automaticamente a tela do perfil correspondente.'
if (-not $SemPausa) {
    Write-Host ''
    Read-Host 'Mantenha as outras janelas abertas. Pressione ENTER para fechar somente este resumo'
}
