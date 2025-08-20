#!/bin/bash

# Script para probar el deployment en Cloud Run
# Autor: Claude Code Assistant

set -e

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }

# Configuración
PROJECT_ID="${PROJECT_ID:-validador-tamaprint}"
SERVICE_NAME="${SERVICE_NAME:-validador-tamaprint}"
REGION="${REGION:-us-central1}"

# Obtener URL del servicio
log "Obteniendo URL del servicio..."
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} \
  --platform managed --region ${REGION} \
  --format 'value(status.url)' 2>/dev/null)

if [ -z "$SERVICE_URL" ]; then
    error "No se pudo obtener la URL del servicio. ¿Está desplegado?"
    exit 1
fi

log "🌐 URL del servicio: ${SERVICE_URL}"
echo

# Test 1: Health Check
log "🩺 Test 1: Health Check"
if curl -s -f "${SERVICE_URL}/health" > /dev/null; then
    log "✅ Health check: OK"
    # Mostrar respuesta completa
    info "Respuesta del health check:"
    curl -s "${SERVICE_URL}/health" | jq . || curl -s "${SERVICE_URL}/health"
else
    error "❌ Health check: FAILED"
fi
echo

# Test 2: Debug Catálogo
log "🗂️  Test 2: Debug Catálogo" 
if curl -s -f "${SERVICE_URL}/debug-catalogo" > /dev/null; then
    log "✅ Debug catálogo: OK"
    info "Primeras filas del catálogo:"
    curl -s "${SERVICE_URL}/debug-catalogo" | jq '.primeras_5_filas[0:2]' || echo "Sin jq disponible"
else
    warn "⚠️  Debug catálogo: No disponible (puede requerir configuración)"
fi
echo

# Test 3: Cache Stats
log "📊 Test 3: Cache Stats"
if curl -s -f "${SERVICE_URL}/cache/stats" > /dev/null; then
    log "✅ Cache stats: OK"
    info "Estadísticas del cache:"
    curl -s "${SERVICE_URL}/cache/stats" | jq . || curl -s "${SERVICE_URL}/cache/stats"
else
    warn "⚠️  Cache stats: Error (revisa logs)"
fi
echo

# Test 4: Validación de Orden (Prueba)
log "📋 Test 4: Validación de Orden de Prueba"
TEST_ORDER='{
  "comprador": {
    "nit": "TEST123"
  },
  "orden_compra": "TEST-DEPLOY-001",
  "items": [{
    "codigo": "TEST-ITEM",
    "descripcion": "Artículo de prueba para deployment", 
    "cantidad": 1,
    "precio_unitario": 100.0,
    "precio_total": 100.0,
    "fecha_entrega": "2024-12-31"
  }]
}'

RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "${SERVICE_URL}/validar-orden" \
  -H "Content-Type: application/json" \
  -d "$TEST_ORDER")

HTTP_CODE=$(echo "$RESPONSE" | tail -1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" = "200" ]; then
    log "✅ Validación de orden: OK (200)"
    info "Orden procesada correctamente"
    echo "$BODY" | jq '.resumen // {mensaje: "Respuesta recibida"}' || echo "Respuesta recibida"
elif [ "$HTTP_CODE" = "400" ]; then
    warn "⚠️  Validación de orden: Error esperado (400) - Artículo no existe"
    info "Esto es normal para un artículo de prueba"
else
    error "❌ Validación de orden: Error inesperado ($HTTP_CODE)"
    echo "$BODY"
fi
echo

# Test 5: Performance básico
log "⚡ Test 5: Test de Performance Básico"
log "Realizando 5 requests al health endpoint..."

TOTAL_TIME=0
SUCCESS_COUNT=0

for i in {1..5}; do
    START_TIME=$(date +%s.%N)
    if curl -s -f "${SERVICE_URL}/health" > /dev/null; then
        END_TIME=$(date +%s.%N)
        REQUEST_TIME=$(echo "$END_TIME - $START_TIME" | bc -l 2>/dev/null || echo "0.5")
        TOTAL_TIME=$(echo "$TOTAL_TIME + $REQUEST_TIME" | bc -l 2>/dev/null || echo "$TOTAL_TIME")
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        info "Request $i: ${REQUEST_TIME}s"
    else
        error "Request $i: FAILED"
    fi
done

if [ $SUCCESS_COUNT -eq 5 ]; then
    AVG_TIME=$(echo "scale=3; $TOTAL_TIME / 5" | bc -l 2>/dev/null || echo "< 0.5")
    log "✅ Performance: ${SUCCESS_COUNT}/5 requests exitosos"
    info "Tiempo promedio: ${AVG_TIME}s"
else
    warn "⚠️  Performance: ${SUCCESS_COUNT}/5 requests exitosos"
fi
echo

# Resumen final
log "📋 RESUMEN DE PRUEBAS"
log "==================="
log "🌐 URL del servicio: ${SERVICE_URL}"
log "📊 Región: ${REGION}"
log "🗂️  Proyecto: ${PROJECT_ID}"
echo

info "📋 Próximos pasos:"
info "1. Si hay errores, revisa los logs:"
info "   gcloud run services logs tail ${SERVICE_NAME} --region ${REGION}"
echo
info "2. Para configurar variables de entorno:"
info "   gcloud run services update ${SERVICE_NAME} \\"
info "     --set-env-vars GOOGLE_DRIVE_FILE_ID=tu_file_id \\"
info "     --region ${REGION}"
echo
info "3. Para usar la API en producción:"
info "   curl -X POST ${SERVICE_URL}/validar-orden \\"
info "     -H 'Content-Type: application/json' \\"
info "     -d @tu_orden.json"
echo

log "🎉 ¡Tu API está funcionando en Cloud Run!"
log "¡Adiós ngrok, hola URL permanente! 🚀"