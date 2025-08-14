@echo off
chcp 65001 >nul
set PYTHONIOENCODING=utf-8
echo Iniciando Validador Tamaprint...
python -m uvicorn validador:app --host 0.0.0.0 --port 8000
pause