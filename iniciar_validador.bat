@echo off
REM === Iniciar FastAPI ===
start cmd /k "cd /d %~dp0 && python -m uvicorn validador:app --reload --port 8000"

REM === Esperar unos segundos para asegurar inicio ===
timeout /t 4 > nul

REM === Iniciar Ngrok desde la misma carpeta ===
start cmd /k "cd /d %~dp0 && ngrok.exe http 8000"
