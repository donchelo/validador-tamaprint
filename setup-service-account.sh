#!/bin/bash

# Script para configurar Service Account y permisos para Cloud Run
# Autor: Claude Code Assistant

set -e

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
warn() { echo -e "${YELLOW}[WARNING] $1${NC}"; }
error() { echo -e "${RED}[ERROR] $1${NC}"; }
info() { echo -e "${BLUE}[INFO] $1${NC}"; }

# Configuración
PROJECT_ID="${PROJECT_ID:-validador-tamaprint}"
SERVICE_ACCOUNT_NAME="validador-tamaprint-sa"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

log "Configurando Service Account para proyecto: ${PROJECT_ID}"

# Verificar que gcloud esté instalado y autenticado
if ! command -v gcloud &> /dev/null; then
    error "gcloud CLI no está instalado"
    exit 1
fi

# Configurar proyecto
gcloud config set project ${PROJECT_ID}

# Crear Service Account
log "Creando Service Account: ${SERVICE_ACCOUNT_NAME}"
if gcloud iam service-accounts describe ${SERVICE_ACCOUNT_EMAIL} &> /dev/null; then
    warn "Service Account ya existe: ${SERVICE_ACCOUNT_EMAIL}"
else
    gcloud iam service-accounts create ${SERVICE_ACCOUNT_NAME} \
        --display-name="Validador TamaPrint Service Account" \
        --description="Service Account para el validador TamaPrint en Cloud Run"
    log "Service Account creado exitosamente"
fi

# Asignar roles necesarios
log "Asignando roles al Service Account..."

# Roles para Cloud Run
ROLES=(
    "roles/run.invoker"
    "roles/secretmanager.secretAccessor"
    "roles/logging.logWriter"
    "roles/monitoring.metricWriter"
    "roles/cloudtrace.agent"
)

for role in "${ROLES[@]}"; do
    log "Asignando rol: ${role}"
    gcloud projects add-iam-policy-binding ${PROJECT_ID} \
        --member="serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
        --role="${role}"
done

# Crear y descargar clave del Service Account
KEY_FILE="service-account-key.json"
log "Creando clave del Service Account..."

if [ -f "${KEY_FILE}" ]; then
    warn "Archivo de clave ya existe: ${KEY_FILE}"
    read -p "¿Deseas crear una nueva clave? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "${KEY_FILE}"
    else
        log "Usando clave existente"
        exit 0
    fi
fi

gcloud iam service-accounts keys create ${KEY_FILE} \
    --iam-account=${SERVICE_ACCOUNT_EMAIL}

log "✅ Service Account configurado exitosamente!"
log ""
info "Detalles del Service Account:"
info "  Nombre: ${SERVICE_ACCOUNT_NAME}"
info "  Email: ${SERVICE_ACCOUNT_EMAIL}"
info "  Archivo de clave: ${KEY_FILE}"
log ""
info "📋 Próximos pasos:"
info "1. Subir la clave como secreto:"
info "   gcloud secrets create google-sheets-credentials --data-file=${KEY_FILE}"
info ""
info "2. Si usas Google Sheets, asegúrate de compartir la hoja con:"
info "   ${SERVICE_ACCOUNT_EMAIL}"
info ""
info "3. Durante el despliegue, Cloud Run usará automáticamente este Service Account"
warn ""
warn "🔒 IMPORTANTE: Mantén el archivo ${KEY_FILE} seguro y no lo subas a Git"