@echo off
setlocal
chcp 65001 >nul
title UBS Rápida - Inicialização
cd /d "%~dp0"

echo Preparando contas ficticias e iniciando o sistema completo...
echo O banco de dados existente sera preservado.
echo O primeiro inicio pode demorar enquanto tudo e preparado.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0iniciar.ps1" %*

if errorlevel 1 (
    echo.
    echo Não foi possível iniciar o UBS Rápida.
    echo Consulte a mensagem acima e tente novamente.
    pause
    exit /b 1
)

exit /b 0
