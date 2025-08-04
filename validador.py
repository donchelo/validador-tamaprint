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
import logging
import sys
from functools import lru_cache
from datetime import datetime, timedelta
import time

# Configuración de logging estructurado
def setup_logging():
    """Configurar logging estructurado con formato personalizado"""
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s | %(levelname)s | %(name)s | %(message)s',
        handlers=[
            logging.StreamHandler(sys.stdout),
            logging.FileHandler('validador.log', encoding='utf-8')
        ]
    )
    return logging.getLogger(__name__)

# Inicializar logger
logger = setup_logging()

class CacheManager:
    """Gestor de cache para mejorar performance"""
    
    def __init__(self, max_size=1000, ttl_seconds=3600):
        self.cache = {}
        self.max_size = max_size
        self.ttl_seconds = ttl_seconds
        self.access_times = {}
        logger.info(f"🔧 Cache inicializado: max_size={max_size}, ttl={ttl_seconds}s")
    
    def get(self, key):
        """Obtener valor del cache"""
        if key in self.cache:
            # Verificar TTL
            if time.time() - self.access_times[key] > self.ttl_seconds:
                logger.debug(f"⏰ Cache expirado para: {key}")
                del self.cache[key]
                del self.access_times[key]
                return None
            
            # Actualizar tiempo de acceso
            self.access_times[key] = time.time()
            logger.debug(f"✅ Cache hit para: {key}")
            return self.cache[key]
        
        logger.debug(f"❌ Cache miss para: {key}")
        return None
    
    def set(self, key, value):
        """Guardar valor en cache"""
        # Limpiar cache si está lleno (LRU)
        if len(self.cache) >= self.max_size:
            self._cleanup_oldest()
        
        self.cache[key] = value
        self.access_times[key] = time.time()
        logger.debug(f"💾 Cache set para: {key}")
    
    def _cleanup_oldest(self):
        """Limpiar entradas más antiguas del cache"""
        if not self.access_times:
            return
        
        oldest_key = min(self.access_times.keys(), key=lambda k: self.access_times[k])
        del self.cache[oldest_key]
        del self.access_times[oldest_key]
        logger.debug(f"🗑️ Cache cleanup: eliminado {oldest_key}")
    
    def clear(self):
        """Limpiar todo el cache"""
        self.cache.clear()
        self.access_times.clear()
        logger.info("🧹 Cache limpiado")
    
    def stats(self):
        """Obtener estadísticas del cache"""
        return {
            "size": len(self.cache),
            "max_size": self.max_size,
            "ttl_seconds": self.ttl_seconds,
            "hit_rate": self._calculate_hit_rate()
        }
    
    def _calculate_hit_rate(self):
        """Calcular tasa de aciertos (simplificado)"""
        # En una implementación real, contaríamos hits/misses
        return len(self.cache) / self.max_size if self.max_size > 0 else 0

# Inicializar cache global
cache_manager = CacheManager()

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
        logger.info("🚀 Iniciando ValidadorOrdenesCompra...")
        try:
            # Validar variables de entorno
            logger.info("📋 Validando variables de entorno...")
            if not GOOGLE_DRIVE_FILE_ID:
                raise ValueError("GOOGLE_DRIVE_FILE_ID no está configurado en .env")
            if not GOOGLE_SHEET_RANGE:
                raise ValueError("GOOGLE_SHEET_RANGE no está configurado en .env")
            if not GOOGLE_APPLICATION_CREDENTIALS:
                raise ValueError("GOOGLE_APPLICATION_CREDENTIALS no está configurado en .env")
            logger.info("✅ Variables de entorno validadas")
            
            # Verificar archivo de credenciales
            logger.info(f"🔐 Verificando credenciales: {GOOGLE_APPLICATION_CREDENTIALS}")
            if not os.path.exists(GOOGLE_APPLICATION_CREDENTIALS):
                raise FileNotFoundError(f"Archivo de credenciales no encontrado: {GOOGLE_APPLICATION_CREDENTIALS}")
            logger.info("✅ Archivo de credenciales encontrado")
            
            # Configurar Google Sheets
            logger.info("🔗 Conectando con Google Sheets...")
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
            logger.info("✅ Conexión con Google Sheets establecida")
            
            # Obtener datos de la hoja
            logger.info(f"📊 Cargando datos del rango: {GOOGLE_SHEET_RANGE}")
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
            logger.info(f"📋 Datos cargados: {len(rows)} filas, {len(headers)} columnas")
            
            # Verificar columnas requeridas
            logger.info("🔍 Verificando columnas requeridas...")
            required_columns = ['Código SN', 'Nº catálogo SN']
            missing_columns = [col for col in required_columns if col not in self.catalogo.columns]
            if missing_columns:
                raise ValueError(f"Columnas faltantes en el catálogo: {missing_columns}")
            logger.info("✅ Columnas requeridas verificadas")
            
            # Crear índice de búsqueda
            logger.info("🔍 Creando índice de búsqueda...")
            self.catalogo['clave_busqueda'] = (
                self.catalogo['Código SN'].astype(str).str.strip().str.upper() +
                "|" +
                self.catalogo['Nº catálogo SN'].astype(str).str.strip().str.lower()
            )
            self.indice_catalogo = self.catalogo.set_index('clave_busqueda')
            logger.info(f"✅ Índice creado con {len(self.indice_catalogo)} claves únicas")
            
            logger.info(f"✅ Catálogo cargado exitosamente: {len(self.catalogo)} registros")
            
        except Exception as e:
            logger.error(f"❌ Error inicializando validador: {e}")
            raise

    def validar_orden(self, orden_json: Dict[str, Any]):
        logger.info("🔍 Iniciando validación de orden...")
        try:
            cliente = str(orden_json['comprador']['nit']).strip().upper()
            orden_numero = orden_json['orden_compra']
            items = orden_json['items']
            
            logger.info(f"📋 Validando orden {orden_numero} para cliente {cliente} con {len(items)} artículos")
            
            if not items:
                logger.warning("⚠️ Orden sin artículos")
                raise ValueError("La orden debe tener al menos un artículo")
            
            articulos_encontrados = []
            articulos_no_encontrados = []
            
            for i, item in enumerate(items, 1):
                codigo = str(item['codigo']).strip()
                clave_busqueda = f"{cliente}|{codigo.lower()}"
                
                logger.debug(f"🔍 Buscando artículo {i}/{len(items)}: {codigo} para cliente {cliente}")
                
                # Intentar obtener del cache primero
                cache_key = f"validacion_{clave_busqueda}"
                cache_result = cache_manager.get(cache_key)
                
                if cache_result is not None:
                    logger.debug(f"⚡ Cache hit para artículo: {codigo}")
                    if cache_result["existe"]:
                        articulo_valido = {
                            "codigo": item['codigo'],
                            "descripcion": item['descripcion'],
                            "cantidad": item['cantidad'],
                            "precio_unitario": item['precio_unitario'],
                            "precio_total": item['precio_total'],
                            "fecha_entrega": item['fecha_entrega']
                        }
                        articulos_encontrados.append(articulo_valido)
                    else:
                        articulo_faltante = {
                            "codigo": item['codigo'],
                            "descripcion": item['descripcion'],
                            "cantidad": item['cantidad'],
                            "motivo": cache_result["motivo"]
                        }
                        articulos_no_encontrados.append(articulo_faltante)
                    continue
                
                # Búsqueda en catálogo
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
                    logger.debug(f"✅ Artículo encontrado: {codigo}")
                    
                    # Guardar en cache
                    cache_manager.set(cache_key, {
                        "existe": True,
                        "registro": registro_catalogo.to_dict()
                    })
                    
                except KeyError:
                    articulo_faltante = {
                        "codigo": item['codigo'],
                        "descripcion": item['descripcion'],
                        "cantidad": item['cantidad'],
                        "motivo": f"La combinación Cliente [{cliente}] + Artículo [{item['codigo']}] NO existe en el catálogo"
                    }
                    articulos_no_encontrados.append(articulo_faltante)
                    logger.warning(f"❌ Artículo no encontrado: {codigo} para cliente {cliente}")
                    
                    # Guardar en cache
                    cache_manager.set(cache_key, {
                        "existe": False,
                        "motivo": articulo_faltante["motivo"]
                    })
            
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
                    f"VALIDACION EXITOSA: Todos los {len(items)} articulos existen en el catalogo. La orden puede procesarse en SAP."
                    if todos_existen else 
                    f"VALIDACION FALLIDA: {len(articulos_no_encontrados)} de {len(items)} articulos NO existen en el catalogo. Revisar articulos faltantes antes de procesar en SAP."
                )
            }
            
            logger.info(f"✅ Validación completada: {len(articulos_encontrados)}/{len(items)} artículos encontrados")
            if todos_existen:
                logger.info("🎉 TODOS los artículos existen - Orden lista para SAP")
            else:
                logger.warning(f"⚠️ {len(articulos_no_encontrados)} artículos faltantes - Revisar antes de SAP")
            
            return resultado
        except Exception as e:
            logger.error(f"❌ Error validando orden: {str(e)}")
            raise ValueError(f"Error validando orden: {str(e)}")

# Inicializar validador
logger.info("🚀 Iniciando Validador Tamaprint...")
try:
    validador = ValidadorOrdenesCompra()
    logger.info("✅ Validador inicializado correctamente")
except Exception as e:
    logger.error(f"❌ Error crítico: {e}")
    logger.error("💡 Verifica la configuración en .env y el archivo credentials.json")
    exit(1)

@app.post("/validar-orden")
async def validar_orden_endpoint(orden: OrdenModel):
    logger.info(f"📥 Nueva solicitud de validación recibida")
    try:
        resultado = validador.validar_orden(orden.dict())
        logger.info(f"✅ Validación exitosa para orden: {resultado['orden_compra']}")
        return JSONResponse(content=resultado, status_code=200)
    except ValueError as e:
        logger.warning(f"⚠️ Error de validación: {str(e)}")
        return JSONResponse(content={
            "TODOS_LOS_ARTICULOS_EXISTEN": False,
            "PUEDE_PROCESAR_EN_SAP": False,
            "error": str(e),
            "mensaje": f"ERROR DE VALIDACIÓN: {str(e)}"
        }, status_code=400)
    except Exception as e:
        logger.error(f"❌ Error interno: {str(e)}")
        return JSONResponse(content={
            "TODOS_LOS_ARTICULOS_EXISTEN": False,
            "PUEDE_PROCESAR_EN_SAP": False,
            "error": str(e),
            "mensaje": f"ERROR INTERNO: {str(e)}"
        }, status_code=500)

@app.get("/health")
async def health_check():
    logger.debug("🔍 Health check solicitado")
    try:
        response = {
            "status": "OK",
            "catalogo_items": len(validador.catalogo),
            "timestamp": datetime.now().isoformat()
        }
        logger.debug(f"✅ Health check exitoso: {response['catalogo_items']} items en catálogo")
        return response
    except Exception as e:
        logger.error(f"❌ Error en health check: {str(e)}")
        return JSONResponse(content={
            "status": "ERROR",
            "error": str(e)
        }, status_code=500)

@app.get("/debug-catalogo")
async def debug_catalogo():
    logger.debug("🔍 Debug catálogo solicitado")
    try:
        response = {
            "primeras_5_filas": validador.catalogo.head(5).to_dict(orient='records'),
            "claves_busqueda": list(validador.indice_catalogo.index[:5])
        }
        logger.debug(f"✅ Debug catálogo exitoso: {len(response['primeras_5_filas'])} filas mostradas")
        return response
    except Exception as e:
        logger.error(f"❌ Error en debug catálogo: {str(e)}")
        return JSONResponse(content={
            "error": str(e)
        }, status_code=500)

@app.get("/cache/stats")
async def cache_stats():
    """Obtener estadísticas del cache"""
    logger.debug("📊 Estadísticas de cache solicitadas")
    try:
        stats = cache_manager.stats()
        logger.debug(f"✅ Stats de cache: {stats['size']} items, hit_rate={stats['hit_rate']:.2f}")
        return stats
    except Exception as e:
        logger.error(f"❌ Error obteniendo stats de cache: {str(e)}")
        return JSONResponse(content={
            "error": str(e)
        }, status_code=500)

@app.post("/cache/clear")
async def clear_cache():
    """Limpiar todo el cache"""
    logger.info("🧹 Limpieza de cache solicitada")
    try:
        cache_manager.clear()
        return {"message": "Cache limpiado exitosamente", "status": "success"}
    except Exception as e:
        logger.error(f"❌ Error limpiando cache: {str(e)}")
        return JSONResponse(content={
            "error": str(e)
        }, status_code=500)