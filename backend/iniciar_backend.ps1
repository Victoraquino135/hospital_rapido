param(
    [Parameter(Mandatory = $true)]
    [string]$PythonPath
)

$ErrorActionPreference = 'Stop'
$Host.UI.RawUI.WindowTitle = 'UBS Rápida - Backend FastAPI'
Set-Location $PSScriptRoot

Write-Host 'Backend FastAPI da UBS Rápida' -ForegroundColor Cyan
Write-Host 'Swagger: http://127.0.0.1:8000/docs' -ForegroundColor Green
Write-Host 'Mantenha esta janela aberta enquanto estiver usando o sistema.'
Write-Host ''

& $PythonPath -m uvicorn app.main:app --host 127.0.0.1 --port 8000
if ($LASTEXITCODE -ne 0) {
    Write-Host ''
    Write-Host 'O backend foi encerrado com erro.' -ForegroundColor Red
    Read-Host 'Pressione ENTER para fechar'
    exit $LASTEXITCODE
}
