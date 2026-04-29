"""Модульные тесты для UTSK Web API"""
import pytest
from fastapi.testclient import TestClient
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))
from app import app

client = TestClient(app)
TOKEN = "utsk2026"

# ====== АУТЕНТИФИКАЦИЯ ======
def test_auth_fail_no_token():
    assert client.get("/api/dashboard").status_code == 403

def test_auth_fail_wrong_token():
    assert client.get("/api/dashboard?token=wrong").status_code == 403

def test_auth_ok():
    assert client.get("/api/dashboard?token=" + TOKEN).status_code == 200

# ====== ДАШБОРД ======
def test_dashboard_structure():
    data = client.get("/api/dashboard?token=" + TOKEN).json()
    assert "total_clients" in data
    assert data["total_clients"] > 0

def test_dashboard_types():
    data = client.get("/api/dashboard?token=" + TOKEN).json()
    assert isinstance(data["total_clients"], int)

# ====== КЛИЕНТЫ ======
def test_clients_list():
    data = client.get("/api/clients?token=" + TOKEN + "&limit=10").json()
    assert len(data) > 0
    assert "code" in data[0]

def test_clients_search():
    # Ищем тестового клиента, а не "АВ Металл"
    data = client.get("/api/clients?token=" + TOKEN + "&search=Test&limit=5").json()
    assert len(data) > 0, "Должен найтись 'Test Client'"

def test_clients_search_no_results():
    data = client.get("/api/clients?token=" + TOKEN + "&search=zzz_no_such_xyz&limit=5").json()
    assert len(data) == 0

# ====== СТАТУСЫ ======
def test_statuses():
    data = client.get("/api/statuses?token=" + TOKEN).json()
    assert len(data) > 0, "Должен быть хотя бы 1 статус"

# ====== РЕКОМЕНДАЦИИ ======
def test_recommendations_existing_client():
    data = client.get("/api/recommendations/36?token=" + TOKEN).json()
    assert "client_name" in data

def test_recommendations_nonexistent_client():
    data = client.get("/api/recommendations/999999?token=" + TOKEN).json()
    assert "error" in data

# ====== ГЛАВНАЯ СТРАНИЦА ======
def test_index_html():
    response = client.get("/?token=" + TOKEN)
    assert response.status_code == 200
    assert "UTSK" in response.text

def test_plan_page(test_client):
    """Проверка страницы плана разработки"""
    response = test_client.get("/plan?token=utsk2026")
    assert response.status_code == 200
    assert "UTSK" in response.text or "План разработки" in response.text


def test_db_reference_page(test_client):
    """Проверка справочника БД"""
    response = test_client.get("/db-reference?token=utsk2026")
    assert response.status_code == 200
    assert "UTSK" in response.text or "Справочник" in response.text


def test_plan_page_no_auth(test_client):
    """Страница плана без токена = 403"""
    response = test_client.get("/plan")
    assert response.status_code == 403


def test_db_reference_no_auth(test_client):
    """Справочник без токена = 403"""
    response = test_client.get("/db-reference")
    assert response.status_code == 403
