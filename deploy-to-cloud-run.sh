#!/bin/bash

# Script de despliegue para Google Cloud Run
# Autor: Claude Code Assistant
# Descripción: Automatiza el despliegue del Validador TamaPrint a Google Cloud Run

set -e  # Salir si hay errores

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Configuración (puedes modificar estos valores)
PROJECT_ID="${PROJECT_ID:-validador-tamaprint}"
SERVICE_NAME="${SERVICE_NAME:-validador-tamaprint}"
REGION="${REGION:-us-central1}"
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"

# Verificar dependencias
log "Verificando dependencias..."

if ! command -v gcloud &> /dev/null; then
    error "gcloud CLI no está instalado. Instala Google Cloud SDK desde: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    error "Docker no está instalado. Instala Docker desde: https://docs.docker.com/get-docker/"
    exit 1
fi

# Verificar autenticación
log "Verificando autenticación con Google Cloud..."
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q "."; then
    error "No estás autenticado en Google Cloud. Ejecuta: gcloud auth login"
    exit 1
fi

# Configurar proyecto
log "Configurando proyecto: ${PROJECT_ID}"
gcloud config set project ${PROJECT_ID}

# Habilitar APIs necesarias
log "Habilitando APIs necesarias..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable secretmanager.googleapis.com

# Verificar que el archivo de credenciales existe
if [ ! -f "credentials.json" ]; then
    warn "credentials.json no encontrado en el directorio actual."
    info "Necesitas colocar tu archivo de credenciales de Google Sheets aquí."
    info "O puedes subirlo manualmente a Secret Manager después del despliegue."
fi

# Construir imagen Docker
log "Construyendo imagen Docker..."
docker build -t ${IMAGE_NAME} .

# Subir imagen a Container Registry
log "Subiendo imagen a Google Container Registry..."
docker push ${IMAGE_NAME}

# Desplegar a Cloud Run
log "Desplegando a Cloud Run..."

# Comando base de despliegue
DEPLOY_CMD="gcloud run deploy ${SERVICE_NAME} \
    --image ${IMAGE_NAME} \
    --platform managed \
    --region ${REGION} \
    --allow-unauthenticated \
    --port 8080 \
    --memory 512Mi \
    --cpu 1 \
    --min-instances 0 \
    --max-instances 10 \
    --timeout 300s \
    --concurrency 80"

# Agregar variables de entorno si existen
if [ -f ".env.cloud" ]; then
    log "Configurando variables de entorno desde .env.cloud..."
    # Nota: En producción, usa Secret Manager para datos sensibles
    DEPLOY_CMD="${DEPLOY_CMD} --set-env-vars PORT=8080,ENVIRONMENT=production"
fi

# Ejecutar despliegue
eval $DEPLOY_CMD

# Obtener URL del servicio
SERVICE_URL=$(gcloud run services describe ${SERVICE_NAME} --platform managed --region ${REGION} --format 'value(status.url)')

log "✅ Despliegue completado exitosamente!"
log "🌐 URL del servicio: ${SERVICE_URL}"
log ""
log "📋 Próximos pasos:"
info "1. Configurar variables de entorno en Cloud Run Console:"
info "   - GOOGLE_DRIVE_FILE_ID"
info "   - GOOGLE_SHEET_RANGE" 
info "   - GOOGLE_APPLICATION_CREDENTIALS=/app/credentials.json"
info ""
info "2. Subir credentials.json a Secret Manager:"
info "   gcloud secrets create google-sheets-credentials --data-file=credentials.json"
info ""
info "3. Configurar el servicio para usar el secreto:"
info "   gcloud run services update ${SERVICE_NAME} \\"
info "     --update-secrets /app/credentials.json=google-sheets-credentials:latest \\"
info "     --region ${REGION}"
info ""
info "4. Probar el servicio:"
info "   curl ${SERVICE_URL}/health"
info ""
log "🎉 Tu API ya no depende de ngrok - tienes una URL permanente!"