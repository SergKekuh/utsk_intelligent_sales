"""Модульные тесты для UTSK Web API"""
import pytest
from fastapi.testclient import TestClient
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))
from app.main import app

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
    res = client.get("/api/clients?token=" + TOKEN + "&limit=10").json()
    data = res.get("data", res) if isinstance(res, dict) else res
    assert len(data) > 0
    assert "code" in data[0]

def test_clients_search():
    # Ищем тестового клиента, а не "АВ Металл"
    res = client.get("/api/clients?token=" + TOKEN + "&search=Test&limit=5").json()
    data = res.get("data", res) if isinstance(res, dict) else res
    assert len(data) > 0, "Должен найтись 'Test Client'"

def test_clients_search_no_results():
    res = client.get("/api/clients?token=" + TOKEN + "&search=zzz_no_such_xyz&limit=5").json()
    data = res.get("data", res) if isinstance(res, dict) else res
    assert len(data) == 0

# ====== СТАТУСЫ ======
def test_statuses():
    data = client.get("/api/statuses?token=" + TOKEN).json()
    assert len(data) > 0, "Должен быть хотя бы 1 статус"

# ====== РЕКОМЕНДАЦИИ ======
def test_recommendations_existing_client():
    data = client.get("/api/recommendations/TEST_999999?token=" + TOKEN).json()
    assert "client_name" in data

def test_recommendations_nonexistent_client():
    response = client.get("/api/recommendations/TEST_NONEXISTENT_99999?token=" + TOKEN)
    assert response.status_code == 404
    assert "detail" in response.json()

# ====== ВОРОНКА ПРОДАЖ ======
def test_funnel_extended_structure():
    response = client.get("/api/funnel?token=" + TOKEN + "&year=2026")
    assert response.status_code == 200
    data = response.json()
    assert "funnel" in data
    assert "lifecycle" in data
    assert "new_clients_funnel" in data
    assert isinstance(data["lifecycle"], list)
    assert isinstance(data["new_clients_funnel"], list)


# ====== ГЛАВНАЯ СТРАНИЦА ======
def test_index_html():
    response = client.get("/?token=" + TOKEN)
    assert response.status_code == 200
    assert "UTSK" in response.text

def test_plan_page():
    """Проверка страницы плана разработки"""
    response = client.get("/plan?token=utsk2026")
    assert response.status_code == 200
    assert "UTSK" in response.text or "План разработки" in response.text


def test_db_reference_page():
    """Проверка справочника БД"""
    response = client.get("/db-reference?token=utsk2026")
    assert response.status_code == 200
    assert "UTSK" in response.text or "Справочник" in response.text


def test_plan_page_no_auth():
    """Страница плана без токена = 403"""
    response = client.get("/plan")
    assert response.status_code == 403


def test_db_reference_no_auth():
    """Справочник без токена = 403"""
    response = client.get("/db-reference")
    assert response.status_code == 403


# ====== АНАЛИТИКА НОВЫХ КЛИЕНТОВ ======
def test_new_clients_analytics_page():
    response = client.get("/new-clients-analytics?token=" + TOKEN)
    assert response.status_code == 200
    assert "Аналитика новых клиентов" in response.text or "UTSK" in response.text

def test_new_clients_overview():
    response = client.get("/api/analytics/new-clients-overview?token=" + TOKEN + "&year=2026")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "total_new" in data
    assert "total_revenue" in data
    assert "avg_ticket" in data

def test_new_clients_frequency():
    response = client.get("/api/analytics/new-clients-frequency?token=" + TOKEN + "&year=2026")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "data" in data
    assert isinstance(data["data"], list)

def test_new_clients_abc():
    response = client.get("/api/analytics/new-clients-abc?token=" + TOKEN + "&year=2026")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "data" in data

def test_new_clients_abc_compare():
    response = client.get("/api/analytics/new-clients-abc-compare?token=" + TOKEN + "&year=2026")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "data" in data

def test_new_clients_list():
    response = client.get("/api/analytics/new-clients-list?token=" + TOKEN + "&year=2026&limit=10")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "data" in data
    assert len(data["data"]) > 0


# ====== АНАЛИТИКА НЕАКТИВНЫХ КЛИЕНТОВ ======
def test_inactive_clients_analytics_page():
    response = client.get("/inactive-clients-analytics?token=" + TOKEN)
    assert response.status_code == 200
    assert "Неактивные клиенты" in response.text or "UTSK" in response.text

def test_inactive_clients_overview():
    response = client.get("/api/analytics/inactive-clients-overview?token=" + TOKEN + "&year=2026")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "sleeping_count" in data
    assert "churned_count" in data
    assert data["sleeping_count"] > 0

def test_inactive_clients_list_sleeping():
    response = client.get("/api/analytics/inactive-clients-list?token=" + TOKEN + "&status_id=8&limit=10")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert len(data["data"]) > 0

def test_inactive_clients_list_churned():
    response = client.get("/api/analytics/inactive-clients-list?token=" + TOKEN + "&status_id=9&limit=10")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert len(data["data"]) > 0

def test_inactive_clients_distribution():
    response = client.get("/api/analytics/inactive-clients-distribution?token=" + TOKEN + "&status_id=8")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "data" in data

def test_inactive_clients_abc():
    response = client.get("/api/analytics/inactive-clients-abc?token=" + TOKEN + "&status_id=8")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "data" in data

# ====== ABC STRUCTURE ======
def test_abc_structure_page():
    response = client.get("/abc-structure?token=" + TOKEN)
    assert response.status_code == 200
    assert "Структурный анализ ABC" in response.text

def test_abc_structure_api():
    response = client.get("/api/analytics/abc-structure?token=" + TOKEN + "&year=2026")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "sections" in data["data"]

def test_abc_segment_detail_api():
    for seg in ['c2', 'abc', 'total', 'important']:
        response = client.get(f"/api/analytics/abc-segment-detail?token={TOKEN}&segment={seg}&year=2026")
        assert response.status_code == 200
        data = response.json()
        assert data["status"] == "ok"
        assert "matrix" in data["data"]
        assert "local_abc" in data["data"]
        assert "repeat_decomp" in data["data"]
        assert "kpis" in data["data"]


