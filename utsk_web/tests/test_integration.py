"""Интеграционные тесты"""
from fastapi.testclient import TestClient
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))
from app import app

client = TestClient(app)
TOKEN = "utsk2026"

def test_full_user_scenario():
    """Сценарий: дашборд → клиенты → рекомендации"""
    # 1. Дашборд
    dashboard = client.get("/api/dashboard?token=" + TOKEN).json()
    assert dashboard["total_clients"] > 0
    
    # 2. Клиенты (ищем Test)
    clients = client.get("/api/clients?token=" + TOKEN + "&search=Test").json()
    assert len(clients) > 0
    client_code = clients[0]["code"]
    
    # 3. Рекомендации
    recs = client.get(f"/api/recommendations/{client_code}?token=" + TOKEN).json()
    assert "client_name" in recs

def test_error_handling():
    assert client.get("/api/dashboard?token=wrong").status_code == 403
    assert "error" in client.get("/api/recommendations/999999?token=" + TOKEN).json()
