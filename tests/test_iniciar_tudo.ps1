$ErrorActionPreference = 'Stop'

$raizProjeto = Split-Path -Parent $PSScriptRoot
$iniciador = Join-Path $raizProjeto 'INICIAR_TUDO.bat'

$preferenciaAnterior = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
$saida = & $iniciador -Validar -SemPausa 2>&1 | Out-String
$codigoSaida = $LASTEXITCODE
$ErrorActionPreference = $preferenciaAnterior

if ($codigoSaida -ne 0) {
    Write-Error "O iniciador falhou com o codigo $codigoSaida.`n$saida"
}

if ($saida -match 'Atualizando as depend.ncias do backend') {
    Write-Error "O iniciador padrao nao deve atualizar dependencias em toda abertura.`n$saida"
}

$conteudoBatch = Get-Content -Raw $iniciador
if ($conteudoBatch -notmatch [regex]::Escape('Use -AtualizarTudo')) {
    Write-Error 'O iniciador nao informa como solicitar uma atualizacao completa.'
}

$conteudoPowerShell = Get-Content -Raw (Join-Path $raizProjeto 'scripts\iniciar.ps1')
foreach ($trecho in @(
    'CPF: 12345678909  Senha: Admin@123',
    'CPF: 98765432100  Senha: Recepcao@123',
    'CPF: 45678912364  Senha: Enfermagem@123',
    'CPF: 39053344705  Senha: Medico@123',
    'CPF: 52998224725  Senha: Paciente@123'
)) {
    if ($conteudoPowerShell -notmatch [regex]::Escape($trecho)) {
        Write-Error "O iniciador nao exibe a credencial ficticia esperada: $trecho"
    }
}

foreach ($trecho in @('.ubs_build_stamp', 'Testar-AplicativoAtualizado')) {
    if ($conteudoPowerShell -notmatch [regex]::Escape($trecho)) {
        Write-Error "O iniciador nao possui o controle de build rapido esperado: $trecho"
    }
}

Write-Host 'PASS: o iniciador abre rapido e oferece atualizacao completa opcional.' -ForegroundColor Green
