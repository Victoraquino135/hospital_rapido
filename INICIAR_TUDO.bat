@echo off
setlocal
set "SEM_PAUSA="
for %%A in (%*) do if /I "%%~A"=="-SemPausa" set "SEM_PAUSA=1"
chcp 65001 >nul
title UBS Rápida - Iniciador oficial
cd /d "%~dp0"

echo =====================================================
echo              UBS RAPIDA - INICIAR TUDO
echo =====================================================
echo.
echo Iniciador oficial do sistema.
echo Projeto: %CD%
echo Backend: http://127.0.0.1:8000/docs
echo Frontend: Flutter para Windows, Chrome ou Edge
echo Modos: padrao Windows ^| -Dispositivo chrome ^| -Dispositivo edge
echo.
echo O banco SQLite e os dados existentes serao preservados.
echo A configuracao SMTP sera verificada antes da inicializacao.
echo Segredos de configuracao nao serao exibidos.
echo Credenciais ficticias de demonstracao serao mostradas apos o seed.
echo As contas ficticias serao verificadas sem duplicacao.
echo O aplicativo Windows sera recompilado quando o conteudo do frontend mudar.
echo Use -AtualizarTudo quando quiser atualizar dependencias e recompilar tudo.
echo O primeiro inicio pode demorar durante a preparacao inicial.
echo.
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\iniciar.ps1" %*

if errorlevel 1 (
    echo.
    echo ERRO: nao foi possivel iniciar o UBS Rapida.
    echo Consulte a mensagem apresentada acima e tente novamente.
    if not defined SEM_PAUSA pause
    exit /b 1
)

exit /b 0
