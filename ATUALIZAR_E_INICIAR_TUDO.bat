@echo off
setlocal
chcp 65001 >nul
title UBS Rápida - Atualizar e iniciar tudo
cd /d "%~dp0"

echo =====================================================
echo        UBS RAPIDA - ATUALIZAR E INICIAR TUDO
echo =====================================================
echo.
echo O banco SQLite e os dados existentes serao preservados.
echo A interface sera recompilada antes da abertura.
echo.

powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0iniciar.ps1" -AtualizarTudo %*

if errorlevel 1 (
    echo.
    echo Nao foi possivel atualizar e iniciar o UBS Rapida.
    echo Consulte a mensagem acima e tente novamente.
    pause
    exit /b 1
)

exit /b 0
