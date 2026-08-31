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

def test_segmentation_matrix_v2():
    resp = client.get(f"/api/analytics/segmentation-matrix-v2?token={TOKEN}&year=2026&limit_price=146000")
    assert resp.status_code == 200
    json_data = resp.json()
    assert json_data["status"] == "ok"
    assert len(json_data["data"]) == 5
    assert json_data["totals"]["total_clients"] == 729
    assert json_data["totals"]["c2_clients"] == 377
    assert json_data["totals"]["new_clients"] == 151
    assert json_data["totals"]["retained_clients"] == 579

def test_segmentation_current_year():
    resp = client.get(f"/api/analytics/segmentation-current-year?token={TOKEN}&year=2026&limit_price=146000")
    assert resp.status_code == 200
    json_data = resp.json()
    assert json_data["status"] == "ok"
    assert len(json_data["data"]) == 6
    assert json_data["totals"]["total_count"] == 729
    assert json_data["totals"]["new_count"] == 151
    assert json_data["totals"]["c2_count"] == 377
    assert json_data["totals"]["retained_count"] == 579
    # Check frequency groups
    groups = [r["freq_group"] for r in json_data["data"]]
    assert groups == ["raz", "povt", "kvart", "mes", "ned", "den"]

def test_segmentation_past_years():
    resp = client.get(f"/api/analytics/segmentation-past-years?token={TOKEN}&year=2026")
    assert resp.status_code == 200
    json_data = resp.json()
    assert json_data["status"] == "ok"
    assert len(json_data["sleeping"]) == 6
    assert len(json_data["churned"]) == 6
    assert json_data["totals"]["sleeping_count"] == 401
    assert json_data["totals"]["churned_count"] == 270

def test_segment_detail_page():
    resp = client.get(f"/segment-detail?token={TOKEN}&year=2026&segment=raz&table=general&category=Разові (1)")
    assert resp.status_code == 200
    assert "Деталізація:" in resp.text
    assert "monthlySegmentChart" in resp.text
    assert "clientsTableBody" in resp.text

def test_segment_detail_api():
    resp = client.get(f"/api/analytics/segment-detail?token={TOKEN}&year=2026&segment=raz&table=general&category=Разові (1)")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["kpi"]["total_companies"] == 226
    assert len(data["monthly_distribution"]) == 12
    assert len(data["clients"]) == 226
    assert data["clients"][0]["code"]

def test_general_segmentation_page():
    resp = client.get(f"/general-segmentation?token={TOKEN}&year=2026")
    assert resp.status_code == 200
    assert "Загальна сегментація клієнтської бази" in resp.text
    assert "chartCohorts" in resp.text
    assert "chartIndustry" in resp.text
    assert "companiesTbody" in resp.text

def test_general_segmentation_api():
    resp = client.get(f"/api/analytics/general-segmentation-companies?token={TOKEN}&year=2026")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["count"] == 729
    assert len(data["data"]) == 729
    assert data["kpi"]["total_firms"] == 729
    assert data["kpi"]["repeat_loyal_count"] == 503
    assert data["cohort_counts"]["SINGLE"] == 226
    assert data["cohort_counts"]["REPEAT"] == 174
    assert data["cohort_counts"]["QUARTERLY"] == 188
    assert data["cohort_counts"]["MONTHLY"] == 126

def test_repeat_segmentation_page():
    resp = client.get(f"/repeat-segmentation?token={TOKEN}&year=2026")
    assert resp.status_code == 200
    assert "Повторні (розкладені)" in resp.text
    assert "chartSubgroupsCount" in resp.text
    assert "chartSubgroupsRev" in resp.text
    assert "companiesTbody" in resp.text

def test_repeat_segmentation_api():
    resp = client.get(f"/api/analytics/repeat-segmentation-companies?token={TOKEN}&year=2026")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["count"] == 174
    assert len(data["data"]) == 174
    assert data["kpi"]["total_repeat"] == 174
    assert data["kpi"]["quick_double"] > 0
    assert data["kpi"]["center"] > 0
    assert data["kpi"]["candidates"] > 0
    assert data["data"][0]["code"]

def test_consolidated_segmentation_page():
    resp = client.get(f"/consolidated-segmentation?token={TOKEN}&year=2026")
    assert resp.status_code == 200
    assert "Всі (консолідовано)" in resp.text
    assert "chartConsCount" in resp.text
    assert "chartConsRev" in resp.text
    assert "companiesTbody" in resp.text

def test_consolidated_segmentation_api():
    resp = client.get(f"/api/analytics/consolidated-segmentation-companies?token={TOKEN}&year=2026")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["count"] == 729
    assert len(data["data"]) == 729
    assert data["kpi"]["total_companies"] == 729
    assert data["kpi"]["single_cons"] > 0
    assert data["kpi"]["repeat_core"] > 0
    assert data["kpi"]["loyal"] > 0
    assert data["data"][0]["code"]

def test_c2_segmentation_page():
    resp = client.get(f"/c2-segmentation?token={TOKEN}&year=2026")
    assert resp.status_code == 200
    assert "C2 ≤ 2 т/рік" in resp.text
    assert "chartC2Frequency" in resp.text
    assert "chartC2TopProducts" in resp.text
    assert "companiesTbody" in resp.text

def test_c2_segmentation_api():
    resp = client.get(f"/api/analytics/c2-segmentation-companies?token={TOKEN}&year=2026")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["count"] > 0
    assert len(data["data"]) > 0
    assert data["kpi"]["total_c2"] > 0
    assert len(data["top_products"]) > 0
    assert data["data"][0]["code"]

def test_new_clients_segmentation_page():
    resp = client.get(f"/new-clients-segmentation?token={TOKEN}&year=2026")
    assert resp.status_code == 200
    assert "🆕 Нові клієнти" in resp.text
    assert "chartNewFrequency" in resp.text
    assert "chartNewMonthly" in resp.text
    assert "companiesTbody" in resp.text

def test_new_clients_segmentation_api():
    resp = client.get(f"/api/analytics/new-clients-segmentation-companies?token={TOKEN}&year=2026")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["count"] > 0
    assert len(data["data"]) > 0
    assert data["kpi"]["total_new"] > 0
    assert len(data["monthly_distribution"]) > 0
    assert data["data"][0]["code"]

def test_churned_segmentation_page():
    resp = client.get(f"/churned-segmentation?token={TOKEN}&year=2026")
    assert resp.status_code == 200
    assert "👻 Вибули" in resp.text
    assert "chartChurnYear" in resp.text
    assert "chartChurnCohort" in resp.text
    assert "companiesTbody" in resp.text

def test_churned_segmentation_api():
    resp = client.get(f"/api/analytics/churned-segmentation-companies?token={TOKEN}&year=2026")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["count"] > 0
    assert len(data["data"]) > 0
    assert data["kpi"]["total_churned"] > 0
    assert len(data["year_distribution"]) > 0
    assert data["data"][0]["code"]

def test_sleeping_segmentation_page():
    resp = client.get(f"/sleeping-segmentation?token={TOKEN}&year=2026")
    assert resp.status_code == 200
    assert "💤 Сплячі" in resp.text
    assert "chartSleepDormancy" in resp.text
    assert "chartSleepCohort" in resp.text
    assert "companiesTbody" in resp.text

def test_sleeping_segmentation_api():
    resp = client.get(f"/api/analytics/sleeping-segmentation-companies?token={TOKEN}&year=2026")
    assert resp.status_code == 200
    data = resp.json()
    assert data["status"] == "ok"
    assert data["count"] > 0
    assert len(data["data"]) > 0
    assert data["kpi"]["total_sleeping"] > 0
    assert len(data["dormancy_distribution"]) > 0
    assert data["data"][0]["code"]









