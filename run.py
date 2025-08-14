#!/usr/bin/env python3
"""
Script principal para ejecutar el Validador TamaPrint
Usa la nueva estructura organizada del proyecto
"""

import sys
import os
import argparse
from pathlib import Path

# Agregar el directorio src al path
project_root = Path(__file__).parent
src_path = project_root / "src"
sys.path.insert(0, str(src_path))

def main():
    parser = argparse.ArgumentParser(
        description="Validador TamaPrint - Script de inicio",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  python run.py                    # Inicio normal
  python run.py --port 8080       # Puerto específico
  python run.py --host 127.0.0.1  # Host específico
  python run.py --reload          # Modo desarrollo con recarga
        """
    )
    
    parser.add_argument(
        "--host", 
        default="0.0.0.0",
        help="Host para el servidor (default: 0.0.0.0)"
    )
    
    parser.add_argument(
        "--port", 
        type=int, 
        default=8000,
        help="Puerto para el servidor (default: 8000)"
    )
    
    parser.add_argument(
        "--reload", 
        action="store_true",
        help="Habilitar recarga automática (modo desarrollo)"
    )
    
    parser.add_argument(
        "--log-level", 
        default="info",
        choices=["debug", "info", "warning", "error"],
        help="Nivel de logging (default: info)"
    )
    
    args = parser.parse_args()
    
    # Verificar que el módulo principal existe
    validador_path = src_path / "validador.py"
    if not validador_path.exists():
        print(f"❌ Error: No se encuentra el archivo principal en {validador_path}")
        print("   Asegúrate de que la estructura del proyecto esté correcta")
        sys.exit(1)
    
    # Configurar argumentos para uvicorn
    uvicorn_args = [
        "src.validador:app",
        "--host", args.host,
        "--port", str(args.port),
        "--log-level", args.log_level
    ]
    
    if args.reload:
        uvicorn_args.append("--reload")
    
    print("🚀 Iniciando Validador TamaPrint...")
    print(f"   Host: {args.host}")
    print(f"   Puerto: {args.port}")
    print(f"   Modo: {'Desarrollo' if args.reload else 'Producción'}")
    print(f"   Log Level: {args.log_level}")
    print()
    
    try:
        import uvicorn
        uvicorn.run(*uvicorn_args)
    except ImportError:
        print("❌ Error: uvicorn no está instalado")
        print("   Ejecuta: pip install -r requirements.txt")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\n👋 Servidor detenido por el usuario")
    except Exception as e:
        print(f"❌ Error al iniciar el servidor: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
