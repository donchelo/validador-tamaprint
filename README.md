# 🚀 Validador TamaPrint - Ultra Simplificado

Validador de órdenes de compra que verifica artículos contra un catálogo en Google Sheets.

## 📁 Estructura del Proyecto

```
validador-tamaprint/
├── src/                    # Código fuente principal
│   ├── __init__.py
│   ├── validador.py       # Aplicación FastAPI principal
│   └── verificar_sistema.py
├── scripts/               # Scripts de PowerShell
│   ├── __init__.py
│   ├── iniciar.ps1        # Script principal unificado
│   ├── test_simple.ps1
│   └── test_rapido.ps1
├── tests/                 # Pruebas automatizadas
│   ├── __init__.py
│   ├── test_validador.py
│   ├── test_iniciador_unificado.py
│   ├── ejecutar_tests.py
│   └── probar_mejoras.py
├── config/                # Configuración y archivos externos
│   ├── __init__.py
│   ├── config.py          # Configuración centralizada
│   └── ngrok.exe
├── logs/                  # Archivos de log
│   ├── __init__.py
│   └── validador.log
├── docs/                  # Documentación
│   ├── __init__.py
│   ├── README.md
│   ├── INSTRUCCIONES_RAPIDAS.md
│   ├── MEJORAS_V2.1.md
│   └── UNIFICACION_V3.0.md
├── run.py                 # Script de inicio Python
├── requirements.txt       # Dependencias
└── .gitignore
```

## ⚡ Inicio Ultra-Rápido

### 🚀 Opción 1: Script PowerShell (Recomendado)
```powershell
.\scripts\iniciar.ps1
```

### 🐍 Opción 2: Script Python
```bash
python run.py
```

### 🔧 Opción 3: Manual
```bash
python -m uvicorn src.validador:app --host 0.0.0.0 --port 8000
```

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

### Health Check
```bash
GET http://localhost:8000/health
```

## 🛠️ Configuración

### 1. Variables de Entorno
Crear archivo `.env` en la raíz del proyecto:
```env
GOOGLE_DRIVE_FILE_ID=TU_GOOGLE_SHEET_ID
GOOGLE_SHEET_RANGE=Hoja1!A:Z
GOOGLE_APPLICATION_CREDENTIALS=credentials.json
```

### 2. Credenciales de Google
- Descargar `credentials.json` desde Google Cloud Console
- Colocar en la raíz del proyecto

### 3. Ngrok (Opcional)
- Descargar `ngrok.exe` desde https://ngrok.com/download
- Colocar en `config/ngrok.exe`

## 🧪 Ejecutar Pruebas

```bash
# Ejecutar todas las pruebas
python -m pytest tests/

# Ejecutar pruebas específicas
python -m pytest tests/test_validador.py -v

# Ejecutar con cobertura
python -m pytest tests/ --cov=src --cov-report=html
```

## 📚 Documentación

- **Instrucciones Rápidas**: `docs/INSTRUCCIONES_RAPIDAS.md`
- **Mejoras V2.1**: `docs/MEJORAS_V2.1.md`
- **Unificación V3.0**: `docs/UNIFICACION_V3.0.md`

## 🔧 Desarrollo

### Estructura de Código
- **`src/validador.py`**: Aplicación FastAPI principal
- **`config/config.py`**: Configuración centralizada
- **`tests/`**: Pruebas unitarias y de integración

### Agregar Nuevas Funcionalidades
1. Crear módulo en `src/`
2. Agregar pruebas en `tests/`
3. Actualizar documentación en `docs/`
4. Actualizar `config/config.py` si es necesario

## 🚀 Despliegue

### Local
```bash
python run.py --host 127.0.0.1 --port 8000
```

### Producción
```bash
python run.py --host 0.0.0.0 --port 8000
```

### Con Ngrok (Acceso Público)
```powershell
.\scripts\iniciar.ps1
```

## 📝 Logs

Los logs se guardan en `logs/validador.log` con el siguiente formato:
```
2024-01-15 10:30:00 | INFO | validador | Servidor iniciado en puerto 8000
2024-01-15 10:30:05 | INFO | validador | Validación exitosa para orden OC-2024-001
```

## 🛑 Para Detener

1. **Servidor FastAPI:** `Ctrl+C` en la terminal del servidor
2. **Ngrok:** `Ctrl+C` en la terminal de ngrok
3. **Modo automático:** Cerrar la ventana de PowerShell

## 📞 Soporte

Si tienes problemas:
1. Ejecuta: `.\scripts\iniciar.ps1 -VerificarSolo`
2. Revisa los logs en `logs/validador.log`
3. Verifica la documentación en `docs/`
4. Asegúrate de que todos los archivos estén en su lugar

## 🔄 Migración desde Versiones Anteriores

### Cambios en V3.0
- ✅ Estructura de directorios organizada
- ✅ Configuración centralizada
- ✅ Scripts unificados
- ✅ Mejor manejo de rutas
- ✅ Documentación actualizada

### Archivos Movidos
- `validador.py` → `src/validador.py`
- `*.ps1` → `scripts/`
- `test_*.py` → `tests/`
- `*.md` → `docs/`
- `ngrok.exe` → `config/`
- `validador.log` → `logs/`
