from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, validator
import pandas as pd
import json
from datetime import datetime
import os
from dotenv import load_dotenv
import gspread
from google.oauth2.service_account import Credentials
from typing import List, Dict, Any

# Cargar variables de entorno
load_dotenv()

# Variables de entorno
GOOGLE_DRIVE_FILE_ID = os.getenv('GOOGLE_DRIVE_FILE_ID')
GOOGLE_SHEET_RANGE = os.getenv('GOOGLE_SHEET_RANGE')
GOOGLE_APPLICATION_CREDENTIALS = os.getenv('GOOGLE_APPLICATION_CREDENTIALS')

app = FastAPI(title="Validador Tamaprint", version="1.0.0")

class ItemModel(BaseModel):
    codigo: str
    descripcion: str
    cantidad: int
    precio_unitario: float
    precio_total: float
    fecha_entrega: str
    
    @validator('cantidad')
    def cantidad_must_be_positive(cls, v):
        if v <= 0:
            raise ValueError('La cantidad debe ser mayor a 0')
        return v
    
    @validator('precio_unitario', 'precio_total')
    def precio_must_be_positive(cls, v):
        if v < 0:
            raise ValueError('El precio debe ser mayor o igual a 0')
        return v

class CompradorModel(BaseModel):
    nit: str
    
    @validator('nit')
    def nit_must_not_be_empty(cls, v):
        if not v.strip():
            raise ValueError('El NIT no puede estar vacío')
        return v.strip()

class OrdenModel(BaseModel):
    comprador: CompradorModel
    orden_compra: str
    items: List[ItemModel]
    
    @validator('items')
    def items_must_not_be_empty(cls, v):
        if not v:
            raise ValueError('La orden debe tener al menos un artículo')
        return v

class ValidadorOrdenesCompra:
    def __init__(self):
        try:
            # Validar variables de entorno
            if not GOOGLE_DRIVE_FILE_ID:
                raise ValueError("GOOGLE_DRIVE_FILE_ID no está configurado en .env")
            if not GOOGLE_SHEET_RANGE:
                raise ValueError("GOOGLE_SHEET_RANGE no está configurado en .env")
            if not GOOGLE_APPLICATION_CREDENTIALS:
                raise ValueError("GOOGLE_APPLICATION_CREDENTIALS no está configurado en .env")
            
            # Verificar archivo de credenciales
            if not os.path.exists(GOOGLE_APPLICATION_CREDENTIALS):
                raise FileNotFoundError(f"Archivo de credenciales no encontrado: {GOOGLE_APPLICATION_CREDENTIALS}")
            
            # Configurar Google Sheets
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
            
            # Obtener datos de la hoja
            if '!' in GOOGLE_SHEET_RANGE:
                sheet_name, sheet_range = GOOGLE_SHEET_RANGE.split('!')
            else:
                sheet_name = 'Hoja1'
                sheet_range = GOOGLE_SHEET_RANGE
                
            worksheet = sh.worksheet(sheet_name)
            data = worksheet.get(sheet_range)
            
            if not data or len(data) < 2:
                raise ValueError("El catálogo está vacío o no tiene datos válidos")
                
            headers = data[0]
            rows = data[1:]
            self.catalogo = pd.DataFrame(rows, columns=headers)
            
            # Verificar columnas requeridas
            required_columns = ['Código SN', 'Nº catálogo SN']
            missing_columns = [col for col in required_columns if col not in self.catalogo.columns]
            if missing_columns:
                raise ValueError(f"Columnas faltantes en el catálogo: {missing_columns}")
            
            # Crear índice de búsqueda
            self.catalogo['clave_busqueda'] = (
                self.catalogo['Código SN'].astype(str).str.strip().str.upper() +
                "|" +
                self.catalogo['Nº catálogo SN'].astype(str).str.strip().str.lower()
            )
            self.indice_catalogo = self.catalogo.set_index('clave_busqueda')
            
            print(f"✅ Catálogo cargado: {len(self.catalogo)} registros")
            
        except Exception as e:
            print(f"❌ Error inicializando validador: {e}")
            raise

    def validar_orden(self, orden_json: Dict[str, Any]):
        try:
            cliente = str(orden_json['comprador']['nit']).strip().upper()
            orden_numero = orden_json['orden_compra']
            items = orden_json['items']
            
            if not items:
                raise ValueError("La orden debe tener al menos un artículo")
            
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
            
            return {
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
                    f"VALIDACION EXITOSA: Todos los {len(items)} articulos existen en el catalogo. La orden puede procesarse en SAP."
                    if todos_existen else 
                    f"VALIDACION FALLIDA: {len(articulos_no_encontrados)} de {len(items)} articulos NO existen en el catalogo. Revisar articulos faltantes antes de procesar en SAP."
                )
            }
        except Exception as e:
            raise ValueError(f"Error validando orden: {str(e)}")

# Inicializar validador
print("🚀 Iniciando Validador Tamaprint...")
try:
    validador = ValidadorOrdenesCompra()
except Exception as e:
    print(f"❌ Error crítico: {e}")
    print("💡 Verifica la configuración en .env y el archivo credentials.json")
    exit(1)

@app.post("/validar-orden")
async def validar_orden_endpoint(orden: OrdenModel):
    try:
        resultado = validador.validar_orden(orden.dict())
        return JSONResponse(content=resultado, status_code=200)
    except ValueError as e:
        return JSONResponse(content={
            "TODOS_LOS_ARTICULOS_EXISTEN": False,
            "PUEDE_PROCESAR_EN_SAP": False,
            "error": str(e),
            "mensaje": f"ERROR DE VALIDACIÓN: {str(e)}"
        }, status_code=400)
    except Exception as e:
        return JSONResponse(content={
            "TODOS_LOS_ARTICULOS_EXISTEN": False,
            "PUEDE_PROCESAR_EN_SAP": False,
            "error": str(e),
            "mensaje": f"ERROR INTERNO: {str(e)}"
        }, status_code=500)

@app.get("/health")
async def health_check():
    try:
        return {
            "status": "OK",
            "catalogo_items": len(validador.catalogo),
            "timestamp": datetime.now().isoformat()
        }
    except Exception as e:
        return JSONResponse(content={
            "status": "ERROR",
            "error": str(e)
        }, status_code=500)

@app.get("/debug-catalogo")
async def debug_catalogo():
    try:
        return {
            "primeras_5_filas": validador.catalogo.head(5).to_dict(orient='records'),
            "claves_busqueda": list(validador.indice_catalogo.index[:5])
        }
    except Exception as e:
        return JSONResponse(content={
            "error": str(e)
        }, status_code=500)