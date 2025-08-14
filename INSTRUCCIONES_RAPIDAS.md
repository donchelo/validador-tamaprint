# Instrucciones Rapidas - Validador TamaPrint

## Inicio Rapido (Recomendado)

### Opcion 1: Script Simple (MAS FACIL)
```powershell
# Ejecutar el nuevo script simple
.\iniciar_simple.ps1
```

### Opcion 2: Archivo Batch (Sin Unicode)
```cmd
# Doble click en el archivo o ejecutar:
iniciar.bat
```

### Opcion 3: Comandos Manuales
```powershell
# 1. Activar entorno virtual
.\.venv\Scripts\Activate.ps1

# 2. Iniciar servidor
python -m uvicorn validador:app --reload --host 127.0.0.1 --port 3000

# 3. En otra terminal: iniciar ngrok
.\ngrok.exe http 3000
```

## 📋 Checklist de Verificación

- [ ] Servidor ejecutándose en `http://localhost:3000`
- [ ] Health check responde: `curl http://localhost:3000/health`
- [ ] Ngrok funcionando (si se necesita acceso público)
- [ ] URL pública disponible (si se usa ngrok)

## 🔧 Solución de Problemas

### Error: "Puerto en uso"
```powershell
# Cambiar puerto
python -m uvicorn validador:app --reload --host 127.0.0.1 --port 8080
```

### Error: "Entorno virtual no encontrado"
```powershell
# Recrear entorno virtual
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### Error: "ngrok no encontrado"
- Descargar ngrok desde: https://ngrok.com/download
- Colocar `ngrok.exe` en la carpeta del proyecto

## 🌐 URLs Importantes

- **Local:** `http://localhost:3000`
- **Health:** `http://localhost:3000/health`
- **Debug:** `http://localhost:3000/debug-catalogo`
- **Validar:** `POST http://localhost:3000/validar-orden`

## 🛑 Para Detener

1. **Servidor FastAPI:** `Ctrl+C` en la terminal del servidor
2. **Ngrok:** `Ctrl+C` en la terminal de ngrok

## 📝 Notas

- **Siempre activar el entorno virtual** antes de ejecutar
- **Ngrok requiere una cuenta gratuita** para uso público
- **La URL pública de ngrok cambia** cada vez que se reinicia
- **Verificar siempre** que ambos servicios funcionen antes de usar

## 📞 Soporte

Si tienes problemas:
1. Revisa la guía completa: `GUIA_INICIO.md`
2. Verifica que todos los archivos estén presentes
3. Asegúrate de tener Python 3.8+ instalado 