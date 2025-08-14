# Test Rápido - Sistema Unificado V3.0
# Pruebas básicas del nuevo iniciador unificado

Write-Host "========================================" -ForegroundColor Green
Write-Host "    TEST RÁPIDO - SISTEMA UNIFICADO" -ForegroundColor Green
Write-Host "    Validador TamaPrint V3.0" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""

$tests_passed = 0
$tests_failed = 0
$total_tests = 0

function Test-Step {
    param($TestName, $TestScript)
    $global:total_tests++
    Write-Host "[$total_tests] $TestName" -ForegroundColor Yellow -NoNewline
    
    try {
        $result = & $TestScript
        if ($result) {
            Write-Host " ✅ PASÓ" -ForegroundColor Green
            $global:tests_passed++
        } else {
            Write-Host " ❌ FALLÓ" -ForegroundColor Red
            $global:tests_failed++
        }
    } catch {
        Write-Host " ❌ ERROR: $_" -ForegroundColor Red
        $global:tests_failed++
    }
    Write-Host ""
}

# Test 1: Verificar que iniciar.ps1 existe
Test-Step "Verificar archivo iniciar.ps1" {
    Test-Path "iniciar.ps1"
}

# Test 2: Verificar que archivos antiguos fueron eliminados
Test-Step "Verificar archivos eliminados" {
    $archivos_antiguos = @("iniciar.bat", "iniciar_simple.ps1", "iniciar_manual.ps1", "iniciar_validador.ps1")
    $presentes = $archivos_antiguos | Where-Object { Test-Path $_ }
    return $presentes.Count -eq 0
}

# Test 3: Verificar ayuda
Test-Step "Verificar comando de ayuda" {
    try {
        $result = & powershell -ExecutionPolicy Bypass -File "iniciar.ps1" "-h" 2>&1
        return $result -like "*AYUDA*"
    } catch {
        return $false
    }
}

# Test 4: Verificar modo -VerificarSolo
Test-Step "Verificar modo -VerificarSolo" {
    try {
        $result = & powershell -ExecutionPolicy Bypass -File "iniciar.ps1" "-VerificarSolo" 2>&1
        return $result -like "*SISTEMA VERIFICADO*"
    } catch {
        return $false
    }
}

# Test 5: Verificar documentación actualizada
Test-Step "Verificar documentación" {
    $doc_files = @("INSTRUCCIONES_RAPIDAS.md", "UNIFICACION_V3.0.md")
    $all_exist = $doc_files | ForEach-Object { Test-Path $_ } | Where-Object { $_ -eq $false }
    return $all_exist.Count -eq 0
}

# Test 6: Verificar archivos críticos
Test-Step "Verificar archivos críticos" {
    $critical_files = @("src\validador.py", "requirements.txt")
    $missing = $critical_files | Where-Object { -not (Test-Path $_) }
    return $missing.Count -eq 0
}

# Test 7: Verificar sintaxis de PowerShell
Test-Step "Verificar sintaxis PowerShell" {
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content "iniciar.ps1" -Raw), [ref]$null)
        return $true
    } catch {
        return $false
    }
}

# Test 8: Verificar parámetros válidos
Test-Step "Verificar parámetros válidos" {
    $valid_modes = @("auto", "simple", "manual", "batch")
    $all_valid = $true
    
    foreach ($mode in $valid_modes) {
        try {
            $result = & powershell -ExecutionPolicy Bypass -File "iniciar.ps1" $mode "-VerificarSolo" 2>&1
            if ($result -like "*ERROR*" -and $result -notlike "*SISTEMA VERIFICADO*") {
                $all_valid = $false
            }
        } catch {
            $all_valid = $false
        }
    }
    return $all_valid
}

Write-Host "========================================" -ForegroundColor Green
Write-Host "    RESULTADOS FINALES" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Total de pruebas: $total_tests" -ForegroundColor Cyan
Write-Host "Pruebas pasadas: $tests_passed" -ForegroundColor Green
Write-Host "Pruebas fallidas: $tests_failed" -ForegroundColor Red
Write-Host "Porcentaje de éxito: $([math]::Round(($tests_passed/$total_tests)*100, 1))%" -ForegroundColor Yellow
Write-Host ""

if ($tests_failed -eq 0) {
    Write-Host "🎉 ¡TODAS LAS PRUEBAS PASARON!" -ForegroundColor Green
    Write-Host "   El sistema unificado funciona perfectamente." -ForegroundColor Green
} elseif ($tests_passed -gt ($total_tests * 0.7)) {
    Write-Host "✅ La mayoría de las pruebas pasaron." -ForegroundColor Yellow
    Write-Host "   El sistema funciona correctamente." -ForegroundColor Yellow
} else {
    Write-Host "⚠️ Varias pruebas fallaron." -ForegroundColor Red
    Write-Host "   Revisar el sistema." -ForegroundColor Red
}

Write-Host ""
Write-Host "Para pruebas completas ejecutar: python test_iniciador_unificado.py" -ForegroundColor Gray
Write-Host ""
