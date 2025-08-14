"""
Configuración centralizada del proyecto Validador TamaPrint
"""

import os
from pathlib import Path

# Rutas del proyecto
PROJECT_ROOT = Path(__file__).parent.parent
SRC_DIR = PROJECT_ROOT / "src"
LOGS_DIR = PROJECT_ROOT / "logs"
CONFIG_DIR = PROJECT_ROOT / "config"
TESTS_DIR = PROJECT_ROOT / "tests"
SCRIPTS_DIR = PROJECT_ROOT / "scripts"
DOCS_DIR = PROJECT_ROOT / "docs"

# Configuración del servidor
DEFAULT_PORT = 8000
DEFAULT_HOST = "0.0.0.0"

# Configuración de logging
LOG_FILE = LOGS_DIR / "validador.log"
LOG_LEVEL = "INFO"

# Configuración de ngrok
NGROK_EXE = CONFIG_DIR / "ngrok.exe"

# Configuración de archivos
REQUIREMENTS_FILE = PROJECT_ROOT / "requirements.txt"
ENV_FILE = PROJECT_ROOT / ".env"
CREDENTIALS_FILE = PROJECT_ROOT / "credentials.json"

# Configuración de la aplicación
APP_NAME = "Validador TamaPrint"
APP_VERSION = "3.0"
APP_DESCRIPTION = "Validador de órdenes de compra que verifica artículos contra un catálogo en Google Sheets"

# Configuración de cache
CACHE_MAX_SIZE = 1000
CACHE_TTL_SECONDS = 3600

# Configuración de Google Sheets
GOOGLE_SHEET_RANGE = "Hoja1!A:Z"

# URLs de la aplicación
HEALTH_ENDPOINT = "/health"
DEBUG_ENDPOINT = "/debug-catalogo"
VALIDATE_ENDPOINT = "/validar-orden"
DOCS_ENDPOINT = "/docs"

def ensure_directories():
    """Asegurar que todos los directorios necesarios existan"""
    directories = [LOGS_DIR, CONFIG_DIR, SRC_DIR, TESTS_DIR, SCRIPTS_DIR, DOCS_DIR]
    for directory in directories:
        directory.mkdir(exist_ok=True)

def get_ngrok_path():
    """Obtener la ruta al ejecutable de ngrok"""
    return str(NGROK_EXE)

def get_log_file_path():
    """Obtener la ruta al archivo de log"""
    return str(LOG_FILE)

def get_src_module_path():
    """Obtener la ruta al módulo principal"""
    return str(SRC_DIR)
