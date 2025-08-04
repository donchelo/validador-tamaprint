# API Validador TamaPrint - Documentación

## Estado del Servidor
✅ **Servidor iniciado correctamente en:** `http://localhost:8000`

## Endpoints Disponibles

### 1. Health Check
- **URL:** `GET /health`
- **Descripción:** Verifica el estado del servidor y muestra información del catálogo
- **Ejemplo:** `curl http://localhost:8000/health`

### 2. Debug Catálogo
- **URL:** `GET /debug-catalogo`
- **Descripción:** Muestra las primeras 5 filas del catálogo y claves de búsqueda
- **Ejemplo:** `curl http://localhost:8000/debug-catalogo`

### 3. Validar Orden de Compra
- **URL:** `POST /validar-orden`
- **Descripción:** Valida una orden de compra contra el catálogo
- **Content-Type:** `application/json`

#### Estructura del JSON de entrada:
```json
{
  "comprador": {
    "nit": "CN901426336"
  },
  "orden_compra": "OC-2024-001",
  "items": [
    {
      "codigo": "14003793002",
      "descripcion": "Producto de ejemplo",
      "cantidad": 10,
      "precio_unitario": 100.0,
      "precio_total": 1000.0,
      "fecha_entrega": "2024-12-31"
    }
  ]
}
```

#### Ejemplo de uso con curl:
```bash
curl -X POST http://localhost:8000/validar-orden \
  -H "Content-Type: application/json" \
  -d '{
    "comprador": {"nit": "CN901426336"},
    "orden_compra": "OC-2024-001",
    "items": [
      {
        "codigo": "14003793002",
        "descripcion": "Producto de ejemplo",
        "cantidad": 10,
        "precio_unitario": 100.0,
        "precio_total": 1000.0,
        "fecha_entrega": "2024-12-31"
      }
    ]
  }'
```

## Respuesta de Validación

La API devuelve un JSON con la siguiente estructura:

```json
{
  "orden_compra": "OC-2024-001",
  "cliente": "CN901426336",
  "fecha_validacion": "2024-08-03 21:57:32",
  "TODOS_LOS_ARTICULOS_EXISTEN": true,
  "PUEDE_PROCESAR_EN_SAP": true,
  "resumen": {
    "total_articulos": 1,
    "articulos_encontrados": 1,
    "articulos_faltantes": 0,
    "porcentaje_exito": 100.0
  },
  "articulos_listos_para_sap": [...],
  "articulos_que_NO_existen": [],
  "mensaje": "VALIDACION EXITOSA: Todos los 1 articulos existen en el catalogo. La orden puede procesarse en SAP."
}
```

## Información del Sistema

- **Catálogo cargado:** 10,982 registros
- **Modo:** Demo (usando datos de prueba)
- **Servidor:** Uvicorn con FastAPI
- **Puerto:** 8000
- **Host:** 0.0.0.0 (accesible desde cualquier IP)

## Para detener el servidor
Presiona `Ctrl+C` en la terminal donde está ejecutándose el servidor.

## Para reiniciar el servidor
```bash
uvicorn validador:app --reload --host 0.0.0.0 --port 8000
``` 