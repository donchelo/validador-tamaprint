# Script de inicio automático simplificado para Validador Tamaprint

Write-Host "========================================" -ForegroundColor Green
Write-Host "    VALIDADOR TAMAPRINT - INICIO AUTO" -ForegroundColor Green  
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Función para mostrar progreso
function Show-Progress {
    param($Message, $Step, $Total)
    Write-Host "[$Step/$Total] $Message" -ForegroundColor Yellow
}

try {
    # Paso 1: Verificar archivos
    Show-Progress "Verificando archivos..." 1 4
    
    if (-not (Test-Path "validador.py")) {
        throw "ERROR: No se encuentra validador.py"
    }
    
    if (-not (Test-Path "ngrok.exe")) {
        throw "ERROR: No se encuentra ngrok.exe"
    }
    
    Write-Host "    OK: Archivos encontrados" -ForegroundColor Green
    
    # Paso 2: Limpiar procesos anteriores
    Show-Progress "Limpiando procesos anteriores..." 2 4
    Get-Process | Where-Object {$_.ProcessName -eq "python" -or $_.ProcessName -eq "ngrok"} | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "    OK: Procesos limpiados" -ForegroundColor Green
    
    # Paso 3: Iniciar FastAPI
    Show-Progress "Iniciando servidor FastAPI..." 3 4
    $fastApiProcess = Start-Process -FilePath "python" -ArgumentList "-m", "uvicorn", "validador:app", "--host", "0.0.0.0", "--port", "8000" -WindowStyle Hidden -PassThru
    
    Write-Host "    Esperando que el servidor se inicie..." -ForegroundColor Cyan
    Start-Sleep -Seconds 8
    
    # Verificar que el servidor esté funcionando
    try {
        Invoke-RestMethod -Uri "http://localhost:8000/health" -Method GET -TimeoutSec 5 | Out-Null
        Write-Host "    OK: Servidor FastAPI funcionando" -ForegroundColor Green
    } catch {
        throw "ERROR: El servidor FastAPI no se inició correctamente"
    }
    
    # Paso 4: Iniciar ngrok y obtener URL
    Show-Progress "Iniciando ngrok y obteniendo URL..." 4 4
    $ngrokProcess = Start-Process -FilePath ".\ngrok.exe" -ArgumentList "http", "8000" -WindowStyle Hidden -PassThru
    
    Write-Host "    Esperando conexión de ngrok..." -ForegroundColor Cyan
    Start-Sleep -Seconds 8
    
    # Obtener URL pública
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -Method GET -TimeoutSec 10
        $publicUrl = $response.tunnels[0].public_url
        
        if (-not $publicUrl) {
            throw "No se pudo obtener la URL pública"
        }
        
        Write-Host "    OK: URL obtenida exitosamente" -ForegroundColor Green
        
    } catch {
        throw "ERROR: No se pudo obtener la URL pública de ngrok"
    }
    
    # Mostrar resultado final
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "                LISTO!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "URL PUBLICA PARA MAKE.COM:" -ForegroundColor Cyan
    Write-Host "    $publicUrl" -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host ""
    
    Write-Host "ENDPOINTS DISPONIBLES:" -ForegroundColor Yellow
    Write-Host "    • Health Check:  $publicUrl/health"
    Write-Host "    • Validar Orden: $publicUrl/validar-orden (POST)"
    Write-Host "    • Debug:         $publicUrl/debug-catalogo"
    Write-Host ""
    
    Write-Host "CONFIGURACION EN MAKE.COM:" -ForegroundColor Magenta
    Write-Host "    URL: $publicUrl/validar-orden"
    Write-Host "    Metodo: POST"
    Write-Host "    Content-Type: application/json"
    Write-Host ""
    
    Write-Host "IMPORTANTE:" -ForegroundColor Red
    Write-Host "    • NO cierres esta ventana de PowerShell"
    Write-Host "    • La URL cambia cada vez que reinicias"
    Write-Host "    • FastAPI y ngrok estan corriendo en segundo plano"
    Write-Host ""
    
    Write-Host "Para detener todo: Cierra esta ventana o presiona Ctrl+C" -ForegroundColor Red
    Write-Host ""
    
    # Probar la conexión
    Write-Host "Probando conexión..." -ForegroundColor Cyan
    try {
        $healthCheck = Invoke-RestMethod -Uri "$publicUrl/health" -Method GET -TimeoutSec 10
        Write-Host "    OK: Conexión exitosa - Catalogo: $($healthCheck.catalogo_items) registros" -ForegroundColor Green
    } catch {
        Write-Host "    AVISO: La URL funciona pero ngrok muestra pagina de advertencia (normal)" -ForegroundColor Yellow
        Write-Host "    OK: Make.com puede acceder sin problemas" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Presiona cualquier tecla para mantener los servicios corriendo..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
} catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Soluciones posibles:" -ForegroundColor Yellow
    Write-Host "    • Verifica que Python este instalado"
    Write-Host "    • Ejecuta: pip install -r requirements.txt"
    Write-Host "    • Verifica que ngrok.exe este en la carpeta"
    Write-Host "    • Cierra otras instancias del validador"
    Write-Host ""
    Read-Host "Presiona Enter para salir"
} finally {
    # Limpiar al salir
    Write-Host "Limpiando procesos..." -ForegroundColor Gray
    if ($fastApiProcess -and -not $fastApiProcess.HasExited) {
        $fastApiProcess.Kill()
    }
    if ($ngrokProcess -and -not $ngrokProcess.HasExited) {
        $ngrokProcess.Kill()
    }
}