# Guía de Inicio - Validador TamaPrint

## 🚀 Pasos para iniciar el proyecto desde cero

### Paso 1: Abrir PowerShell en el directorio del proyecto
```powershell
cd "C:\Users\chelo\OneDrive\Escritorio\tamaprint\validador-tamaprint - 2.0"
```

### Paso 2: Activar el entorno virtual
```powershell
.\.venv\Scripts\Activate.ps1
```
**Resultado esperado:** Ver `(.venv)` al inicio del prompt

### Paso 3: Verificar que Python esté disponible
```powershell
python --version
```
**Resultado esperado:** `Python 3.13.3` (o similar)

### Paso 4: Iniciar el servidor FastAPI
```powershell
python -m uvicorn validador:app --reload --host 127.0.0.1 --port 3000
```
**Resultado esperado:**
```
INFO:     Will watch for changes in these directories: ['C:\\Users\\chelo\\OneDrive\\Escritorio\\tamaprint\\validador-tamaprint - 2.0']
INFO:     Uvicorn running on http://127.0.0.1:3000 (Press CTRL+C to quit)
INFO:     Started reloader process [XXXXX] using StatReload
Iniciando validador...
Catalogo cargado: 10982 registros
...
INFO:     Started server process [XXXXX]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
```

### Paso 5: Verificar que el servidor esté funcionando
**En una nueva terminal PowerShell:**
```powershell
curl http://localhost:3000/health
```
**Resultado esperado:** JSON con status "OK"

### Paso 6: Iniciar ngrok (en una nueva terminal)
**Abrir una nueva ventana de PowerShell y navegar al directorio:**
```powershell
cd "C:\Users\chelo\OneDrive\Escritorio\tamaprint\validador-tamaprint - 2.0"
```

**Ejecutar ngrok:**
```powershell
.\ngrok.exe http 3000
```
**Resultado esperado:**
```
Session Status                online
Account                       [tu cuenta]
Version                       3.x.x
Region                       United States (us)
Web Interface                 http://127.0.0.1:4040
Forwarding                    https://XXXXX.ngrok-free.app -> http://localhost:3000
```

### Paso 7: Verificar que ngrok esté funcionando
**En otra terminal PowerShell:**
```powershell
curl http://localhost:4040/api/tunnels
```
**Resultado esperado:** JSON con información del túnel

## 🔧 Solución de Problemas

### Si el puerto 3000 está ocupado:
```powershell
# Cambiar a puerto 8080
python -m uvicorn validador:app --reload --host 127.0.0.1 --port 8080
# Y actualizar ngrok:
.\ngrok.exe http 8080
```

### Si ngrok da error de autenticación:
```powershell
# Verificar sesiones activas en: https://dashboard.ngrok.com/agents
# Terminar sesiones anteriores si es necesario
```

### Si el entorno virtual no se activa:
```powershell
# Recrear el entorno virtual
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

## 📋 Checklist de Verificación

- [ ] Entorno virtual activado (`.venv`)
- [ ] Servidor FastAPI ejecutándose en puerto 3000
- [ ] Health check responde correctamente
- [ ] Ngrok ejecutándose y exponiendo el puerto
- [ ] URL pública de ngrok funcionando

## 🌐 URLs Finales

- **Local:** `http://localhost:3000`
- **Público:** `https://XXXXX.ngrok-free.app` (la URL cambia cada vez)
- **Panel ngrok:** `http://localhost:4040`

## 🛑 Para detener todo

1. **Servidor FastAPI:** `Ctrl+C` en la terminal donde está ejecutándose
2. **Ngrok:** `Ctrl+C` en la terminal donde está ejecutándose

## 📝 Notas Importantes

- **Siempre activar el entorno virtual** antes de ejecutar el servidor
- **Usar puerto 3000** para evitar conflictos
- **Ngrok requiere una nueva terminal** separada del servidor
- **La URL pública de ngrok cambia** cada vez que se reinicia
- **Verificar siempre** que ambos servicios estén funcionando antes de usar el API 