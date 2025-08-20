# 🚀 Validador TamaPrint - Cloud Run Setup

## ✅ URL Permanente - Ya No Más ngrok

Tu backend ahora está listo para Google Cloud Run. Una vez desplegado, tendrás una **URL permanente** como:

```
https://validador-tamaprint-xxx-uc.a.run.app
```

---

## 🎯 Archivos Creados para el Deployment

### 📁 Archivos de Configuración
- `Dockerfile` - Imagen optimizada para FastAPI
- `.dockerignore` - Optimización del build
- `service.yaml` - Configuración de Cloud Run
- `.env.cloud` - Variables de entorno para producción

### 🛠️ Scripts de Automatización  
- `deploy-to-cloud-run.sh` - Deployment completo automatizado
- `setup-service-account.sh` - Configuración de permisos
- `test-deployment.sh` - Pruebas post-deployment

### 📚 Documentación
- `DEPLOYMENT-GUIDE.md` - Guía completa paso a paso
- `CLOUD-RUN-SETUP.md` - Este archivo de resumen

---

## ⚡ Quick Start

### 1. Instalación de Prerequisites
```bash
# Google Cloud SDK
curl https://sdk.cloud.google.com | bash
# Restart terminal, then:
gcloud init

# Docker Desktop
# Descargar desde: https://docs.docker.com/get-docker/
```

### 2. Deployment en 3 comandos
```bash
# Autenticar
gcloud auth login
gcloud auth configure-docker

# Configurar proyecto  
export PROJECT_ID="validador-tamaprint"
gcloud config set project $PROJECT_ID

# Desplegar automáticamente
chmod +x deploy-to-cloud-run.sh
./deploy-to-cloud-run.sh
```

### 3. Configurar credenciales
```bash
# Subir credenciales a Secret Manager
gcloud secrets create google-sheets-credentials --data-file=credentials.json

# Configurar variables
gcloud run services update validador-tamaprint \
  --set-env-vars="GOOGLE_DRIVE_FILE_ID=tu_file_id" \
  --set-env-vars="GOOGLE_SHEET_RANGE=Hoja1!A1:Z1000" \
  --update-secrets="/app/credentials.json=google-sheets-credentials:latest" \
  --region us-central1
```

### 4. Probar deployment
```bash
chmod +x test-deployment.sh
./test-deployment.sh
```

---

## 💰 Costos Estimados

Cloud Run es **extremadamente económico**:

| Uso Mensual | Costo Estimado |
|-------------|----------------|
| Sin tráfico | **$0.00** |
| 1,000 requests | **~$0.24** |
| 10,000 requests | **~$2.40** |
| 100,000 requests | **~$24.00** |

**¡Solo pagas cuando alguien usa tu API!**

---

## 🔧 Ventajas vs ngrok

| Característica | ngrok | Cloud Run |
|---------------|-------|-----------|
| **URL permanente** | ❌ Cambia | ✅ Nunca cambia |
| **Disponibilidad** | ❌ Manual | ✅ 24/7 automática |
| **HTTPS** | ✅ Sí | ✅ Nativo |
| **Escalabilidad** | ❌ 1 instancia | ✅ 0-1000+ instancias |
| **Costo** | $5+/mes | ✅ $0 sin uso |
| **Monitoreo** | ❌ Básico | ✅ Completo |

---

## 📊 Tu Nueva URL

Una vez desplegado, tendrás endpoints como:

```bash
# Health Check  
GET https://tu-servicio-xxx-uc.a.run.app/health

# Validar Orden
POST https://tu-servicio-xxx-uc.a.run.app/validar-orden

# Debug Catálogo
GET https://tu-servicio-xxx-uc.a.run.app/debug-catalogo

# Cache Stats
GET https://tu-servicio-xxx-uc.a.run.app/cache/stats
```

---

## 🛡️ Configuración de Seguridad

### Para uso público (actual):
```bash
# API accesible desde cualquier lugar
gcloud run services add-iam-policy-binding validador-tamaprint \
  --member="allUsers" \
  --role="roles/run.invoker"
```

### Para uso privado (opcional):
```bash  
# Solo usuarios autorizados
gcloud run services remove-iam-policy-binding validador-tamaprint \
  --member="allUsers" \
  --role="roles/run.invoker"

gcloud run services add-iam-policy-binding validador-tamaprint \
  --member="user:tu-email@gmail.com" \
  --role="roles/run.invoker"
```

---

## 🔄 Actualizaciones

### Para actualizar tu código:
```bash
# 1. Hacer cambios en src/validador.py
# 2. Re-ejecutar deployment
./deploy-to-cloud-run.sh

# ¡Tu URL permanece igual!
```

---

## 📞 Soporte y Troubleshooting

### Ver logs en tiempo real:
```bash
gcloud run services logs tail validador-tamaprint --region us-central1
```

### Estado del servicio:
```bash
gcloud run services describe validador-tamaprint --region us-central1
```

### Reiniciar servicio:
```bash
gcloud run services update validador-tamaprint \
  --region us-central1 \
  --clear-env-vars=""  # Forzar redeploy
```

---

## 🎉 ¡Todo Listo!

### Próximos pasos:
1. ✅ **Ejecutar** `./deploy-to-cloud-run.sh`
2. ✅ **Configurar** variables de entorno  
3. ✅ **Probar** con `./test-deployment.sh`
4. ✅ **Usar** tu nueva URL permanente
5. ✅ **Eliminar** ngrok de tu flujo de trabajo

### Tu nueva realidad:
- 🌐 **URL que nunca cambia**
- ⚡ **Disponibilidad 24/7** 
- 💰 **Costos mínimos**
- 📈 **Escalado automático**
- 🔒 **HTTPS nativo**
- 📊 **Monitoreo completo**

**¡Bienvenido al mundo de las APIs en producción real!** 🚀