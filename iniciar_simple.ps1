# Script SIMPLE para iniciar Validador Tamaprint
# Version sin emojis ni caracteres especiales

Write-Host "========================================"
Write-Host "  VALIDADOR TAMAPRINT - INICIO SIMPLE"  
Write-Host "========================================"
Write-Host ""

try {
    # Limpiar procesos previos
    Write-Host "[1/4] Limpiando procesos anteriores..."
    Get-Process | Where-Object {$_.ProcessName -eq "python" -or $_.ProcessName -eq "ngrok"} | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    
    # Verificar dependencias
    Write-Host "[2/4] Instalando dependencias..."
    pip install -r requirements.txt | Out-Null
    
    # Iniciar FastAPI en background
    Write-Host "[3/4] Iniciando servidor FastAPI..."
    $env:PYTHONIOENCODING="utf-8"
    Start-Process -FilePath "python" -ArgumentList "-m", "uvicorn", "validador:app", "--host", "0.0.0.0", "--port", "8000" -WindowStyle Hidden
    
    # Esperar que el servidor inicie
    Start-Sleep -Seconds 15
    
    # Verificar que el servidor responda
    $healthCheck = $null
    $maxTries = 5
    for ($i = 1; $i -le $maxTries; $i++) {
        try {
            $healthCheck = Invoke-RestMethod -Uri "http://localhost:8000/health" -Method GET -TimeoutSec 10
            if ($healthCheck.status -eq "OK") {
                Write-Host "    Servidor FastAPI funcionando correctamente"
                break
            }
        } catch {
            Write-Host "    Intento $i/$maxTries - Esperando servidor..."
            Start-Sleep -Seconds 5
        }
    }
    
    if (-not $healthCheck -or $healthCheck.status -ne "OK") {
        throw "El servidor FastAPI no se inicio correctamente"
    }
    
    # Iniciar ngrok
    Write-Host "[4/4] Iniciando tunel ngrok..."
    Start-Process -FilePath ".\ngrok.exe" -ArgumentList "http", "8000" -WindowStyle Hidden
    Start-Sleep -Seconds 10
    
    # Obtener URL publica
    $publicUrl = $null
    $maxRetries = 8
    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -Method GET -TimeoutSec 10
            if ($response.tunnels -and $response.tunnels.Count -gt 0) {
                $publicUrl = $response.tunnels[0].public_url
                break
            }
        } catch {
            Write-Host "    Obteniendo URL... intento $i/$maxRetries"
            Start-Sleep -Seconds 5
        }
    }
    
    if (-not $publicUrl) {
        throw "No se pudo obtener la URL publica de ngrok"
    }
    
    # Mostrar resultado
    Write-Host ""
    Write-Host "========================================"
    Write-Host "           SISTEMA LISTO!"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "URL PARA MAKE.COM:" -ForegroundColor Green
    Write-Host "  $publicUrl/validar-orden" -ForegroundColor White
    Write-Host ""
    Write-Host "ENDPOINTS:" -ForegroundColor Yellow
    Write-Host "  Health:  $publicUrl/health"
    Write-Host "  Validar: $publicUrl/validar-orden (POST)"
    Write-Host "  Debug:   $publicUrl/debug-catalogo"
    Write-Host ""
    Write-Host "IMPORTANTE:" -ForegroundColor Red
    Write-Host "  - NO cierres esta ventana"
    Write-Host "  - La URL cambia cada reinicio"
    Write-Host "  - Servicios corriendo en segundo plano"
    Write-Host ""
    Write-Host "Presiona ENTER para mantener servicios activos..."
    Read-Host
    
} catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "SOLUCION:" -ForegroundColor Yellow
    Write-Host "1. Verifica que Python este instalado"
    Write-Host "2. Ejecuta: pip install -r requirements.txt"
    Write-Host "3. Verifica que ngrok.exe este presente"
    Write-Host ""
    Read-Host "Presiona ENTER para salir"
}