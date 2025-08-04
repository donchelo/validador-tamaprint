@echo off
title Validador Tamaprint - Inicializador Automático
color 0A

echo.
echo =====================================================
echo     🚀 VALIDADOR TAMAPRINT - INICIO AUTOMÁTICO
echo =====================================================
echo.

REM === Verificar archivos esenciales ===
echo [1/4] Verificando archivos esenciales...
if not exist "validador.py" (
    echo ❌ ERROR: No se encuentra validador.py
    pause
    exit /b 1
)

if not exist "ngrok.exe" (
    echo ❌ ERROR: No se encuentra ngrok.exe
    pause
    exit /b 1
)

echo    ✅ Archivos esenciales encontrados
echo.

REM === Instalar dependencias si es necesario ===
echo [2/4] Verificando dependencias...
python -c "import fastapi, uvicorn, pandas" >nul 2>&1
if errorlevel 1 (
    echo    📦 Instalando dependencias...
    pip install -r requirements.txt
)
echo    ✅ Dependencias verificadas
echo.

REM === Iniciar FastAPI en segundo plano ===
echo [3/4] Iniciando servidor FastAPI...
start "FastAPI Server" /min cmd /c "python -m uvicorn validador:app --host 0.0.0.0 --port 8000"

REM === Esperar a que el servidor se inicie ===
echo    ⏳ Esperando que el servidor se inicie...
timeout /t 8 > nul

REM === Verificar que el servidor esté funcionando ===
curl http://localhost:8000/health >nul 2>&1
if errorlevel 1 (
    echo ❌ ERROR: El servidor no se inició correctamente
    pause
    exit /b 1
)
echo    ✅ Servidor FastAPI funcionando

REM === Iniciar ngrok en segundo plano ===
echo [4/4] Iniciando túnel ngrok...
start "Ngrok Tunnel" /min cmd /c "ngrok.exe http 8000"

REM === Esperar a que ngrok se conecte ===
echo    ⏳ Esperando conexión de ngrok...
timeout /t 8 > nul

REM === Obtener URL pública de ngrok ===
echo    🔍 Obteniendo URL pública...
for /f "tokens=*" %%i in ('curl -s http://localhost:4040/api/tunnels ^| findstr "public_url"') do set ngrok_response=%%i

REM === Extraer URL usando PowerShell ===
for /f "tokens=*" %%i in ('powershell -Command "$response = Invoke-RestMethod -Uri 'http://localhost:4040/api/tunnels'; $response.tunnels[0].public_url"') do set NGROK_URL=%%i

echo.
echo =====================================================
echo                   ✅ ¡LISTO!
echo =====================================================
echo.
echo 🌐 URL PÚBLICA PARA MAKE.COM:
echo    %NGROK_URL%
echo.
echo 📋 ENDPOINTS DISPONIBLES:
echo    • Health Check:  %NGROK_URL%/health
echo    • Validar Orden: %NGROK_URL%/validar-orden (POST)
echo    • Debug:         %NGROK_URL%/debug-catalogo
echo.
echo 🔧 CONFIGURACIÓN EN MAKE.COM:
echo    URL: %NGROK_URL%/validar-orden
echo    Método: POST
echo    Content-Type: application/json
echo.
echo ⚠️  IMPORTANTE: 
echo    • NO cierres esta ventana
echo    • La URL cambia cada vez que reinicias
echo    • FastAPI y ngrok están corriendo en segundo plano
echo.
echo 🛑 Para detener todo: Cierra esta ventana
echo.

REM === Mantener la ventana abierta ===
pause
