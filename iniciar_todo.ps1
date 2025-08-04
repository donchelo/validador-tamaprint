# Script para iniciar Validador TamaPrint completo
# Autor: Sistema
# Fecha: 2024

Write-Host "========================================" -ForegroundColor Green
Write-Host "    Iniciando Validador TamaPrint" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Verificar que estamos en el directorio correcto
if (-not (Test-Path "validador.py")) {
    Write-Host "ERROR: No se encuentra validador.py" -ForegroundColor Red
    Write-Host "Asegúrate de ejecutar este script desde el directorio del proyecto" -ForegroundColor Red
    Read-Host "Presiona Enter para salir"
    exit 1
}

# Activar entorno virtual
Write-Host "[1/4] Activando entorno virtual..." -ForegroundColor Yellow
try {
    & "\.venv\Scripts\Activate.ps1"
    Write-Host "✅ Entorno virtual activado" -ForegroundColor Green
} catch {
    Write-Host "❌ Error activando entorno virtual" -ForegroundColor Red
    Write-Host "Ejecuta: python -m venv .venv" -ForegroundColor Yellow
    Read-Host "Presiona Enter para salir"
    exit 1
}

# Verificar Python
Write-Host "[2/4] Verificando Python..." -ForegroundColor Yellow
try {
    $pythonVersion = python --version
    Write-Host "✅ $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python no encontrado" -ForegroundColor Red
    Read-Host "Presiona Enter para salir"
    exit 1
}

# Verificar ngrok
Write-Host "[3/4] Verificando ngrok..." -ForegroundColor Yellow
if (-not (Test-Path "ngrok.exe")) {
    Write-Host "❌ ngrok.exe no encontrado" -ForegroundColor Red
    Write-Host "Descarga ngrok desde: https://ngrok.com/download" -ForegroundColor Yellow
    Read-Host "Presiona Enter para salir"
    exit 1
}
Write-Host "✅ ngrok.exe encontrado" -ForegroundColor Green

# Iniciar servidor FastAPI en segundo plano
Write-Host "[4/4] Iniciando servidor FastAPI..." -ForegroundColor Yellow
Write-Host ""
Write-Host "🌐 Servidor local: http://localhost:3000" -ForegroundColor Cyan
Write-Host "🔍 Health check: http://localhost:3000/health" -ForegroundColor Cyan
Write-Host "📊 Debug catálogo: http://localhost:3000/debug-catalogo" -ForegroundColor Cyan
Write-Host ""
Write-Host "🌍 Para exponer públicamente, ejecuta en otra terminal:" -ForegroundColor Yellow
Write-Host "   .\iniciar_ngrok.bat" -ForegroundColor White
Write-Host ""
Write-Host "Para detener: Ctrl+C" -ForegroundColor Red
Write-Host ""

# Iniciar el servidor
try {
    python -m uvicorn validador:app --reload --host 127.0.0.1 --port 3000
} catch {
    Write-Host "❌ Error iniciando el servidor" -ForegroundColor Red
    Read-Host "Presiona Enter para salir"
} 