@echo off
title Validador Tamaprint - Inicializador
color 0A

echo.
echo =====================================================
echo        VALIDADOR TAMAPRINT 2.0 - INICIANDO
echo =====================================================
echo.

REM === Verificar archivos necesarios ===
echo [1/5] Verificando archivos necesarios...
if not exist "validador.py" (
    echo ERROR: No se encuentra validador.py
    pause
    exit /b 1
)

if not exist "credentials.json" (
    echo ERROR: No se encuentra credentials.json
    pause
    exit /b 1
)

if not exist ".env" (
    echo ERROR: No se encuentra .env
    pause
    exit /b 1
)

if not exist "ngrok.exe" (
    echo ERROR: No se encuentra ngrok.exe
    pause
    exit /b 1
)

echo    ✅ Todos los archivos necesarios encontrados
echo.

REM === Verificar Python ===
echo [2/5] Verificando Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python no está instalado o no está en el PATH
    pause
    exit /b 1
)
echo    ✅ Python disponible

REM === Instalar/Verificar dependencias ===
echo [3/5] Verificando dependencias...
python -c "import fastapi, uvicorn, pandas, gspread" >nul 2>&1
if errorlevel 1 (
    echo    Instalando dependencias faltantes...
    pip install -r requirements.txt
)
echo    ✅ Dependencias verificadas

REM === Iniciar FastAPI (sin --reload para estabilidad) ===
echo [4/5] Iniciando servidor FastAPI...
start "FastAPI Server" cmd /k "cd /d %~dp0 && echo Iniciando FastAPI en puerto 8000... && python -m uvicorn validador:app --host 0.0.0.0 --port 8000"

REM === Esperar inicio del servidor ===
echo    Esperando inicio del servidor...
timeout /t 6 > nul

REM === Iniciar Ngrok ===
echo [5/5] Iniciando túnel Ngrok...
start "Ngrok Tunnel" cmd /k "cd /d %~dp0 && echo Iniciando Ngrok... && ngrok.exe http 8000"

REM === Esperar a que ngrok se conecte ===
timeout /t 3 > nul

echo.
echo =====================================================
echo                    ✅ LISTO! 
echo =====================================================
echo.
echo 📍 URLs de acceso:
echo    • Local:     http://localhost:8000
echo    • Health:    http://localhost:8000/health  
echo    • Docs:      http://localhost:8000/docs
echo    • Ngrok UI:  http://localhost:4040
echo.
echo 🔗 Para obtener la URL pública de ngrok:
echo    Visita http://localhost:4040 y copia la URL https
echo.
echo 📋 Endpoints para Make.com:
echo    • Validación: [URL_NGROK]/validar-orden
echo    • Health:     [URL_NGROK]/health
echo.
echo ⚠️  IMPORTANTE: No cierres las ventanas de FastAPI ni Ngrok
echo.

REM === Abrir automáticamente el dashboard de ngrok ===
timeout /t 2 > nul
start http://localhost:4040

echo Presiona cualquier tecla para salir (las aplicaciones seguirán corriendo)...
pause > nul
