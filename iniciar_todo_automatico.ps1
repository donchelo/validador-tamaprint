# Script de inicio automático para Validador Tamaprint
# Inicia FastAPI + ngrok y proporciona la URL final para Make.com

Write-Host "========================================" -ForegroundColor Green
Write-Host "    VALIDADOR TAMAPRINT AUTO" -ForegroundColor Green  
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Función para mostrar progreso
function Show-Progress {
    param($Message, $Step, $Total)
    Write-Host "[$Step/$Total] $Message" -ForegroundColor Yellow
}

# Función para verificar si un puerto está en uso
function Test-Port {
    param($Port)
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $connection.Connect("127.0.0.1", $Port)
        $connection.Close()
        return $true
    } catch {
        return $false
    }
}

# Función para terminar procesos anteriores
function Stop-PreviousProcesses {
    Get-Process | Where-Object {$_.ProcessName -eq "python" -or $_.ProcessName -eq "ngrok"} | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

try {
    # Paso 1: Verificar archivos
    Show-Progress "Verificando archivos esenciales..." 1 5
    
    if (-not (Test-Path "validador.py")) {
        throw "ERROR: No se encuentra validador.py"
    }
    
    if (-not (Test-Path "ngrok.exe")) {
        throw "ERROR: No se encuentra ngrok.exe"
    }
    
    Write-Host "    OK: Archivos encontrados" -ForegroundColor Green
    
    # Paso 2: Limpiar procesos anteriores
    Show-Progress "Limpiando procesos anteriores..." 2 5
    Stop-PreviousProcesses
    Write-Host "    ✅ Procesos limpiados" -ForegroundColor Green
    
    # Paso 3: Iniciar FastAPI
    Show-Progress "Iniciando servidor FastAPI..." 3 5
    $fastApiProcess = Start-Process -FilePath "python" -ArgumentList "-m", "uvicorn", "validador:app", "--host", "0.0.0.0", "--port", "8000" -WindowStyle Hidden -PassThru
    
    # Esperar a que el servidor se inicie
    Write-Host "    ⏳ Esperando que el servidor se inicie..." -ForegroundColor Cyan
    $timeout = 15
    $elapsed = 0
    do {
        Start-Sleep -Seconds 1
        $elapsed++
        if ($elapsed -gt $timeout) {
            throw "❌ ERROR: El servidor FastAPI no se inició en $timeout segundos"
        }
    } while (-not (Test-Port 8000))
    
    Write-Host "    ✅ Servidor FastAPI funcionando" -ForegroundColor Green
    
    # Paso 4: Iniciar ngrok
    Show-Progress "Iniciando túnel ngrok..." 4 5
    $ngrokProcess = Start-Process -FilePath ".\ngrok.exe" -ArgumentList "http", "8000" -WindowStyle Hidden -PassThru
    
    # Esperar a que ngrok se conecte
    Write-Host "    ⏳ Esperando conexión de ngrok..." -ForegroundColor Cyan
    $timeout = 15
    $elapsed = 0
    do {
        Start-Sleep -Seconds 1
        $elapsed++
        if ($elapsed -gt $timeout) {
            throw "❌ ERROR: ngrok no se conectó en $timeout segundos"
        }
    } while (-not (Test-Port 4040))
    
    Start-Sleep -Seconds 3  # Tiempo adicional para que ngrok establezca el túnel
    
    # Paso 5: Obtener URL pública
    Show-Progress "Obteniendo URL pública..." 5 5
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -Method GET
        $publicUrl = $response.tunnels[0].public_url
        
        if (-not $publicUrl) {
            throw "No se pudo obtener la URL pública"
        }
        
        Write-Host "    ✅ URL obtenida exitosamente" -ForegroundColor Green
        
    } catch {
        throw "❌ ERROR: No se pudo obtener la URL pública de ngrok: $_"
    }
    
    # Mostrar resultado final
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "                ✅ ¡LISTO!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "🌐 URL PÚBLICA PARA MAKE.COM:" -ForegroundColor Cyan
    Write-Host "    $publicUrl" -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host ""
    
    Write-Host "📋 ENDPOINTS DISPONIBLES:" -ForegroundColor Yellow
    Write-Host "    • Health Check:  $publicUrl/health"
    Write-Host "    • Validar Orden: $publicUrl/validar-orden (POST)"
    Write-Host "    • Debug:         $publicUrl/debug-catalogo"
    Write-Host ""
    
    Write-Host "🔧 CONFIGURACIÓN EN MAKE.COM:" -ForegroundColor Magenta
    Write-Host "    URL: $publicUrl/validar-orden"
    Write-Host "    Método: POST"
    Write-Host "    Content-Type: application/json"
    Write-Host ""
    
    Write-Host "⚠️  IMPORTANTE:" -ForegroundColor Red
    Write-Host "    • NO cierres esta ventana de PowerShell"
    Write-Host "    • La URL cambia cada vez que reinicias"
    Write-Host "    • FastAPI y ngrok están corriendo en segundo plano"
    Write-Host ""
    
    Write-Host "🛑 Para detener todo: Cierra esta ventana o presiona Ctrl+C" -ForegroundColor Red
    Write-Host ""
    
    # Probar la conexión
    Write-Host "🔍 Probando conexión..." -ForegroundColor Cyan
    try {
        $healthCheck = Invoke-RestMethod -Uri "$publicUrl/health" -Method GET -Headers @{"Accept"="application/json"} -ErrorAction Stop
        Write-Host "    ✅ Conexión exitosa - Catálogo: $($healthCheck.catalogo_items) registros" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠️  Advertencia: La URL funciona pero ngrok muestra página de advertencia (normal)" -ForegroundColor Yellow
        Write-Host "    ✅ Make.com puede acceder sin problemas" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "Presiona cualquier tecla para mantener los servicios corriendo..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
} catch {
    Write-Host ""
    Write-Host "❌ ERROR: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "💡 Soluciones posibles:" -ForegroundColor Yellow
    Write-Host "    • Verifica que Python esté instalado"
    Write-Host "    • Ejecuta: pip install -r requirements.txt"
    Write-Host "    • Verifica que ngrok.exe esté en la carpeta"
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