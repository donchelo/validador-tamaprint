#!/usr/bin/env python3
"""
Script para ejecutar tests unitarios del Validador Tamaprint
"""

import subprocess
import sys
import os

def print_header():
    print("=" * 60)
    print("    🧪 TESTS UNITARIOS - VALIDADOR TAMAPRINT")
    print("=" * 60)
    print()

def run_tests():
    """Ejecutar tests con pytest"""
    print("🔍 Ejecutando tests unitarios...")
    print()
    
    try:
        # Ejecutar pytest con formato verbose
        result = subprocess.run([
            sys.executable, "-m", "pytest", 
            "test_validador.py", 
            "-v", 
            "--tb=short"
        ], capture_output=True, text=True, timeout=60)
        
        print("📊 RESULTADOS DE LOS TESTS:")
        print("-" * 40)
        
        if result.returncode == 0:
            print("✅ TODOS LOS TESTS PASARON")
            print("🎉 El código está funcionando correctamente")
        else:
            print("❌ ALGUNOS TESTS FALLARON")
            print("🔧 Revisa los errores abajo")
        
        print()
        print("📝 OUTPUT DETALLADO:")
        print("-" * 40)
        print(result.stdout)
        
        if result.stderr:
            print("⚠️ ERRORES:")
            print("-" * 40)
            print(result.stderr)
        
        return result.returncode == 0
        
    except subprocess.TimeoutExpired:
        print("⏰ Timeout: Los tests tardaron demasiado")
        return False
    except FileNotFoundError:
        print("❌ Error: pytest no está instalado")
        print("💡 Ejecuta: pip install pytest")
        return False
    except Exception as e:
        print(f"❌ Error ejecutando tests: {e}")
        return False

def check_dependencies():
    """Verificar que las dependencias estén instaladas"""
    print("🔍 Verificando dependencias...")
    
    required_packages = ["pytest", "pandas", "fastapi"]
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package)
            print(f"   ✅ {package}")
        except ImportError:
            print(f"   ❌ {package} - NO INSTALADO")
            missing_packages.append(package)
    
    if missing_packages:
        print(f"\n💡 Instalar dependencias faltantes:")
        print(f"   pip install {' '.join(missing_packages)}")
        return False
    
    print("✅ Todas las dependencias están instaladas")
    return True

def main():
    print_header()
    
    # Verificar dependencias
    if not check_dependencies():
        print("\n❌ Instala las dependencias antes de ejecutar los tests")
        return
    
    print()
    
    # Ejecutar tests
    success = run_tests()
    
    print("\n" + "=" * 60)
    if success:
        print("🎉 TESTS COMPLETADOS EXITOSAMENTE")
        print("   El código está listo para producción")
    else:
        print("❌ TESTS FALLARON")
        print("   Revisa los errores y corrige el código")
    print("=" * 60)

if __name__ == "__main__":
    main() 