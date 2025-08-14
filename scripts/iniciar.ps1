# ========================================
#    VALIDADOR TAMAPRINT - INICIADOR UNIFICADO
#    Version 3.0 - Un solo archivo para todo
# ========================================

param(
    [Parameter(Position=0)]
    [ValidateSet("simple", "manual", "auto", "batch")]
    [string]$Modo = "auto",
    
    [int]$Puerto = 0,
    
    [switch]$NoNgrok,
    
    [switch]$VerificarSolo
)

# Configuracion de colores
$Colors = @{
    Header = "Green"
    Success = "Green"
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
    URL = "White"
    Background = "DarkBlue"
}

function Write-Header {
    param($Message)
    Write-Host "========================================" -ForegroundColor $Colors.Header
    Write-Host "    $Message" -ForegroundColor $Colors.Header
    Write-Host "========================================" -ForegroundColor $Colors.Header
    Write-Host ""
}

function Write-Step {
    param($Step, $Total, $Message)
    Write-Host "[$Step/$Total] $Message" -ForegroundColor $Colors.Info
}

function Write-Success {
    param($Message)
    Write-Host "[OK] $Message" -ForegroundColor $Colors.Success
}

function Write-Warning {
    param($Message)
    Write-Host "[WARN] $Message" -ForegroundColor $Colors.Warning
}

function Write-Error {
    param($Message)
    Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Error
}

function Write-URL {
    param($Message, $URL)
    Write-Host "$Message" -ForegroundColor $Colors.Info
    Write-Host "  $URL" -ForegroundColor $Colors.URL -BackgroundColor $Colors.Background
}

# Funcion para verificar archivos criticos
function Test-CriticalFiles {
    Write-Step 1 6 "Verificando archivos criticos..."
    
    $criticalFiles = @("src\validador.py", "requirements.txt")
    $optionalFiles = @("config\ngrok.exe", ".env", "credentials.json")
    $missingFiles = @()
    
    foreach ($file in $criticalFiles) {
        if (Test-Path $file) {
            Write-Success "$file"
        } else {
            Write-Error "$file - FALTANTE"
            $missingFiles += $file
        }
    }
    
    foreach ($file in $optionalFiles) {
        if (Test-Path $file) {
            Write-Success "$file (opcional)"
        } else {
            Write-Warning "$file (opcional) - No encontrado"
        }
    }
    
    if ($missingFiles.Count -gt 0) {
        throw "ERROR: Faltan archivos criticos: $($missingFiles -join ', ')"
    }
    
    if ($NoNgrok -and -not (Test-Path "config\ngrok.exe")) {
        Write-Warning "Modo sin ngrok seleccionado - config\ngrok.exe no es necesario"
    }
}

# Funcion para verificar e instalar dependencias
function Install-Dependencies {
    Write-Step 2 6 "Verificando dependencias..."
    
    # Verificar entorno virtual
    if (Test-Path ".venv") {
        Write-Success "Entorno virtual encontrado"
        try {
            & ".\.venv\Scripts\Activate.ps1"
            Write-Success "Entorno virtual activado"
        } catch {
            Write-Warning "No se pudo activar entorno virtual, continuando..."
        }
    } else {
        Write-Warning "No se encontro entorno virtual"
    }
    
    # Verificar dependencias
    try {
        $pipOutput = & python -c "import fastapi; print('OK')" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    Instalando dependencias..." -ForegroundColor $Colors.Warning
            & pip install -r requirements.txt
            if ($LASTEXITCODE -ne 0) {
                throw "Error al instalar dependencias"
            }
            Write-Success "Dependencias instaladas"
        } else {
            Write-Success "Dependencias ya instaladas"
        }
    } catch {
        throw "ERROR: No se pudieron instalar las dependencias. Ejecuta manualmente: pip install -r requirements.txt"
    }
}

# Funcion para limpiar procesos
function Clean-Processes {
    Write-Step 3 6 "Limpiando procesos anteriores..."
    
    $pythonProcesses = Get-Process | Where-Object {$_.ProcessName -eq "python"}
    foreach ($proc in $pythonProcesses) {
        try {
            $procInfo = Get-WmiObject -Class Win32_Process -Filter "ProcessId = $($proc.Id)"
            if ($procInfo.CommandLine -like "*uvicorn*" -or $procInfo.CommandLine -like "*validador*") {
                Write-Host "    Deteniendo proceso Python (uvicorn): $($proc.Id)" -ForegroundColor $Colors.Warning
                $proc.Kill()
            }
        } catch {
            # Ignorar errores
        }
    }
    
    $ngrokProcesses = Get-Process | Where-Object {$_.ProcessName -eq "ngrok"}
    foreach ($proc in $ngrokProcesses) {
        Write-Host "    Deteniendo proceso ngrok: $($proc.Id)" -ForegroundColor $Colors.Warning
        $proc.Kill()
    }
    
    Start-Sleep -Seconds 3
    Write-Success "Procesos limpiados"
}

# Funcion para encontrar puerto disponible
function Find-AvailablePort {
    param($StartPort = 8000)
    
    if ($Puerto -gt 0) {
        Write-Host "    Usando puerto especificado: $Puerto" -ForegroundColor $Colors.Info
        return $Puerto
    }
    
    Write-Host "    Buscando puerto disponible desde $StartPort..." -ForegroundColor $Colors.Info
    
    for ($port = $StartPort; $port -le 8100; $port++) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.Connect("localhost", $port)
            $tcpClient.Close()
            Write-Host "    Puerto $port en uso, probando siguiente..." -ForegroundColor Gray
        } catch {
            Write-Success "Puerto $port disponible"
            return $port
        }
    }
    throw "No se encontro puerto disponible entre $StartPort-8100"
}

# Funcion para iniciar FastAPI
function Start-FastAPI {
    param($Port)
    
    Write-Step 4 6 "Iniciando servidor FastAPI..."
    
    if ($Modo -eq "batch") {
        Write-Host "    Modo batch: iniciando en primer plano..." -ForegroundColor $Colors.Info
            Write-Host "    Ejecutando: python -m uvicorn src.validador:app --host 0.0.0.0 --port $Port" -ForegroundColor $Colors.Info
    python -m uvicorn src.validador:app --host 0.0.0.0 --port $Port
        return
    }
    
    # Modo automatico o manual
    $fastApiProcess = Start-Process -FilePath "python" -ArgumentList "-m", "uvicorn", "src.validador:app", "--host", "0.0.0.0", "--port", "$Port" -WindowStyle Hidden -PassThru
    
    Write-Host "    Esperando que el servidor se inicie (15 segundos)..." -ForegroundColor $Colors.Info
    Start-Sleep -Seconds 15
    
    # Verificar que el servidor este funcionando
    $maxRetries = 8
    $retry = 0
    $serverRunning = $false
    
    while ($retry -lt $maxRetries -and -not $serverRunning) {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:$Port/health" -Method GET -TimeoutSec 10
            if ($response.status -eq "OK") {
                $serverRunning = $true
                Write-Success "Servidor FastAPI funcionando en puerto $Port"
                Write-Host "    Catalogo cargado: $($response.catalogo_items) registros" -ForegroundColor $Colors.Success
            } else {
                throw "Respuesta inesperada del servidor"
            }
        } catch {
            $retry++
            Write-Host "    Reintento $retry/$maxRetries... (esperando 5 segundos)" -ForegroundColor $Colors.Warning
            Start-Sleep -Seconds 5
        }
    }
    
    if (-not $serverRunning) {
        throw "ERROR: El servidor FastAPI no se inicio correctamente despues de $maxRetries intentos"
    }
    
    return $fastApiProcess
}

# Funcion para iniciar ngrok
function Start-Ngrok {
    param($Port)
    
    if ($NoNgrok) {
        Write-Warning "Modo sin ngrok seleccionado - saltando ngrok"
        return $null
    }
    
    Write-Step 5 6 "Iniciando ngrok..."
    
    if (-not (Test-Path "config\ngrok.exe")) {
        throw "ERROR: config\ngrok.exe no encontrado. Descarga desde https://ngrok.com/download"
    }
    
    $ngrokProcess = Start-Process -FilePath ".\config\ngrok.exe" -ArgumentList "http", "$Port" -WindowStyle Hidden -PassThru
    
    Write-Host "    Esperando conexion de ngrok (15 segundos)..." -ForegroundColor $Colors.Info
    Start-Sleep -Seconds 15
    
    # Obtener URL publica
    $maxNgrokRetries = 8
    $ngrokRetry = 0
    $publicUrl = $null
    
    while ($ngrokRetry -lt $maxNgrokRetries -and -not $publicUrl) {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -Method GET -TimeoutSec 15
            if ($response.tunnels -and $response.tunnels.Count -gt 0) {
                $publicUrl = $response.tunnels[0].public_url
                Write-Success "URL obtenida exitosamente"
            } else {
                throw "No hay tuneles disponibles"
            }
        } catch {
            $ngrokRetry++
            Write-Host "    Esperando ngrok... intento $ngrokRetry/$maxNgrokRetries (esperando 8 segundos)" -ForegroundColor $Colors.Warning
            Start-Sleep -Seconds 8
        }
    }
    
    if (-not $publicUrl) {
        throw "ERROR: No se pudo obtener la URL publica de ngrok despues de $maxNgrokRetries intentos"
    }
    
    return @{
        Process = $ngrokProcess
        URL = $publicUrl
    }
}

# Funcion para mostrar resultado final
function Show-Result {
    param($Port, $PublicUrl, $Modo)
    
    Write-Step 6 6 "Configuracion completada"
    
    Write-Host ""
    Write-Header "SISTEMA LISTO!"
    
    if ($PublicUrl) {
        Write-URL "URL PUBLICA PARA MAKE.COM:" $PublicUrl
        Write-Host ""
        Write-Host "ENDPOINTS DISPONIBLES:" -ForegroundColor $Colors.Info
        Write-Host "    • Health Check:  $PublicUrl/health"
        Write-Host "    • Validar Orden: $PublicUrl/validar-orden (POST)"
        Write-Host "    • Debug:         $PublicUrl/debug-catalogo"
    } else {
        Write-Host "SERVIDOR LOCAL:" -ForegroundColor $Colors.Info
        Write-Host "    • URL: http://localhost:$Port" -ForegroundColor $Colors.URL
        Write-Host "    • Health: http://localhost:$Port/health"
        Write-Host "    • Validar: http://localhost:$Port/validar-orden (POST)"
        Write-Host "    • Debug: http://localhost:$Port/debug-catalogo"
    }
    
    Write-Host ""
    Write-Host "CONFIGURACION:" -ForegroundColor $Colors.Info
    Write-Host "    • Modo: $Modo"
    Write-Host "    • Puerto: $Port"
    Write-Host "    • Ngrok: $(if($NoNgrok){'Deshabilitado'}else{'Habilitado'})"
    Write-Host ""
    
    Write-Host "IMPORTANTE:" -ForegroundColor $Colors.Error
    Write-Host "    • NO cierres esta ventana" -ForegroundColor $Colors.Error
    if ($PublicUrl) {
        Write-Host "    • La URL cambia cada reinicio" -ForegroundColor $Colors.Error
    }
    Write-Host "    • Servicios corriendo en segundo plano" -ForegroundColor $Colors.Error
    Write-Host ""
    
    if ($Modo -ne "batch") {
        Write-Host "Presiona cualquier tecla para mantener los servicios corriendo..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
}

# Funcion para mostrar ayuda
function Show-Help {
    Write-Header "AYUDA - VALIDADOR TAMAPRINT"
    Write-Host "USO:" -ForegroundColor $Colors.Info
    Write-Host "    .\iniciar.ps1 [MODO] [OPCIONES]" -ForegroundColor $Colors.URL
    Write-Host ""
    Write-Host "MODOS DISPONIBLES:" -ForegroundColor $Colors.Info
    Write-Host "    auto    - Inicio automatico completo (por defecto)" -ForegroundColor $Colors.URL
    Write-Host "    simple  - Inicio simple sin verificaciones extras" -ForegroundColor $Colors.URL
    Write-Host "    manual  - Inicio paso a paso con mas control" -ForegroundColor $Colors.URL
    Write-Host "    batch   - Inicio en primer plano (como iniciar.bat)" -ForegroundColor $Colors.URL
    Write-Host ""
    Write-Host "OPCIONES:" -ForegroundColor $Colors.Info
    Write-Host "    -Puerto <numero>  - Especificar puerto manualmente" -ForegroundColor $Colors.URL
    Write-Host "    -NoNgrok         - No iniciar ngrok (solo servidor local)" -ForegroundColor $Colors.URL
    Write-Host "    -VerificarSolo   - Solo verificar sistema sin iniciar" -ForegroundColor $Colors.URL
    Write-Host ""
    Write-Host "EJEMPLOS:" -ForegroundColor $Colors.Info
    Write-Host "    .\iniciar.ps1                    # Inicio automatico" -ForegroundColor $Colors.URL
    Write-Host "    .\iniciar.ps1 simple             # Inicio simple" -ForegroundColor $Colors.URL
    Write-Host "    .\iniciar.ps1 -Puerto 8080       # Puerto especifico" -ForegroundColor $Colors.URL
    Write-Host "    .\iniciar.ps1 -NoNgrok           # Solo servidor local" -ForegroundColor $Colors.URL
    Write-Host "    .\iniciar.ps1 -VerificarSolo     # Solo verificar" -ForegroundColor $Colors.URL
    Write-Host ""
}

# Funcion principal
function Main {
    # Mostrar ayuda si se solicita
    if ($args -contains "-h" -or $args -contains "--help" -or $args -contains "-?") {
        Show-Help
        return
    }
    
    # Verificar solo si se solicita
    if ($VerificarSolo) {
        Write-Header "VERIFICACION DEL SISTEMA"
        Test-CriticalFiles
        Install-Dependencies
        Write-Host ""
        Write-Success "SISTEMA VERIFICADO - Todo listo para iniciar"
        return
    }
    
    # Mostrar informacion del modo
    Write-Header "VALIDADOR TAMAPRINT - INICIADOR UNIFICADO"
    Write-Host "Modo seleccionado: $Modo" -ForegroundColor $Colors.Info
    if ($Puerto -gt 0) {
        Write-Host "Puerto especificado: $Puerto" -ForegroundColor $Colors.Info
    }
    if ($NoNgrok) {
        Write-Host "Ngrok: Deshabilitado" -ForegroundColor $Colors.Warning
    }
    Write-Host ""
    
    try {
        # Ejecutar pasos segun el modo
        if ($Modo -eq "simple") {
            # Modo simple: menos verificaciones
            Write-Step 1 4 "Verificando archivos criticos..."
            Test-CriticalFiles
            
            Write-Step 2 4 "Instalando dependencias..."
            Install-Dependencies
            
            Write-Step 3 4 "Limpiando procesos..."
            Clean-Processes
            
            Write-Step 4 4 "Iniciando servidor..."
            $port = Find-AvailablePort
            $fastApiProcess = Start-FastAPI -Port $port
            
            if (-not $NoNgrok) {
                $ngrokResult = Start-Ngrok -Port $port
                Show-Result -Port $port -PublicUrl $ngrokResult.URL -Modo $Modo
            } else {
                Show-Result -Port $port -PublicUrl $null -Modo $Modo
            }
            
        } elseif ($Modo -eq "manual") {
            # Modo manual: paso a paso
            Write-Host "Modo manual seleccionado. Ejecutando paso a paso..." -ForegroundColor $Colors.Info
            Write-Host ""
            
            Test-CriticalFiles
            Install-Dependencies
            Clean-Processes
            
            $port = Find-AvailablePort
            Write-Host "Puerto seleccionado: $port" -ForegroundColor $Colors.Success
            Write-Host ""
            
            Write-Host "¿Iniciar FastAPI? (S/N): " -ForegroundColor $Colors.Info -NoNewline
            $response = Read-Host
            if ($response -eq "S" -or $response -eq "s") {
                $fastApiProcess = Start-FastAPI -Port $port
            }
            
            if (-not $NoNgrok) {
                Write-Host "¿Iniciar ngrok? (S/N): " -ForegroundColor $Colors.Info -NoNewline
                $response = Read-Host
                if ($response -eq "S" -or $response -eq "s") {
                    $ngrokResult = Start-Ngrok -Port $port
                    Show-Result -Port $port -PublicUrl $ngrokResult.URL -Modo $Modo
                } else {
                    Show-Result -Port $port -PublicUrl $null -Modo $Modo
                }
            } else {
                Show-Result -Port $port -PublicUrl $null -Modo $Modo
            }
            
        } else {
            # Modo automatico (por defecto)
            Test-CriticalFiles
            Install-Dependencies
            Clean-Processes
            
            $port = Find-AvailablePort
            $fastApiProcess = Start-FastAPI -Port $port
            
            if (-not $NoNgrok) {
                $ngrokResult = Start-Ngrok -Port $port
                Show-Result -Port $port -PublicUrl $ngrokResult.URL -Modo $Modo
            } else {
                Show-Result -Port $port -PublicUrl $null -Modo $Modo
            }
        }
        
    } catch {
        Write-Host ""
        Write-Error "ERROR: $_"
        Write-Host ""
        Write-Host "Soluciones posibles:" -ForegroundColor $Colors.Warning
        Write-Host "    • Verifica que Python este instalado" -ForegroundColor $Colors.Info
        Write-Host "    • Ejecuta: pip install -r requirements.txt" -ForegroundColor $Colors.Info
        Write-Host "    • Verifica que config\ngrok.exe este en la carpeta" -ForegroundColor $Colors.Info
        Write-Host "    • Cierra otras instancias del validador" -ForegroundColor $Colors.Info
        Write-Host "    • Usa: .\iniciar.ps1 -VerificarSolo" -ForegroundColor $Colors.Info
        Write-Host ""
        Read-Host "Presiona Enter para salir"
    } finally {
        # Limpiar al salir (solo en modo automatico)
        if ($Modo -eq "auto" -or $Modo -eq "simple") {
            Write-Host "Limpiando procesos..." -ForegroundColor Gray
            if ($fastApiProcess -and -not $fastApiProcess.HasExited) {
                $fastApiProcess.Kill()
            }
            if ($ngrokResult -and $ngrokResult.Process -and -not $ngrokResult.Process.HasExited) {
                $ngrokResult.Process.Kill()
            }
        }
    }
}

# Ejecutar funcion principal
Main
