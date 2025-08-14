# Script de inicio MANUAL para Validador Tamaprint
# Versión de respaldo - Inicio paso a paso

Write-Host "========================================" -ForegroundColor Green
Write-Host "    VALIDADOR TAMAPRINT - INICIO MANUAL" -ForegroundColor Green  
Write-Host "    Versión de respaldo" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Función para limpiar procesos
function Clean-All-Processes {
    Write-Host "Limpiando todos los procesos..." -ForegroundColor Red
    Get-Process | Where-Object {$_.ProcessName -eq "python" -or $_.ProcessName -eq "ngrok"} | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 5
    Write-Host "Procesos limpiados" -ForegroundColor Green
}

# Función para activar entorno virtual
function Activate-VirtualEnv {
    if (Test-Path ".venv") {
        Write-Host "Activando entorno virtual..." -ForegroundColor Cyan
        & ".\.venv\Scripts\Activate.ps1"
        Write-Host "Entorno virtual activado" -ForegroundColor Green
    }
}

# Función para verificar puerto
function Test-Port {
    param($Port)
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $tcpClient.Connect("localhost", $Port)
        $tcpClient.Close()
        return $false  # Puerto en uso
    } catch {
        return $true   # Puerto disponible
    }
}

# Función para encontrar puerto libre
function Find-Free-Port {
    for ($port = 8000; $port -le 8100; $port++) {
        if (Test-Port $port) {
            return $port
        }
    }
    return 8000  # Por defecto
}

try {
    # Paso 1: Limpiar procesos
    Write-Host "Paso 1: Limpiando procesos anteriores..." -ForegroundColor Yellow
    Clean-All-Processes
    
    # Paso 2: Activar entorno virtual
    Write-Host "Paso 2: Activando entorno virtual..." -ForegroundColor Yellow
    Activate-VirtualEnv
    
    # Paso 3: Encontrar puerto
    Write-Host "Paso 3: Encontrando puerto disponible..." -ForegroundColor Yellow
    $port = Find-Free-Port
    Write-Host "Usando puerto: $port" -ForegroundColor Green
    
    # Paso 4: Iniciar FastAPI
    Write-Host "Paso 4: Iniciando FastAPI..." -ForegroundColor Yellow
    Write-Host "Ejecutando: python -m uvicorn validador:app --host 0.0.0.0 --port $port" -ForegroundColor Cyan
    
    $fastApiJob = Start-Job -ScriptBlock {
        param($port)
        Set-Location $using:PWD
        python -m uvicorn validador:app --host 0.0.0.0 --port $port
    } -ArgumentList $port
    
    Write-Host "Esperando 20 segundos para que FastAPI se inicie..." -ForegroundColor Cyan
    Start-Sleep -Seconds 20
    
    # Paso 5: Verificar FastAPI
    Write-Host "Paso 5: Verificando FastAPI..." -ForegroundColor Yellow
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:$port/health" -Method GET -TimeoutSec 10
        Write-Host "✅ FastAPI funcionando - Catálogo: $($response.catalogo_items) registros" -ForegroundColor Green
    } catch {
        Write-Host "❌ FastAPI no responde. Revisa los logs." -ForegroundColor Red
        throw "FastAPI no está funcionando"
    }
    
    # Paso 6: Iniciar ngrok
    Write-Host "Paso 6: Iniciando ngrok..." -ForegroundColor Yellow
    Write-Host "Ejecutando: .\ngrok.exe http $port" -ForegroundColor Cyan
    
    $ngrokJob = Start-Job -ScriptBlock {
        param($port)
        Set-Location $using:PWD
        .\ngrok.exe http $port
    } -ArgumentList $port
    
    Write-Host "Esperando 15 segundos para que ngrok se conecte..." -ForegroundColor Cyan
    Start-Sleep -Seconds 15
    
    # Paso 7: Obtener URL
    Write-Host "Paso 7: Obteniendo URL pública..." -ForegroundColor Yellow
    $maxRetries = 10
    $publicUrl = $null
    
    for ($i = 1; $i -le $maxRetries; $i++) {
        try {
            $response = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -Method GET -TimeoutSec 10
            if ($response.tunnels -and $response.tunnels.Count -gt 0) {
                $publicUrl = $response.tunnels[0].public_url
                Write-Host "✅ URL obtenida: $publicUrl" -ForegroundColor Green
                break
            }
        } catch {
            Write-Host "Intento $i/$maxRetries - Esperando 5 segundos..." -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }
    
    if (-not $publicUrl) {
        throw "No se pudo obtener la URL de ngrok"
    }
    
    # Resultado final
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "                LISTO!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "URL PARA MAKE.COM:" -ForegroundColor Cyan
    Write-Host "$publicUrl/validar-orden" -ForegroundColor White -BackgroundColor DarkBlue
    Write-Host ""
    Write-Host "Puerto local: $port" -ForegroundColor Gray
    Write-Host "Jobs activos: FastAPI y ngrok" -ForegroundColor Gray
    Write-Host ""
    Write-Host "Para detener: Get-Job | Stop-Job" -ForegroundColor Red
    Write-Host ""
    
    # Mantener activo
    Write-Host "Presiona cualquier tecla para mantener activo..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    
} catch {
    Write-Host ""
    Write-Host "ERROR: $_" -ForegroundColor Red
    Write-Host ""
    Write-Host "Comandos manuales:" -ForegroundColor Yellow
    Write-Host "1. python -m uvicorn validador:app --host 0.0.0.0 --port 8000" -ForegroundColor Cyan
    Write-Host "2. .\ngrok.exe http 8000" -ForegroundColor Cyan
    Write-Host ""
    Read-Host "Presiona Enter para salir"
} finally {
    # Limpiar jobs
    Get-Job | Stop-Job -ErrorAction SilentlyContinue
    Get-Job | Remove-Job -ErrorAction SilentlyContinue
}
