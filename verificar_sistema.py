#!/usr/bin/env python3
"""
Script de verificación del sistema para Validador Tamaprint 2.0
Verifica que todos los componentes estén correctamente instalados y configurados.
"""

import sys
import os
import json
import subprocess
from pathlib import Path

def print_header():
    print("=" * 60)
    print("    VALIDADOR TAMAPRINT 2.0 - VERIFICACIÓN DE SISTEMA")
    print("=" * 60)
    print()

def check_python_version():
    """Verificar versión de Python"""
    print("[CHECK] Verificando Python...")
    version = sys.version_info
    if version.major < 3 or (version.major == 3 and version.minor < 8):
        print(f"   [ERROR] Python {version.major}.{version.minor} detectado. Se requiere Python 3.8+")
        return False
    print(f"   [OK] Python {version.major}.{version.minor}.{version.micro} OK")
    return True

def check_files():
    """Verificar archivos necesarios"""
    print("\n[CHECK] Verificando archivos necesarios...")
    
    required_files = [
        "validador.py",
        "requirements.txt", 
        "credentials.json",
        ".env",
        "ngrok.exe"
    ]
    
    missing_files = []
    for file in required_files:
        if os.path.exists(file):
            print(f"   [OK] {file}")
        else:
            print(f"   [ERROR] {file} - FALTANTE")
            missing_files.append(file)
    
    return len(missing_files) == 0, missing_files

def check_dependencies():
    """Verificar dependencias de Python"""
    print("\n[CHECK] Verificando dependencias...")
    
    required_packages = [
        "fastapi",
        "uvicorn", 
        "pandas",
        "gspread",
        "google-auth",
        "python-dotenv",
        "pydantic"
    ]
    
    missing_packages = []
    for package in required_packages:
        try:
            __import__(package.replace("-", "_"))
            print(f"   [OK] {package}")
        except ImportError:
            print(f"   [ERROR] {package} - NO INSTALADO")
            missing_packages.append(package)
    
    return len(missing_packages) == 0, missing_packages

def check_env_config():
    """Verificar configuración del archivo .env"""
    print("\n[CHECK] Verificando configuración...")
    
    if not os.path.exists(".env"):
        print("   [ERROR] Archivo .env no encontrado")
        return False
    
    with open(".env", "r", encoding="utf-8") as f:
        content = f.read()
    
    # Verificar variables importantes
    required_vars = ["GOOGLE_DRIVE_FILE_ID", "GOOGLE_SHEET_RANGE", "GOOGLE_APPLICATION_CREDENTIALS"]
    issues = []
    
    for var in required_vars:
        if var not in content:
            issues.append(f"Variable {var} no encontrada")
        elif f"{var}=" in content:
            # Extraer valor
            for line in content.split('\n'):
                if line.startswith(f"{var}="):
                    value = line.split('=', 1)[1].strip()
                    if not value or value == "your_value_here":
                        issues.append(f"Variable {var} no tiene un valor válido")
                    else:
                        print(f"   [OK] {var}")
                    break
    
    if issues:
        for issue in issues:
            print(f"   [WARNING] {issue}")
        return False
    
    return True

def check_credentials():
    """Verificar archivo de credenciales"""
    print("\n[CHECK] Verificando credenciales...")
    
    if not os.path.exists("credentials.json"):
        print("   [ERROR] credentials.json no encontrado")
        return False
    
    try:
        with open("credentials.json", "r") as f:
            creds = json.load(f)
        
        required_fields = ["type", "project_id", "private_key", "client_email"]
        for field in required_fields:
            if field in creds:
                print(f"   [OK] {field}")
            else:
                print(f"   [ERROR] Campo '{field}' faltante en credentials.json")
                return False
        
        return True
    except json.JSONDecodeError:
        print("   [ERROR] credentials.json no es un JSON válido")
        return False

def check_ngrok():
    """Verificar ngrok"""
    print("\n[CHECK] Verificando ngrok...")
    
    if not os.path.exists("ngrok.exe"):
        print("   [ERROR] ngrok.exe no encontrado")
        return False
    
    try:
        result = subprocess.run(["ngrok.exe", "version"], 
                              capture_output=True, text=True, timeout=10)
        if result.returncode == 0:
            version = result.stdout.strip().split('\n')[0]
            print(f"   [OK] {version}")
            return True
        else:
            print("   [ERROR] ngrok no responde correctamente")
            return False
    except (subprocess.TimeoutExpired, subprocess.CalledProcessError, FileNotFoundError):
        print("   [ERROR] Error ejecutando ngrok")
        return False

def main():
    print_header()
    
    all_checks = []
    
    # Realizar todas las verificaciones
    all_checks.append(check_python_version())
    
    files_ok, missing_files = check_files()
    all_checks.append(files_ok)
    
    deps_ok, missing_deps = check_dependencies()
    all_checks.append(deps_ok)
    
    all_checks.append(check_env_config())
    all_checks.append(check_credentials())
    all_checks.append(check_ngrok())
    
    # Resumen final
    print("\n" + "=" * 60)
    if all(all_checks):
        print("[SUCCESS] SISTEMA VERIFICADO CORRECTAMENTE!")
        print("   Todos los componentes están listos.")
        print("   Puedes ejecutar 'iniciar_validador.bat' con confianza.")
    else:
        print("[WARNING] PROBLEMAS DETECTADOS:")
        if not files_ok:
            print(f"   - Archivos faltantes: {', '.join(missing_files)}")
        if not deps_ok:
            print(f"   - Dependencias faltantes: {', '.join(missing_deps)}")
            print("   - Ejecuta: pip install -r requirements.txt")
        
        print("\n   Resuelve estos problemas antes de continuar.")
    
    print("=" * 60)
    input("\nPresiona Enter para salir...")

if __name__ == "__main__":
    main()