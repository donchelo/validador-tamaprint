# Instrucciones Rapidas - Validador TamaPrint

## 🚀 Inicio Unificado (NUEVO - V3.0)

### Opción 1: Inicio Automático (RECOMENDADO)
```powershell
# Inicio automático completo
.\iniciar.ps1
```

### Opción 2: Inicio Simple
```powershell
# Inicio rápido sin verificaciones extras
.\iniciar.ps1 simple
```

### Opción 3: Inicio Manual (Paso a Paso)
```powershell
# Control total del proceso
.\iniciar.ps1 manual
```

### Opción 4: Inicio en Primer Plano
```powershell
# Como el antiguo iniciar.bat
.\iniciar.ps1 batch
```

### Opción 5: Solo Verificar Sistema
```powershell
# Verificar sin iniciar
.\iniciar.ps1 -VerificarSolo
```

### Opción 6: Puerto Específico
```powershell
# Usar puerto específico
.\iniciar.ps1 -Puerto 8080
```

### Opción 7: Sin Ngrok (Solo Local)
```powershell
# Solo servidor local
.\iniciar.ps1 -NoNgrok
```

## 📋 Checklist de Verificación

- [ ] Servidor ejecutándose en `http://localhost:8000` (o puerto detectado)
- [ ] Health check responde: `curl http://localhost:8000/health`
- [ ] Ngrok funcionando (si se necesita acceso público)
- [ ] URL pública disponible (si se usa ngrok)

## 🔧 Solución de Problemas

### Error: "Puerto en uso"
```powershell
# El sistema detecta automáticamente puertos disponibles
# O especifica uno manualmente:
.\iniciar.ps1 -Puerto 8080
```

### Error: "Entorno virtual no encontrado"
```powershell
# El sistema instala dependencias automáticamente
# O verifica manualmente:
.\iniciar.ps1 -VerificarSolo
```

### Error: "ngrok no encontrado"
- Descargar ngrok desde: https://ngrok.com/download
- Colocar `ngrok.exe` en la carpeta del proyecto
- O usar modo sin ngrok: `.\iniciar.ps1 -NoNgrok`

## 🌐 URLs Importantes

- **Local:** `http://localhost:8000` (o puerto detectado)
- **Health:** `http://localhost:8000/health`
- **Debug:** `http://localhost:8000/debug-catalogo`
- **Validar:** `POST http://localhost:8000/validar-orden`

## 🛑 Para Detener

1. **Servidor FastAPI:** `Ctrl+C` en la terminal del servidor
2. **Ngrok:** `Ctrl+C` en la terminal de ngrok
3. **Modo automático:** Cerrar la ventana de PowerShell

## 📝 Notas

- **Un solo archivo:** `iniciar.ps1` reemplaza todos los anteriores
- **Detección automática:** Puerto, dependencias y archivos
- **Múltiples modos:** Automático, simple, manual, batch
- **Opciones flexibles:** Puerto específico, sin ngrok, solo verificar
- **Siempre activar el entorno virtual** antes de ejecutar
- **Ngrok requiere una cuenta gratuita** para uso público
- **La URL pública de ngrok cambia** cada vez que se reinicia
- **Verificar siempre** que ambos servicios funcionen antes de usar

## 📞 Soporte

Si tienes problemas:
1. Ejecuta: `.\iniciar.ps1 -VerificarSolo`
2. Revisa la guía completa: `README.md`
3. Verifica que todos los archivos estén presentes
4. Asegúrate de tener Python 3.8+ instalado

## 🔄 Migración desde V2.1

### Archivos Eliminados:
- ❌ `iniciar.bat` → Usar: `.\iniciar.ps1 batch`
- ❌ `iniciar_simple.ps1` → Usar: `.\iniciar.ps1 simple`
- ❌ `iniciar_manual.ps1` → Usar: `.\iniciar.ps1 manual`
- ❌ `iniciar_validador.ps1` → Usar: `.\iniciar.ps1` (automático)

### Nuevo Archivo:
- ✅ `iniciar.ps1` - **UN SOLO ARCHIVO PARA TODO** 