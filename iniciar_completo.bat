@echo off
chcp 65001 > nul
set PYTHONIOENCODING=utf-8

echo Iniciando Validador TamaPrint con ngrok...
echo.

cd /d "%~dp0"

echo [1/2] Iniciando servidor Python en segundo plano...
start /min cmd /k "python run.py"

echo [2/2] Esperando 5 segundos antes de iniciar ngrok...
timeout /t 5 /nobreak > nul

echo Iniciando ngrok...
config\ngrok.exe http 8000

pause