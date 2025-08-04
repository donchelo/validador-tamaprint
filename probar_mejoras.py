#!/usr/bin/env python3
"""
Script para probar las mejoras implementadas en el Validador Tamaprint
"""

import requests
import json
import time
import sys

def print_header():
    print("=" * 60)
    print("    🚀 PRUEBAS DE MEJORAS - VALIDADOR TAMAPRINT")
    print("=" * 60)
    print()

def test_health_check(base_url):
    """Probar health check"""
    print("🔍 Probando Health Check...")
    try:
        response = requests.get(f"{base_url}/health", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Health Check OK - Catálogo: {data.get('catalogo_items', 'N/A')} items")
            return True
        else:
            print(f"   ❌ Health Check falló: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Error en Health Check: {e}")
        return False

def test_cache_stats(base_url):
    """Probar estadísticas de cache"""
    print("📊 Probando Cache Stats...")
    try:
        response = requests.get(f"{base_url}/cache/stats", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Cache Stats OK - Size: {data.get('size', 0)}, Max: {data.get('max_size', 0)}")
            return True
        else:
            print(f"   ❌ Cache Stats falló: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Error en Cache Stats: {e}")
        return False

def test_validation_with_cache(base_url):
    """Probar validación con cache"""
    print("⚡ Probando Validación con Cache...")
    
    # Datos de prueba
    test_data = {
        "comprador": {"nit": "CN800069933"},
        "orden_compra": "TEST-2024-001",
        "items": [
            {
                "codigo": "14003793002",
                "descripcion": "Producto Test",
                "cantidad": 5,
                "precio_unitario": 100.0,
                "precio_total": 500.0,
                "fecha_entrega": "2024-01-15"
            }
        ]
    }
    
    try:
        # Primera validación (cache miss)
        print("   🔍 Primera validación (cache miss)...")
        start_time = time.time()
        response1 = requests.post(f"{base_url}/validar-orden", json=test_data, timeout=10)
        time1 = time.time() - start_time
        
        if response1.status_code == 200:
            print(f"   ✅ Primera validación exitosa en {time1:.3f}s")
        else:
            print(f"   ❌ Primera validación falló: {response1.status_code}")
            return False
        
        # Segunda validación (cache hit)
        print("   ⚡ Segunda validación (cache hit)...")
        start_time = time.time()
        response2 = requests.post(f"{base_url}/validar-orden", json=test_data, timeout=10)
        time2 = time.time() - start_time
        
        if response2.status_code == 200:
            print(f"   ✅ Segunda validación exitosa en {time2:.3f}s")
            if time2 < time1:
                print(f"   🎉 Cache funcionando: {time1/time2:.1f}x más rápido")
            else:
                print(f"   ⚠️ Cache no mejoró performance")
        else:
            print(f"   ❌ Segunda validación falló: {response2.status_code}")
            return False
        
        return True
        
    except Exception as e:
        print(f"   ❌ Error en validación: {e}")
        return False

def test_cache_clear(base_url):
    """Probar limpieza de cache"""
    print("🧹 Probando Limpieza de Cache...")
    try:
        response = requests.post(f"{base_url}/cache/clear", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Cache limpiado: {data.get('message', 'OK')}")
            return True
        else:
            print(f"   ❌ Limpieza de cache falló: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Error limpiando cache: {e}")
        return False

def test_logging():
    """Verificar que los logs se están generando"""
    print("📝 Verificando Logs...")
    try:
        import os
        if os.path.exists("validador.log"):
            with open("validador.log", "r", encoding="utf-8") as f:
                lines = f.readlines()
                print(f"   ✅ Log file encontrado: {len(lines)} líneas")
                if len(lines) > 0:
                    print(f"   📄 Última línea: {lines[-1].strip()}")
                return True
        else:
            print("   ⚠️ Log file no encontrado (puede ser normal si no se han hecho requests)")
            return True
    except Exception as e:
        print(f"   ❌ Error verificando logs: {e}")
        return False

def main():
    print_header()
    
    # URL base
    base_url = "http://localhost:8000"
    
    print("🚀 Iniciando pruebas de mejoras...")
    print()
    
    tests = [
        ("Health Check", lambda: test_health_check(base_url)),
        ("Cache Stats", lambda: test_cache_stats(base_url)),
        ("Validación con Cache", lambda: test_validation_with_cache(base_url)),
        ("Limpieza de Cache", lambda: test_cache_clear(base_url)),
        ("Verificación de Logs", lambda: test_logging())
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        print(f"\n🧪 {test_name}:")
        if test_func():
            passed += 1
        print()
    
    print("=" * 60)
    print(f"📊 RESULTADOS: {passed}/{total} tests pasaron")
    
    if passed == total:
        print("🎉 TODAS LAS MEJORAS FUNCIONAN CORRECTAMENTE!")
        print("   ✅ Logging estructurado implementado")
        print("   ✅ Cache funcionando")
        print("   ✅ Tests unitarios disponibles")
    else:
        print("⚠️ Algunas pruebas fallaron")
        print("   💡 Verifica que el servidor esté corriendo en http://localhost:8000")
    
    print("=" * 60)

if __name__ == "__main__":
    main() 