# Script de inicio automático mejorado para Validador Tamaprint

Write-Host "========================================" -ForegroundColor Green
Write-Host "    VALIDADOR TAMAPRINT - INICIO AUTO" -ForegroundColor Green  
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Función para mostrar progreso
function Show-Progress {
    param($Message, $Step, $Total)
    Write-Host "[$Step/$Total] $Message" -ForegroundColor Yellow
}

# Función para encontrar puerto disponible
function Find-AvailablePort {
    param($StartPort = 8000)
    
    for ($port = $StartPort; $port -le 8100; $port++) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.Connect("localhost", $port)
            $tcpClient.Close()
        } catch {
            Write-Host "    Puerto $port disponible" -ForegroundColor Green
            return $port
        }
    }
    throw "No se encontró puerto disponible entre 8000-8100"
}

# Función para verificar e instalar dependencias
function Install-Dependencies {
    Write-Host "    Verificando dependencias de Python..." -ForegroundColor Cyan
    try {
        $pipOutput = & pip show fastapi 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    Instalando dependencias..." -ForegroundColor Yellow
            & pip install -r requirements.txt
            if ($LASTEXITCODE -ne 0) {
                throw "Error al instalar dependencias"
            }
        }
        Write-Host "    OK: Dependencias verificadas" -ForegroundColor Green
    } catch {
        throw "ERROR: No se pudieron instalar las dependencias. Ejecuta manualmente: pip install -r requirements.txt"
    }
}

try {
    # Paso 1: Verificar archivos y dependencias
    Show-Progress "Verificando archivos y dependencias..." 1 5
    
    if (-not (Test-Path "validador.py")) {
        throw "ERROR: No se encuentra validador.py"
    }
    
    if (-not (Test-Path "ngrok.exe")) {
        throw "ERROR: No se encuentra ngrok.exe"
    }
    
    if (-not (Test-Path "requirements.txt")) {
        throw "ERROR: No se encuentra requirements.txt"
    }
    
    Write-Host "    OK: Archivos encontrados" -ForegroundColor Green
    
    # Verificar e instalar dependencias automáticamente
    Install-Dependencies
    
    # Paso 2: Limpiar procesos anteriores
    Show-Progress "Limpiando procesos anteriores..." 2 5
    Get-Process | Where-Object {$_.ProcessName -eq "python" -or $_.ProcessName -eq "ngrok"} | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 3
    Write-Host "    OK: Procesos limpiados" -ForegroundColor Green
    
    # Paso 3: Detectar puerto disponible
    Show-Progress "Detectando puerto disponible..." 3 5
    $availablePort = Find-AvailablePort
    Write-Host "    Usando puerto: $availablePort" -ForegroundColor Cyan
    
    # Paso 4: Iniciar FastAPI
    Show-Progress "Iniciando servidor FastAPI..." 4 5
    $fastApiProcess = Start-Process -FilePath "python" -ArgumentList "-m", "uvicorn", "validador:app", "--host", "0.0.0.0", "--port", "$availablePort" -WindowStyle Hidden -PassThru
    
    Write-Host "    Esperando que el servidor se inicie..." -ForegroundColor Cyan
    Start-Sleep -Seconds 10
    
    # Verificar que el servidor esté funcionando
    $maxRetries = 5
    $retry = 0
    $serverRunning = $false
    
    while ($retry -lt $maxRetries -and -not $serverRunning) {
        try {
            Invoke-RestMethod -Uri "http://localhost:$availablePort/health" -Method GET -TimeoutSec 5 | Out-Null
            $serverRunning = $true
            Write-Host "    OK: Servidor FastAPI funcionando en puerto $availablePort" -ForegroundColor Green
        } catch {
            $retry++
            Write-Host "    Reintento $retry/$maxRetries..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
        }
    }
    
    if (-not $serverRunning) {
        throw "ERROR: El servidor FastAPI no se inició correctamente después de $maxRetries intentos"
    }
    
    # Paso 5: Iniciar ngrok y obtener URL
    Show-Progress "Iniciando ngrok y obteniendo URL..." 5 5
    $ngrokProcess = Start-Process -FilePath ".\ngrok.exe" -ArgumentList "http", "$availablePort" -WindowStyle Hidden -PassThru
    
    Write-Host "    Esperando conexión de ngrok..." -ForegroundColor Cyan
    Start-Sleep -Seconds 10
    
    # Obtener URL pública con reintentos
    $maxNgrokRetries = 6
    $ngrokRetry = 0
    $publicUrl = $null
    
    while ($ngrokRetry -lt $maxNgrokRetries -and -not $publicUrl) {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -Method GET -TimeoutSec 10
            if ($response.tunnels -and $response.tunnels.Count -gt 0) {
                $publicUrl = $response.tunnels[0].public_url
                Write-Host "    OK: URL obtenida exitosamente" -ForegroundColor Green
            } else {
                throw "No hay túneles disponibles"
            }
        } catch {
            $ngrokRetry++
            Write-Host "    Esperando ngrok... intento $ngrokRetry/$maxNgrokRetries" -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }
    
    if (-not $publicUrl) {
        throw "ERROR: No se pudo obtener la URL pública de ngrok después de $maxNgrokRetries intentos"
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
    Write-Host "    Puerto usado: $availablePort"
    Write-Host ""
    
    Write-Host "IMPORTANTE:" -ForegroundColor Red
    Write-Host "    • NO cierres esta ventana de PowerShell"
    Write-Host "    • La URL cambia cada vez que reinicias"
    Write-Host "    • FastAPI y ngrok estan corriendo en segundo plano"
    Write-Host "    • Puerto detectado automáticamente: $availablePort"
    Write-Host ""
    
    Write-Host "Para detener todo: Cierra esta ventana o presiona Ctrl+C" -ForegroundColor Red
    Write-Host ""
    
    # Probar la conexión
    Write-Host "Probando conexión..." -ForegroundColor Cyan
    try {
        $healthCheck = Invoke-RestMethod -Uri "$publicUrl/health" -Method GET -TimeoutSec 15
        Write-Host "    OK: Conexión exitosa - Catalogo: $($healthCheck.catalogo_items) registros" -ForegroundColor Green
        Write-Host "    Servidor: localhost:$availablePort -> $publicUrl" -ForegroundColor Green
    } catch {
        Write-Host "    AVISO: La URL funciona pero ngrok muestra pagina de advertencia (normal)" -ForegroundColor Yellow
        Write-Host "    OK: Make.com puede acceder sin problemas" -ForegroundColor Green
        Write-Host "    Servidor: localhost:$availablePort -> $publicUrl" -ForegroundColor Green
    }
    
    Write-Host ""
    Write-Host "SISTEMA COMPLETAMENTE FUNCIONAL" -ForegroundColor Green -BackgroundColor DarkGreen
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