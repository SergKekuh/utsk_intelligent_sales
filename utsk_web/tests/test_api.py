"""
Модульные тесты для UTSK Web API
Запуск: pytest tests/ -v
"""

import pytest
from fastapi.testclient import TestClient
import sys
import os

# Добавляем backend в путь
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

from app import app

client = TestClient(app)
TOKEN = "utsk2026"

# ====== АУТЕНТИФИКАЦИЯ ======
def test_auth_fail_no_token():
    """Без токена — 403"""
    response = client.get("/api/dashboard")
    assert response.status_code == 403

def test_auth_fail_wrong_token():
    """Неверный токен — 403"""
    response = client.get("/api/dashboard?token=wrong")
    assert response.status_code == 403

def test_auth_ok():
    """Верный токен — 200"""
    response = client.get("/api/dashboard?token=" + TOKEN)
    assert response.status_code == 200

# ====== ДАШБОРД ======
def test_dashboard_structure():
    """Дашборд возвращает правильные поля"""
    response = client.get("/api/dashboard?token=" + TOKEN)
    data = response.json()
    assert "total_clients" in data
    assert "active_30d" in data
    assert "total_revenue" in data
    assert data["total_clients"] > 0, "Должен быть хотя бы 1 клиент"

def test_dashboard_types():
    """Проверка типов данных в дашборде"""
    response = client.get("/api/dashboard?token=" + TOKEN)
    data = response.json()
    assert isinstance(data["total_clients"], int)
    assert isinstance(data["active_30d"], int)
    assert isinstance(data["total_revenue"], (int, float))

# ====== КЛИЕНТЫ ======
def test_clients_list():
    """Список клиентов не пустой"""
    response = client.get("/api/clients?token=" + TOKEN + "&limit=10")
    data = response.json()
    assert len(data) > 0, "Должен быть хотя бы 1 клиент"
    assert "code" in data[0]
    assert "name" in data[0]

def test_clients_search():
    """Поиск клиента по названию"""
    response = client.get("/api/clients?token=" + TOKEN + "&search=АВ%20Металл&limit=5")
    data = response.json()
    assert len(data) > 0, "Должен найтись клиент 'АВ Металл'"

def test_clients_search_no_results():
    """Поиск несуществующего клиента"""
    response = client.get("/api/clients?token=" + TOKEN + "&search=zzz_no_such_client_xyz&limit=5")
    data = response.json()
    assert len(data) == 0, "Не должно быть результатов"

# ====== СТАТУСЫ ======
def test_statuses():
    """Распределение по статусам"""
    response = client.get("/api/statuses?token=" + TOKEN)
    data = response.json()
    assert len(data) > 0, "Должен быть хотя бы 1 статус"
    assert "status_name" in data[0]
    assert "count" in data[0]

# ====== РЕКОМЕНДАЦИИ ======
def test_recommendations_existing_client():
    """Рекомендации для существующего клиента"""
    response = client.get("/api/recommendations/36?token=" + TOKEN)
    data = response.json()
    assert "client_name" in data
    assert "recommendations" in data

def test_recommendations_nonexistent_client():
    """Рекомендации для несуществующего клиента"""
    response = client.get("/api/recommendations/999999?token=" + TOKEN)
    data = response.json()
    assert "error" in data

# ====== ГЛАВНАЯ СТРАНИЦА ======
def test_index_html():
    """Главная страница отдаёт HTML"""
    response = client.get("/?token=" + TOKEN)
    assert response.status_code == 200
    assert "text/html" in response.headers["content-type"]
    assert "UTSK" in response.text

if __name__ == "__main__":
    pytest.main([__file__, "-v"])
