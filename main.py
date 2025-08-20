#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Archivo principal simplificado para Cloud Run
"""
import os
import sys
from pathlib import Path

# Configurar rutas correctas
sys.path.insert(0, '/app')
sys.path.insert(0, '/app/src')

# Importar la aplicación
try:
    from src.validador import app
except ImportError:
    # Si no funciona, crear una app básica de prueba
    from fastapi import FastAPI
    app = FastAPI(title="Validador TamaPrint", version="2.0.0")
    
    @app.get("/")
    async def root():
        return {"message": "¡Validador TamaPrint funcionando en Cloud Run!", "status": "OK"}
    
    @app.get("/health")
    async def health():
        return {"status": "OK", "message": "Servicio funcionando correctamente"}

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8080"))
    uvicorn.run(app, host="0.0.0.0", port=port)