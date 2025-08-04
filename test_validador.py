#!/usr/bin/env python3
"""
Tests unitarios para Validador Tamaprint
"""

import pytest
import pandas as pd
from unittest.mock import Mock, patch, MagicMock
import sys
import os

# Agregar el directorio actual al path para importar el módulo
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from validador import (
    ItemModel, 
    CompradorModel, 
    OrdenModel, 
    ValidadorOrdenesCompra
)

# Datos de prueba
CATALOGO_TEST = pd.DataFrame({
    'Código SN': ['CN800069933', 'CN800069933', 'CN800069934'],
    'Nº catálogo SN': ['14003793002', '14003793003', '14003793004'],
    'Descripción': ['Producto 1', 'Producto 2', 'Producto 3'],
    'Precio': [100.0, 200.0, 300.0]
})

class TestItemModel:
    """Tests para el modelo ItemModel"""
    
    def test_item_valido(self):
        """Test: Item válido"""
        item = ItemModel(
            codigo="14003793002",
            descripcion="Producto Test",
            cantidad=5,
            precio_unitario=100.0,
            precio_total=500.0,
            fecha_entrega="2024-01-15"
        )
        assert item.codigo == "14003793002"
        assert item.cantidad == 5
        assert item.precio_unitario == 100.0
    
    def test_cantidad_negativa(self):
        """Test: Cantidad negativa debe fallar"""
        with pytest.raises(ValueError, match="La cantidad debe ser mayor a 0"):
            ItemModel(
                codigo="14003793002",
                descripcion="Producto Test",
                cantidad=-1,
                precio_unitario=100.0,
                precio_total=500.0,
                fecha_entrega="2024-01-15"
            )
    
    def test_precio_negativo(self):
        """Test: Precio negativo debe fallar"""
        with pytest.raises(ValueError, match="El precio debe ser mayor o igual a 0"):
            ItemModel(
                codigo="14003793002",
                descripcion="Producto Test",
                cantidad=5,
                precio_unitario=-100.0,
                precio_total=500.0,
                fecha_entrega="2024-01-15"
            )

class TestCompradorModel:
    """Tests para el modelo CompradorModel"""
    
    def test_nit_valido(self):
        """Test: NIT válido"""
        comprador = CompradorModel(nit="CN800069933")
        assert comprador.nit == "CN800069933"
    
    def test_nit_vacio(self):
        """Test: NIT vacío debe fallar"""
        with pytest.raises(ValueError, match="El NIT no puede estar vacío"):
            CompradorModel(nit="   ")
    
    def test_nit_con_espacios(self):
        """Test: NIT con espacios debe limpiarse"""
        comprador = CompradorModel(nit="  CN800069933  ")
        assert comprador.nit == "CN800069933"

class TestOrdenModel:
    """Tests para el modelo OrdenModel"""
    
    def test_orden_valida(self):
        """Test: Orden válida"""
        orden = OrdenModel(
            comprador=CompradorModel(nit="CN800069933"),
            orden_compra="OC-2024-001",
            items=[
                ItemModel(
                    codigo="14003793002",
                    descripcion="Producto Test",
                    cantidad=5,
                    precio_unitario=100.0,
                    precio_total=500.0,
                    fecha_entrega="2024-01-15"
                )
            ]
        )
        assert orden.orden_compra == "OC-2024-001"
        assert len(orden.items) == 1
    
    def test_orden_sin_items(self):
        """Test: Orden sin items debe fallar"""
        with pytest.raises(ValueError, match="La orden debe tener al menos un artículo"):
            OrdenModel(
                comprador=CompradorModel(nit="CN800069933"),
                orden_compra="OC-2024-001",
                items=[]
            )

class TestValidadorOrdenesCompra:
    """Tests para la clase ValidadorOrdenesCompra"""
    
    @patch('validador.gspread.authorize')
    @patch('validador.Credentials.from_service_account_file')
    @patch('validador.os.path.exists')
    @patch('validador.os.getenv')
    def setup_method(self, method, mock_getenv, mock_exists, mock_credentials, mock_gspread):
        """Setup para cada test"""
        # Mock de variables de entorno
        mock_getenv.side_effect = lambda x: {
            'GOOGLE_DRIVE_FILE_ID': 'test_file_id',
            'GOOGLE_SHEET_RANGE': 'Hoja1!A:Z',
            'GOOGLE_APPLICATION_CREDENTIALS': 'credentials.json'
        }.get(x)
        
        # Mock de archivo de credenciales
        mock_exists.return_value = True
        
        # Mock de Google Sheets
        mock_worksheet = Mock()
        mock_worksheet.get.return_value = [
            ['Código SN', 'Nº catálogo SN', 'Descripción', 'Precio'],
            ['CN800069933', '14003793002', 'Producto 1', '100.0'],
            ['CN800069933', '14003793003', 'Producto 2', '200.0']
        ]
        
        mock_sheet = Mock()
        mock_sheet.worksheet.return_value = mock_worksheet
        
        mock_gc = Mock()
        mock_gc.open_by_key.return_value = mock_sheet
        
        mock_gspread.return_value = mock_gc
        
        # Crear instancia del validador
        self.validador = ValidadorOrdenesCompra()
    
    def test_validar_orden_todos_encontrados(self):
        """Test: Validar orden donde todos los artículos existen"""
        orden_json = {
            "comprador": {"nit": "CN800069933"},
            "orden_compra": "OC-2024-001",
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
        
        resultado = self.validador.validar_orden(orden_json)
        
        assert resultado["TODOS_LOS_ARTICULOS_EXISTEN"] == True
        assert resultado["PUEDE_PROCESAR_EN_SAP"] == True
        assert len(resultado["articulos_listos_para_sap"]) == 1
        assert len(resultado["articulos_que_NO_existen"]) == 0
        assert resultado["resumen"]["porcentaje_exito"] == 100.0
    
    def test_validar_orden_articulos_faltantes(self):
        """Test: Validar orden donde algunos artículos no existen"""
        orden_json = {
            "comprador": {"nit": "CN800069933"},
            "orden_compra": "OC-2024-001",
            "items": [
                {
                    "codigo": "14003793002",  # Existe
                    "descripcion": "Producto Test",
                    "cantidad": 5,
                    "precio_unitario": 100.0,
                    "precio_total": 500.0,
                    "fecha_entrega": "2024-01-15"
                },
                {
                    "codigo": "14003793099",  # No existe
                    "descripcion": "Producto No Existe",
                    "cantidad": 3,
                    "precio_unitario": 150.0,
                    "precio_total": 450.0,
                    "fecha_entrega": "2024-01-15"
                }
            ]
        }
        
        resultado = self.validador.validar_orden(orden_json)
        
        assert resultado["TODOS_LOS_ARTICULOS_EXISTEN"] == False
        assert resultado["PUEDE_PROCESAR_EN_SAP"] == False
        assert len(resultado["articulos_listos_para_sap"]) == 0
        assert len(resultado["articulos_que_NO_existen"]) == 1
        assert resultado["resumen"]["porcentaje_exito"] == 50.0
    
    def test_validar_orden_sin_items(self):
        """Test: Validar orden sin artículos debe fallar"""
        orden_json = {
            "comprador": {"nit": "CN800069933"},
            "orden_compra": "OC-2024-001",
            "items": []
        }
        
        with pytest.raises(ValueError, match="La orden debe tener al menos un artículo"):
            self.validador.validar_orden(orden_json)
    
    def test_validar_orden_cliente_diferente(self):
        """Test: Validar orden con cliente que no tiene artículos"""
        orden_json = {
            "comprador": {"nit": "CN800069999"},  # Cliente diferente
            "orden_compra": "OC-2024-001",
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
        
        resultado = self.validador.validar_orden(orden_json)
        
        assert resultado["TODOS_LOS_ARTICULOS_EXISTEN"] == False
        assert len(resultado["articulos_que_NO_existen"]) == 1
        assert "CN800069999" in resultado["articulos_que_NO_existen"][0]["motivo"]

class TestEndpoints:
    """Tests para los endpoints de FastAPI"""
    
    @patch('validador.validador')
    def test_health_check(self, mock_validador):
        """Test: Health check endpoint"""
        from validador import app
        from fastapi.testclient import TestClient
        
        # Mock del validador
        mock_validador.catalogo = pd.DataFrame({'test': [1, 2, 3]})
        
        client = TestClient(app)
        response = client.get("/health")
        
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "OK"
        assert "catalogo_items" in data
        assert "timestamp" in data
    
    @patch('validador.validador')
    def test_debug_catalogo(self, mock_validador):
        """Test: Debug catálogo endpoint"""
        from validador import app
        from fastapi.testclient import TestClient
        
        # Mock del validador
        mock_validador.catalogo = pd.DataFrame({
            'Código SN': ['CN800069933'],
            'Nº catálogo SN': ['14003793002']
        })
        mock_validador.indice_catalogo = pd.DataFrame({
            'test': ['value']
        }, index=['CN800069933|14003793002'])
        
        client = TestClient(app)
        response = client.get("/debug-catalogo")
        
        assert response.status_code == 200
        data = response.json()
        assert "primeras_5_filas" in data
        assert "claves_busqueda" in data

if __name__ == "__main__":
    # Ejecutar tests
    pytest.main([__file__, "-v"]) 