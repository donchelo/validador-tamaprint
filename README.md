# 🚀 Validador Tamaprint - Ultra Simplificado

Validador de órdenes de compra que verifica artículos contra un catálogo en Google Sheets.

## ⚡ Inicio Ultra-Rápido (Recomendado)

### Opción 1: Script Automático (Windows)
```bash
# Doble clic en el archivo o ejecutar:
iniciar_validador.bat
```
**Resultado:** El script hace TODO automáticamente y te da la URL final para Make.com

### Opción 2: Script PowerShell (Más robusto)
```powershell
.\iniciar_todo_automatico.ps1
```
**Resultado:** Inicio automático con mejor manejo de errores

### Opción 3: Manual (Solo si necesitas control total)
1. **Instalar dependencias:** `pip install -r requirements.txt`
2. **Configurar `.env`:** 
   ```env
   GOOGLE_DRIVE_FILE_ID=TU_GOOGLE_SHEET_ID
   GOOGLE_SHEET_RANGE=Hoja1!A:Z
   GOOGLE_APPLICATION_CREDENTIALS=credentials.json
   ```
3. **Iniciar servidor:** `python -m uvicorn validador:app --host 0.0.0.0 --port 8000`
4. **Iniciar ngrok:** `.\ngrok.exe http 8000`

## 📍 URLs de Acceso

| Servicio | URL |
|----------|-----|
| **API Principal** | http://localhost:8000 |
| **Documentación** | http://localhost:8000/docs |
| **Health Check** | http://localhost:8000/health |

## 🔗 API Endpoints

### Validar Orden de Compra
```bash
POST http://localhost:8000/validar-orden
```

**JSON de ejemplo:**
```json
{
  "comprador": {
    "nit": "CN800069933"
  },
  "orden_compra": "OC-2024-001",
  "items": [
    {
      "codigo": "14003793002",
      "descripcion": "Producto Demo",
      "cantidad": 5,
      "precio_unitario": 100.0,
      "precio_total": 500.0,
      "fecha_entrega": "2024-01-15"
    }
  ]
}
```

**Respuesta exitosa:**
```json
{
  "TODOS_LOS_ARTICULOS_EXISTEN": true,
  "PUEDE_PROCESAR_EN_SAP": true,
  "orden_compra": "OC-2024-001",
  "cliente": "CN800069933",
  "resumen": {
    "total_articulos": 1,
    "articulos_encontrados": 1,
    "articulos_faltantes": 0,
    "porcentaje_exito": 100.0
  },
  "mensaje": "VALIDACION EXITOSA: Todos los 1 articulos existen en el catalogo..."
}
```

## 🌐 Acceso Público (Opcional)

Para exponer la API públicamente:
```bash
ngrok.exe http 8000
```

## 🛠 Verificación del Sistema

```bash
python verificar_sistema.py
```

## 📁 Estructura del Proyecto

```
validador-tamaprint/
├── validador.py              # Aplicación principal
├── requirements.txt          # Dependencias
├── verificar_sistema.py     # Verificación básica
├── iniciar_validador.bat    # Script de inicio
├── README.md                # Esta documentación
├── .env                     # Variables de entorno
├── credentials.json         # Credenciales Google
└── ngrok.exe               # Túnel público (opcional)
```

## 🔧 Solución de Problemas

### Error: "Puerto en uso"
```bash
python -m uvicorn validador:app --host 0.0.0.0 --port 8080
```

### Error: "Google Sheets no encontrado"
- Verificar que `credentials.json` existe
- Verificar que el Google Sheet ID es correcto
- Verificar que el Service Account tiene acceso

### Error: "Dependencias faltantes"
```bash
pip install -r requirements.txt
```

## 📊 Monitoreo

- **Health Check:** `GET /health`
- **Debug Catálogo:** `GET /debug-catalogo`
- **Logs:** Revisar terminal donde se ejecuta el servidor

---

**Versión:** Ultra Simplificada  
**Desarrollado con:** FastAPI + Google Sheets