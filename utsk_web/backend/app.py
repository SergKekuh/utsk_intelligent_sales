"""
UTSK Intelligent Sales — Web Demo Server
Запуск: python backend/app.py
Доступ: http://0.0.0.0:5000
"""

from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session
import os
import uvicorn
import logging

# ====== КОНФИГУРАЦИЯ ======
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:root@localhost:5432/bd_intelligent_sales")
DEMO_TOKEN = os.getenv("DEMO_TOKEN", "utsk2026")
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", 5000))

# Абсолютные пути
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(BASE_DIR)
ROOT_DIR = os.path.dirname(PROJECT_DIR)
FRONTEND_DIR = os.path.join(PROJECT_DIR, "frontend", "static")
DOCS_DIR = os.path.join(ROOT_DIR, "docs")

# Логирование
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# ====== ПРИЛОЖЕНИЕ ======
app = FastAPI(title="UTSK Intelligent Sales API", version="1.0.0")

# Подключение к БД
engine = create_engine(DATABASE_URL)

def get_db():
    return Session(engine)

# Статика
if os.path.exists(os.path.join(PROJECT_DIR, "frontend", "static")):
    app.mount("/static", StaticFiles(directory=os.path.join(PROJECT_DIR, "frontend", "static")), name="static")

# ====== АУТЕНТИФИКАЦИЯ ======
def verify_token(token: str = Query(None)):
    if token != DEMO_TOKEN:
        raise HTTPException(status_code=403, detail="Неверный токен доступа")
    return True

# ====== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ======
def find_file(filename: str, search_dirs: list) -> str | None:
    for directory in search_dirs:
        filepath = os.path.join(directory, filename)
        if os.path.exists(filepath):
            logger.info(f"✅ Найден файл: {filepath}")
            return filepath
    logger.error(f"❌ Файл не найден: {filename}")
    return None

# ====== СТРАНИЦЫ ======
@app.get("/", response_class=HTMLResponse)
async def index(request: Request, token: str = Query(None)):
    verify_token(token)
    search_dirs = [FRONTEND_DIR, os.path.join(PROJECT_DIR, "frontend", "static"), os.path.join(ROOT_DIR, "frontend", "static")]
    filepath = find_file("index.html", search_dirs)
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Главная страница не найдена")

@app.get("/plan", response_class=HTMLResponse)
async def plan_page(request: Request, token: str = Query(None)):
    verify_token(token)
    search_dirs = [DOCS_DIR, ROOT_DIR, os.path.join(ROOT_DIR, "docs"), PROJECT_DIR, FRONTEND_DIR]
    filepath = find_file("plan.html", search_dirs)
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница плана не найдена")

@app.get("/db-reference", response_class=HTMLResponse)
async def db_reference_page(request: Request, token: str = Query(None)):
    verify_token(token)
    search_dirs = [DOCS_DIR, ROOT_DIR, os.path.join(ROOT_DIR, "docs"), PROJECT_DIR, FRONTEND_DIR]
    filepath = find_file("db_reference.html", search_dirs)
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Справочник не найден")

@app.get("/client-detail", response_class=HTMLResponse)
async def client_detail_page(request: Request, token: str = Query(None), code: str = Query(None)):
    """Страница детализации клиента"""
    verify_token(token)
    search_dirs = [FRONTEND_DIR, os.path.join(PROJECT_DIR, "frontend", "static"), os.path.join(ROOT_DIR, "frontend", "static")]
    filepath = find_file("client-detail.html", search_dirs)
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница детализации клиента не найдена")

@app.get("/product-analytics", response_class=HTMLResponse)
async def product_analytics_page(request: Request, token: str = Query(None), code: str = Query(None)):
    """Страница аналитики продуктов клиента"""
    verify_token(token)
    search_dirs = [FRONTEND_DIR, os.path.join(PROJECT_DIR, "frontend", "static"), os.path.join(ROOT_DIR, "frontend", "static")]
    filepath = find_file("product-analytics.html", search_dirs)
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница аналитики продуктов не найдена")

@app.get("/product-recommendations", response_class=HTMLResponse)
async def product_recommendations_page(request: Request, token: str = Query(None)):
    """Страница-заглушка: рекомендации по продукту"""
    verify_token(token)
    search_dirs = [FRONTEND_DIR, os.path.join(PROJECT_DIR, "frontend", "static")]
    filepath = find_file("product-recommendations.html", search_dirs)
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница не найдена")

# ====== API: ДАШБОРД ======
@app.get("/api/dashboard")
def dashboard(token: str = Query(None)):
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(text("SELECT * FROM get_dashboard_stats()")).first()
        return {
            "total_clients": result.total_clients,
            "active_30d": result.active_30d,
            "active_90d": result.active_90d,
            "total_revenue": round(float(result.total_revenue), 2),
            "revenue_30d": round(float(result.revenue_30d), 2)
        }
    finally:
        db.close()

# ====== API: КЛИЕНТЫ ======
@app.get("/api/clients")
def clients(token: str = Query(None), limit: int = 50, search: str = ""):
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(text("SELECT * FROM get_clients_list(:limit, :search)"), {"limit": limit, "search": search})
        return [dict(row._mapping) for row in result]
    finally:
        db.close()

# ====== API: АКТИВНЫЕ КЛИЕНТЫ ======
@app.get("/api/clients/active")
def active_clients(token: str = Query(None), limit: int = 20):
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(text("SELECT * FROM get_active_clients(:limit)"), {"limit": limit})
        return [dict(row._mapping) for row in result]
    finally:
        db.close()

# ====== API: ТОП ПРОДАЖ (80% RULE) ======
@app.get("/api/clients/top-sales")
def get_top_clients_sales(
    token: str = Query(None),
    year: int = 2026,
    date_from: str = Query(None),
    date_to: str = Query(None)
):
    """
    Топ клиентов по продажам с накопительным процентом (80% rule).
    Использует хранимую функцию get_top_clients_80pct для быстрой выборки.
    """
    verify_token(token)
    db = get_db()
    try:
        rows = db.execute(
            text("SELECT * FROM get_top_clients_80pct(:year, :date_from, :date_to)"),
            {
                "year": year,
                "date_from": date_from if date_from else None,
                "date_to": date_to if date_to else None
            }
        ).fetchall()

        if not rows:
            return {
                "status": "ok",
                "clients": [],
                "total_revenue": 0,
                "period_label": "Нет данных"
            }

        first_row = dict(rows[0]._mapping)
        total_revenue = float(first_row.get("total_revenue")) if first_row.get("total_revenue") else 0.0
        period_label = first_row.get("period_label", "")

        result = []
        for r_raw in rows:
            r = dict(r_raw._mapping)
            last_date_str = r["last_purchase_date"].strftime("%d.%m.%Y") if r.get("last_purchase_date") else "—"
            result.append({
                "code": r["code"],
                "name": r["name"] or "—",
                "status_2025": r["status_2025"] or "—",
                "status_2026": r["status_2026"] or "—",
                "goods_revenue": float(r["goods_revenue"]),
                "invoice_count": r["invoice_count"],
                "last_purchase_date": last_date_str,
                "pct_of_total": float(r["pct_of_total"]),
                "running_pct": float(r["running_pct"]),
                "is_included": bool(r.get("is_included", True))
            })

        return {
            "status": "ok",
            "clients": result,
            "total_revenue": total_revenue,
            "period_label": period_label,
            "date_from": date_from or f"{year}-01-01",
            "date_to": date_to or "сегодня"
        }
    except Exception as e:
        logger.error(f"Ошибка в get_top_clients_sales: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

# ====== API: РИСК ОТТОКА ======
@app.get("/api/clients/churn-risk")
def churn_risk(token: str = Query(None), limit: int = 20):
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(text("SELECT * FROM get_churn_risk_clients(:limit)"), {"limit": limit})
        return [dict(row._mapping) for row in result]
    finally:
        db.close()

# ====== API: ДЕТАЛИЗАЦИЯ КЛИЕНТА ======
@app.get("/api/clients/detail/{code}")
def get_client_detail(code: str, token: str = Query(None), year: int = 2026):
    """Детальная информация о клиенте"""
    verify_token(token)
    db = get_db()
    try:
        # 1. Основная информация о клиенте
        q_main = text("SELECT * FROM get_client_detail(:code, :year)")
        client_res = db.execute(q_main, {"year": year, "code": code}).fetchone()
        if not client_res:
            raise HTTPException(status_code=404, detail=f"Клиент '{code}' не найден")
        
        client_data = dict(client_res._mapping)

        # 2. Статус 2025 года
        res_2025 = db.execute(
            text("SELECT get_client_status_2025(:code, :year_prev)"),
            {"code": code, "year_prev": year - 1}
        ).scalar()
        status_2025 = res_2025 or "—"

        # 3. Помесячная динамика (2026 vs 2025)
        monthly_rows = db.execute(
            text("SELECT * FROM get_client_monthly_dynamics(:code, :year, :year_prev)"),
            {"code": code, "year": year, "year_prev": year - 1}
        ).fetchall()
        monthly_data = [dict(m._mapping) for m in monthly_rows]
        for m in monthly_data:
            m["revenue_current"] = float(m["revenue_current"]) if m.get("revenue_current") else 0.0
            m["revenue_previous"] = float(m["revenue_previous"]) if m.get("revenue_previous") else 0.0

        # 4. Последние 20 накладных
        q_invoices = text("SELECT * FROM get_client_invoices(:code, :year, NULL, NULL, NULL, 20)")
        invoice_rows = db.execute(q_invoices, {"code": code, "year": year}).fetchall()
        last_invoices = [dict(i._mapping) for i in invoice_rows]
        for inv in last_invoices:
            inv["total"] = float(inv["total"]) if inv.get("total") else 0.0

        last_date_str = client_data["last_purchase_date"].strftime("%d.%m.%Y") if client_data.get("last_purchase_date") else "—"

        return {
            "status": "ok",
            "client": {
                "code": client_data["code"],
                "name": client_data["name"] or "—",
                "status": client_data["status"] or "—",
                "status_2025": status_2025,
                "total_revenue": float(client_data["total_revenue"]),
                "total_invoices": client_data["total_invoices"],
                "avg_check": float(client_data["avg_check"]),
                "last_purchase_date": last_date_str,
                "monthly_data": monthly_data,
                "last_invoices": last_invoices
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Ошибка get_client_detail {code}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

# ====== API: НАКЛАДНЫЕ КЛИЕНТА С ФИЛЬТРАМИ ======
@app.get("/api/clients/invoices/{code}")
def get_client_invoices(
    code: str,
    token: str = Query(None),
    year: int = 2026,
    month: str = "all",
    date_from: str = Query(None),
    date_to: str = Query(None),
    limit: int = 50
):
    """Список накладных клиента с фильтрацией по году, месяцу и датам"""
    verify_token(token)
    db = get_db()
    try:
        month_int = int(month) if (month and month.isdigit() and month != "all") else None
        
        q = text("SELECT * FROM get_client_invoices(:code, :year, :month_int, :date_from, :date_to, :limit)")

        rows = db.execute(q, {
            "code": code,
            "year": year,
            "month_int": month_int,
            "date_from": date_from if date_from else None,
            "date_to": date_to if date_to else None,
            "limit": limit
        }).fetchall()

        invoices = [dict(r._mapping) for r in rows]
        total_sum = 0.0
        total_positions = 0
        for inv in invoices:
            inv_tot = float(inv["total"]) if inv.get("total") else 0.0
            inv["total"] = inv_tot
            total_sum += inv_tot
            total_positions += inv.get("positions", 0)

        return {
            "status": "ok",
            "invoices": invoices,
            "total_count": len(invoices),
            "total_sum": total_sum,
            "total_positions": total_positions,
            "invoice_filters": {
                "year": year,
                "month": month,
                "date_from": date_from,
                "date_to": date_to
            }
        }
    except Exception as e:
        logger.error(f"Ошибка get_client_invoices {code}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

# ====== API: ДЕТАЛИЗАЦИЯ НАКЛАДНОЙ (ITEMS) ======
@app.get("/api/invoices/{number}/items")
def get_invoice_items(number: str, token: str = Query(None)):
    """
    Детализация накладной — список товаров с количеством, весом, ценой и стоимостью.
    """
    verify_token(token)
    db = get_db()
    try:
        # 1. Основная информация о накладной
        q_doc = text("""
            SELECT 
                TO_CHAR(d.invoice_date, 'DD.MM.YYYY') AS date,
                d.doc_number AS number,
                COALESCE(ROUND(SUM(sl.amount)::numeric, 0), 0) AS total
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            WHERE d.doc_number = :number
            GROUP BY d.id, d.invoice_date, d.doc_number
        """)
        invoice_row = db.execute(q_doc, {"number": number}).fetchone()
        if not invoice_row:
            raise HTTPException(status_code=404, detail=f"Накладная '{number}' не найдена")
        
        inv_data = dict(invoice_row._mapping)

        # 2. Строки накладной (товары)
        q_items = text("SELECT * FROM get_invoice_items(:number)")
        item_rows = db.execute(q_items, {"number": number}).fetchall()
        items = []
        for r in item_rows:
            m = dict(r._mapping)
            items.append({
                "code": m["code"],
                "name": m["name"],
                "quantity": float(m["quantity"]) if m.get("quantity") else 0.0,
                "weight_kg": float(m["weight_kg"]) if m.get("weight_kg") else 0.0,
                "price": float(m["price"]) if m.get("price") else 0.0,
                "total": float(m["total"]) if m.get("total") else 0.0
            })

        return {
            "status": "ok",
            "date": inv_data["date"],
            "number": inv_data["number"],
            "total": float(inv_data["total"]),
            "items": items
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Ошибка invoice-items {number}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

# ====== API: СТАТУСЫ ======
@app.get("/api/statuses")
def statuses(token: str = Query(None)):
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(text("SELECT * FROM get_statuses_distribution()"))
        return [dict(row._mapping) for row in result]
    finally:
        db.close()

# ====== API: ТОВАРЫ ======
@app.get("/api/products")
def products(token: str = Query(None), limit: int = 50, search: str = ""):
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(text("SELECT * FROM get_products_list(:limit, :search)"), {"limit": limit, "search": search})
        return [dict(row._mapping) for row in result]
    finally:
        db.close()

# ====== API: РЕКОМЕНДАЦИИ ДЛЯ КЛИЕНТА (4 БЛОКА + FALLBACK) ======
@app.get("/api/recommendations/{client_code}")
def recommendations_for_client(client_code: str, token: str = Query(None)):
    """Персональные рекомендации — 4 блока: история, новинки, cross-sells, цифровой след"""
    verify_token(token)
    db = get_db()
    try:
        # Проверяем клиента
        client = db.execute(
            text("SELECT code, name, activity_direction_id FROM clients WHERE code = :code"),
            {"code": client_code}
        ).first()
        
        if not client:
            raise HTTPException(status_code=404, detail=f"Клиент '{client_code}' не найден")

        recommendations = []
        
        # ====== БЛОК 1: История покупок (РАСШИРЕННЫЙ: 2026 vs 2025 + тренд) ======
        result = db.execute(text("SELECT * FROM get_recommendations_for_client(:client_code)"), {"client_code": client_code})

        for row in result:
            r = dict(row._mapping)
            # Приводим типы
            r['purchases_current_year'] = int(r.get('purchases_current_year') or 0)
            r['purchases_prev_year'] = int(r.get('purchases_prev_year') or 0)
            r['pct_current_year'] = float(r.get('pct_current_year') or 0.0)
            r['pct_prev_year'] = float(r.get('pct_prev_year') or 0.0)
            r['revenue_current_year'] = float(r.get('revenue_current_year') or 0.0)
            r['revenue_prev_year'] = float(r.get('revenue_prev_year') or 0.0)
            r['in_stock'] = float(r.get('in_stock') or 0.0)
            r['days_since_last'] = int(r.get('days_since_last') or 0)
            r['purchase_count'] = int(r.get('purchase_count_total') or 0)  # для обратной совместимости
            r['purchase_count_total'] = int(r.get('purchase_count_total') or 0)
            r['priority'] = 1
            r['reason'] = 'Часто покупаете'
            recommendations.append(r)
        
        # ====== БЛОК 2: Новинки по направлению ======
        if client.activity_direction_id:
            result = db.execute(
                text("SELECT * FROM get_recommendations_block2(:direction_id, :client_code)"),
                {"direction_id": client.activity_direction_id, "client_code": client_code}
            )
            for row in result:
                recommendations.append(dict(row._mapping))
        
        # ====== БЛОК 3: Сопутствующие товары (cross-sells) ======
        result = db.execute(
            text("SELECT * FROM get_recommendations_block3(:client_code)"),
            {"client_code": client_code}
        )
        for row in result:
            recommendations.append(dict(row._mapping))
        
        # ====== БЛОК 4: Цифровой след (просмотры за 7 дней) ======
        result = db.execute(
            text("SELECT * FROM get_recommendations_block4(:client_code)"),
            {"client_code": client_code}
        )
        for row in result:
            recommendations.append(dict(row._mapping))
        
        # ====== СОРТИРОВКА: по приоритету, затем по % от выручки в текущем году (убывание) ======
        recommendations.sort(key=lambda r: (
            r.get('priority', 99),
            -float(r.get('pct_current_year', 0) or 0),
            -int(r.get('purchases_current_year', 0) or r.get('purchase_count_total', 0) or 0)
        ))
        
        # ====== Ограничиваем 5 рекомендациями ======
        recommendations = recommendations[:5]
        
        # ====== FALLBACK: популярные товары ======
        if not recommendations:
            result = db.execute(text("SELECT * FROM get_recommendations_fallback()"))
            for row in result:
                recommendations.append(dict(row._mapping))
        
        return {
            "client_code": client.code,
            "client_name": client.name,
            "recommendations": recommendations,
            "count": len(recommendations)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Ошибка рекомендаций для {client_code}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

# ====== API: ВОРОНКА ПРОДАЖ ======
@app.get("/api/funnel")
def funnel(token: str = Query(None), year: int = 2026):
    """
    Воронка продаж: 
    1) Активные клиенты по частоте (funnel)
    2) Жизненный цикл клиентов — Спящие / Ушедшие (lifecycle)
    3) Распределение только Новых клиентов по частоте (new_clients_funnel)
    """
    verify_token(token)
    db = get_db()
    try:
        # 1. Активные клиенты по частоте накладных (существующая воронка)
        result_active = db.execute(text("SELECT * FROM get_funnel_data(:year)"), {"year": year})
        
        active_funnel = []
        for row in result_active:
            r = dict(row._mapping)
            if r.get("revenue") is not None:
                r["revenue"] = round(float(r["revenue"]), 2)
            active_funnel.append(r)

        # 2. Таблица 1: Жизненный цикл клиентов (Спящие / Ушедшие)
        desc_sleeping = f"Нет покупок в {year}, были в {year-1}"
        desc_left = f"Нет покупок в {year} и {year-1}"
        result_lifecycle = db.execute(text("""
            SELECT 
                sr.id AS status_id,
                sr.status_name,
                COUNT(DISTINCT c.code) AS count,
                CASE sr.id
                    WHEN 8 THEN :desc_sleeping
                    WHEN 9 THEN :desc_left
                    ELSE 'Неактивные клиенты'
                END AS description
            FROM clients c
            JOIN status_rules sr ON c.current_status_id = sr.id
            WHERE c.current_status_id IN (8, 9)
              AND c.code NOT IN ('9653', '11230')
            GROUP BY sr.id, sr.status_name
            ORDER BY CASE sr.id WHEN 8 THEN 1 WHEN 9 THEN 2 ELSE 3 END
        """), {"desc_sleeping": desc_sleeping, "desc_left": desc_left})

        lifecycle = []
        for row in result_lifecycle:
            r = dict(row._mapping)
            lifecycle.append({
                "status_id": r["status_id"],
                "status_name": r["status_name"],
                "count": r["count"],
                "description": r["description"]
            })

        # 3. Таблица 2: Новые клиенты по частоте покупок (только status_id=1)
        result_new = db.execute(text("SELECT * FROM get_new_clients_frequency(:year)"), {"year": year})

        new_clients_funnel = []
        for row in result_new:
            r = dict(row._mapping)
            new_clients_funnel.append({
                "stage": r["frequency_group"],
                "sort_order": r["sort_order"],
                "count": r["new_count"],
                "revenue": round(float(r["new_revenue"]), 2)
            })

        return {
            "status": "ok",
            "year": year,
            "funnel": active_funnel,
            "lifecycle": lifecycle,
            "new_clients_funnel": new_clients_funnel
        }
    except Exception as e:
        logger.error(f"Ошибка funnel: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== API: ТОП РЕКОМЕНДАЦИЙ (общие) ======
@app.get("/api/recommendations")
def top_recommendations(token: str = Query(None), limit: int = 10):
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(
            text("SELECT * FROM get_top_recommendations(:limit)"),
            {"limit": limit}
        )
        return [dict(row._mapping) for row in result]
    finally:
        db.close()
# ====== API: АНАЛИТИКА — МЕСЯЧНАЯ ДИНАМИКА ======
@app.get("/api/analytics/monthly-revenue")
def monthly_revenue(token: str = Query(None), year: int = 2026):
    """Динамика выручки по месяцам (товар + услуги)"""
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(text("SELECT * FROM get_monthly_revenue(:year)"), {"year": year})
        
        data = []
        for row in result:
            r = dict(row._mapping)
            # Преобразуем NUMERIC в float для JSON
            for key in ['goods_revenue', 'services_revenue', 'total_revenue']:
                if key in r and r[key] is not None:
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        
        return {"status": "ok", "year": year, "data": data, "count": len(data)}
    except Exception as e:
        logger.error(f"Ошибка monthly_revenue: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== API: АНАЛИТИКА — YoY СРАВНЕНИЕ ======
@app.get("/api/analytics/yoy-comparison")
def yoy_comparison(token: str = Query(None), year1: int = 2026, year2: int = 2025):
    """Сравнение двух годов (честный YoY — одни и те же клиенты в обоих годах)"""
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(text("SELECT * FROM get_yoy_comparison(:year1, :year2)"), {"year1": year1, "year2": year2})
        
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            # Добавляем % роста
            if r.get('goods_revenue_y2', 0) > 0:
                r['growth_pct'] = round(((r.get('goods_revenue_y1', 0) - r.get('goods_revenue_y2', 0)) / r['goods_revenue_y2']) * 100, 1)
            else:
                r['growth_pct'] = None
            data.append(r)
        
        return {"status": "ok", "year1": year1, "year2": year2, "data": data, "count": len(data)}
    except Exception as e:
        logger.error(f"Ошибка yoy_comparison: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

# ====== СТРАНИЦА: АНАЛИТИКА ПО КЛИЕНТАМ ======
@app.get("/analytics", response_class=HTMLResponse)
async def analytics_page(request: Request, token: str = Query(None)):
    verify_token(token)
    search_dirs = [FRONTEND_DIR, os.path.join(PROJECT_DIR, "frontend", "static"), os.path.join(ROOT_DIR, "frontend", "static")]
    filepath = find_file("analytics.html", search_dirs)
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница аналитики не найдена")

# ====== СТРАНИЦА: СРАВНЕНИЕ СЕГМЕНТОВ ======
@app.get("/comparison", response_class=HTMLResponse)
async def comparison_page(request: Request, token: str = Query(None)):
    verify_token(token)
    search_dirs = [FRONTEND_DIR, os.path.join(PROJECT_DIR, "frontend", "static"), os.path.join(ROOT_DIR, "frontend", "static")]
    filepath = find_file("comparison.html", search_dirs)
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница сравнения не найдена")

@app.get("/avg-check", response_class=HTMLResponse)
async def avg_check_page(request: Request, token: str = Query(None)):
    """Страница аналитики среднего чека"""
    verify_token(token)
    search_dirs = [FRONTEND_DIR, os.path.join(PROJECT_DIR, "frontend", "static"), os.path.join(ROOT_DIR, "frontend", "static")]
    filepath = find_file("avg-check.html", search_dirs)
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница аналитики среднего чека не найдена")

@app.get("/advanced", response_class=HTMLResponse)
async def advanced_page(request: Request, token: str = Query(None)):
    """Страница расширенной аналитики"""
    verify_token(token)
    search_dirs = [FRONTEND_DIR, os.path.join(PROJECT_DIR, "frontend", "static"), os.path.join(ROOT_DIR, "frontend", "static")]
    filepath = find_file("advanced.html", search_dirs)
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Расширенная страница аналитики не найдена")

    # ====== API: PIVOT ABC-ОТЧЁТ ======
@app.get("/api/analytics/pivot-report")
def pivot_report(
    token: str = Query(None),
    year: int = 2026,
    multiplier: float = 2.9,
    limit_price: float = 146000,
    direction: str = "below"
):
    """PIVOT-таблица ABC-сегментации из generate_custom_sales_report"""
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(
            text("SELECT * FROM generate_custom_sales_report(:year, :multiplier, :limit_price, :direction)"),
            {
                "year": year,
                "multiplier": multiplier,
                "limit_price": limit_price,
                "direction": direction
            }
        )
        
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        
        return {
            "status": "ok",
            "params": {
                "year": year,
                "multiplier": multiplier,
                "limit_price": limit_price,
                "direction": direction
            },
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка pivot_report: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== API: ФОРМАТИРОВАННЫЙ PIVOT-ОТЧЁТ ======
@app.get("/api/analytics/pivot-formatted")
def pivot_formatted(
    token: str = Query(None),
    year: int = 2026,
    multiplier: float = 2.9,
    limit_price: float = 146000
):
    """PIVOT-отчёт: группы C2 и ABC с правильными названиями метрик"""
    verify_token(token)
    db = get_db()
    try:
        below_result = db.execute(
            text("SELECT * FROM generate_custom_sales_report(:year, :multiplier, :limit_price, 'below')"),
            {"year": year, "multiplier": multiplier, "limit_price": limit_price}
        )
        above_result = db.execute(
            text("SELECT * FROM generate_custom_sales_report(:year, :multiplier, :limit_price, 'above')"),
            {"year": year, "multiplier": multiplier, "limit_price": limit_price}
        )
        
        def rows_to_list(result):
            data = []
            for row in result:
                r = dict(row._mapping)
                for key in r:
                    if r[key] is not None:
                        try:
                            r[key] = round(float(r[key]), 2)
                        except (ValueError, TypeError):
                            pass
                data.append(r)
            return data
        
        below_data = rows_to_list(below_result)
        above_data = rows_to_list(above_result)
        
        return {
            "status": "ok",
            "params": {"year": year, "multiplier": multiplier, "limit_price": limit_price},
            "below": below_data,
            "above": above_data,
            "below_count": len(below_data),
            "above_count": len(above_data)
        }
        
    except Exception as e:
        logger.error(f"Ошибка pivot_formatted: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== API: ABC-ГРУППЫ (ПИРАМИДА) ======
@app.get("/api/analytics/abc-groups")
def abc_groups(
    token: str = Query(None),
    year: int = 2026,
    multiplier: float = 2.9
):
    """ABC-сегментация: группы A1..C2 + Total (из get_abc_groups)"""
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(
            text("SELECT * FROM get_abc_groups(:year, :multiplier)"),
            {"year": year, "multiplier": multiplier}
        )
        
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        
        return {
            "status": "ok",
            "params": {"year": year, "multiplier": multiplier},
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка abc_groups: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

# ======================================================================
# API ДЛЯ СТРАНИЦЫ /monthly — АНАЛИТИКА ЗА МЕСЯЦ
# ======================================================================

# ====== 1. ДИНАМИКА ПО ДНЯМ ======
@app.get("/api/analytics/daily-revenue")
def daily_revenue(
    token: str = Query(None),
    year: int = 2026,
    month: int = 5
):
    """Выручка по дням внутри месяца"""
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(
            text("SELECT * FROM get_daily_revenue(:year, :month)"),
            {"year": year, "month": month}
        )
        
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        
        return {"status": "ok", "year": year, "month": month, "data": data, "count": len(data)}
    except Exception as e:
        logger.error(f"Ошибка daily_revenue: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== 2. СРАВНЕНИЕ МЕСЯЦЕВ ======
@app.get("/api/analytics/monthly-detail")
def monthly_detail(
    token: str = Query(None),
    year: int = 2026,
    month: int = 5
):
    """Метрики за текущий и прошлый месяц + структура товары/услуги"""
    verify_token(token)
    db = get_db()
    try:
        # Текущий месяц
        current = db.execute(
            text("SELECT * FROM get_monthly_detail_metrics(:year, :month)"),
            {"year": year, "month": month}
        ).first()
        
        # Прошлый месяц
        prev_month = month - 1
        prev_year = year
        if prev_month == 0:
            prev_month = 12
            prev_year = year - 1
        
        previous = db.execute(
            text("SELECT * FROM get_monthly_detail_metrics(:year, :month)"),
            {"year": prev_year, "month": prev_month}
        ).first()
        
        def row_to_dict(row):
            if not row: return {}
            r = dict(row._mapping)
            for k in r:
                if r[k] is not None:
                    r[k] = round(float(r[k]), 2)
                else:
                    r[k] = 0.0
            return r
        
        current_dict = row_to_dict(current)
        previous_dict = row_to_dict(previous)
        
        # Расчёт роста
        growth = {}
        for key in ['goods_revenue', 'invoice_count', 'active_clients', 'services_revenue']:
            prev_val = previous_dict.get(key, 0) or 0
            curr_val = current_dict.get(key, 0) or 0
            growth[key] = round(float((curr_val - prev_val) / prev_val * 100), 1) if prev_val > 0 else None
        
        # Средний чек
        curr_inv = max(current_dict.get('invoice_count', 1), 1)
        prev_inv = max(previous_dict.get('invoice_count', 1), 1)
        current_dict['avg_ticket'] = round(float(current_dict.get('goods_revenue', 0)) / float(curr_inv), 2)
        previous_dict['avg_ticket'] = round(float(previous_dict.get('goods_revenue', 0)) / float(prev_inv), 2)
        
        prev_ticket = previous_dict.get('avg_ticket', 0) or 0
        curr_ticket = current_dict.get('avg_ticket', 0) or 0
        growth['avg_ticket'] = round(float((curr_ticket - prev_ticket) / prev_ticket * 100), 1) if prev_ticket > 0 else None
        
        return {
            "status": "ok",
            "current": {"year": year, "month": month, **current_dict},
            "previous": {"year": prev_year, "month": prev_month, **previous_dict},
            "growth": growth
        }
    except Exception as e:
        logger.error(f"Ошибка monthly_detail: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== 3. МИГРАЦИЯ ABC-ГРУПП ======
@app.get("/api/analytics/abc-migration")
def abc_migration(
    token: str = Query(None),
    year: int = 2026,
    groups: str = "A1,A2,B1,B2",
    multiplier: float = 2.9
):
    """
    Клиенты с ABC-группой groups в year-1 → их метрики в year.
    groups: список через запятую (A1,A2,B1,B2 или C1,C2)
    """
    verify_token(token)
    db = get_db()
    try:
        year_prev = year - 1
        group_list = [g.strip() for g in groups.split(",")]
        
        result = db.execute(
            text("SELECT * FROM get_abc_migration(:year, :groups, :multiplier)"),
            {"year": year, "groups": group_list, "multiplier": multiplier}
        )
        
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        
        return {
            "status": "ok",
            "year_prev": year_prev,
            "year": year,
            "groups": groups,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка abc_migration: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== 4. ЗАЛЁТНЫЕ (C1/C2 + Новые) ======
@app.get("/api/analytics/zaletnye")
def zaletnye(
    token: str = Query(None),
    year: int = 2026,
    multiplier: float = 2.9
):
    """Залётные: C1/C2 в прошлом году + новые клиенты → их метрики в текущем"""
    verify_token(token)
    db = get_db()
    try:
        year_prev = year - 1
        
        result = db.execute(
            text("SELECT * FROM get_zaletnye(:year, :multiplier)"),
            {"year": year, "multiplier": multiplier}
        )
        
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        
        return {
            "status": "ok",
            "year_prev": year_prev,
            "year": year,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка zaletnye: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== 5. ОТРАСЛИ ЗА МЕСЯЦ ======
@app.get("/api/analytics/monthly-directions")
def monthly_directions(
    token: str = Query(None),
    year: int = 2026,
    month: int = 5
):
    """Выручка по направлениям за месяц"""
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(
            text("SELECT * FROM get_monthly_directions(:year, :month)"),
            {"year": year, "month": month}
        )
        
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        
        return {"status": "ok", "year": year, "month": month, "data": data, "count": len(data)}
    except Exception as e:
        logger.error(f"Ошибка monthly_directions: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== 6. ТОП-ТОВАРЫ ЗА МЕСЯЦ ======
@app.get("/api/analytics/monthly-products")
def monthly_products(
    token: str = Query(None),
    year: int = 2026,
    month: int = 5,
    limit: int = 10
):
    """Топ товаров за месяц"""
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(
            text("SELECT * FROM get_monthly_products(:year, :month, :limit)"),
            {"year": year, "month": month, "limit": limit}
        )
        
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        
        return {"status": "ok", "year": year, "month": month, "data": data, "count": len(data)}
    except Exception as e:
        logger.error(f"Ошибка monthly_products: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== 7. ТОП-КЛИЕНТЫ ЗА МЕСЯЦ ======
@app.get("/api/analytics/monthly-top-clients")
def monthly_top_clients(
    token: str = Query(None),
    year: int = 2026,
    month: int = 5,
    limit: int = 10,
    multiplier: float = 2.9
):
    """Топ-клиенты за месяц с ABC-группой из прошлого года"""
    verify_token(token)
    db = get_db()
    try:
        year_prev = year - 1
        
        result = db.execute(
            text("SELECT * FROM get_monthly_top_clients(:year, :month, :year_prev, :mult, :limit)"),
            {
                "year": year,
                "month": month,
                "year_prev": year_prev,
                "mult": multiplier,
                "limit": limit
            }
        )
        
        data = []
        for i, row in enumerate(result):
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            r["position"] = i + 1
            data.append(r)
        
        return {"status": "ok", "year": year, "month": month, "data": data, "count": len(data)}
    except Exception as e:
        logger.error(f"Ошибка monthly_top_clients: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== СТРАНИЦА /monthly ======
@app.get("/monthly", response_class=HTMLResponse)
async def monthly_page(request: Request, token: str = Query(None)):
    verify_token(token)
    search_dirs = [FRONTEND_DIR, os.path.join(PROJECT_DIR, "frontend", "static"), os.path.join(ROOT_DIR, "frontend", "static")]
    filepath = find_file("monthly.html", search_dirs)
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница помесячной аналитики не найдена")

# ====== 0. КОЛИЧЕСТВО АКТИВНЫХ КЛИЕНТОВ ЗА ГОД ======
@app.get("/api/analytics/yearly-clients-count")
def yearly_clients_count(
    token: str = Query(None),
    year: int = 2026
):
    """Количество активных клиентов за год (из client_year_activity)"""
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(
            text("SELECT get_yearly_clients_count(:year)"),
            {"year": year}
        ).scalar()
        
        return {"status": "ok", "year": year, "active_clients": result}
    except Exception as e:
        logger.error(f"Ошибка yearly_clients_count: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()

# ====== ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ДЛЯ ABC-СРАВНЕНИЯ ======

def fetch_pivot_data_sync(year, multiplier, limit_price, direction):
    """Синхронная версия получения PIVOT-данных"""
    db = get_db()
    try:
        result = db.execute(
            text("SELECT * FROM generate_custom_sales_report(:year, :multiplier, :limit_price, :direction)"),
            {
                "year": year,
                "multiplier": multiplier,
                "limit_price": limit_price,
                "direction": direction
            }
        )
        
        data = []
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            data.append(r)
        return data
    except Exception as e:
        logger.error(f"Ошибка fetch_pivot_data для {direction}: {e}")
        return []
    finally:
        db.close()


def parse_pivot_data(below_data, above_data):
    """Парсит PIVOT-данные в формат с groups"""
    result = {
        "groups": [],
        "pivot": {
            "below": below_data,
            "above": above_data
        }
    }
    
    # Собираем группы из above (ABC-группы)
    groups_dict = {}
    
    for row in above_data:
        group_name = row.get('out_group_name')
        metric = row.get('out_metric')
        
        if group_name and group_name not in ['Total', 'Итого']:
            if group_name not in groups_dict:
                groups_dict[group_name] = {
                    'out_group_name': group_name,
                    'out_total_companies': 0,
                    'out_total_sales': 0,
                    'out_total_invoices': 0
                }
            
            if metric == 'Кол-во компаний':
                groups_dict[group_name]['out_total_companies'] = row.get('out_total', 0)
            elif metric == 'Сумма продаж':
                groups_dict[group_name]['out_total_sales'] = row.get('out_total', 0)
            elif metric == 'Накладных':
                groups_dict[group_name]['out_total_invoices'] = row.get('out_total', 0)
    
    # Конвертируем в список
    result['groups'] = list(groups_dict.values())
    
    # Сортируем по порядку
    order = {'A1': 1, 'A2': 2, 'A3': 3, 'B1': 4, 'B2': 5, 'C1': 6, 'C2': 7}
    result['groups'].sort(key=lambda x: order.get(x.get('out_group_name', ''), 99))
    
    # Добавляем Total
    total_data = None
    for row in above_data:
        if row.get('out_group_name') == 'Total':
            if row.get('out_metric') == 'Кол-во компаний':
                if not total_data:
                    total_data = {'out_group_name': 'Total', 'out_total_companies': 0, 'out_total_sales': 0, 'out_total_invoices': 0}
                total_data['out_total_companies'] = row.get('out_total', 0)
            elif row.get('out_metric') == 'Сумма продаж':
                if not total_data:
                    total_data = {'out_group_name': 'Total', 'out_total_companies': 0, 'out_total_sales': 0, 'out_total_invoices': 0}
                total_data['out_total_sales'] = row.get('out_total', 0)
            elif row.get('out_metric') == 'Накладных':
                if not total_data:
                    total_data = {'out_group_name': 'Total', 'out_total_companies': 0, 'out_total_sales': 0, 'out_total_invoices': 0}
                total_data['out_total_invoices'] = row.get('out_total', 0)
    
    if total_data:
        result['groups'].append(total_data)
    
    return result


# ====== API: СРАВНЕНИЕ ABC ======
@app.get("/api/analytics/abc-comparison")
def abc_comparison(
    token: str = Query(None),
    year: int = 2026,
    multiplier: float = 2.9,
    limit_price: float = 146000
):
    """Сравнение ABC-сегментации за два года"""
    verify_token(token)
    
    try:
        prev_year = year - 1
        
        # Текущий год
        current_below = fetch_pivot_data_sync(year, multiplier, limit_price, "below")
        current_above = fetch_pivot_data_sync(year, multiplier, limit_price, "above")
        current_data = parse_pivot_data(current_below, current_above)
        
        # Предыдущий год
        prev_below = fetch_pivot_data_sync(prev_year, multiplier, limit_price, "below")
        prev_above = fetch_pivot_data_sync(prev_year, multiplier, limit_price, "above")
        prev_data = parse_pivot_data(prev_below, prev_above)
        
        return {
            "status": "ok",
            "current_year": year,
            "prev_year": prev_year,
            "current": current_data,
            "prev": prev_data
        }
        
    except Exception as e:
        logger.error(f"Ошибка abc_comparison: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ====== API: ПОВТОРНЫЕ КЛИЕНТЫ (2-3 накладных) ======
@app.get("/api/analytics/recurrent-clients")
def recurrent_clients(
    token: str = Query(None),
    year: int = 2026,
    multiplier: float = 2.9
):
    """Детальный список повторных клиентов (2-3 накладных за год) с ABC-группой"""
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(
            text("SELECT * FROM get_recurrent_clients(:year, :multiplier)"),
            {"year": year, "multiplier": multiplier}
        )

        data = []
        for row in result:
            r = dict(row._mapping)
            days = r.get('days_between') or 0
            inv_count = int(r.get('invoice_count', 2))
            # Классификация по паттерну повторности
            if days <= 7:
                rec_class = 'g1'
                rec_label = 'Ближе к разовым'
                recommendation = 'Стимулировать регулярность'
            elif inv_count >= 3:
                rec_class = 'g3'
                rec_label = 'Ближе к постоянным'
                recommendation = 'Программа лояльности'
            else:
                rec_class = 'g2'
                rec_label = 'Повторные (Центр)'
                recommendation = 'Рамочное соглашение'

            data.append({
                "client_code": r['client_code'],
                "client_name": r['name'] or '',
                "ipn": r['ipn'] or '',
                "okpo": r['okpo_code'] or '',
                "invoice_count": inv_count,
                "goods_revenue": float(r['goods_revenue'] or 0),
                "first_date": str(r['first_date']) if r['first_date'] else '',
                "last_date": str(r['last_date']) if r['last_date'] else '',
                "days_between": days,
                "abc_group": r.get('abc_group', 'C2'),
                "rec_class": rec_class,
                "rec_label": rec_label,
                "recommendation": recommendation
            })

        return {"status": "ok", "year": year, "data": data, "count": len(data)}
    except Exception as e:
        logger.error(f"Ошибка recurrent_clients: {e}")
        return {"status": "error", "detail": str(e)}
    finally:
        db.close()


# ====== API: YoY-СРАВНЕНИЕ КЛИЕНТОВ С ABC-ГРУППАМИ ======
@app.get("/api/analytics/clients-yoy")
def clients_yoy(
    token: str = Query(None),
    year: int = 2026,
    multiplier: float = 2.9
):
    """YoY-сравнение клиентов: ABC-группа текущего и прошлого года, выручка, изменение"""
    verify_token(token)
    db = get_db()
    try:
        year_prev = year - 1

        result = db.execute(
            text("SELECT * FROM get_clients_yoy(:year, :multiplier)"),
            {"year": year, "multiplier": multiplier}
        )

        data = []
        for row in result:
            r = dict(row._mapping)
            rev_c = float(r.get('revenue_curr') or 0)
            rev_p = float(r.get('revenue_prev') or 0)
            delta_pct = round((rev_c - rev_p) / rev_p * 100, 1) if rev_p > 0 else None
            data.append({
                "client_code": r['client_code'],
                "client_name": r['client_name'] or '',
                "revenue_curr": rev_c,
                "revenue_prev": rev_p,
                "invoices_curr": int(r.get('invoices_curr') or 0),
                "invoices_prev": int(r.get('invoices_prev') or 0),
                "abc_curr": r.get('abc_curr', 'Новый'),
                "abc_prev": r.get('abc_prev', 'Новый'),
                "delta_pct": delta_pct,
                "is_new": rev_p == 0,
                "is_lost": rev_c == 0
            })

        # Агрегированная статистика по группам
                # Агрегированная статистика по группам (только основные ABC-группы)
        groups_order = ['A1', 'A2', 'A3', 'B1', 'B2', 'C1', 'C2']
        stats_curr = {}
        stats_prev = {}
        for d in data:
            g = d['abc_curr']
            if g in groups_order:  # 🔥 Только основные группы
                if g not in stats_curr:
                    stats_curr[g] = {'group': g, 'count': 0, 'revenue': 0}
                stats_curr[g]['count'] += 1
                stats_curr[g]['revenue'] += d['revenue_curr']

            g2 = d['abc_prev']
            if g2 in groups_order:  # 🔥 Только основные группы
                if g2 not in stats_prev:
                    stats_prev[g2] = {'group': g2, 'count': 0, 'revenue': 0}
                stats_prev[g2]['count'] += 1
                stats_prev[g2]['revenue'] += d['revenue_prev']

                # Определяем максимальный месяц
        max_month_curr = db.execute(
            text("SELECT COALESCE(MAX(EXTRACT(MONTH FROM invoice_date)), 12) FROM documents WHERE EXTRACT(YEAR FROM invoice_date) = :year"),
            {"year": year}
        ).scalar()
        
        month_names = ['','Январь','Февраль','Март','Апрель','Май','Июнь','Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь']

        return {
            "status": "ok",
            "year": year,
            "year_prev": year_prev,
            "max_month": int(max_month_curr),
            "note": f"Сравнение за {int(max_month_curr)} мес. ({month_names[int(max_month_curr)]})",
            "data": data,
            "count": len(data),
            "stats_curr": [stats_curr[g] for g in groups_order if g in stats_curr],
            "stats_prev": [stats_prev[g] for g in groups_order if g in stats_prev]
        }
    except Exception as e:
        logger.error(f"Ошибка clients_yoy: {e}")
        return {"status": "error", "detail": str(e)}
    finally:
        db.close()


# ====== API: СРАВНЕНИЕ СЕГМЕНТОВ ======
@app.get("/api/analytics/segment-comparison")
def get_segment_comparison(
    token: str = Query(None),
    year_current: int = 2026,
    year_previous: int = 2025
):
    """
    Полный набор данных для страницы сравнения сегментов.
    Возвращает 6 групп RFM + 4 альтернативные группы.
    Использует функции get_rfm_funnel и get_alt_funnel.
    """
    verify_token(token)
    db = get_db()
    
    try:
        rfm_data = {}
        alt_data = {}
        
        for year in [year_current, year_previous]:
            # 1. 6 RFM групп
            rows_rfm = db.execute(
                text("SELECT * FROM get_rfm_funnel(:year)"),
                {"year": year}
            ).fetchall()

            groups_rfm = {
                'one': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0},
                'repeat': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0},
                'quarter': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0},
                'month': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0},
                'week': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0},
                'day': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0}
            }
            
            for row in rows_rfm:
                r = dict(row._mapping)
                g_key = r['rfm_group']
                if g_key in groups_rfm:
                    groups_rfm[g_key] = {
                        'companies': int(r['companies'] or 0),
                        'invoices': int(r['invoices'] or 0),
                        'sales': float(r['sales'] or 0),
                        'avg_check': float(r['avg_check'] or 0)
                    }
            
            total_companies_rfm = sum(g['companies'] for g in groups_rfm.values())
            total_sales_rfm = sum(g['sales'] for g in groups_rfm.values())
            
            rfm_data[str(year)] = {
                'groups': groups_rfm,
                'total_companies': total_companies_rfm,
                'total_invoices': sum(g['invoices'] for g in groups_rfm.values()),
                'total_sales': total_sales_rfm,
                'avg_check': round(total_sales_rfm / total_companies_rfm, 2) if total_companies_rfm else 0
            }
            
            # 2. Альтернативная классификация (4 группы)
            rows_alt = db.execute(
                text("SELECT * FROM get_alt_funnel(:year, 2.9, 146000)"),
                {"year": year}
            ).fetchall()

            groups_alt = {}
            tot_comp_alt = 0
            tot_sales_alt = 0.0
            for row in rows_alt:
                r = dict(row._mapping)
                k = r['group_key']
                comp = int(r['companies'] or 0)
                sales = float(r['sales'] or 0)
                avg_chk = float(r['avg_check'] or 0)
                groups_alt[k] = {'companies': comp, 'sales': sales, 'avg_check': avg_chk}
                tot_comp_alt += comp
                tot_sales_alt += sales
            
            alt_data[str(year)] = {
                'groups': groups_alt,
                'total_companies': tot_comp_alt,
                'total_sales': round(tot_sales_alt, 2)
            }
            
        return {
            "status": "ok",
            "rfm": rfm_data,
            "alt": alt_data,
            "years": {
                "current": year_current,
                "previous": year_previous
            }
        }
    except Exception as e:
        logger.error(f"Ошибка в get_segment_comparison: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== API: СТРУКТУРНЫЙ АНАЛИЗ ABC ======
@app.get("/api/analytics/abc-structure")
def abc_structure(
    token: str = Query(None),
    year: int = 2026,
    multiplier: float = 2.9,
    limit_price: float = 146000,
    active_only: bool = True
):
    """Возвращает структурированные данные для 4 секций ABC-анализа"""
    verify_token(token)
    db = get_db()
    try:
        # Получаем данные через функцию get_abc_structure_data
        report_rows = db.execute(
            text("SELECT * FROM get_abc_structure_data(:year, :multiplier, :limit_price)"),
            {"year": year, "multiplier": multiplier, "limit_price": limit_price}
        ).fetchall()
        
        if not report_rows:
            return {"status": "ok", "data": {"sections": {}, "year": year, "active_count": 0}}

        below_rows = [r for r in report_rows if r._mapping.get('out_direction') == 'below']
        above_rows = [r for r in report_rows if r._mapping.get('out_direction') == 'above']
        
        def parse_data(result):
            """Парсит результат в структуру {группа: {метрика: {диапазон: значение}}}"""
            data = {}
            for row in result:
                r = dict(row._mapping)
                group = r.get('out_group_name')
                metric = r.get('out_metric')
                if group not in data:
                    data[group] = {}
                data[group][metric] = {
                    '1': float(r.get('out_1', 0) or 0),
                    '2_3': float(r.get('out_2_3', 0) or 0),
                    '4_10': float(r.get('out_4_10', 0) or 0),
                    '11_40': float(r.get('out_11_40', 0) or 0),
                    '41_170': float(r.get('out_41_170', 0) or 0),
                    '171_plus': float(r.get('out_171_plus', 0) or 0),
                    'total': float(r.get('out_total', 0) or 0)
                }
            return data
        
        below = parse_data(below_rows)
        above = parse_data(above_rows)

        def get_metric_dict(data_dict, default_grp, metric_name):
            if metric_name == 'Накладных':
                return data_dict.get('Всего', {}).get('Накладных', {}) or data_dict.get(default_grp, {}).get('Накладных', {})
            return data_dict.get(default_grp, {}).get(metric_name, {})

        metric_names = ['Кол-во компаний', 'Накладных', 'Сумма продаж', 'Средний чек', '% от общ']
        metric_keys = ['companies', 'invoices', 'sales', 'avg_ticket', 'pct']
        ranges = ['1', '2_3', '4_10', '11_40', '41_170', '171_plus']

        c2_sec = {}
        abc_sec = {}
        for i, metric in enumerate(metric_names):
            k = metric_keys[i]
            c2_sec[k] = get_metric_dict(below, 'C2', metric) or {'1': 0, '2_3': 0, '4_10': 0, '11_40': 0, '41_170': 0, '171_plus': 0, 'total': 0}
            abc_sec[k] = get_metric_dict(above, 'ABC', metric) or {'1': 0, '2_3': 0, '4_10': 0, '11_40': 0, '41_170': 0, '171_plus': 0, 'total': 0}

        grand_sales = (c2_sec['sales'].get('total', 0) + abc_sec['sales'].get('total', 0)) or 1.0

        # Корректируем % от общ относительного общего итога (C2 + ABC)
        c2_sec['pct'] = {r: round(c2_sec['sales'].get(r, 0) / grand_sales * 100, 2) for r in ranges}
        c2_sec['pct']['total'] = round(c2_sec['sales'].get('total', 0) / grand_sales * 100, 2)

        abc_sec['pct'] = {r: round(abc_sec['sales'].get(r, 0) / grand_sales * 100, 2) for r in ranges}
        abc_sec['pct']['total'] = round(abc_sec['sales'].get('total', 0) / grand_sales * 100, 2)

        # Рассчитываем Total (Случайные C2 + Основные ABC)
        total_sec = {
            'companies': {r: c2_sec['companies'].get(r, 0) + abc_sec['companies'].get(r, 0) for r in ranges},
            'invoices': {r: c2_sec['invoices'].get(r, 0) + abc_sec['invoices'].get(r, 0) for r in ranges},
            'sales': {r: c2_sec['sales'].get(r, 0) + abc_sec['sales'].get(r, 0) for r in ranges},
        }
        total_sec['companies']['total'] = sum(total_sec['companies'][r] for r in ranges)
        total_sec['invoices']['total'] = sum(total_sec['invoices'][r] for r in ranges)
        total_sec['sales']['total'] = sum(total_sec['sales'][r] for r in ranges)
        total_sec['avg_ticket'] = {
            r: round(total_sec['sales'][r] / total_sec['invoices'][r], 2) if total_sec['invoices'][r] else 0.0 for r in ranges
        }
        total_sec['avg_ticket']['total'] = round(total_sec['sales']['total'] / total_sec['invoices']['total'], 2) if total_sec['invoices']['total'] else 0.0
        total_sec['pct'] = {r: round(total_sec['sales'][r] / grand_sales * 100, 2) for r in ranges}
        total_sec['pct']['total'] = round(total_sec['sales']['total'] / grand_sales * 100, 2)

        # Рассчитываем Important (ABC + C2 с 4+ документами)
        c2_4plus_ranges = ['4_10', '11_40', '41_170', '171_plus']
        imp_sec = {
            'companies': {r: abc_sec['companies'].get(r, 0) + (c2_sec['companies'].get(r, 0) if r in c2_4plus_ranges else 0) for r in ranges},
            'invoices': {r: abc_sec['invoices'].get(r, 0) + (c2_sec['invoices'].get(r, 0) if r in c2_4plus_ranges else 0) for r in ranges},
            'sales': {r: abc_sec['sales'].get(r, 0) + (c2_sec['sales'].get(r, 0) if r in c2_4plus_ranges else 0) for r in ranges},
        }
        imp_sec['companies']['total'] = sum(imp_sec['companies'][r] for r in ranges)
        imp_sec['invoices']['total'] = sum(imp_sec['invoices'][r] for r in ranges)
        imp_sec['sales']['total'] = sum(imp_sec['sales'][r] for r in ranges)
        imp_sec['avg_ticket'] = {
            r: round(imp_sec['sales'][r] / imp_sec['invoices'][r], 2) if imp_sec['invoices'][r] else 0.0 for r in ranges
        }
        imp_sec['avg_ticket']['total'] = round(imp_sec['sales']['total'] / imp_sec['invoices']['total'], 2) if imp_sec['invoices']['total'] else 0.0
        imp_sec['pct'] = {r: round(imp_sec['sales'][r] / grand_sales * 100, 2) for r in ranges}
        imp_sec['pct']['total'] = round(imp_sec['sales']['total'] / grand_sales * 100, 2)

        c2_sec['name'] = 'Случайные C2'
        c2_sec['icon'] = '📥'
        abc_sec['name'] = 'Основные ABC'
        abc_sec['icon'] = '📈'
        total_sec['name'] = 'Все ABC'
        total_sec['icon'] = '📊'
        imp_sec['name'] = 'Важные — ABC'
        imp_sec['icon'] = '⭐'

        result = {
            'year': year,
            'multiplier': multiplier,
            'limit_price': limit_price,
            'active_count': int(total_sec['companies']['total']),
            'sections': {
                'c2': c2_sec,
                'abc': abc_sec,
                'total': total_sec,
                'important': imp_sec
            }
        }
        return {'status': 'ok', 'data': result}

    except Exception as e:
        logger.error(f"Ошибка abc_structure: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== API: ДЕТАЛЬНЫЙ АНАЛИЗ C2 ======
@app.get("/api/analytics/c2-detail")
def c2_detail(
    token: str = Query(None),
    year: int = 2026,
    multiplier: float = 2.9,
    limit_price: float = 146000,
    active_only: bool = True
):
    """Глубокий анализ сегмента C2 с распаковкой повторных и внутренней ABC-классификацией"""
    verify_token(token)
    db = get_db()
    try:
        sql = text("SELECT * FROM get_c2_detail(:year, :multiplier, :limit_price)")
        rows = db.execute(sql, {"year": year, "multiplier": multiplier, "limit_price": limit_price}).fetchall()
        rows_prev = db.execute(sql, {"year": year - 1, "multiplier": multiplier, "limit_price": limit_price}).fetchall()
        
        freq_groups = ['1', '2_1d', '2_diff', '3', '4_10', '11_40', '41_plus']
        classes = ['A', 'B', 'C']
        
        matrix = {cls: {fg: {'comp': 0, 'inv': 0, 'sales': 0.0} for fg in freq_groups} for cls in classes}
        matrix_prev = {cls: {fg: {'comp': 0, 'inv': 0, 'sales': 0.0} for fg in freq_groups} for cls in classes}
        local_abc = {cls: {'comp': 0, 'inv': 0, 'sales': 0.0} for cls in classes}
        repeat_decomp = {fg: {'comp': 0, 'inv': 0, 'sales': 0.0} for fg in freq_groups}
        
        total_comp = 0
        total_inv = 0
        total_sales = 0.0
        
        for r in rows:
            cls = r.internal_class
            fg = r.freq_group
            sales = float(r.goods_revenue or 0)
            inv = int(r.invoices_count or 0)
            
            total_comp += 1
            total_inv += inv
            total_sales += sales
            
            local_abc[cls]['comp'] += 1
            local_abc[cls]['inv'] += inv
            local_abc[cls]['sales'] += sales
            
            repeat_decomp[fg]['comp'] += 1
            repeat_decomp[fg]['inv'] += inv
            repeat_decomp[fg]['sales'] += sales
            
            matrix[cls][fg]['comp'] += 1
            matrix[cls][fg]['inv'] += inv
            matrix[cls][fg]['sales'] += sales

        for r in rows_prev:
            cls = r.internal_class
            fg = r.freq_group
            sales = float(r.goods_revenue or 0)
            inv = int(r.invoices_count or 0)
            matrix_prev[cls][fg]['comp'] += 1
            matrix_prev[cls][fg]['inv'] += inv
            matrix_prev[cls][fg]['sales'] += sales

        comp_2_1d = repeat_decomp['2_1d']['comp']
        comp_2_diff = repeat_decomp['2_diff']['comp']
        total_2_comp = comp_2_1d + comp_2_diff
        false_repeat_pct = round(comp_2_1d / total_2_comp * 100, 1) if total_2_comp > 0 else 0.0
        
        class_a_sales_pct = round(local_abc['A']['sales'] / total_sales * 100, 1) if total_sales > 0 else 0.0
        class_a_comp_pct = round(local_abc['A']['comp'] / total_comp * 100, 1) if total_comp > 0 else 0.0

        return {
            "status": "ok",
            "year": year,
            "year_prev": year - 1,
            "limit_price": limit_price,
            "data": {
                "total_companies": total_comp,
                "total_invoices": total_inv,
                "total_sales": round(total_sales, 2),
                "avg_ticket": round(total_sales / total_inv, 2) if total_inv else 0.0,
                "local_abc": local_abc,
                "repeat_decomp": repeat_decomp,
                "matrix": matrix,
                "matrix_prev": matrix_prev,
                "kpis": {
                    "false_repeat_pct": false_repeat_pct,
                    "class_a_sales_pct": class_a_sales_pct,
                    "class_a_comp_pct": class_a_comp_pct,
                    "false_repeat_comp": comp_2_1d,
                    "true_repeat_comp": comp_2_diff
                }
            }
        }
    except Exception as e:
        logger.error(f"Ошибка c2_detail: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== API: УНИВЕРСАЛЬНЫЙ ДЕТАЛЬНЫЙ АНАЛИЗ СЕГМЕНТОВ ======
@app.get("/api/analytics/segment-detail")
def segment_detail(
    token: str = Query(None),
    segment: str = Query("abc"),
    year: int = 2026,
    multiplier: float = 2.9,
    limit_price: float = 146000,
    active_only: bool = True
):
    """Детальный анализ любого сегмента (c2, abc, total, important) с матрицей и локальным ABC"""
    verify_token(token)
    db = get_db()
    try:
        sql = text("SELECT * FROM get_segment_detail(:segment, :year, :multiplier, :limit_price)")
        
        rows = db.execute(sql, {"segment": segment, "year": year, "multiplier": multiplier, "limit_price": limit_price}).fetchall()
        rows_prev = db.execute(sql, {"segment": segment, "year": year - 1, "multiplier": multiplier, "limit_price": limit_price}).fetchall()
        
        freq_groups = ['1', '2_1d', '2_diff', '3', '4_10', '11_40', '41_170', '171_plus']
        classes = ['A', 'B', 'C']
        
        matrix = {cls: {fg: {'comp': 0, 'inv': 0, 'sales': 0.0} for fg in freq_groups} for cls in classes}
        matrix_prev = {cls: {fg: {'comp': 0, 'inv': 0, 'sales': 0.0} for fg in freq_groups} for cls in classes}
        local_abc = {cls: {'comp': 0, 'inv': 0, 'sales': 0.0} for cls in classes}
        repeat_decomp = {fg: {'comp': 0, 'inv': 0, 'sales': 0.0} for fg in freq_groups}
        
        total_comp = 0
        total_inv = 0
        total_sales = 0.0
        
        for r in rows:
            cls = r.internal_class
            fg = r.freq_group
            sales = float(r.goods_revenue or 0)
            inv = int(r.invoices_count or 0)
            
            total_comp += 1
            total_inv += inv
            total_sales += sales
            
            local_abc[cls]['comp'] += 1
            local_abc[cls]['inv'] += inv
            local_abc[cls]['sales'] += sales
            
            repeat_decomp[fg]['comp'] += 1
            repeat_decomp[fg]['inv'] += inv
            repeat_decomp[fg]['sales'] += sales
            
            matrix[cls][fg]['comp'] += 1
            matrix[cls][fg]['inv'] += inv
            matrix[cls][fg]['sales'] += sales

        for r in rows_prev:
            cls = r.internal_class
            fg = r.freq_group
            sales = float(r.goods_revenue or 0)
            inv = int(r.invoices_count or 0)
            matrix_prev[cls][fg]['comp'] += 1
            matrix_prev[cls][fg]['inv'] += inv
            matrix_prev[cls][fg]['sales'] += sales

        comp_2_1d = repeat_decomp['2_1d']['comp']
        comp_2_diff = repeat_decomp['2_diff']['comp']
        total_2_comp = comp_2_1d + comp_2_diff
        false_repeat_pct = round(comp_2_1d / total_2_comp * 100, 1) if total_2_comp > 0 else 0.0
        
        class_a_sales_pct = round(local_abc['A']['sales'] / total_sales * 100, 1) if total_sales > 0 else 0.0
        class_a_comp_pct = round(local_abc['A']['comp'] / total_comp * 100, 1) if total_comp > 0 else 0.0

        return {
            "status": "ok",
            "segment": segment,
            "year": year,
            "year_prev": year - 1,
            "limit_price": limit_price,
            "data": {
                "total_companies": total_comp,
                "total_invoices": total_inv,
                "total_sales": round(total_sales, 2),
                "avg_ticket": round(total_sales / total_inv, 2) if total_inv else 0.0,
                "local_abc": local_abc,
                "repeat_decomp": repeat_decomp,
                "matrix": matrix,
                "matrix_prev": matrix_prev,
                "kpis": {
                    "false_repeat_pct": false_repeat_pct,
                    "class_a_sales_pct": class_a_sales_pct,
                    "class_a_comp_pct": class_a_comp_pct,
                    "false_repeat_comp": comp_2_1d,
                    "true_repeat_comp": comp_2_diff
                }
            }
        }
    except Exception as e:
        logger.error(f"Ошибка segment_detail: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== API: ДЕТАЛЬНЫЙ АНАЛИЗ ОСНОВНЫХ ABC ======
@app.get("/api/analytics/abc-groups-detail")
def abc_groups_detail(
    token: str = Query(None),
    year: int = 2026,
    multiplier: float = 2.9,
    limit_price: float = 146000
):
    """Детальный анализ ABC-сегмента по группам A1, A2, A3, B1, B2, C1"""
    verify_token(token)
    db = get_db()
    try:
        sql = text("SELECT * FROM get_abc_groups_detail(:year, :multiplier, :limit_price)")
        rows = db.execute(sql, {"year": year, "multiplier": multiplier, "limit_price": limit_price}).fetchall()
        
        group_names = {
            'A1': 'A1 (>8.7 млн ₴)',
            'A2': 'A2 (5.8 - 8.7 млн ₴)',
            'A3': 'A3 (4.35 - 5.8 млн ₴)',
            'B1': 'B1 (2.9 - 4.35 млн ₴)',
            'B2': 'B2 (1.45 - 2.9 млн ₴)',
            'C1': 'C1 (435 тыс - 1.45 млн ₴)',
            'C2_above': 'C2 выше границы'
        }
        
        total_sales = sum(float(r.sales or 0) for r in rows)
        total_comp = sum(int(r.companies or 0) for r in rows)
        total_inv = sum(int(r.invoices or 0) for r in rows)
        
        groups_data = {}
        for r in rows:
            grp = r.abc_group
            sales = float(r.sales or 0)
            comp = int(r.companies or 0)
            inv = int(r.invoices or 0)
            groups_data[grp] = {
                'name': group_names.get(grp, grp),
                'companies': comp,
                'invoices': inv,
                'sales': round(sales, 2),
                'avg_ticket': round(sales / inv, 2) if inv else 0.0,
                'pct_of_abc': round(sales / total_sales * 100, 1) if total_sales else 0.0
            }
            
        a1_sales = groups_data.get('A1', {}).get('sales', 0.0)
        a1_share = round(a1_sales / total_sales * 100, 1) if total_sales else 0.0

        return {
            "status": "ok",
            "year": year,
            "multiplier": multiplier,
            "limit_price": limit_price,
            "data": {
                "total_companies": total_comp,
                "total_invoices": total_inv,
                "total_sales": round(total_sales, 2),
                "avg_ticket": round(total_sales / total_inv, 2) if total_inv else 0.0,
                "groups": groups_data,
                "kpis": {
                    "top_group_share": a1_share,
                    "avg_sales_per_client": round(total_sales / total_comp, 2) if total_comp else 0.0
                }
            }
        }
    except Exception as e:
        logger.error(f"Ошибка abc_groups_detail: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== API: ДЕТАЛЬНЫЙ АНАЛИЗ ВАЖНЫХ ABC ======
@app.get("/api/analytics/important-detail")
def important_detail(
    token: str = Query(None),
    year: int = 2026,
    multiplier: float = 2.9,
    limit_price: float = 146000
):
    """Детальный анализ Важных клиентов (ABC + C2 с 4+ накладными)"""
    verify_token(token)
    db = get_db()
    try:
        sql = text("SELECT * FROM get_important_detail(:year, :multiplier, :limit_price)")
        rows = db.execute(sql, {"year": year, "multiplier": multiplier, "limit_price": limit_price}).fetchall()
        
        grand_total = float(rows[0].grand_total) if rows else 1.0
        total_comp = len(rows)
        total_inv = sum(int(r.invoices_count or 0) for r in rows)
        total_sales = sum(float(r.goods_revenue or 0) for r in rows)
        
        top_clients = []
        for r in rows[:15]:
            sales = float(r.goods_revenue or 0)
            inv = int(r.invoices_count or 0)
            top_clients.append({
                "client_code": r.client_code,
                "client_name": r.client_name,
                "invoices_count": inv,
                "goods_revenue": round(sales, 2),
                "avg_ticket": round(sales / inv, 2) if inv else 0.0,
                "category": r.category
            })

        vip_sales_share = round(total_sales / grand_total * 100, 1)

        return {
            "status": "ok",
            "year": year,
            "limit_price": limit_price,
            "data": {
                "total_companies": total_comp,
                "total_invoices": total_inv,
                "total_sales": round(total_sales, 2),
                "avg_ticket": round(total_sales / total_inv, 2) if total_inv else 0.0,
                "vip_sales_share": vip_sales_share,
                "top_clients": top_clients
            }
        }
    except Exception as e:
        logger.error(f"Ошибка important_detail: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()



# ====== API: ТОП КЛИЕНТОВ ЗА МЕСЯЦ (С ИСКЛЮЧЕНИЕМ И 80% ПРАВИЛОМ) ======
@app.get("/api/analytics/top-clients")
def top_clients(
    token: str = Query(None),
    year: int = Query(None),
    month: int = Query(None),
    limit: int = 50,
    exclude_client: str = Query("9653")
):
    """
    Топ-клиенты за указанный или последний доступный месяц с исключением указанного клиента.
    Возвращает клиентов для расчёта 80% на фронтенде.
    """
    verify_token(token)
    db = get_db()
    try:
        # Авто-выбор года и месяца, если не переданы или за указанный месяц нет документов
        target_year = year or 2026
        target_month = month or 7
        
        check_count = db.execute(text("""
            SELECT COUNT(*) FROM documents
            WHERE EXTRACT(YEAR FROM invoice_date) = :year AND EXTRACT(MONTH FROM invoice_date) = :month
        """), {"year": target_year, "month": target_month}).scalar()

        if check_count == 0:
            latest = db.execute(text("""
                SELECT EXTRACT(YEAR FROM invoice_date)::integer AS yr, EXTRACT(MONTH FROM invoice_date)::integer AS mo
                FROM documents
                ORDER BY invoice_date DESC LIMIT 1
            """)).fetchone()
            if latest:
                target_year = latest.yr
                target_month = latest.mo

        # Основной запрос через функцию get_top_clients_monthly
        result = db.execute(text(
            "SELECT * FROM get_top_clients_monthly(:year, :month, :limit, :exclude_client)"
        ), {
            "year": target_year,
            "month": target_month,
            "exclude_client": exclude_client,
            "limit": limit
        }).fetchall()
        
        data = []
        total_revenue = 0
        for row in result:
            r = dict(row._mapping)
            for key in r:
                if r[key] is not None and isinstance(r[key], (int, float)):
                    r[key] = round(float(r[key]), 2)
            total_revenue += r.get('goods_revenue', 0)
            data.append(r)
        
        # Получаем данные исключённого клиента для плашки внизу
        excluded_info = None
        if exclude_client:
            excl_row = db.execute(
                text("SELECT * FROM get_excluded_client_info(:year, :month, :exclude_client)"),
                {
                    "year": target_year,
                    "month": target_month,
                    "exclude_client": exclude_client
                }
            ).fetchone()
            if excl_row:
                excluded_info = dict(excl_row._mapping)
                if excluded_info.get('goods_revenue'):
                    excluded_info['goods_revenue'] = round(float(excluded_info['goods_revenue']), 2)
        
        return {
            "status": "ok",
            "year": target_year,
            "month": target_month,
            "data": data,
            "total_revenue": round(total_revenue, 2),
            "excluded_client": exclude_client,
            "excluded_client_info": excluded_info,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка top_clients: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== СТРАНИЦА: ABC-СТРУКТУРА ======
@app.get("/abc-structure", response_class=HTMLResponse)
async def abc_structure_page(request: Request, token: str = Query(None)):
    verify_token(token)
    search_dirs = [FRONTEND_DIR, os.path.join(PROJECT_DIR, "frontend", "static")]
    filepath = find_file("abc_structure.html", search_dirs)
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница ABC-структуры не найдена")


# ======================================================================
# API ДЛЯ СТРАНИЦЫ /new-clients-analytics — АНАЛИТИКА НОВЫХ КЛИЕНТОВ
# ======================================================================

@app.get("/new-clients-analytics", response_class=HTMLResponse)
async def new_clients_analytics_page(request: Request, token: str = Query(None)):
    verify_token(token)
    search_dirs = [FRONTEND_DIR, os.path.join(PROJECT_DIR, "frontend", "static"), os.path.join(ROOT_DIR, "frontend", "static")]
    filepath = find_file("new-clients-analytics.html", search_dirs)
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница не найдена")


@app.get("/api/analytics/new-clients-overview")
def new_clients_overview(
    token: str = Query(None),
    year: int = Query(2026)
):
    """Обзорная аналитика по новым клиентам (KPI)"""
    verify_token(token)
    db = get_db()
    try:
        sql = text("SELECT * FROM get_new_clients_overview(:year)")
        row = db.execute(sql, {"year": year}).fetchone()
        if not row:
            return {
                "status": "ok",
                "year": year,
                "total_new": 0,
                "total_revenue": 0.0,
                "avg_revenue_per_client": 0.0,
                "avg_ticket": 0.0,
                "pct_of_total_revenue": 0.0,
                "new_in_top80": 0,
                "avg_invoices": 0.0
            }
        
        r = dict(row._mapping)
        return {
            "status": "ok",
            "year": year,
            "total_new": int(r["total_new"] or 0),
            "total_revenue": float(r["total_revenue"] or 0.0),
            "avg_revenue_per_client": float(r["avg_revenue_per_client"] or 0.0),
            "avg_ticket": float(r["avg_ticket"] or 0.0),
            "pct_of_total_revenue": float(r["pct_of_total_revenue"] or 0.0),
            "new_in_top80": int(r["new_in_top80"] or 0),
            "avg_invoices": float(r["avg_invoices"] or 0.0)
        }
    except Exception as e:
        logger.error(f"Ошибка new_clients_overview: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


@app.get("/api/analytics/new-clients-frequency")
def new_clients_frequency(
    token: str = Query(None),
    year: int = Query(2026)
):
    """Аналитика частоты покупок новых клиентов"""
    verify_token(token)
    db = get_db()
    try:
        sql = text("SELECT * FROM get_new_clients_frequency(:year)")
        result = db.execute(sql, {"year": year}).fetchall()
        data = []
        for row in result:
            r = dict(row._mapping)
            data.append({
                "frequency_group": r["frequency_group"],
                "sort_order": int(r["sort_order"]),
                "new_count": int(r["new_count"] or 0),
                "new_revenue": float(r["new_revenue"] or 0.0),
                "avg_ticket": float(r["avg_ticket"] or 0.0),
                "new_pct": float(r["new_pct"] or 0.0),
                "all_count": int(r["all_count"] or 0),
                "share_pct": float(r["share_pct"] or 0.0)
            })
        return {
            "status": "ok",
            "year": year,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка new_clients_frequency: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


@app.get("/api/analytics/new-clients-abc")
def new_clients_abc(
    token: str = Query(None),
    year: int = Query(2026),
    multiplier: float = Query(2.9)
):
    """ABC-анализ новых клиентов"""
    verify_token(token)
    db = get_db()
    try:
        sql = text("SELECT * FROM get_new_clients_abc(:year, :multiplier)")
        result = db.execute(sql, {"year": year, "multiplier": multiplier}).fetchall()
        data = []
        for row in result:
            r = dict(row._mapping)
            data.append({
                "abc_group": r["abc_group"],
                "count": int(r["count"] or 0),
                "revenue": float(r["revenue"] or 0.0),
                "pct": float(r["pct"] or 0.0)
            })
        return {
            "status": "ok",
            "year": year,
            "multiplier": multiplier,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка new_clients_abc: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


@app.get("/api/analytics/new-clients-abc-compare")
def new_clients_abc_compare(
    token: str = Query(None),
    year: int = Query(2026),
    multiplier: float = Query(2.9)
):
    """Сравнение ABC-структуры Новых клиентов vs Все клиенты"""
    verify_token(token)
    db = get_db()
    try:
        sql = text("SELECT * FROM get_new_clients_abc_compare(:year, :multiplier)")
        res = db.execute(sql, {"year": year, "multiplier": multiplier}).fetchall()
        data = []
        for row in res:
            r = dict(row._mapping)
            data.append({
                "abc_group": r["abc_group"],
                "new_count": int(r["new_count"] or 0),
                "new_revenue": float(r["new_revenue"] or 0.0),
                "new_pct": float(r["new_pct"] or 0.0),
                "all_count": int(r["all_count"] or 0),
                "all_revenue": float(r["all_revenue"] or 0.0),
                "all_pct": float(r["all_pct"] or 0.0),
                "count_share_pct": float(r["count_share_pct"] or 0.0),
                "revenue_share_pct": float(r["revenue_share_pct"] or 0.0)
            })
            
        return {
            "status": "ok",
            "year": year,
            "multiplier": multiplier,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка new_clients_abc_compare: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


@app.get("/api/analytics/new-clients-list")
def new_clients_list(
    token: str = Query(None),
    year: int = Query(2026),
    search: str = Query(None),
    abc_group: str = Query(None),
    limit: int = Query(50),
    offset: int = Query(0)
):
    """Список новых клиентов с фильтрацией и пагинацией"""
    verify_token(token)
    db = get_db()
    try:
        sql = text("SELECT * FROM get_new_clients_list(:year, :search, :abc_group, :limit, :offset)")
        result = db.execute(sql, {
            "year": year,
            "search": search if search else None,
            "abc_group": abc_group if abc_group else None,
            "limit": limit,
            "offset": offset
        }).fetchall()
        
        data = []
        for row in result:
            r = dict(row._mapping)
            data.append({
                "code": r["code"],
                "name": r["name"],
                "docs": int(r["docs"] or 0),
                "revenue": float(r["revenue"] or 0.0),
                "first_date": r["first_date"] or "",
                "last_date": r["last_date"] or "",
                "abc_group": r["abc_group"]
            })
            
        return {
            "status": "ok",
            "year": year,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка new_clients_list: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ======================================================================
# API ДЛЯ СТРАНИЦЫ /inactive-clients-analytics — АНАЛИТИКА НЕАКТИВНЫХ КЛИЕНТОВ
# ======================================================================

@app.get("/inactive-clients-analytics", response_class=HTMLResponse)
async def inactive_clients_analytics_page(request: Request, token: str = Query(None)):
    verify_token(token)
    search_dirs = [FRONTEND_DIR, os.path.join(PROJECT_DIR, "frontend", "static"), os.path.join(ROOT_DIR, "frontend", "static")]
    filepath = find_file("inactive-clients-analytics.html", search_dirs)
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница не найдена")


@app.get("/api/analytics/inactive-clients-overview")
def inactive_clients_overview(
    token: str = Query(None),
    year: int = Query(2026)
):
    """Обзорная аналитика по неактивным клиентам (Спящие и Ушедшие)"""
    verify_token(token)
    db = get_db()
    try:
        sql = text("SELECT * FROM get_inactive_clients_overview(:year)")
        row = db.execute(sql, {"year": year}).fetchone()
        r = dict(row._mapping) if row else {}
        return {
            "status": "ok",
            "year": year,
            "sleeping_count": int(r.get("sleeping_count", 0)),
            "churned_count": int(r.get("churned_count", 0)),
            "total_all": int(r.get("total_all", 0)),
            "pct_inactive": float(r.get("pct_inactive", 0.0)),
            "sleeping_rev_2025": float(r.get("sleeping_rev_2025", 0.0)),
            "churned_rev_2024": float(r.get("churned_rev_2024", 0.0)),
            "high_risk_count": int(r.get("high_risk_count", 0))
        }
    except Exception as e:
        logger.error(f"Ошибка inactive_clients_overview: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


@app.get("/api/analytics/inactive-clients-list")
def inactive_clients_list(
    token: str = Query(None),
    status_id: int = Query(8),
    search: str = Query(None),
    abc_group: str = Query(None),
    days_min: int = Query(None),
    days_max: int = Query(None),
    limit: int = Query(50),
    offset: int = Query(0)
):
    """Список неактивных клиентов (Спящие status_id=8 или Ушедшие status_id=9)"""
    verify_token(token)
    db = get_db()
    year_prev = 2025 if status_id == 8 else 2024
    try:
        sql = text("SELECT * FROM get_inactive_clients_list(:status_id, :year_prev, :search, :abc_group, :days_min, :days_max, :limit, :offset)")
        result = db.execute(sql, {
            "status_id": status_id,
            "year_prev": year_prev,
            "search": search if search else None,
            "abc_group": abc_group if abc_group else None,
            "days_min": days_min,
            "days_max": days_max,
            "limit": limit,
            "offset": offset
        }).fetchall()
        
        data = []
        for row in result:
            r = dict(row._mapping)
            days = int(r["days_since"]) if r["days_since"] != 9999 else None
            abc = r["abc_group"] or "C"
            
            # Генерация рекомендации
            if status_id == 8:
                if days and days > 180 and abc == 'A':
                    rec = "⚠️ Срочно связаться (A-клиент)"
                elif days and days > 90:
                    rec = "📞 Позвонить клиенту"
                else:
                    rec = "📧 Напомнить о себе"
            else:
                if abc == 'A':
                    rec = "🔥 Попробовать вернуть (A-клиент)"
                elif abc == 'B':
                    rec = "📞 Запросить обратную связь"
                else:
                    rec = "📋 Архив / Прогрев"

            data.append({
                "code": r["code"],
                "name": r["name"],
                "docs_prev": int(r["docs_prev"] or 0),
                "rev_prev": float(r["rev_prev"] or 0.0),
                "abc_group": abc,
                "last_date": r["last_date"] or "—",
                "days_since": days if days is not None else 999,
                "recommendation": rec
            })
            
        return {
            "status": "ok",
            "status_id": status_id,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка inactive_clients_list: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


@app.get("/api/analytics/inactive-clients-distribution")
def inactive_clients_distribution(
    token: str = Query(None),
    status_id: int = Query(8)
):
    """Распределение неактивных клиентов по давности последней покупки"""
    verify_token(token)
    db = get_db()
    try:
        sql = text("SELECT * FROM get_inactive_clients_distribution(:status_id)")
        result = db.execute(sql, {"status_id": status_id}).fetchall()
        data = [dict(r._mapping) for r in result]
        return {
            "status": "ok",
            "status_id": status_id,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка inactive_clients_distribution: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


@app.get("/api/analytics/inactive-clients-abc")
def inactive_clients_abc(
    token: str = Query(None),
    status_id: int = Query(8),
    year_prev: int = Query(2025)
):
    """ABC-анализ неактивных клиентов в прошлом году"""
    verify_token(token)
    db = get_db()
    target_year = 2025 if status_id == 8 else 2024
    try:
        sql = text("SELECT * FROM get_inactive_clients_abc(:status_id, :target_year)")
        result = db.execute(sql, {"status_id": status_id, "target_year": target_year}).fetchall()
        data = []
        for row in result:
            r = dict(row._mapping)
            data.append({
                "abc_group": r["abc_group"],
                "count": int(r["count"] or 0),
                "revenue": float(r["revenue"] or 0.0),
                "pct": float(r["pct"] or 0.0)
            })
        return {
            "status": "ok",
            "status_id": status_id,
            "target_year": target_year,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка inactive_clients_abc: {e}")
        raise HTTPException(status_code=500, detail=str(e))
@app.get("/api/analytics/client-products/{client_code}")
def client_products_analytics(
    client_code: str,
    token: str = Query(None),
    year: int = 2026
):
    """Товары клиента за год: использует get_client_products, расчитывает ABC и проценты"""
    verify_token(token)
    db = get_db()
    try:
        client = db.execute(
            text("SELECT name FROM clients WHERE code = :code"),
            {"code": client_code}
        ).fetchone()
        client_name = client[0] if client else client_code

        services_rev = db.execute(text("""
            SELECT COALESCE(SUM(sl.amount), 0)
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            JOIN products p ON sl.product_code = p.code
            WHERE d.client_code = :code
              AND EXTRACT(YEAR FROM d.invoice_date) = :year
              AND p.is_service = TRUE
        """), {"code": client_code, "year": year}).scalar() or 0.0

        rows = db.execute(
            text("SELECT * FROM get_client_products(:code, :year)"),
            {"code": client_code, "year": year}
        ).fetchall()

        stock_rows = db.execute(text("SELECT code, COALESCE(in_stock_balance, 0) as in_stock FROM products")).fetchall()
        stock_map = {r.code: float(r.in_stock or 0) for r in stock_rows}

        goods_rev = sum(float(r._mapping['total_sales'] or 0) for r in rows)
        total_rev = goods_rev + float(services_rev)

        products = []
        cum_rev = 0.0
        for r in rows:
            rm = dict(r._mapping)
            sales = float(rm.get('total_sales') or 0)
            cum_rev += sales
            
            if goods_rev > 0:
                pct = round(sales / goods_rev * 100, 1)
                prev_cum = cum_rev - sales
                if cum_rev <= goods_rev * 0.80 or prev_cum < goods_rev * 0.80:
                    abc_grp = 'A'
                elif cum_rev <= goods_rev * 0.95 or prev_cum < goods_rev * 0.95:
                    abc_grp = 'B'
                else:
                    abc_grp = 'C'
            else:
                pct = 0.0
                abc_grp = 'C'

            rm['pct_of_total'] = pct
            rm['abc_group'] = abc_grp
            rm['in_stock'] = stock_map.get(rm['product_code'], 0.0)
            rm['total_sales'] = round(sales, 2)
            rm['total_quantity'] = round(float(rm.get('total_quantity') or 0), 2)
            rm['invoice_count'] = int(rm.get('invoice_count') or 0)
            products.append(rm)

        return {
            "status": "ok",
            "client_code": client_code,
            "client_name": client_name,
            "year": year,
            "total_revenue": round(total_rev, 2),
            "goods_revenue": round(goods_rev, 2),
            "services_revenue": round(float(services_rev), 2),
            "unique_products": len(products),
            "products": products,
            "count": len(products)
        }
    except Exception as e:
        logger.error(f"Ошибка client_products_analytics: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


@app.get("/api/analytics/client-products-compare/{client_code}")
def client_products_compare(
    client_code: str,
    token: str = Query(None)
):
    """Сравнение покупок 2026 vs 2025 из хранимой функции get_client_products_compare"""
    verify_token(token)
    db = get_db()
    try:
        rows = db.execute(
            text("SELECT * FROM get_client_products_compare(:code)"),
            {"code": client_code}
        ).fetchall()

        products = []
        for r in rows:
            rm = dict(r._mapping)
            rev_2026 = float(rm.get('revenue_curr') or 0.0)
            rev_2025 = float(rm.get('revenue_prev') or 0.0)
            diff = rev_2026 - rev_2025
            if rev_2025 > 0:
                growth_pct = round(diff / rev_2025 * 100, 1)
            elif rev_2026 > 0:
                growth_pct = 100.0
            else:
                growth_pct = 0.0

            products.append({
                "product_code": rm.get('product_code'),
                "product_name": rm.get('product_name'),
                "sales_2025": round(rev_2025, 2),
                "sales_2026": round(rev_2026, 2),
                "qty_2025": round(float(rm.get('qty_prev') or 0.0), 2),
                "qty_2026": round(float(rm.get('qty_curr') or 0.0), 2),
                "diff": round(diff, 2),
                "growth_pct": growth_pct
            })

        return {
            "status": "ok",
            "client_code": client_code,
            "products": products,
            "count": len(products)
        }
    except Exception as e:
        logger.error(f"Ошибка client_products_compare: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


@app.get("/api/analytics/client-products-recommendations/{client_code}")
def client_products_recommendations(
    client_code: str,
    token: str = Query(None)
):
    """Рекомендации товаров для клиента: 4 блока"""
    verify_token(token)
    db = get_db()
    try:
        # Блок 1: Cross-sell (трубы)
        cross_rows = db.execute(
            text("SELECT * FROM get_client_cross_sell_pipes(:code)"),
            {"code": client_code}
        ).fetchall()
        cross_sell = [
            {"product_code": r.product_code, "product_name": r.product_name, 
             "reason": r.reason, "in_stock": float(r.in_stock or 0)} 
            for r in cross_rows
        ]

        # Блок 2: Похожие типоразмеры
        similar_rows = db.execute(
            text("SELECT * FROM get_client_similar_sizes(:code)"),
            {"code": client_code}
        ).fetchall()
        similar_size = [
            {"product_code": r.product_code, "product_name": r.product_name,
             "diameter": float(r.diameter) if r.diameter is not None else None,
             "wall_thickness": float(r.wall_thickness) if r.wall_thickness is not None else None,
             "reason": r.reason, "in_stock": float(r.in_stock or 0)} 
            for r in similar_rows
        ]

        # Fallback для similar_size
        if len(similar_size) < 5:
            existing = {s["product_code"] for s in similar_size}
            fallback_rows = db.execute(
                text("SELECT * FROM get_client_similar_fallback(:code)"),
                {"code": client_code}
            ).fetchall()
            for r in fallback_rows:
                if r.product_code not in existing and len(similar_size) < 5:
                    similar_size.append({
                        "product_code": r.product_code, "product_name": r.product_name,
                        "diameter": float(r.diameter) if r.diameter is not None else None,
                        "wall_thickness": float(r.wall_thickness) if r.wall_thickness is not None else None,
                        "reason": r.reason, "in_stock": float(r.in_stock or 0)
                    })

        # Блок 3: Популярное в сегменте
        dir_rows = db.execute(
            text("SELECT * FROM get_client_direction_variety(:code)"),
            {"code": client_code}
        ).fetchall()
        direction_variety = [
            {"product_code": r.product_code, "product_name": r.product_name,
             "popularity": int(r.popularity or 0), "reason": r.reason, 
             "in_stock": float(r.in_stock or 0)} 
            for r in dir_rows
        ]

        # Блок 4: Услуги
        services = [
            {"product_name": "Послуги порізки та різання металопрокату", "usage_count": "Рекомендовано", "code": "service_cut"},
            {"product_name": "Послуги доставки по Україні", "usage_count": "Рекомендовано", "code": "service_delivery"},
            {"product_name": "Послуги бронювання", "usage_count": "Рекомендовано", "code": "service_reserve"},
            {"product_name": "Послуги розрахунок профільної труби", "usage_count": "Рекомендовано", "code": "service_profile"}
        ]

        return {
            "status": "ok", "client_code": client_code,
            "cross_sell": cross_sell, "similar_size": similar_size,
            "direction_variety": direction_variety, "services": services
        }
    except Exception as e:
        logger.error(f"Ошибка client_products_recommendations: {e}")
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        db.close()


# ====== HEALTH CHECK ======
@app.get("/health")
def health():
    try:
        db = get_db()
        result = db.execute(text("SELECT COUNT(*) FROM clients")).scalar()
        db.close()
        return {"status": "ok", "database": "connected", "clients_count": result}
    except Exception as e:
        return {"status": "error", "message": str(e)}
        
# ====== ЗАПУСК ======
if __name__ == "__main__":
    print("=" * 60)
    print("🚀 UTSK Intelligent Sales — Web Demo Server")
    print("=" * 60)
    print(f"📍 Доступ: http://{HOST}:{PORT}")
    print(f"🔑 Токен: {DEMO_TOKEN}")
    print("=" * 60)
    uvicorn.run(app, host=HOST, port=PORT, log_level="info")
