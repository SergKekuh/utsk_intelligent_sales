"""Тесты для новой аналитики сегментации клиентов (Вкладка 5)"""
import os
import sys
import pytest
from fastapi.testclient import TestClient

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))
from app.main import app

client = TestClient(app)
TOKEN = "utsk2026"

def test_segmentation_kpi():
    resp = client.get(f"/api/analytics/segmentation-kpi?token={TOKEN}&year=2026&limit_price=146000")
    assert resp.status_code == 200
    json_data = resp.json()
    assert json_data["status"] == "ok"
    assert json_data["data"]["total_clients"] == 729
    assert json_data["data"]["repeat_loyal_clients"] == 503
    assert json_data["data"]["c2_clients"] == 377
    assert json_data["data"]["new_clients"] == 151

def test_segmentation_special():
    resp = client.get(f"/api/analytics/segmentation-special?token={TOKEN}&year=2026&limit_price=146000")
    assert resp.status_code == 200
    json_data = resp.json()
    assert json_data["status"] == "ok"
    assert len(json_data["data"]) == 4
    codes = [d["segment_code"] for d in json_data["data"]]
    assert "c2" in codes
    assert "new_clients" in codes
    assert "churned" in codes
    assert "sleeping" in codes

def test_segmentation_matrix():
    resp = client.get(f"/api/analytics/segmentation-matrix?token={TOKEN}&year=2026&limit_price=146000")
    assert resp.status_code == 200
    json_data = resp.json()
    assert json_data["status"] == "ok"
    assert len(json_data["rows"]) == 19
    assert "sections" in json_data
    assert "chart_data" in json_data
