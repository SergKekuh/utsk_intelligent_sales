"""
Интеграционные тесты: полный пользовательский сценарий
"""

from fastapi.testclient import TestClient
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))
from app import app

client = TestClient(app)
TOKEN = "utsk2026"

def test_full_user_scenario():
    """Полный сценарий: дашборд → клиенты → рекомендации"""
    
    # 1. Открываем дашборд
    response = client.get("/api/dashboard?token=" + TOKEN)
    assert response.status_code == 200
    dashboard = response.json()
    assert dashboard["total_clients"] > 0
    
    # 2. Ищем клиента
    response = client.get("/api/clients?token=" + TOKEN + "&search=АВ%20Металл")
    assert response.status_code == 200
    clients = response.json()
    assert len(clients) > 0
    client_code = clients[0]["code"]
    
    # 3. Получаем рекомендации для этого клиента
    response = client.get(f"/api/recommendations/{client_code}?token=" + TOKEN)
    assert response.status_code == 200
    recs = response.json()
    assert "client_name" in recs
    
    # 4. Проверяем статусы
    response = client.get("/api/statuses?token=" + TOKEN)
    assert response.status_code == 200
    statuses = response.json()
    assert len(statuses) > 0
    
    print(f"✅ Сценарий пройден: клиент #{client_code} — {recs['client_name']}")

def test_error_handling():
    """Обработка ошибок"""
    # Неверный токен
    response = client.get("/api/dashboard?token=wrong")
    assert response.status_code == 403
    
    # Несуществующий клиент
    response = client.get("/api/recommendations/999999?token=" + TOKEN)
    assert response.status_code == 200
    data = response.json()
    assert "error" in data

if __name__ == "__main__":
    import pytest
    pytest.main([__file__, "-v"])
