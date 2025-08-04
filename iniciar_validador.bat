@echo off
title Validador Tamaprint - Inicializador
color 0A

echo.
echo =====================================================
echo        VALIDADOR TAMAPRINT - INICIANDO
echo =====================================================
echo.

REM === Verificar archivos esenciales ===
echo [1/3] Verificando archivos esenciales...
if not exist "validador.py" (
    echo ERROR: No se encuentra validador.py
    pause
    exit /b 1
)

if not exist "requirements.txt" (
    echo ERROR: No se encuentra requirements.txt
    pause
    exit /b 1
)

echo    ✅ Archivos esenciales encontrados
echo.

REM === Instalar dependencias si es necesario ===
echo [2/3] Verificando dependencias...
python -c "import fastapi, uvicorn, pandas" >nul 2>&1
if errorlevel 1 (
    echo    Instalando dependencias...
    pip install -r requirements.txt
)
echo    ✅ Dependencias verificadas
echo.

REM === Iniciar servidor ===
echo [3/3] Iniciando servidor...
echo.
echo 📍 URLs de acceso:
echo    • Local:     http://localhost:8000
echo    • Health:    http://localhost:8000/health  
echo    • Docs:      http://localhost:8000/docs
echo.
echo 🌐 Para acceso público, ejecuta en otra terminal:
echo    ngrok.exe http 8000
echo.
echo ⚠️  Para detener: Ctrl+C
echo.

python -m uvicorn validador:app --host 0.0.0.0 --port 8000
