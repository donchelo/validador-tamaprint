# 🚀 Guía de Despliegue - Google Cloud Run

Esta guía te ayudará a desplegar tu Validador TamaPrint en Google Cloud Run para tener una **URL permanente** que reemplace ngrok.

## 🎯 Resultado Final
Una vez completado, tendrás:
- ✅ URL permanente: `https://validador-tamaprint-xxx-uc.a.run.app`
- ✅ Escalado automático (0 a 1000+ instancias)
- ✅ HTTPS nativo
- ✅ Solo pagas por uso
- ✅ Disponibilidad 24/7

---

## 📋 Prerrequisitos

### 1. Instalar Google Cloud SDK
```bash
# Windows (con Chocolatey)
choco install gcloudsdk

# O descargar desde: https://cloud.google.com/sdk/docs/install
```

### 2. Instalar Docker
```bash
# Windows (con Chocolatey)  
choco install docker-desktop

# O descargar desde: https://docs.docker.com/get-docker/
```

### 3. Tener una cuenta de Google Cloud
- Ir a https://cloud.google.com/
- Crear cuenta si no tienes una
- Habilitar facturación (tiene créditos gratis)

---

## 🛠️ Configuración Inicial

### Paso 1: Autenticación
```bash
# Autenticarse en Google Cloud
gcloud auth login

# Configurar Docker para usar gcloud
gcloud auth configure-docker
```

### Paso 2: Crear Proyecto
```bash
# Crear nuevo proyecto (opcional)
gcloud projects create validador-tamaprint --name="Validador TamaPrint"

# Configurar proyecto activo
gcloud config set project validador-tamaprint

# Verificar proyecto actual
gcloud config get-value project
```

### Paso 3: Configurar Variables de Entorno
```bash
# Establecer variables para los scripts
export PROJECT_ID="validador-tamaprint"
export SERVICE_NAME="validador-tamaprint"  
export REGION="us-central1"
```

---

## 🚀 Despliegue Automatizado

### Opción A: Script Automático (Recomendado)

```bash
# Hacer el script ejecutable
chmod +x deploy-to-cloud-run.sh

# Ejecutar despliegue completo
./deploy-to-cloud-run.sh
```

### Opción B: Paso a Paso Manual

#### 1. Habilitar APIs
```bash
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

#### 2. Construir imagen
```bash
docker build -t gcr.io/${PROJECT_ID}/validador-tamaprint .
```

#### 3. Subir imagen
```bash
docker push gcr.io/${PROJECT_ID}/validador-tamaprint
```

#### 4. Desplegar a Cloud Run
```bash
gcloud run deploy validador-tamaprint \
  --image gcr.io/${PROJECT_ID}/validador-tamaprint \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 10
```

---

## 🔐 Configuración de Credenciales

### Paso 1: Subir credenciales como secreto
```bash
# Subir tu archivo credentials.json como secreto
gcloud secrets create google-sheets-credentials \
  --data-file=credentials.json
```

### Paso 2: Configurar variables de entorno
```bash
gcloud run services update validador-tamaprint \
  --set-env-vars="GOOGLE_DRIVE_FILE_ID=tu_file_id_aqui" \
  --set-env-vars="GOOGLE_SHEET_RANGE=Hoja1!A1:Z1000" \
  --set-env-vars="GOOGLE_APPLICATION_CREDENTIALS=/app/credentials.json" \
  --region us-central1
```

### Paso 3: Montar el secreto
```bash
gcloud run services update validador-tamaprint \
  --update-secrets="/app/credentials.json=google-sheets-credentials:latest" \
  --region us-central1
```

---

## 🧪 Verificación y Testing

### 1. Obtener URL del servicio
```bash
SERVICE_URL=$(gcloud run services describe validador-tamaprint \
  --platform managed --region us-central1 \
  --format 'value(status.url)')

echo "URL de tu servicio: $SERVICE_URL"
```

### 2. Probar Health Check
```bash
curl $SERVICE_URL/health
```

### 3. Probar validación completa
```bash
curl -X POST $SERVICE_URL/validar-orden \
  -H "Content-Type: application/json" \
  -d '{
    "comprador": {"nit": "123456789"},
    "orden_compra": "TEST-001",
    "items": [{
      "codigo": "TEST123",
      "descripcion": "Producto de prueba",
      "cantidad": 1,
      "precio_unitario": 100.0,
      "precio_total": 100.0,
      "fecha_entrega": "2024-12-31"
    }]
  }'
```

---

## 📊 Monitoreo y Logs

### Ver logs en tiempo real
```bash
gcloud run services logs tail validador-tamaprint --region us-central1
```

### Ver métricas en Cloud Console
1. Ir a https://console.cloud.google.com/run
2. Seleccionar tu servicio
3. Ver pestañas: Métricas, Logs, Revisiones

---

## 💰 Optimización de Costos

### Configurar escalado inteligente
```bash
gcloud run services update validador-tamaprint \
  --min-instances 0 \
  --max-instances 10 \
  --concurrency 80 \
  --cpu-throttling \
  --region us-central1
```

### Estimación de costos:
- **Sin tráfico**: $0.00/mes
- **1000 requests/mes**: ~$0.24/mes
- **10000 requests/mes**: ~$2.40/mes

---

## 🔧 Actualización de la Aplicación

### Para actualizar tu código:
```bash
# 1. Hacer cambios en el código
# 2. Reconstruir imagen
docker build -t gcr.io/${PROJECT_ID}/validador-tamaprint .

# 3. Subir nueva imagen  
docker push gcr.io/${PROJECT_ID}/validador-tamaprint

# 4. Redesplegar (automático con Cloud Build)
gcloud run services update validador-tamaprint \
  --image gcr.io/${PROJECT_ID}/validador-tamaprint \
  --region us-central1
```

---

## 🛡️ Seguridad y Mejores Prácticas

### 1. Usar Service Account específico
```bash
./setup-service-account.sh
```

### 2. Restringir acceso (opcional)
```bash
# Quitar acceso público
gcloud run services remove-iam-policy-binding validador-tamaprint \
  --member="allUsers" \
  --role="roles/run.invoker" \
  --region us-central1

# Dar acceso solo a usuarios específicos
gcloud run services add-iam-policy-binding validador-tamaprint \
  --member="user:tu-email@gmail.com" \
  --role="roles/run.invoker" \
  --region us-central1
```

### 3. Configurar dominio personalizado (opcional)
```bash
# Mapear dominio personalizado
gcloud run domain-mappings create \
  --service validador-tamaprint \
  --domain api.tudominio.com \
  --region us-central1
```

---

## 🆘 Troubleshooting

### Error: "Service account does not exist"
```bash
# Crear service account
gcloud iam service-accounts create validador-tamaprint-sa
```

### Error: "Permission denied"
```bash
# Verificar roles del usuario
gcloud projects get-iam-policy ${PROJECT_ID}
```

### Error: "Container failed to start"
```bash
# Ver logs detallados
gcloud run services logs read validador-tamaprint --region us-central1
```

### Error de conexión a Google Sheets
1. Verificar que `credentials.json` esté en Secret Manager
2. Verificar que la hoja esté compartida con el service account email
3. Verificar variables de entorno: `GOOGLE_DRIVE_FILE_ID`, `GOOGLE_SHEET_RANGE`

---

## 📞 Soporte

### Recursos útiles:
- [Documentación Cloud Run](https://cloud.google.com/run/docs)
- [Precios Cloud Run](https://cloud.google.com/run/pricing)
- [Límites Cloud Run](https://cloud.google.com/run/quotas)

### Comandos de diagnóstico:
```bash
# Estado del servicio
gcloud run services describe validador-tamaprint --region us-central1

# Revisiones del servicio  
gcloud run revisions list --service validador-tamaprint --region us-central1

# Configuración actual
gcloud run services describe validador-tamaprint \
  --region us-central1 --format export
```

---

## 🎉 ¡Listo!

Una vez completado este proceso, tendrás tu **URL permanente** que podrás usar en lugar de ngrok. 

**Tu nueva URL será algo como:**
`https://validador-tamaprint-xxx-uc.a.run.app`

Esta URL:
- ✅ **Nunca cambia**
- ✅ **Siempre está disponible** 
- ✅ **Escala automáticamente**
- ✅ **Tiene HTTPS nativo**
- ✅ **Es muy económica**

¡Adiós ngrok, hola Cloud Run! 🚀