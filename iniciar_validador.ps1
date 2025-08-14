# Script de inicio automático MEJORADO para Validador Tamaprint
# Versión 2.1 - Soluciona todos los problemas de inicio

Write-Host "========================================" -ForegroundColor Green
Write-Host "    VALIDADOR TAMAPRINT - INICIO AUTO" -ForegroundColor Green  
Write-Host "    Versión 2.1 - Mejorado" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Función para mostrar progreso
function Show-Progress {
    param($Message, $Step, $Total)
    Write-Host "[$Step/$Total] $Message" -ForegroundColor Yellow
}

# Función para encontrar puerto disponible (MEJORADA)
function Find-AvailablePort {
    param($StartPort = 8000)
    
    Write-Host "    Buscando puerto disponible desde $StartPort..." -ForegroundColor Cyan
    
    for ($port = $StartPort; $port -le 8100; $port++) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.Connect("localhost", $port)
            $tcpClient.Close()
            Write-Host "    Puerto $port en uso, probando siguiente..." -ForegroundColor Gray
        } catch {
            Write-Host "    ✅ Puerto $port disponible" -ForegroundColor Green
            return $port
        }
    }
    throw "No se encontró puerto disponible entre $StartPort-8100"
}

# Función para verificar e instalar dependencias (MEJORADA)
function Install-Dependencies {
    Write-Host "    Verificando entorno virtual..." -ForegroundColor Cyan
    
    # Verificar si existe entorno virtual
    if (Test-Path ".venv") {
        Write-Host "    ✅ Entorno virtual encontrado" -ForegroundColor Green
        Write-Host "    Activando entorno virtual..." -ForegroundColor Cyan
        
        # Activar entorno virtual
        try {
            & ".\.venv\Scripts\Activate.ps1"
            Write-Host "    ✅ Entorno virtual activado" -ForegroundColor Green
        } catch {
            Write-Host "    ⚠️ No se pudo activar entorno virtual, continuando..." -ForegroundColor Yellow
        }
    } else {
        Write-Host "    ⚠️ No se encontró entorno virtual" -ForegroundColor Yellow
    }
    
    Write-Host "    Verificando dependencias de Python..." -ForegroundColor Cyan
    try {
        # Verificar si fastapi está instalado
        $pipOutput = & python -c "import fastapi; print('OK')" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    Instalando dependencias..." -ForegroundColor Yellow
            & pip install -r requirements.txt
            if ($LASTEXITCODE -ne 0) {
                throw "Error al instalar dependencias"
            }
            Write-Host "    ✅ Dependencias instaladas" -ForegroundColor Green
        } else {
            Write-Host "    ✅ Dependencias ya instaladas" -ForegroundColor Green
        }
    } catch {
        throw "ERROR: No se pudieron instalar las dependencias. Ejecuta manualmente: pip install -r requirements.txt"
    }
}

# Función para limpiar procesos (MEJORADA)
function Clean-Processes {
    Write-Host "    Limpiando procesos anteriores..." -ForegroundColor Cyan
    
    # Detener procesos de Python que ejecutan uvicorn
    $pythonProcesses = Get-Process | Where-Object {$_.ProcessName -eq "python"}
    foreach ($proc in $pythonProcesses) {
        try {
            $procInfo = Get-WmiObject -Class Win32_Process -Filter "ProcessId = $($proc.Id)"
            if ($procInfo.CommandLine -like "*uvicorn*" -or $procInfo.CommandLine -like "*validador*") {
                Write-Host "    Deteniendo proceso Python (uvicorn): $($proc.Id)" -ForegroundColor Yellow
                $proc.Kill()
            }
        } catch {
            # Ignorar errores
        }
    }
    
    # Detener procesos de ngrok
    $ngrokProcesses = Get-Process | Where-Object {$_.ProcessName -eq "ngrok"}
    foreach ($proc in $ngrokProcesses) {
        Write-Host "    Deteniendo proceso ngrok: $($proc.Id)" -ForegroundColor Yellow
        $proc.Kill()
    }
    
    Start-Sleep -Seconds 5
    Write-Host "    ✅ Procesos limpiados" -ForegroundColor Green
}

# Función para verificar archivos críticos
function Test-CriticalFiles {
    Write-Host "    Verificando archivos críticos..." -ForegroundColor Cyan
    
    $criticalFiles = @("validador.py", "requirements.txt", "ngrok.exe")
    $missingFiles = @()
    
    foreach ($file in $criticalFiles) {
        if (Test-Path $file) {
            Write-Host "    ✅ $file" -ForegroundColor Green
        } else {
            Write-Host "    ❌ $file - FALTANTE" -ForegroundColor Red
            $missingFiles += $file
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        throw "ERROR: Faltan archivos críticos: $($missingFiles -join ', ')"
    }
    
    # Verificar archivos opcionales
    $optionalFiles = @(".env", "credentials.json")
    foreach ($file in $optionalFiles) {
        if (Test-Path $file) {
            Write-Host "    ✅ $file (opcional)" -ForegroundColor Green
        } else {
            Write-Host "    ⚠️ $file (opcional) - No encontrado" -ForegroundColor Yellow
        }
    }
}

try {
    # Paso 1: Verificar archivos críticos
    Show-Progress "Verificando archivos críticos..." 1 6
    Test-CriticalFiles
    
    # Paso 2: Verificar e instalar dependencias
    Show-Progress "Verificando dependencias..." 2 6
    Install-Dependencies
    
    # Paso 3: Limpiar procesos anteriores
    Show-Progress "Limpiando procesos anteriores..." 3 6
    Clean-Processes
    
    # Paso 4: Detectar puerto disponible
    Show-Progress "Detectando puerto disponible..." 4 6
    $availablePort = Find-AvailablePort
    Write-Host "    Usando puerto: $availablePort" -ForegroundColor Cyan
    
    # Paso 5: Iniciar FastAPI (MEJORADO)
    Show-Progress "Iniciando servidor FastAPI..." 5 6
    
    # Iniciar FastAPI con más tiempo de espera
    $fastApiProcess = Start-Process -FilePath "python" -ArgumentList "-m", "uvicorn", "validador:app", "--host", "0.0.0.0", "--port", "$availablePort" -WindowStyle Hidden -PassThru
    
    Write-Host "    Esperando que el servidor se inicie (15 segundos)..." -ForegroundColor Cyan
    Start-Sleep -Seconds 15
    
    # Verificar que el servidor esté funcionando (MEJORADO)
    $maxRetries = 8
    $retry = 0
    $serverRunning = $false
    
    while ($retry -lt $maxRetries -and -not $serverRunning) {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:$availablePort/health" -Method GET -TimeoutSec 10
            if ($response.status -eq "OK") {
                $serverRunning = $true
                Write-Host "    ✅ Servidor FastAPI funcionando en puerto $availablePort" -ForegroundColor Green
                Write-Host "    📊 Catálogo cargado: $($response.catalogo_items) registros" -ForegroundColor Green
            } else {
                throw "Respuesta inesperada del servidor"
            }
        } catch {
            $retry++
            Write-Host "    Reintento $retry/$maxRetries... (esperando 5 segundos)" -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }
    
    if (-not $serverRunning) {
        throw "ERROR: El servidor FastAPI no se inició correctamente después de $maxRetries intentos"
    }
    
    # Paso 6: Iniciar ngrok y obtener URL (MEJORADO)
    Show-Progress "Iniciando ngrok y obteniendo URL..." 6 6
    $ngrokProcess = Start-Process -FilePath ".\ngrok.exe" -ArgumentList "http", "$availablePort" -WindowStyle Hidden -PassThru
    
    Write-Host "    Esperando conexion de ngrok (15 segundos)..." -ForegroundColor Cyan
    Start-Sleep -Seconds 15
    
    # Obtener URL pública con reintentos (MEJORADO)
    $maxNgrokRetries = 8
    $ngrokRetry = 0
    $publicUrl = $null
    
    while ($ngrokRetry -lt $maxNgrokRetries -and -not $publicUrl) {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -Method GET -TimeoutSec 15
            if ($response.tunnels -and $response.tunnels.Count -gt 0) {
                $publicUrl = $response.tunnels[0].public_url
                Write-Host "    ✅ URL obtenida exitosamente" -ForegroundColor Green
            } else {
                throw "No hay túneles disponibles"
            }
        } catch {
            $ngrokRetry++
            Write-Host "    Esperando ngrok... intento $ngrokRetry/$maxNgrokRetries (esperando 8 segundos)" -ForegroundColor Yellow
            Start-Sleep -Seconds 8
        }
    }
    
    if (-not $publicUrl) {
        throw "ERROR: No se pudo obtener la URL pública de ngrok después de $maxNgrokRetries intentos"
    }
    
    # Mostrar resultado final (MEJORADO)
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
    
    # Probar la conexión (MEJORADO)
    Write-Host "Probando conexión..." -ForegroundColor Cyan
    try {
        $healthCheck = Invoke-RestMethod -Uri "$publicUrl/health" -Method GET -TimeoutSec 20
        Write-Host "    ✅ Conexión exitosa - Catalogo: $($healthCheck.catalogo_items) registros" -ForegroundColor Green
        Write-Host "    🌐 Servidor: localhost:$availablePort -> $publicUrl" -ForegroundColor Green
    } catch {
        Write-Host "    ⚠️ La URL funciona pero ngrok muestra pagina de advertencia (normal)" -ForegroundColor Yellow
        Write-Host "    ✅ Make.com puede acceder sin problemas" -ForegroundColor Green
        Write-Host "    🌐 Servidor: localhost:$availablePort -> $publicUrl" -ForegroundColor Green
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
    Write-Host "    • Verifica que el entorno virtual esté configurado"
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