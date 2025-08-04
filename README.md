# 🚀 Validador Tamaprint 2.0

Validador de órdenes de compra integrado con Google Sheets y ngrok para procesamiento automatizado en SAP.

## 📋 Descripción

Este sistema valida automáticamente los artículos de las órdenes de compra contra un catálogo en Google Sheets, separando las órdenes válidas de las que tienen artículos faltantes, y preparándolas para procesamiento RPA en SAP.

## 🔧 Configuración Inicial (Solo la primera vez)

### 1. **Requisitos del Sistema**
- Python 3.8 o superior
- Conexión a internet
- Cuenta de Google con acceso a Google Sheets

### 2. **Configurar Google Sheets**
1. Crea un Service Account en Google Cloud Console
2. Descarga el archivo de credenciales como `credentials.json`
3. Coloca `credentials.json` en la carpeta del proyecto
4. Comparte tu Google Sheet con el email del Service Account

### 3. **Configurar Variables de Entorno**
Edita el archivo `.env` con tus datos:
```env
GOOGLE_DRIVE_FILE_ID=TU_GOOGLE_SHEET_ID_AQUI
GOOGLE_SHEET_RANGE=Hoja1!A:Z
GOOGLE_APPLICATION_CREDENTIALS=credentials.json
```

### 4. **Instalar Dependencias**
```bash
pip install -r requirements.txt
```

## 🚀 Uso Diario - Activar Backend

### **Opción 1: Automático (Recomendado)**

1. **Abrir VS Code** en la carpeta del proyecto
2. **Ejecutar:** Doble clic en `iniciar_validador.bat`
3. **Esperar:** El script hará todo automáticamente
4. **Obtener URL:** Se abrirá http://localhost:4040 automáticamente

### **Opción 2: Manual**

1. **Abrir terminal** en VS Code (Ctrl + `)
2. **Ejecutar FastAPI:**
   ```bash
   python -m uvicorn validador:app --host 0.0.0.0 --port 8000
   ```
3. **Nueva terminal** (Ctrl + Shift + `)
4. **Ejecutar ngrok:**
   ```bash
   .\ngrok.exe http 8000
   ```
5. **Copiar URL** de la salida de ngrok

## 📍 URLs de Acceso

| Servicio | URL Local | URL Pública |
|----------|-----------|-------------|
| **API Principal** | http://localhost:8000 | https://[ID].ngrok-free.app |
| **Documentación** | http://localhost:8000/docs | https://[ID].ngrok-free.app/docs |
| **Health Check** | http://localhost:8000/health | https://[ID].ngrok-free.app/health |
| **Ngrok Dashboard** | http://localhost:4040 | - |

## 🔗 Integración con Make.com

### **Endpoints para Make.com:**

- **Validación de órdenes:** `https://[TU_URL_NGROK]/validar-orden`
- **Health Check:** `https://[TU_URL_NGROK]/health`

### **Ejemplo de JSON para validación:**
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

### **Respuesta exitosa:**
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
  "articulos_listos_para_sap": [...],
  "mensaje": "VALIDACION EXITOSA: Todos los 1 articulos existen en el catalogo..."
}
```

## 🛠 Herramientas de Diagnóstico

### **Verificar Sistema:**
```bash
python verificar_sistema.py
```

Este script verifica:
- ✅ Versión de Python
- ✅ Archivos necesarios
- ✅ Dependencias instaladas
- ✅ Configuración de .env
- ✅ Credenciales de Google
- ✅ Funcionamiento de ngrok

## 📁 Estructura del Proyecto

```
validador-tamaprint-2.0/
├── validador.py              # Aplicación principal FastAPI
├── requirements.txt          # Dependencias Python
├── credentials.json          # Credenciales Google (NO subir a Git)
├── .env                      # Variables de entorno (NO subir a Git)
├── ngrok.exe                # Ejecutable ngrok
├── iniciar_validador.bat    # Script de inicio automático
├── verificar_sistema.py     # Script de diagnóstico
├── README.md                # Esta documentación
└── docs/                    # Documentación adicional
```

## 🔍 Troubleshooting

### **Problema:** "Error cargando Google Sheets"
**Solución:**
1. Verificar que `credentials.json` existe
2. Verificar que el Google Sheet ID es correcto
3. Verificar que el Service Account tiene acceso al Sheet

### **Problema:** "Port 8000 already in use"
**Solución:**
1. Cerrar todas las ventanas de comandos
2. Reiniciar el script

### **Problema:** "Ngrok authentication failed"
**Solución:**
1. Registrarse en ngrok.com
2. Obtener auth token
3. Ejecutar: `ngrok config add-authtoken TU_TOKEN`

### **Problema:** Validación siempre falla
**Solución:**
1. Verificar formato de NITs (deben ser mayúsculas: CN123456)
2. Verificar nombres de columnas en Google Sheets
3. Ejecutar `verificar_sistema.py` para diagnóstico

## 📊 Monitoreo

### **Logs importantes:**
- ✅ "Catalogo cargado: X registros"
- ✅ "Indice de busqueda creado"
- ⚠️ "Error cargando Google Sheets"
- 📍 "Buscando clave: 'CN123456|14003793002'"

### **Métricas clave:**
- Tiempo de respuesta de validación
- Porcentaje de éxito de validaciones
- Número de registros en catálogo

## 🚨 Importante

- ❌ **NO cierres** las ventanas de FastAPI ni ngrok mientras esté en uso
- ❌ **NO subas** `credentials.json` ni `.env` a Git
- ✅ **Mantén** ngrok corriendo para que Make.com funcione
- ✅ **Verifica** regularmente que el túnel ngrok sigue activo

## 🆘 Soporte

Si encuentras problemas:

1. **Ejecutar diagnóstico:** `python verificar_sistema.py`
2. **Revisar logs** en las ventanas de FastAPI y ngrok
3. **Verificar conexión** con http://localhost:8000/health
4. **Reiniciar completamente** cerrando todas las ventanas y ejecutando `iniciar_validador.bat`

---

**Versión:** 2.0  
**Última actualización:** $(Get-Date -Format "yyyy-MM-dd")  
**Desarrollado con:** FastAPI + Google Sheets + ngrok