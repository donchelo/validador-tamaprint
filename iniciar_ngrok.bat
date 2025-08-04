@echo off
echo ========================================
echo    Iniciando Ngrok para TamaPrint
echo ========================================
echo.

echo [1/2] Verificando ngrok...
if not exist "ngrok.exe" (
    echo ERROR: ngrok.exe no encontrado en el directorio
    echo Asegurate de que ngrok.exe esté en la carpeta del proyecto
    pause
    exit /b 1
)

echo [2/2] Iniciando túnel ngrok...
echo.
echo Túnel iniciado en: https://XXXXX.ngrok-free.app
echo Panel de control: http://localhost:4040
echo.
echo Para detener: Ctrl+C
echo.
ngrok.exe http 3000

pause 