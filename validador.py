from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel
import pandas as pd
import json
from datetime import datetime
import os
from dotenv import load_dotenv
import gspread
from google.oauth2.service_account import Credentials
from typing import List, Dict, Any

# Cargar variables de entorno del archivo .env
load_dotenv()

# Variables de entorno para Google Sheets
GOOGLE_DRIVE_FILE_ID = os.getenv('GOOGLE_DRIVE_FILE_ID')
GOOGLE_SHEET_RANGE = os.getenv('GOOGLE_SHEET_RANGE')
GOOGLE_APPLICATION_CREDENTIALS = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')

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

class ValidadorOrdenesCompra:
    def __init__(self):
        try:
            scopes = [
                'https://www.googleapis.com/auth/spreadsheets',
                'https://www.googleapis.com/auth/drive'
            ]
            credentials = Credentials.from_service_account_file(
                GOOGLE_APPLICATION_CREDENTIALS,
                scopes=scopes
            )
            gc = gspread.authorize(credentials)
            sh = gc.open_by_key(GOOGLE_DRIVE_FILE_ID)
            # Separar nombre de hoja y rango
            if '!' in GOOGLE_SHEET_RANGE:
                sheet_name, sheet_range = GOOGLE_SHEET_RANGE.split('!')
            else:
                sheet_name = 'Hoja1'
                sheet_range = GOOGLE_SHEET_RANGE
            worksheet = sh.worksheet(sheet_name)
            data = worksheet.get(sheet_range)
            headers = data[0]
            rows = data[1:]
            self.catalogo = pd.DataFrame(rows, columns=headers)
            print(f"✅ Catálogo cargado: {len(self.catalogo)} registros")
            print("Columnas encontradas:", list(self.catalogo.columns))
            # Normalizar claves para comparación robusta
            self.catalogo['clave_busqueda'] = (
                self.catalogo['Código SN'].astype(str).str.strip().str.lower() +
                "|" +
                self.catalogo['Nº catálogo SN'].astype(str).str.strip().str.lower()
            )
            self.indice_catalogo = self.catalogo.set_index('clave_busqueda')
            print("✅ Índice de búsqueda creado")
        except Exception as e:
            print(f"❌ Error cargando Google Sheets: {e}")
            raise
    def validar_orden(self, orden_json: Dict[str, Any]):
        cliente = str(orden_json['comprador']['nit']).strip().lower()
        orden_numero = orden_json['orden_compra']
        items = orden_json['items']
        articulos_encontrados = []
        articulos_no_encontrados = []
        for item in items:
            clave_busqueda = f"{cliente}|{str(item['codigo']).strip().lower()}"
            try:
                registro_catalogo = self.indice_catalogo.loc[clave_busqueda]
                articulo_valido = {
                    "codigo": item['codigo'],
                    "descripcion": item['descripcion'],
                    "cantidad": item['cantidad'],
                    "precio_unitario": item['precio_unitario'],
                    "precio_total": item['precio_total'],
                    "fecha_entrega": item['fecha_entrega']
                }
                articulos_encontrados.append(articulo_valido)
            except KeyError:
                articulo_faltante = {
                    "codigo": item['codigo'],
                    "descripcion": item['descripcion'],
                    "cantidad": item['cantidad'],
                    "motivo": f"La combinación Cliente [{cliente}] + Artículo [{item['codigo']}] NO existe en el catálogo"
                }
                articulos_no_encontrados.append(articulo_faltante)
        todos_existen = len(articulos_no_encontrados) == 0
        resultado = {
            "orden_compra": orden_numero,
            "cliente": cliente,
            "fecha_validacion": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            "TODOS_LOS_ARTICULOS_EXISTEN": todos_existen,
            "PUEDE_PROCESAR_EN_SAP": todos_existen,
            "resumen": {
                "total_articulos": len(items),
                "articulos_encontrados": len(articulos_encontrados),
                "articulos_faltantes": len(articulos_no_encontrados),
                "porcentaje_exito": round(len(articulos_encontrados) / len(items) * 100, 2)
            },
            "articulos_listos_para_sap": articulos_encontrados if todos_existen else [],
            "articulos_que_NO_existen": articulos_no_encontrados,
            "mensaje": (
                f"✅ VALIDACIÓN EXITOSA: Todos los {len(items)} artículos existen en el catálogo. La orden puede procesarse en SAP."
                if todos_existen else 
                f"❌ VALIDACIÓN FALLIDA: {len(articulos_no_encontrados)} de {len(items)} artículos NO existen en el catálogo. Revisar artículos faltantes antes de procesar en SAP."
            )
        }
        return resultado

print("🚀 Iniciando validador...")
validador = ValidadorOrdenesCompra()

@app.post("/validar-orden")
async def validar_orden_endpoint(orden: OrdenModel):
    try:
        print("📥 Recibida petición de validación")
        orden_dict = orden.dict()
        print(f"📋 Orden: {orden_dict.get('orden_compra', 'N/A')}")
        print(f"👤 Cliente: {orden_dict.get('comprador', {}).get('nit', 'N/A')}")
        print(f"📦 Items: {len(orden_dict.get('items', []))}")
        resultado = validador.validar_orden(orden_dict)
        print(f"✅ Validación completada: {resultado['resumen']['articulos_encontrados']}/{resultado['resumen']['total_articulos']} artículos válidos")
        return JSONResponse(content=resultado, status_code=200)
    except Exception as e:
        print(f"❌ Error en validación: {e}")
        return JSONResponse(content={
            "TODOS_LOS_ARTICULOS_EXISTEN": False,
            "PUEDE_PROCESAR_EN_SAP": False,
            "error": str(e),
            "mensaje": f"❌ ERROR EN VALIDACIÓN: {str(e)}"
        }, status_code=500)

@app.get("/health")
async def health_check():
    return {
        "status": "OK",
        "catalogo_items": len(validador.catalogo),
        "timestamp": datetime.now().isoformat()
    }

# Para desarrollo local con: uvicorn validador:app --reload