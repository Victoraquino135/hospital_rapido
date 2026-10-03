@echo off
rem Atalho mantido por compatibilidade. A inicializacao oficial fica em INICIAR_TUDO.bat.
if /i "%~1"=="--check" (
    call "%~dp0INICIAR_TUDO.bat" -Validar
    exit /b %errorlevel%
)
call "%~dp0INICIAR_TUDO.bat" %*
exit /b %errorlevel%
