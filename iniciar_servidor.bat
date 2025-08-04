@echo off
echo ========================================
echo    Iniciando Validador TamaPrint
echo ========================================
echo.

REM Activar entorno virtual
echo [1/3] Activando entorno virtual...
call .venv\Scripts\Activate.bat

REM Verificar Python
echo [2/3] Verificando Python...
python --version

REM Iniciar servidor FastAPI
echo [3/3] Iniciando servidor FastAPI...
echo.
echo Servidor iniciado en: http://localhost:3000
echo Health check: http://localhost:3000/health
echo.
echo Para detener: Ctrl+C
echo.
python -m uvicorn validador:app --reload --host 127.0.0.1 --port 3000

pause 