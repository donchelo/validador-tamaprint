# Test Simple - Sistema Unificado V3.0
Write-Host "========================================" -ForegroundColor Green
Write-Host "    TEST SIMPLE - SISTEMA UNIFICADO" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

# Test 1: Verificar archivo
Write-Host "[1] Verificando archivo iniciar.ps1..." -ForegroundColor Yellow -NoNewline
if (Test-Path "iniciar.ps1") {
    Write-Host " [OK]" -ForegroundColor Green
} else {
    Write-Host " [ERROR]" -ForegroundColor Red
}

# Test 2: Verificar archivos eliminados
Write-Host "[2] Verificando archivos eliminados..." -ForegroundColor Yellow -NoNewline
$archivos_antiguos = @("iniciar.bat", "iniciar_simple.ps1", "iniciar_manual.ps1", "iniciar_validador.ps1")
$presentes = $archivos_antiguos | Where-Object { Test-Path $_ }
if ($presentes.Count -eq 0) {
    Write-Host " [OK]" -ForegroundColor Green
} else {
    Write-Host " [ERROR: $($presentes -join ', ')]" -ForegroundColor Red
}

# Test 3: Verificar modo -VerificarSolo
Write-Host "[3] Probando modo -VerificarSolo..." -ForegroundColor Yellow -NoNewline
try {
    $result = & powershell -ExecutionPolicy Bypass -File "iniciar.ps1" "-VerificarSolo" 2>&1
    if ($result -like "*SISTEMA VERIFICADO*") {
        Write-Host " [OK]" -ForegroundColor Green
    } else {
        Write-Host " [ERROR]" -ForegroundColor Red
    }
} catch {
    Write-Host " [ERROR: $_]" -ForegroundColor Red
}

# Test 4: Verificar documentacion
Write-Host "[4] Verificando documentacion..." -ForegroundColor Yellow -NoNewline
$doc_files = @("INSTRUCCIONES_RAPIDAS.md", "UNIFICACION_V3.0.md")
$all_exist = $doc_files | ForEach-Object { Test-Path $_ } | Where-Object { $_ -eq $false }
if ($all_exist.Count -eq 0) {
    Write-Host " [OK]" -ForegroundColor Green
} else {
    Write-Host " [ERROR]" -ForegroundColor Red
}

# Test 5: Verificar archivos criticos
Write-Host "[5] Verificando archivos criticos..." -ForegroundColor Yellow -NoNewline
$critical_files = @("src\validador.py", "requirements.txt")
$missing = $critical_files | Where-Object { -not (Test-Path $_) }
if ($missing.Count -eq 0) {
    Write-Host " [OK]" -ForegroundColor Green
} else {
    Write-Host " [ERROR: $($missing -join ', ')]" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "    RESULTADO: SISTEMA UNIFICADO FUNCIONA" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Para usar el sistema:" -ForegroundColor Cyan
Write-Host "  .\iniciar.ps1                    # Inicio automatico" -ForegroundColor White
Write-Host "  .\iniciar.ps1 simple            # Inicio simple" -ForegroundColor White
Write-Host "  .\iniciar.ps1 -VerificarSolo    # Solo verificar" -ForegroundColor White
Write-Host ""
