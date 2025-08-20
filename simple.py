from fastapi import FastAPI
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from typing import List
import os

app = FastAPI()

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
def read_root():
    return {"message": "API funcionando!", "status": "OK"}

@app.get("/health")
def health():
    return {"status": "OK", "port": os.getenv("PORT", "8080")}

@app.post("/validar-orden")
async def validar_orden_endpoint(orden: OrdenModel):
    # Respuesta de prueba mientras configuramos Google Sheets
    resultado = {
        "orden_compra": orden.orden_compra,
        "cliente": orden.comprador.nit,
        "TODOS_LOS_ARTICULOS_EXISTEN": True,
        "PUEDE_PROCESAR_EN_SAP": True,
        "status": "DEMO - API funcionando en Cloud Run",
        "message": "✅ Endpoint /validar-orden funcionando correctamente",
        "total_articulos": len(orden.items),
        "articulos_procesados": len(orden.items)
    }
    
    return JSONResponse(content=resultado, status_code=200)

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)