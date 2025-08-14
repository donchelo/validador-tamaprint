#!/usr/bin/env python3
"""
Verificación básica del sistema Validador Tamaprint
"""

import sys
import os
import subprocess

def print_header():
    print("=" * 50)
    print("    VERIFICACIÓN BÁSICA DEL SISTEMA")
    print("=" * 50)
    print()

def check_python():
    """Verificar Python"""
    print("[CHECK] Verificando Python...")
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        print(f"   ❌ Python {version.major}.{version.minor} - Se requiere Python 3.8+")
        return False
    print(f"   ✅ Python {version.major}.{version.minor}.{version.micro}")
    return True

def check_files():
    """Verificar archivos esenciales"""
    print("\n[CHECK] Verificando archivos...")
    
    required_files = ["src/validador.py", "requirements.txt"]
    optional_files = [".env", "credentials.json", "config/ngrok.exe"]
    
    all_ok = True
    
    for file in required_files:
        if os.path.exists(file):
            print(f"   ✅ {file}")
        else:
            print(f"   ❌ {file} - FALTANTE")
            all_ok = False
    
    for file in optional_files:
        if os.path.exists(file):
            print(f"   ✅ {file}")
        else:
            print(f"   ⚠️  {file} - Opcional")
    
    return all_ok

def check_dependencies():
    """Verificar dependencias básicas"""
    print("\n[CHECK] Verificando dependencias...")
    
    # Mapeo de nombres de paquetes a módulos de importación
    package_mapping = {
        "fastapi": "fastapi",
        "uvicorn": "uvicorn", 
        "pandas": "pandas",
        "gspread": "gspread",
        "google-auth": "google.auth",
        "python-dotenv": "dotenv",
        "pydantic": "pydantic"
    }
    
    missing_packages = []
    for package, module in package_mapping.items():
        try:
            __import__(module)
            print(f"   ✅ {package}")
        except ImportError:
            print(f"   ❌ {package} - NO INSTALADO")
            missing_packages.append(package)
    
    if missing_packages:
        print(f"\n   💡 Instalar dependencias: pip install -r requirements.txt")
        return False
    
    return True

def main():
    print_header()
    
    checks = []
    checks.append(check_python())
    checks.append(check_files())
    checks.append(check_dependencies())
    
    print("\n" + "=" * 50)
    if all(checks):
        print("✅ SISTEMA LISTO!")
        print("   Ejecuta: python -m uvicorn src.validador:app --host 0.0.0.0 --port 8000")
    else:
        print("❌ PROBLEMAS DETECTADOS:")
        print("   - Instala dependencias: pip install -r requirements.txt")
        print("   - Verifica que todos los archivos estén presentes")
    
    print("=" * 50)

if __name__ == "__main__":
    main()