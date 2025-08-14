#!/usr/bin/env python3
"""
Test Suite para el Iniciador Unificado - Validador TamaPrint V3.0
Pruebas automatizadas del nuevo sistema de inicio unificado
"""

import subprocess
import time
import requests
import json
import os
import sys
import signal
import psutil
from datetime import datetime

class TestIniciadorUnificado:
    def __init__(self):
        self.test_results = []
        self.current_test = 0
        self.total_tests = 0
        self.powershell_processes = []
        self.python_processes = []
        self.ngrok_processes = []
        
    def print_header(self, message):
        print("=" * 60)
        print(f"    {message}")
        print("=" * 60)
        print()
        
    def print_test(self, test_name, status="RUNNING"):
        self.current_test += 1
        status_emoji = {
            "RUNNING": "🔄",
            "PASS": "✅",
            "FAIL": "❌",
            "SKIP": "⏭️"
        }
        print(f"{status_emoji[status]} [{self.current_test}/{self.total_tests}] {test_name}")
        
    def log_result(self, test_name, status, details=""):
        result = {
            "test": test_name,
            "status": status,
            "details": details,
            "timestamp": datetime.now().isoformat()
        }
        self.test_results.append(result)
        
        if status == "PASS":
            print(f"    ✅ PASÓ: {details}")
        elif status == "FAIL":
            print(f"    ❌ FALLÓ: {details}")
        elif status == "SKIP":
            print(f"    ⏭️ OMITIDO: {details}")
        print()
        
    def cleanup_processes(self):
        """Limpiar todos los procesos relacionados"""
        print("🧹 Limpiando procesos...")
        
        # Detener procesos de PowerShell que ejecuten iniciar.ps1
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                if proc.info['name'] == 'powershell.exe':
                    cmdline = ' '.join(proc.info['cmdline'] or [])
                    if 'iniciar.ps1' in cmdline:
                        print(f"    Deteniendo PowerShell (iniciar.ps1): {proc.info['pid']}")
                        proc.terminate()
                        proc.wait(timeout=5)
            except (psutil.NoSuchProcess, psutil.TimeoutExpired):
                pass
                
        # Detener procesos de Python (uvicorn)
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                if proc.info['name'] == 'python.exe':
                    cmdline = ' '.join(proc.info['cmdline'] or [])
                    if 'uvicorn' in cmdline or 'validador' in cmdline:
                        print(f"    Deteniendo Python (uvicorn): {proc.info['pid']}")
                        proc.terminate()
                        proc.wait(timeout=5)
            except (psutil.NoSuchProcess, psutil.TimeoutExpired):
                pass
                
        # Detener procesos de ngrok
        for proc in psutil.process_iter(['pid', 'name']):
            try:
                if proc.info['name'] == 'ngrok.exe':
                    print(f"    Deteniendo ngrok: {proc.info['pid']}")
                    proc.terminate()
                    proc.wait(timeout=5)
            except (psutil.NoSuchProcess, psutil.TimeoutExpired):
                pass
                
        time.sleep(3)
        print("✅ Limpieza completada")
        print()
        
    def test_1_archivo_existe(self):
        """Test 1: Verificar que iniciar.ps1 existe"""
        self.print_test("Verificar que iniciar.ps1 existe")
        
        if os.path.exists("iniciar.ps1"):
            self.log_result("Archivo iniciar.ps1", "PASS", "Archivo encontrado correctamente")
            return True
        else:
            self.log_result("Archivo iniciar.ps1", "FAIL", "Archivo no encontrado")
            return False
            
    def test_2_archivos_eliminados(self):
        """Test 2: Verificar que los archivos antiguos fueron eliminados"""
        self.print_test("Verificar eliminación de archivos antiguos")
        
        archivos_eliminados = [
            "iniciar.bat",
            "iniciar_simple.ps1", 
            "iniciar_manual.ps1",
            "iniciar_validador.ps1"
        ]
        
        archivos_presentes = []
        for archivo in archivos_eliminados:
            if os.path.exists(archivo):
                archivos_presentes.append(archivo)
                
        if not archivos_presentes:
            self.log_result("Archivos eliminados", "PASS", "Todos los archivos antiguos fueron eliminados")
            return True
        else:
            self.log_result("Archivos eliminados", "FAIL", f"Archivos aún presentes: {', '.join(archivos_presentes)}")
            return False
            
    def test_3_ayuda_funciona(self):
        """Test 3: Verificar que la ayuda funciona"""
        self.print_test("Verificar funcionamiento de la ayuda")
        
        try:
            result = subprocess.run(
                ["powershell", "-ExecutionPolicy", "Bypass", "-File", "iniciar.ps1", "-h"],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            if result.returncode == 0 and "AYUDA" in result.stdout:
                self.log_result("Ayuda", "PASS", "Comando de ayuda funciona correctamente")
                return True
            else:
                self.log_result("Ayuda", "FAIL", f"Error en ayuda: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            self.log_result("Ayuda", "FAIL", "Timeout en comando de ayuda")
            return False
        except Exception as e:
            self.log_result("Ayuda", "FAIL", f"Excepción: {str(e)}")
            return False
            
    def test_4_verificar_solo(self):
        """Test 4: Verificar modo -VerificarSolo"""
        self.print_test("Verificar modo -VerificarSolo")
        
        try:
            result = subprocess.run(
                ["powershell", "-ExecutionPolicy", "Bypass", "-File", "iniciar.ps1", "-VerificarSolo"],
                capture_output=True,
                text=True,
                timeout=60
            )
            
            if result.returncode == 0 and "SISTEMA VERIFICADO" in result.stdout:
                self.log_result("VerificarSolo", "PASS", "Verificación del sistema exitosa")
                return True
            else:
                self.log_result("VerificarSolo", "FAIL", f"Error en verificación: {result.stderr}")
                return False
                
        except subprocess.TimeoutExpired:
            self.log_result("VerificarSolo", "FAIL", "Timeout en verificación")
            return False
        except Exception as e:
            self.log_result("VerificarSolo", "FAIL", f"Excepción: {str(e)}")
            return False
            
    def test_5_modo_batch(self):
        """Test 5: Verificar modo batch (inicio en primer plano)"""
        self.print_test("Verificar modo batch")
        
        try:
            # Iniciar en modo batch
            process = subprocess.Popen(
                ["powershell", "-ExecutionPolicy", "Bypass", "-File", "iniciar.ps1", "batch", "-Puerto", "8001"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            # Esperar un poco para que inicie
            time.sleep(10)
            
            # Verificar si el proceso sigue corriendo
            if process.poll() is None:
                # Verificar si el servidor responde
                try:
                    response = requests.get("http://localhost:8001/health", timeout=10)
                    if response.status_code == 200:
                        self.log_result("Modo batch", "PASS", "Servidor iniciado correctamente en modo batch")
                        process.terminate()
                        process.wait(timeout=10)
                        return True
                    else:
                        process.terminate()
                        self.log_result("Modo batch", "FAIL", f"Servidor no responde correctamente: {response.status_code}")
                        return False
                except requests.exceptions.RequestException:
                    process.terminate()
                    self.log_result("Modo batch", "FAIL", "No se pudo conectar al servidor")
                    return False
            else:
                stdout, stderr = process.communicate()
                self.log_result("Modo batch", "FAIL", f"Proceso terminó prematuramente: {stderr}")
                return False
                
        except Exception as e:
            self.log_result("Modo batch", "FAIL", f"Excepción: {str(e)}")
            return False
            
    def test_6_modo_simple(self):
        """Test 6: Verificar modo simple"""
        self.print_test("Verificar modo simple")
        
        try:
            # Iniciar en modo simple
            process = subprocess.Popen(
                ["powershell", "-ExecutionPolicy", "Bypass", "-File", "iniciar.ps1", "simple", "-Puerto", "8002"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            # Esperar para que inicie
            time.sleep(20)
            
            # Verificar si el proceso sigue corriendo
            if process.poll() is None:
                # Verificar si el servidor responde
                try:
                    response = requests.get("http://localhost:8002/health", timeout=10)
                    if response.status_code == 200:
                        self.log_result("Modo simple", "PASS", "Servidor iniciado correctamente en modo simple")
                        process.terminate()
                        process.wait(timeout=10)
                        return True
                    else:
                        process.terminate()
                        self.log_result("Modo simple", "FAIL", f"Servidor no responde correctamente: {response.status_code}")
                        return False
                except requests.exceptions.RequestException:
                    process.terminate()
                    self.log_result("Modo simple", "FAIL", "No se pudo conectar al servidor")
                    return False
            else:
                stdout, stderr = process.communicate()
                self.log_result("Modo simple", "FAIL", f"Proceso terminó prematuramente: {stderr}")
                return False
                
        except Exception as e:
            self.log_result("Modo simple", "FAIL", f"Excepción: {str(e)}")
            return False
            
    def test_7_modo_sin_ngrok(self):
        """Test 7: Verificar modo sin ngrok"""
        self.print_test("Verificar modo sin ngrok")
        
        try:
            # Iniciar sin ngrok
            process = subprocess.Popen(
                ["powershell", "-ExecutionPolicy", "Bypass", "-File", "iniciar.ps1", "-NoNgrok", "-Puerto", "8003"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            # Esperar para que inicie
            time.sleep(20)
            
            # Verificar si el proceso sigue corriendo
            if process.poll() is None:
                # Verificar si el servidor responde
                try:
                    response = requests.get("http://localhost:8003/health", timeout=10)
                    if response.status_code == 200:
                        self.log_result("Modo sin ngrok", "PASS", "Servidor iniciado correctamente sin ngrok")
                        process.terminate()
                        process.wait(timeout=10)
                        return True
                    else:
                        process.terminate()
                        self.log_result("Modo sin ngrok", "FAIL", f"Servidor no responde correctamente: {response.status_code}")
                        return False
                except requests.exceptions.RequestException:
                    process.terminate()
                    self.log_result("Modo sin ngrok", "FAIL", "No se pudo conectar al servidor")
                    return False
            else:
                stdout, stderr = process.communicate()
                self.log_result("Modo sin ngrok", "FAIL", f"Proceso terminó prematuramente: {stderr}")
                return False
                
        except Exception as e:
            self.log_result("Modo sin ngrok", "FAIL", f"Excepción: {str(e)}")
            return False
            
    def test_8_deteccion_puerto(self):
        """Test 8: Verificar detección automática de puerto"""
        self.print_test("Verificar detección automática de puerto")
        
        try:
            # Iniciar sin especificar puerto
            process = subprocess.Popen(
                ["powershell", "-ExecutionPolicy", "Bypass", "-File", "iniciar.ps1", "simple", "-NoNgrok"],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            # Esperar para que inicie
            time.sleep(20)
            
            # Verificar si el proceso sigue corriendo
            if process.poll() is None:
                # Buscar en qué puerto está corriendo
                for port in range(8000, 8010):
                    try:
                        response = requests.get(f"http://localhost:{port}/health", timeout=5)
                        if response.status_code == 200:
                            self.log_result("Detección de puerto", "PASS", f"Puerto detectado automáticamente: {port}")
                            process.terminate()
                            process.wait(timeout=10)
                            return True
                    except requests.exceptions.RequestException:
                        continue
                        
                process.terminate()
                self.log_result("Detección de puerto", "FAIL", "No se pudo detectar el puerto automáticamente")
                return False
            else:
                stdout, stderr = process.communicate()
                self.log_result("Detección de puerto", "FAIL", f"Proceso terminó prematuramente: {stderr}")
                return False
                
        except Exception as e:
            self.log_result("Detección de puerto", "FAIL", f"Excepción: {str(e)}")
            return False
            
    def test_9_parametros_invalidos(self):
        """Test 9: Verificar manejo de parámetros inválidos"""
        self.print_test("Verificar manejo de parámetros inválidos")
        
        try:
            result = subprocess.run(
                ["powershell", "-ExecutionPolicy", "Bypass", "-File", "iniciar.ps1", "modo_invalido"],
                capture_output=True,
                text=True,
                timeout=30
            )
            
            # Debería fallar con parámetro inválido
            if result.returncode != 0:
                self.log_result("Parámetros inválidos", "PASS", "Manejo correcto de parámetros inválidos")
                return True
            else:
                self.log_result("Parámetros inválidos", "FAIL", "No se detectó el parámetro inválido")
                return False
                
        except subprocess.TimeoutExpired:
            self.log_result("Parámetros inválidos", "FAIL", "Timeout en prueba de parámetros inválidos")
            return False
        except Exception as e:
            self.log_result("Parámetros inválidos", "FAIL", f"Excepción: {str(e)}")
            return False
            
    def test_10_documentacion_actualizada(self):
        """Test 10: Verificar que la documentación fue actualizada"""
        self.print_test("Verificar documentación actualizada")
        
        archivos_doc = [
            "INSTRUCCIONES_RAPIDAS.md",
            "UNIFICACION_V3.0.md"
        ]
        
        archivos_faltantes = []
        for archivo in archivos_doc:
            if not os.path.exists(archivo):
                archivos_faltantes.append(archivo)
                
        if not archivos_faltantes:
            # Verificar contenido de INSTRUCCIONES_RAPIDAS.md
            try:
                with open("INSTRUCCIONES_RAPIDAS.md", "r", encoding="utf-8") as f:
                    contenido = f.read()
                    if "iniciar.ps1" in contenido and "V3.0" in contenido:
                        self.log_result("Documentación", "PASS", "Documentación actualizada correctamente")
                        return True
                    else:
                        self.log_result("Documentación", "FAIL", "Contenido de documentación no actualizado")
                        return False
            except Exception as e:
                self.log_result("Documentación", "FAIL", f"Error leyendo documentación: {str(e)}")
                return False
        else:
            self.log_result("Documentación", "FAIL", f"Archivos de documentación faltantes: {', '.join(archivos_faltantes)}")
            return False
            
    def run_all_tests(self):
        """Ejecutar todas las pruebas"""
        self.print_header("TEST SUITE - INICIADOR UNIFICADO V3.0")
        
        # Definir todas las pruebas
        tests = [
            ("Verificar archivo iniciar.ps1", self.test_1_archivo_existe),
            ("Verificar archivos eliminados", self.test_2_archivos_eliminados),
            ("Verificar ayuda", self.test_3_ayuda_funciona),
            ("Verificar modo -VerificarSolo", self.test_4_verificar_solo),
            ("Verificar modo batch", self.test_5_modo_batch),
            ("Verificar modo simple", self.test_6_modo_simple),
            ("Verificar modo sin ngrok", self.test_7_modo_sin_ngrok),
            ("Verificar detección de puerto", self.test_8_deteccion_puerto),
            ("Verificar parámetros inválidos", self.test_9_parametros_invalidos),
            ("Verificar documentación", self.test_10_documentacion_actualizada)
        ]
        
        self.total_tests = len(tests)
        passed_tests = 0
        
        print(f"🚀 Iniciando {self.total_tests} pruebas del sistema unificado...")
        print()
        
        # Limpiar procesos antes de empezar
        self.cleanup_processes()
        
        # Ejecutar cada prueba
        for test_name, test_func in tests:
            try:
                if test_func():
                    passed_tests += 1
                time.sleep(2)  # Pausa entre pruebas
            except Exception as e:
                self.log_result(test_name, "FAIL", f"Error inesperado: {str(e)}")
                
        # Mostrar resultados finales
        self.print_header("RESULTADOS FINALES")
        
        print(f"📊 Resumen de pruebas:")
        print(f"   Total: {self.total_tests}")
        print(f"   Pasaron: {passed_tests}")
        print(f"   Fallaron: {self.total_tests - passed_tests}")
        print(f"   Porcentaje de éxito: {(passed_tests/self.total_tests)*100:.1f}%")
        print()
        
        if passed_tests == self.total_tests:
            print("🎉 ¡TODAS LAS PRUEBAS PASARON! El sistema unificado funciona perfectamente.")
        elif passed_tests >= self.total_tests * 0.8:
            print("✅ La mayoría de las pruebas pasaron. El sistema funciona correctamente.")
        else:
            print("⚠️ Varias pruebas fallaron. Revisar el sistema.")
            
        print()
        
        # Mostrar detalles de pruebas fallidas
        failed_tests = [r for r in self.test_results if r["status"] == "FAIL"]
        if failed_tests:
            print("❌ Pruebas que fallaron:")
            for test in failed_tests:
                print(f"   • {test['test']}: {test['details']}")
            print()
            
        # Guardar resultados en archivo
        self.save_results()
        
        # Limpiar al final
        self.cleanup_processes()
        
    def save_results(self):
        """Guardar resultados en archivo JSON"""
        try:
            with open("test_results_unificado.json", "w", encoding="utf-8") as f:
                json.dump({
                    "timestamp": datetime.now().isoformat(),
                    "total_tests": self.total_tests,
                    "passed_tests": len([r for r in self.test_results if r["status"] == "PASS"]),
                    "failed_tests": len([r for r in self.test_results if r["status"] == "FAIL"]),
                    "results": self.test_results
                }, f, indent=2, ensure_ascii=False)
            print("📄 Resultados guardados en: test_results_unificado.json")
        except Exception as e:
            print(f"⚠️ No se pudieron guardar los resultados: {str(e)}")

def main():
    """Función principal"""
    print("🧪 TEST SUITE - VALIDADOR TAMAPRINT V3.0")
    print("   Sistema de Inicio Unificado")
    print()
    
    # Verificar dependencias
    try:
        import requests
        import psutil
    except ImportError as e:
        print(f"❌ Error: Faltan dependencias: {e}")
        print("   Instalar: pip install requests psutil")
        return
        
    # Crear y ejecutar tests
    tester = TestIniciadorUnificado()
    tester.run_all_tests()

if __name__ == "__main__":
    main()
