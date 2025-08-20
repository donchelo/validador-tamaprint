#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Validador TamaPrint - Versión simplificada para Cloud Run
"""
import os
from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import List
import logging

# Configurar logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI(title="Validador TamaPrint", version="2.0.0")

class ItemModel(BaseModel):
    codigo: str
    descripcion: str
    cantidad: int
    precio_unitario: float
    precio_total: float
    fecha_entrega: str

class CompradorModel(BaseModel):
    nit: str

class OrdenModel(BaseModel):
    comprador: CompradorModel
    orden_compra: str
    items: List[ItemModel]

@app.get("/")
async def root():
    return {
        "message": "🎉 ¡Validador TamaPrint funcionando en Cloud Run!",
        "status": "OK",
        "version": "2.0.0",
        "url": "Permanente - Ya no más ngrok!",
        "endpoints": ["/health", "/validar-orden"]
    }

@app.get("/health")
async def health_check():
    logger.info("Health check solicitado")
    
    # Verificar variables de entorno
    env_vars = {
        "GOOGLE_DRIVE_FILE_ID": os.getenv('GOOGLE_DRIVE_FILE_ID', 'No configurado'),
        "GOOGLE_SHEET_RANGE": os.getenv('GOOGLE_SHEET_RANGE', 'No configurado'),
        "GOOGLE_APPLICATION_CREDENTIALS": os.getenv('GOOGLE_APPLICATION_CREDENTIALS', 'No configurado'),
        "PORT": os.getenv('PORT', '8080')
    }
    
    return {
        "status": "OK",
        "message": "¡Servicio funcionando correctamente en Cloud Run!",
        "timestamp": "2025-08-20",
        "environment": env_vars,
        "migration_status": "✅ Migración de ngrok a Cloud Run completada"
    }

@app.post("/validar-orden")
async def validar_orden_endpoint(orden: OrdenModel):
    logger.info(f"Nueva solicitud de validación recibida para orden: {orden.orden_compra}")
    
    try:
        # Por ahora devolvemos una respuesta de prueba
        # hasta que se configure completamente Google Sheets
        resultado = {
            "orden_compra": orden.orden_compra,
            "cliente": orden.comprador.nit,
            "TODOS_LOS_ARTICULOS_EXISTEN": True,
            "PUEDE_PROCESAR_EN_SAP": True,
            "status": "DEMO",
            "message": "🎉 API funcionando en Cloud Run - Configurar Google Sheets para validación completa",
            "total_articulos": len(orden.items),
            "articulos_procesados": len(orden.items)
        }
        
        return JSONResponse(content=resultado, status_code=200)
        
    except Exception as e:
        logger.error(f"Error procesando orden: {str(e)}")
        return JSONResponse(content={
            "error": str(e),
            "message": "Error en validación"
        }, status_code=500)

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", "8080"))
    logger.info(f"🚀 Iniciando Validador TamaPrint en puerto {port}")
    uvicorn.run(app, host="0.0.0.0", port=port)