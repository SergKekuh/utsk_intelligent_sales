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

# ====== API: ДАШБОРД ======
@app.get("/api/dashboard")
def dashboard(token: str = Query(None)):
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(text("""
            SELECT 
                COUNT(DISTINCT c.code) as total_clients,
                COUNT(DISTINCT CASE WHEN c.last_purchase_date >= CURRENT_DATE - INTERVAL '30 days' THEN c.code END) as active_30d,
                COUNT(DISTINCT CASE WHEN c.last_purchase_date >= CURRENT_DATE - INTERVAL '90 days' THEN c.code END) as active_90d,
                COALESCE(SUM(d.total_amount), 0) as total_revenue,
                COALESCE(SUM(CASE WHEN d.invoice_date >= CURRENT_DATE - INTERVAL '30 days' THEN d.total_amount END), 0) as revenue_30d
            FROM clients c LEFT JOIN documents d ON d.client_code = c.code
        """)).first()
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
        result = db.execute(text("""
            SELECT c.code, c.name, sr.status_name as status, c.last_purchase_date
            FROM clients c LEFT JOIN status_rules sr ON c.current_status_id = sr.id
            WHERE c.name ILIKE :search OR c.code ILIKE :search
            ORDER BY c.last_purchase_date DESC NULLS LAST LIMIT :limit
        """), {"search": f"%{search}%", "limit": limit})
        return [dict(row._mapping) for row in result]
    finally:
        db.close()

# ====== API: АКТИВНЫЕ КЛИЕНТЫ ======
@app.get("/api/clients/active")
def active_clients(token: str = Query(None), limit: int = 20):
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(text("""
            SELECT c.code, c.name, sr.status_name as status, c.last_purchase_date,
                   COUNT(d.id) as docs_count, COALESCE(SUM(d.total_amount), 0) as total_revenue
            FROM clients c
            JOIN documents d ON d.client_code = c.code
            LEFT JOIN status_rules sr ON c.current_status_id = sr.id
            WHERE d.invoice_date >= CURRENT_DATE - INTERVAL '30 days'
              AND c.code != ALL(ARRAY['9653', '11230'])  -- исключения: Південтрансбудкомплект ТОВ, НЬЮЕРДЖІ ТОВ
            GROUP BY c.code, c.name, sr.status_name, c.last_purchase_date
            ORDER BY total_revenue DESC LIMIT :limit
        """), {"limit": limit})
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
        result = db.execute(text("""
            SELECT c.code, c.name, sr.status_name as status, c.last_purchase_date,
                   (CURRENT_DATE - c.last_purchase_date::DATE) as days_since_last
            FROM clients c LEFT JOIN status_rules sr ON c.current_status_id = sr.id
            WHERE c.last_purchase_date IS NOT NULL
              AND c.last_purchase_date < CURRENT_DATE - INTERVAL '90 days'
            ORDER BY days_since_last DESC LIMIT :limit
        """), {"limit": limit})
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
        q_main = text("""
            SELECT 
                c.code,
                c.name,
                sr.status_name AS status,
                COALESCE(ROUND(SUM(sl.amount)::numeric, 0), 0) AS total_revenue,
                COUNT(DISTINCT d.id) AS total_invoices,
                COALESCE(ROUND(AVG(sl.amount)::numeric, 0), 0) AS avg_check,
                MAX(d.invoice_date) AS last_purchase_date
            FROM clients c
            LEFT JOIN status_rules sr ON c.current_status_id = sr.id
            LEFT JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = :year
            LEFT JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            WHERE c.code = :code AND COALESCE(pr.is_service, FALSE) = FALSE AND (sl.amount IS NULL OR sl.amount > 0)
            GROUP BY c.code, c.name, sr.status_name
        """)
        client_res = db.execute(q_main, {"year": year, "code": code}).fetchone()
        if not client_res:
            raise HTTPException(status_code=404, detail=f"Клиент '{code}' не найден")
        
        client_data = dict(client_res._mapping)

        # 2. Статус 2025 года
        q_2025 = text("""
            SELECT 
                CASE 
                    WHEN cya.total_docs = 0 THEN 'Спящие'
                    WHEN cya.total_docs = 1 THEN 'Разовые'
                    WHEN cya.total_docs BETWEEN 2 AND 3 THEN 'Повторные'
                    WHEN cya.total_docs BETWEEN 4 AND 10 THEN 'Ежеквартальные'
                    WHEN cya.total_docs BETWEEN 11 AND 40 THEN 'Ежемесячные'
                    WHEN cya.total_docs BETWEEN 41 AND 170 THEN 'Еженедельные'
                    WHEN cya.total_docs > 170 THEN 'Ежедневные'
                    ELSE '—'
                END AS status_2025
            FROM client_year_activity cya
            WHERE cya.client_code = :code AND cya.sales_year = :year_prev
        """)
        res_2025 = db.execute(q_2025, {"code": code, "year_prev": year - 1}).scalar()
        status_2025 = res_2025 or "—"

        # 3. Помесячная динамика (2026 vs 2025)
        q_monthly = text("""
            SELECT 
                EXTRACT(MONTH FROM d.invoice_date)::INTEGER AS month,
                ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = :year THEN sl.amount ELSE 0 END)::numeric, 0) AS revenue_current,
                ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = :year_prev THEN sl.amount ELSE 0 END)::numeric, 0) AS revenue_previous,
                COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = :year THEN d.id END) AS invoices_current,
                COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = :year_prev THEN d.id END) AS invoices_previous
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            WHERE d.client_code = :code
              AND EXTRACT(YEAR FROM d.invoice_date) IN (:year, :year_prev)
              AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
            GROUP BY EXTRACT(MONTH FROM d.invoice_date)
            ORDER BY month
        """)
        monthly_rows = db.execute(q_monthly, {"year": year, "year_prev": year - 1, "code": code}).fetchall()
        monthly_data = [dict(m._mapping) for m in monthly_rows]
        for m in monthly_data:
            m["revenue_current"] = float(m["revenue_current"]) if m.get("revenue_current") else 0.0
            m["revenue_previous"] = float(m["revenue_previous"]) if m.get("revenue_previous") else 0.0

        # 4. Последние 20 накладных
        q_invoices = text("""
            SELECT 
                TO_CHAR(d.invoice_date, 'DD.MM.YYYY') AS date,
                d.doc_number AS number,
                ROUND(SUM(sl.amount)::numeric, 0) AS total,
                COUNT(sl.id) AS positions
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            WHERE d.client_code = :code AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
            GROUP BY d.id, d.invoice_date, d.doc_number
            ORDER BY d.invoice_date DESC
            LIMIT 20
        """)
        invoice_rows = db.execute(q_invoices, {"code": code}).fetchall()
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
        
        q = text("""
            SELECT 
                TO_CHAR(d.invoice_date, 'DD.MM.YYYY') AS date,
                d.doc_number AS number,
                ROUND(SUM(sl.amount)::numeric, 0) AS total,
                COUNT(sl.id) AS positions
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            WHERE d.client_code = :code
              AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
              AND (
                  (:date_from IS NOT NULL AND :date_to IS NOT NULL AND d.invoice_date BETWEEN :date_from AND :date_to)
                  OR
                  (:date_from IS NULL AND :month_int IS NOT NULL AND EXTRACT(YEAR FROM d.invoice_date) = :year AND EXTRACT(MONTH FROM d.invoice_date) = :month_int)
                  OR
                  (:date_from IS NULL AND :month_int IS NULL AND EXTRACT(YEAR FROM d.invoice_date) = :year)
              )
            GROUP BY d.id, d.invoice_date, d.doc_number
            ORDER BY d.invoice_date DESC
            LIMIT :limit
        """)

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
        q_items = text("""
            SELECT 
                sl.product_code AS code,
                COALESCE(pr.name, sl.product_code) AS name,
                COALESCE(sl.quantity, 0) AS quantity,
                COALESCE(sl.amount, 0) AS total,
                COALESCE(pr.weight_per_meter, 0) * COALESCE(sl.quantity, 0) AS weight_kg,
                CASE WHEN COALESCE(sl.quantity, 0) > 0 THEN sl.amount / sl.quantity ELSE 0 END AS price
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            WHERE d.doc_number = :number
            ORDER BY sl.id
        """)
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
        result = db.execute(text("""
            SELECT sr.status_name, COUNT(*) as count
            FROM clients c JOIN status_rules sr ON c.current_status_id = sr.id
            GROUP BY sr.status_name, sr.priority ORDER BY sr.priority
        """))
        return [dict(row._mapping) for row in result]
    finally:
        db.close()

# ====== API: ТОВАРЫ ======
@app.get("/api/products")
def products(token: str = Query(None), limit: int = 50, search: str = ""):
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(text("""
            SELECT p.code, p.name, p.in_stock_balance, ad.name as direction
            FROM products p LEFT JOIN activity_directions ad ON p.anchor_direction_id = ad.id
            WHERE p.name ILIKE :search OR p.code ILIKE :search
            ORDER BY p.code LIMIT :limit
        """), {"search": f"%{search}%", "limit": limit})
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
        
        # ====== БЛОК 1: История покупок ======
        result = db.execute(text("""
            SELECT p.code, p.name, 'Часто покупаете' as reason, 1 as priority,
                   COALESCE(p.in_stock_balance, 0) as in_stock, COUNT(sl.id) as purchase_count
            FROM clients c
            JOIN documents d ON d.client_code = c.code
            JOIN sales_lines sl ON sl.document_id = d.id
            JOIN products p ON sl.product_code = p.code
            WHERE c.code = :client_code AND COALESCE(p.in_stock_balance, 0) > 0
            GROUP BY p.code, p.name, p.in_stock_balance
            HAVING COUNT(sl.id) >= 2
            ORDER BY COUNT(sl.id) DESC
            LIMIT 5
        """), {"client_code": client_code})
        
        for row in result:
            recommendations.append(dict(row._mapping))
        
        # ====== БЛОК 2: Новинки по направлению ======
        if client.activity_direction_id:
            result = db.execute(text("""
                SELECT p.code, p.name, 'Новинка в вашем сегменте' as reason, 2 as priority,
                       COALESCE(p.in_stock_balance, 0) as in_stock, 0 as purchase_count
                FROM products p
                WHERE p.anchor_direction_id = :direction_id
                  AND p.is_new_arrival = TRUE
                  AND COALESCE(p.in_stock_balance, 0) > 0
                  AND p.code NOT IN (
                      SELECT sl2.product_code FROM sales_lines sl2
                      JOIN documents d2 ON sl2.document_id = d2.id
                      WHERE d2.client_code = :client_code
                  )
                ORDER BY p.in_stock_balance DESC
                LIMIT 5
            """), {"direction_id": client.activity_direction_id, "client_code": client_code})
            
            for row in result:
                recommendations.append(dict(row._mapping))
        
        # ====== БЛОК 3: Сопутствующие товары (cross-sells) ======
        result = db.execute(text("""
            SELECT p_related.code, p_related.name, 'С этим обычно берут' as reason, 3 as priority,
                   COALESCE(p_related.in_stock_balance, 0) as in_stock, 0 as purchase_count
            FROM clients c
            JOIN documents d ON d.client_code = c.code
            JOIN sales_lines sl ON sl.document_id = d.id
            JOIN product_cross_sells pcs ON sl.product_code = pcs.main_product_code
            JOIN products p_related ON pcs.related_product_code = p_related.code
            WHERE c.code = :client_code
              AND COALESCE(p_related.in_stock_balance, 0) > 0
              AND p_related.code NOT IN (
                  SELECT sl2.product_code FROM sales_lines sl2
                  JOIN documents d2 ON sl2.document_id = d2.id
                  WHERE d2.client_code = :client_code
              )
            GROUP BY p_related.code, p_related.name, p_related.in_stock_balance
            LIMIT 5
        """), {"client_code": client_code})
        
        for row in result:
            recommendations.append(dict(row._mapping))
        
        # ====== БЛОК 4: Цифровой след (просмотры за 7 дней) ======
        result = db.execute(text("""
            SELECT p.code, p.name, 'Вы недавно интересовались' as reason, 4 as priority,
                   COALESCE(p.in_stock_balance, 0) as in_stock, 0 as purchase_count
            FROM website_behavior_log wbl
            JOIN products p ON wbl.product_code = p.code
            WHERE wbl.client_code = :client_code
              AND wbl.timestamp >= CURRENT_TIMESTAMP - INTERVAL '7 days'
              AND COALESCE(p.in_stock_balance, 0) > 0
              AND p.code NOT IN (
                  SELECT sl2.product_code FROM sales_lines sl2
                  JOIN documents d2 ON sl2.document_id = d2.id
                  WHERE d2.client_code = :client_code
              )
            GROUP BY p.code, p.name, p.in_stock_balance
            ORDER BY MAX(wbl.timestamp) DESC
            LIMIT 5
        """), {"client_code": client_code})
        
        for row in result:
            recommendations.append(dict(row._mapping))
        
        # ====== СОРТИРОВКА: по приоритету, затем по весу ======
        recommendations.sort(key=lambda r: (r.get('priority', 99), -(r.get('in_stock', 0))))
        
        # ====== Ограничиваем 5 рекомендациями ======
        recommendations = recommendations[:5]
        
        # ====== FALLBACK: популярные товары ======
        if not recommendations:
            result = db.execute(text("""
                SELECT p.code, p.name, 'Популярный товар' as reason, 99 as priority,
                       COALESCE(p.in_stock_balance, 0) as in_stock, 0 as purchase_count
                FROM products p
                WHERE COALESCE(p.in_stock_balance, 0) > 0
                ORDER BY p.code
                LIMIT 5
            """))
            
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
    Воронка продаж: распределение клиентов по частоте накладных за выбранный год.
    """
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(text("""
            WITH client_invoices AS (
                SELECT 
                    c.code,
                    COUNT(DISTINCT d.id) AS invoice_count,
                    COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS total_revenue
                FROM clients c
                JOIN client_year_active cya ON cya.client_code = c.code AND cya.sales_year = :year AND cya.is_active = TRUE
                JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = :year
                JOIN sales_lines sl ON sl.document_id = d.id
                LEFT JOIN products pr ON sl.product_code = pr.code
                WHERE c.code NOT IN ('9653', '11230')
                GROUP BY c.code
            ),
            classified AS (
                SELECT 
                    CASE 
                        WHEN invoice_count = 1 THEN 'Разовые (1)'
                        WHEN invoice_count BETWEEN 2 AND 3 THEN 'Повторные (2-3)'
                        WHEN invoice_count BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
                        WHEN invoice_count BETWEEN 11 AND 40 THEN 'Месяц (11-40)'
                        WHEN invoice_count BETWEEN 41 AND 170 THEN 'Неделя (41-170)'
                        ELSE 'День (>170)'
                    END AS stage,
                    CASE 
                        WHEN invoice_count = 1 THEN 1
                        WHEN invoice_count BETWEEN 2 AND 3 THEN 2
                        WHEN invoice_count BETWEEN 4 AND 10 THEN 3
                        WHEN invoice_count BETWEEN 11 AND 40 THEN 4
                        WHEN invoice_count BETWEEN 41 AND 170 THEN 5
                        ELSE 6
                    END AS sort_order,
                    total_revenue
                FROM client_invoices
            )
            SELECT 
                stage,
                COUNT(*) AS count,
                ROUND(SUM(total_revenue)::numeric, 2) AS revenue
            FROM classified
            GROUP BY stage, sort_order
            ORDER BY sort_order
        """), {"year": year})
        
        data = []
        for row in result:
            r = dict(row._mapping)
            if r.get("revenue") is not None:
                r["revenue"] = round(float(r["revenue"]), 2)
            data.append(r)
        return data
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
        result = db.execute(text("""
            SELECT p.code, p.name, COUNT(sl.id) as total_sales,
                   COALESCE(p.in_stock_balance, 0) as in_stock_balance
            FROM products p
            JOIN sales_lines sl ON sl.product_code = p.code
            WHERE COALESCE(p.in_stock_balance, 0) > 0
            GROUP BY p.code, p.name, p.in_stock_balance
            ORDER BY total_sales DESC LIMIT :limit
        """), {"limit": limit})
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
        # Проверяем, существует ли представление
        view_exists = db.execute(text("""
            SELECT EXISTS (
                SELECT FROM pg_views WHERE viewname = 'view_monthly_revenue'
            )
        """)).scalar()
        
        if not view_exists:
            # Если представления нет — считаем на лету
            result = db.execute(text("""
                SELECT 
                    EXTRACT(YEAR FROM d.invoice_date)::INTEGER AS year,
                    EXTRACT(MONTH FROM d.invoice_date)::INTEGER AS month,
                    TO_CHAR(TO_DATE(EXTRACT(MONTH FROM d.invoice_date)::TEXT, 'MM'), 'Mon') AS month_name,
                    COUNT(DISTINCT d.client_code) AS active_clients,
                    COUNT(DISTINCT d.id) AS invoice_count,
                    COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
                    COALESCE(SUM(CASE WHEN pr.is_service = TRUE THEN sl.amount ELSE 0 END), 0) AS services_revenue,
                    COALESCE(SUM(sl.amount), 0) AS total_revenue
                FROM documents d
                JOIN sales_lines sl ON sl.document_id = d.id
                LEFT JOIN products pr ON sl.product_code = pr.code
                JOIN client_year_active cya ON d.client_code = cya.client_code AND cya.sales_year = :year AND cya.is_active = TRUE
                JOIN clients c ON d.client_code = c.code
                WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
                GROUP BY year, month, month_name
                ORDER BY month
            """), {"year": year})
        else:
            result = db.execute(text("""
                SELECT * FROM view_monthly_revenue
                WHERE year = :year
                ORDER BY month
            """), {"year": year})
        
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
        view_exists = db.execute(text("""
            SELECT EXISTS (
                SELECT FROM pg_views WHERE viewname = 'view_yoy_comparison'
            )
        """)).scalar()
        
        if not view_exists:
            # Считаем на лету — клиенты, у которых были продажи в ОБОИХ годах
            result = db.execute(text("""
                WITH mutual_clients AS (
                    SELECT DISTINCT d1.client_code
                    FROM documents d1
                    WHERE EXTRACT(YEAR FROM d1.invoice_date) = :year1
                    INTERSECT
                    SELECT DISTINCT d2.client_code
                    FROM documents d2
                    WHERE EXTRACT(YEAR FROM d2.invoice_date) = :year2
                )
                SELECT 
                    EXTRACT(MONTH FROM d.invoice_date)::INTEGER AS month,
                    TO_CHAR(TO_DATE(EXTRACT(MONTH FROM d.invoice_date)::TEXT, 'MM'), 'Mon') AS month_name,
                    COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = :year1 
                        AND pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue_y1,
                    COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = :year2 
                        AND pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue_y2,
                    COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = :year1 
                        THEN d.client_code END) AS clients_y1,
                    COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = :year2 
                        THEN d.client_code END) AS clients_y2
                FROM documents d
                JOIN sales_lines sl ON sl.document_id = d.id
                LEFT JOIN products pr ON sl.product_code = pr.code
                WHERE d.client_code IN (SELECT client_code FROM mutual_clients)
                  AND EXTRACT(YEAR FROM d.invoice_date) IN (:year1, :year2)
                GROUP BY month, month_name
                ORDER BY month
            """), {"year1": year1, "year2": year2})
        else:
            result = db.execute(text("""
                SELECT * FROM view_yoy_comparison
                ORDER BY month
            """))
        
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
        result = db.execute(text("""
            SELECT 
                EXTRACT(DAY FROM d.invoice_date)::INTEGER AS day,
                COUNT(DISTINCT d.client_code) AS active_clients,
                COUNT(DISTINCT d.id) AS invoice_count,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
                COALESCE(SUM(sl.amount), 0) AS total_revenue
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE
            WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
              AND EXTRACT(MONTH FROM d.invoice_date) = :month
            GROUP BY day
            ORDER BY day
        """), {"year": year, "month": month})
        
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
        current = db.execute(text("""
            SELECT 
                COUNT(DISTINCT d.client_code) AS active_clients,
                COUNT(DISTINCT d.id) AS invoice_count,
                COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
                COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = TRUE THEN sl.amount ELSE 0 END), 0) AS services_revenue,
                COALESCE(SUM(sl.amount), 0) AS total_revenue
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE
            WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
              AND EXTRACT(MONTH FROM d.invoice_date) = :month
        """), {"year": year, "month": month}).first()
        
        # Прошлый месяц
        prev_month = month - 1
        prev_year = year
        if prev_month == 0:
            prev_month = 12
            prev_year = year - 1
        
        previous = db.execute(text("""
            SELECT 
                COUNT(DISTINCT d.client_code) AS active_clients,
                COUNT(DISTINCT d.id) AS invoice_count,
                COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
                COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = TRUE THEN sl.amount ELSE 0 END), 0) AS services_revenue,
                COALESCE(SUM(sl.amount), 0) AS total_revenue
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE
            WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
              AND EXTRACT(MONTH FROM d.invoice_date) = :month
        """), {"year": prev_year, "month": prev_month}).first()
        
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
        
        # Получаем ABC-группы клиентов за прошлый год
        abc_prev = db.execute(
            text("SELECT * FROM get_abc_groups(:year, :multiplier)"),
            {"year": year_prev, "multiplier": multiplier}
        )
        
        # Собираем client_code по группам
        # Для этого нам нужен другой подход — через временную таблицу
        result = db.execute(text("""
            WITH abc_prev AS (
                SELECT 
                    client_code,
                    goods_revenue
                FROM client_year_activity
                WHERE sales_year = :year_prev
            ),
            abc_grouped AS (
                SELECT 
                    client_code,
                    goods_revenue,
                    CASE
                        WHEN goods_revenue >= 3000000 * :mult THEN 'A1'
                        WHEN goods_revenue >= 2000000 * :mult THEN 'A2'
                        WHEN goods_revenue >= 1500000 * :mult THEN 'A3'
                        WHEN goods_revenue >= 1000000 * :mult THEN 'B1'
                        WHEN goods_revenue >= 500000  * :mult THEN 'B2'
                        WHEN goods_revenue >= 150000  * :mult THEN 'C1'
                        WHEN goods_revenue >= 1000    * :mult THEN 'C2'
                        ELSE 'Other'
                    END AS abc_group
                FROM abc_prev
            )
            SELECT 
                ag.abc_group AS group_prev,
                COUNT(DISTINCT ag.client_code) AS companies_count,
                COALESCE(SUM(v.goods_revenue), 0) AS goods_revenue,
                COALESCE(SUM(v.invoice_count), 0) AS invoice_count
            FROM abc_grouped ag
            LEFT JOIN view_client_profiles_yearly v 
                ON v.client_code = ag.client_code 
                AND v.sales_year = :year
            WHERE ag.abc_group = ANY(:groups)
            GROUP BY ag.abc_group
            ORDER BY 
                CASE ag.abc_group
                    WHEN 'A1' THEN 1 WHEN 'A2' THEN 2 WHEN 'A3' THEN 3
                    WHEN 'B1' THEN 4 WHEN 'B2' THEN 5
                    WHEN 'C1' THEN 6 WHEN 'C2' THEN 7
                END
        """), {
            "year_prev": year_prev,
            "year": year,
            "mult": multiplier,
            "groups": group_list
        })
        
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
        
        result = db.execute(text("""
            WITH abc_prev AS (
                SELECT 
                    client_code,
                    goods_revenue
                FROM client_year_activity
                WHERE sales_year = :year_prev
            ),
            abc_grouped AS (
                SELECT 
                    client_code,
                    CASE
                        WHEN goods_revenue >= 3000000 * :mult THEN 'A1'
                        WHEN goods_revenue >= 2000000 * :mult THEN 'A2'
                        WHEN goods_revenue >= 1500000 * :mult THEN 'A3'
                        WHEN goods_revenue >= 1000000 * :mult THEN 'B1'
                        WHEN goods_revenue >= 500000  * :mult THEN 'B2'
                        WHEN goods_revenue >= 150000  * :mult THEN 'C1'
                        WHEN goods_revenue >= 1000    * :mult THEN 'C2'
                        ELSE 'Other'
                    END AS abc_group
                FROM abc_prev
            ),
            -- C1/C2 из прошлого года
            zalet_prev AS (
                SELECT ag.client_code, ag.abc_group AS group_prev
                FROM abc_grouped ag
                WHERE ag.abc_group IN ('C1', 'C2')
            ),
            -- Новые (не было в прошлом году)
            new_clients AS (
                SELECT v.client_code, 'Новый' AS group_prev
                FROM view_client_profiles_yearly v
                WHERE v.sales_year = :year
                  AND v.client_code NOT IN (
                      SELECT client_code FROM client_year_activity WHERE sales_year = :year_prev AND is_active = TRUE
                  )
            ),
            -- Объединяем
            all_zalet AS (
                SELECT * FROM zalet_prev
                UNION ALL
                SELECT * FROM new_clients
            )
            SELECT 
                az.group_prev,
                COUNT(DISTINCT az.client_code) AS companies_count,
                COALESCE(SUM(v.goods_revenue), 0) AS goods_revenue,
                COALESCE(SUM(v.invoice_count), 0) AS invoice_count
            FROM all_zalet az
            LEFT JOIN view_client_profiles_yearly v 
                ON v.client_code = az.client_code 
                AND v.sales_year = :year
            GROUP BY az.group_prev
            ORDER BY 
                CASE az.group_prev
                    WHEN 'C1' THEN 1 WHEN 'C2' THEN 2 WHEN 'Новый' THEN 3
                END
        """), {
            "year_prev": year_prev,
            "year": year,
            "mult": multiplier
        })
        
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
        result = db.execute(text("""
            SELECT 
                COALESCE(ad.name, 'Не указано') AS direction_name,
                COUNT(DISTINCT d.client_code) AS companies_count,
                COUNT(DISTINCT d.id) AS invoice_count,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE
            LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
            WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
              AND EXTRACT(MONTH FROM d.invoice_date) = :month
            GROUP BY ad.name
            ORDER BY goods_revenue DESC
            LIMIT 10
        """), {"year": year, "month": month})
        
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
        result = db.execute(text("""
            SELECT 
                p.code AS product_code,
                p.name AS product_name,
                COUNT(DISTINCT d.id) AS invoice_count,
                COALESCE(SUM(sl.amount), 0) AS total_sales,
                COALESCE(SUM(sl.quantity), 0) AS total_quantity
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            JOIN products p ON sl.product_code = p.code
            WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
              AND EXTRACT(MONTH FROM d.invoice_date) = :month
              AND COALESCE(p.is_service, FALSE) = FALSE
            GROUP BY p.code, p.name
            ORDER BY total_sales DESC
            LIMIT :limit
        """), {"year": year, "month": month, "limit": limit})
        
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
        
        result = db.execute(text("""
            WITH month_data AS (
                SELECT 
                    d.client_code,
                    COUNT(DISTINCT d.id) AS invoice_count,
                    COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
                FROM documents d
                JOIN sales_lines sl ON sl.document_id = d.id
                LEFT JOIN products pr ON sl.product_code = pr.code
                WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
                  AND EXTRACT(MONTH FROM d.invoice_date) = :month
                GROUP BY d.client_code
            ),
            abc_prev AS (
                SELECT 
                    d.client_code,
                    COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue_prev
                FROM documents d
                JOIN sales_lines sl ON sl.document_id = d.id
                LEFT JOIN products pr ON sl.product_code = pr.code
                WHERE EXTRACT(YEAR FROM d.invoice_date) = :year_prev
                GROUP BY d.client_code
            ),
            abc_grouped AS (
                SELECT 
                    client_code,
                    CASE
                        WHEN goods_revenue_prev >= 3000000 * :mult THEN 'A1'
                        WHEN goods_revenue_prev >= 2000000 * :mult THEN 'A2'
                        WHEN goods_revenue_prev >= 1500000 * :mult THEN 'A3'
                        WHEN goods_revenue_prev >= 1000000 * :mult THEN 'B1'
                        WHEN goods_revenue_prev >= 500000  * :mult THEN 'B2'
                        WHEN goods_revenue_prev >= 150000  * :mult THEN 'C1'
                        WHEN goods_revenue_prev >= 1000    * :mult THEN 'C2'
                        ELSE 'Новый'
                    END AS abc_group_prev
                FROM abc_prev
            )
            SELECT 
                c.name AS client_name,
                COALESCE(ag.abc_group_prev, 'Новый') AS group_prev,
                md.invoice_count,
                md.goods_revenue
            FROM month_data md
            JOIN clients c ON c.code = md.client_code
            LEFT JOIN abc_grouped ag ON ag.client_code = md.client_code
            WHERE c.is_active_current = TRUE
            ORDER BY md.goods_revenue DESC
            LIMIT :limit
        """), {
            "year": year,
            "month": month,
            "year_prev": year_prev,
            "mult": multiplier,
            "limit": limit
        })
        
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
    """Количество активных клиентов за год (из client_year_active)"""
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(
            text("SELECT COUNT(*) FROM client_year_active WHERE sales_year = :year AND is_active = TRUE"),
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
        result = db.execute(text("""
            WITH client_invoices AS (
                SELECT
                    d.client_code,
                    c.name,
                    c.ipn,
                    c.okpo_code,
                    COUNT(DISTINCT d.id) AS invoice_count,
                    COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
                    MIN(d.invoice_date) AS first_date,
                    MAX(d.invoice_date) AS last_date,
                    (MAX(d.invoice_date) - MIN(d.invoice_date)) AS days_between
                FROM documents d
                JOIN sales_lines sl ON d.id = sl.document_id
                JOIN client_year_active cya ON d.client_code = cya.client_code AND cya.sales_year = :year AND cya.is_active = TRUE
                JOIN clients c ON d.client_code = c.code
                LEFT JOIN products pr ON sl.product_code = pr.code
                WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
                GROUP BY d.client_code, c.name, c.ipn, c.okpo_code
                HAVING COUNT(DISTINCT d.id) BETWEEN 2 AND 3
            )
            SELECT
                client_code,
                name,
                ipn,
                okpo_code,
                invoice_count,
                goods_revenue,
                first_date,
                last_date,
                days_between,
                CASE
                    WHEN goods_revenue >= 3000000 * :mult THEN 'A1'
                    WHEN goods_revenue >= 2000000 * :mult THEN 'A2'
                    WHEN goods_revenue >= 1500000 * :mult THEN 'A3'
                    WHEN goods_revenue >= 1000000 * :mult THEN 'B1'
                    WHEN goods_revenue >= 500000  * :mult THEN 'B2'
                    WHEN goods_revenue >= 150000  * :mult THEN 'C1'
                    WHEN goods_revenue >= 1000    * :mult THEN 'C2'
                    ELSE 'Ниже C2'
                END AS abc_group
            FROM client_invoices
            ORDER BY goods_revenue DESC
        """), {"year": year, "mult": multiplier})

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

        result = db.execute(text("""
                        WITH max_month AS (
                SELECT COALESCE(MAX(EXTRACT(MONTH FROM invoice_date)), 12) AS max_m
                FROM documents WHERE EXTRACT(YEAR FROM invoice_date) = :year
            ),
            curr AS (
                SELECT
                    d.client_code,
                    COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS revenue,
                    COUNT(DISTINCT d.id) AS invoice_count
                FROM documents d
                JOIN sales_lines sl ON d.id = sl.document_id
                LEFT JOIN products pr ON sl.product_code = pr.code
                JOIN client_year_active cya ON d.client_code = cya.client_code AND cya.sales_year = :year AND cya.is_active = TRUE
                WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
                GROUP BY d.client_code
            ),
            prev AS (
                SELECT
                    d.client_code,
                    COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS revenue,
                    COUNT(DISTINCT d.id) AS invoice_count
                FROM documents d
                JOIN sales_lines sl ON d.id = sl.document_id
                LEFT JOIN products pr ON sl.product_code = pr.code
                JOIN client_year_active cya ON d.client_code = cya.client_code AND cya.sales_year = :year_prev AND cya.is_active = TRUE
                CROSS JOIN max_month m
                WHERE EXTRACT(YEAR FROM d.invoice_date) = :year_prev
                  AND EXTRACT(MONTH FROM d.invoice_date) <= m.max_m
                GROUP BY d.client_code
            ),
            abc_curr AS (
                SELECT client_code, revenue,
                    CASE
                        WHEN revenue >= 3000000 * :mult THEN 'A1'
                        WHEN revenue >= 2000000 * :mult THEN 'A2'
                        WHEN revenue >= 1500000 * :mult THEN 'A3'
                        WHEN revenue >= 1000000 * :mult THEN 'B1'
                        WHEN revenue >= 500000  * :mult THEN 'B2'
                        WHEN revenue >= 150000  * :mult THEN 'C1'
                        WHEN revenue >= 1000            THEN 'C2'
                        ELSE 'Ниже C2'
                    END AS abc_group,
                    invoice_count
                FROM curr
            ),
            abc_prev AS (
                SELECT client_code, revenue,
                    CASE
                        WHEN revenue >= 3000000 * :mult THEN 'A1'
                        WHEN revenue >= 2000000 * :mult THEN 'A2'
                        WHEN revenue >= 1500000 * :mult THEN 'A3'
                        WHEN revenue >= 1000000 * :mult THEN 'B1'
                        WHEN revenue >= 500000  * :mult THEN 'B2'
                        WHEN revenue >= 150000  * :mult THEN 'C1'
                        WHEN revenue >= 1000            THEN 'C2'
                        ELSE 'Ниже C2'
                    END AS abc_group,
                    invoice_count
                FROM prev
            )
            SELECT
                COALESCE(ac.client_code, ap.client_code) AS client_code,
                c.name AS client_name,
                COALESCE(ac.revenue, 0) AS revenue_curr,
                COALESCE(ap.revenue, 0) AS revenue_prev,
                COALESCE(ac.invoice_count, 0) AS invoices_curr,
                COALESCE(ap.invoice_count, 0) AS invoices_prev,
                COALESCE(ac.abc_group, 'Новый') AS abc_curr,
                COALESCE(ap.abc_group, 'Новый') AS abc_prev
            FROM abc_curr ac
            FULL OUTER JOIN abc_prev ap ON ac.client_code = ap.client_code
            JOIN clients c ON c.code = COALESCE(ac.client_code, ap.client_code)
            ORDER BY COALESCE(ac.revenue, 0) DESC            
        """), {"year": year, "year_prev": year_prev, "mult": multiplier})

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
    """
    verify_token(token)
    db = get_db()
    
    try:
        rfm_data = {}
        alt_data = {}
        
        for year in [year_current, year_previous]:
            # Структура по умолчанию для 6 RFM групп
            groups_rfm = {
                'one': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0},
                'repeat': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0},
                'quarter': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0},
                'month': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0},
                'week': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0},
                'day': {'companies': 0, 'invoices': 0, 'sales': 0.0, 'avg_check': 0.0}
            }
            
            result_rfm = db.execute(text("""
                WITH client_invoices AS (
                    SELECT 
                        c.code,
                        COUNT(DISTINCT d.id) AS invoice_count,
                        COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS total_revenue
                    FROM clients c
                    JOIN client_year_active cya ON cya.client_code = c.code AND cya.sales_year = :year AND cya.is_active = TRUE
                    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = :year
                    JOIN sales_lines sl ON sl.document_id = d.id
                    LEFT JOIN products pr ON sl.product_code = pr.code
                    WHERE c.code NOT IN ('9653', '11230')
                    GROUP BY c.code
                ),
                rfm_groups AS (
                    SELECT 
                        CASE 
                            WHEN invoice_count = 1 THEN 'one'
                            WHEN invoice_count BETWEEN 2 AND 3 THEN 'repeat'
                            WHEN invoice_count BETWEEN 4 AND 10 THEN 'quarter'
                            WHEN invoice_count BETWEEN 11 AND 40 THEN 'month'
                            WHEN invoice_count BETWEEN 41 AND 170 THEN 'week'
                            ELSE 'day'
                        END AS rfm_group,
                        COUNT(*) AS companies,
                        SUM(invoice_count) AS invoices,
                        ROUND(SUM(total_revenue)::numeric, 2) AS sales,
                        ROUND(AVG(total_revenue / NULLIF(invoice_count, 0))::numeric, 2) AS avg_check
                    FROM client_invoices
                    GROUP BY rfm_group
                )
                SELECT * FROM rfm_groups
            """), {"year": year})
            
            for row in result_rfm:
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
            
            # ===== Альтернативная классификация (4 группы) =====
            # 🔴 Залётные (random): small/C2 clients (below limit_price) with 1..3 purchases
            # 🟠 Разовые основные (one_time_main): main/ABC clients (above limit_price) with 1 purchase
            # 🔵 Повторно основные (repeat_main): main/ABC clients (above limit_price) with 2..3 purchases
            # 🟢 Постоянные (regular): all clients with 4+ purchases
            below_data = fetch_pivot_data_sync(year, 2.9, 146000, 'below')
            above_data = fetch_pivot_data_sync(year, 2.9, 146000, 'above')
            
            def get_pivot_row(data, grp, metric):
                for r in data:
                    if r.get('out_group_name') == grp and r.get('out_metric') == metric:
                        return r
                return {}
            
            b_comp = get_pivot_row(below_data, 'Total', 'Итого') or get_pivot_row(below_data, 'C2', 'Кол-во компаний')
            b_sales = get_pivot_row(below_data, 'C2', 'Сумма продаж')
            a_comp = get_pivot_row(above_data, 'Total', 'Итого') or get_pivot_row(above_data, 'ABC', 'Кол-во компаний')
            a_sales = get_pivot_row(above_data, 'ABC', 'Сумма продаж')
            
            z_comp = int(b_comp.get('out_1', 0) + b_comp.get('out_2_3', 0))
            z_sales = float(b_sales.get('out_1', 0) + b_sales.get('out_2_3', 0))
            z_avg = round((z_sales / z_comp) / 1000, 2) if z_comp else 0.0
            
            r_comp = int(a_comp.get('out_1', 0))
            r_sales = float(a_sales.get('out_1', 0))
            r_avg = round((r_sales / r_comp) / 1000, 2) if r_comp else 0.0
            
            p_comp = int(a_comp.get('out_2_3', 0))
            p_sales = float(a_sales.get('out_2_3', 0))
            p_avg = round((p_sales / p_comp) / 1000, 2) if p_comp else 0.0
            
            pos_comp = int(
                b_comp.get('out_4_10', 0) + b_comp.get('out_11_40', 0) + b_comp.get('out_41_170', 0) + b_comp.get('out_171_plus', 0) +
                a_comp.get('out_4_10', 0) + a_comp.get('out_11_40', 0) + a_comp.get('out_41_170', 0) + a_comp.get('out_171_plus', 0)
            )
            pos_sales = float(
                b_sales.get('out_4_10', 0) + b_sales.get('out_11_40', 0) + b_sales.get('out_41_170', 0) + b_sales.get('out_171_plus', 0) +
                a_sales.get('out_4_10', 0) + a_sales.get('out_11_40', 0) + a_sales.get('out_41_170', 0) + a_sales.get('out_171_plus', 0)
            )
            pos_avg = round((pos_sales / pos_comp) / 1000, 2) if pos_comp else 0.0
            
            groups_alt = {
                'random': {'companies': z_comp, 'sales': round(z_sales, 2), 'avg_check': z_avg},
                'one_time_main': {'companies': r_comp, 'sales': round(r_sales, 2), 'avg_check': r_avg},
                'repeat_main': {'companies': p_comp, 'sales': round(p_sales, 2), 'avg_check': p_avg},
                'regular': {'companies': pos_comp, 'sales': round(pos_sales, 2), 'avg_check': pos_avg}
            }
            
            alt_data[str(year)] = {
                'groups': groups_alt,
                'total_companies': z_comp + r_comp + p_comp + pos_comp,
                'total_sales': round(z_sales + r_sales + p_sales + pos_sales, 2)
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
    limit_price: float = 146000
):
    """Возвращает структурированные данные для 4 секций ABC-анализа"""
    verify_token(token)
    db = get_db()
    try:
        # Получаем данные через функцию generate_custom_sales_report
        below_result = db.execute(
            text("SELECT * FROM generate_custom_sales_report(:year, :multiplier, :limit_price, 'below')"),
            {"year": year, "multiplier": multiplier, "limit_price": limit_price}
        ).fetchall()
        above_result = db.execute(
            text("SELECT * FROM generate_custom_sales_report(:year, :multiplier, :limit_price, 'above')"),
            {"year": year, "multiplier": multiplier, "limit_price": limit_price}
        ).fetchall()
        
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
        
        below = parse_data(below_result)
        above = parse_data(above_result)

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
    limit_price: float = 146000
):
    """Глубокий анализ сегмента C2 с распаковкой повторных и внутренней ABC-классификацией"""
    verify_token(token)
    db = get_db()
    try:
        sql = text("""
            WITH client_stats AS (
                SELECT 
                    d.client_code,
                    COUNT(DISTINCT d.id) AS invoices_count,
                    COUNT(DISTINCT d.invoice_date) AS distinct_dates,
                    COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
                FROM documents d
                JOIN sales_lines sl ON sl.document_id = d.id
                LEFT JOIN products pr ON sl.product_code = pr.code
                JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE
                WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
                GROUP BY d.client_code
            ),
            c2_clients AS (
                SELECT 
                    client_code,
                    invoices_count,
                    distinct_dates,
                    goods_revenue,
                    CASE
                        WHEN invoices_count = 1 THEN '1'
                        WHEN invoices_count = 2 AND distinct_dates = 1 THEN '2_1d'
                        WHEN invoices_count = 2 AND distinct_dates = 2 THEN '2_diff'
                        WHEN invoices_count = 3 THEN '3'
                        WHEN invoices_count BETWEEN 4 AND 10 THEN '4_10'
                        WHEN invoices_count BETWEEN 11 AND 40 THEN '11_40'
                        ELSE '41_plus'
                    END AS freq_group
                FROM client_stats
                WHERE goods_revenue < :limit_price
            ),
            c2_with_cum AS (
                SELECT 
                    *,
                    SUM(goods_revenue) OVER (ORDER BY goods_revenue DESC, client_code) AS cum_revenue,
                    SUM(goods_revenue) OVER () AS total_c2_revenue
                FROM c2_clients
            )
            SELECT 
                client_code,
                invoices_count,
                goods_revenue,
                freq_group,
                CASE
                    WHEN total_c2_revenue IS NULL OR total_c2_revenue = 0 THEN 'C'
                    WHEN cum_revenue <= total_c2_revenue * 0.80 OR (cum_revenue - goods_revenue) < total_c2_revenue * 0.80 THEN 'A'
                    WHEN cum_revenue <= total_c2_revenue * 0.95 OR (cum_revenue - goods_revenue) < total_c2_revenue * 0.95 THEN 'B'
                    ELSE 'C'
                END AS internal_class
            FROM c2_with_cum
        """)
        rows = db.execute(sql, {"year": year, "limit_price": limit_price}).fetchall()
        rows_prev = db.execute(sql, {"year": year - 1, "limit_price": limit_price}).fetchall()
        
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
    limit_price: float = 146000
):
    """Детальный анализ любого сегмента (c2, abc, total, important) с матрицей и локальным ABC"""
    verify_token(token)
    db = get_db()
    try:
        where_clauses = {
            'c2': 'WHERE goods_revenue < :limit_price',
            'abc': 'WHERE goods_revenue >= :limit_price',
            'total': '',
            'important': 'WHERE goods_revenue >= :limit_price OR invoices_count >= 4'
        }
        where_sql = where_clauses.get(segment.lower(), where_clauses['abc'])

        sql = text(f"""
            WITH client_stats AS (
                SELECT 
                    d.client_code,
                    COUNT(DISTINCT d.id) AS invoices_count,
                    COUNT(DISTINCT d.invoice_date) AS distinct_dates,
                    COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
                FROM documents d
                JOIN sales_lines sl ON sl.document_id = d.id
                LEFT JOIN products pr ON sl.product_code = pr.code
                JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE
                WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
                GROUP BY d.client_code
            ),
            filtered_clients AS (
                SELECT 
                    client_code,
                    invoices_count,
                    distinct_dates,
                    goods_revenue,
                    CASE
                        WHEN invoices_count = 1 THEN '1'
                        WHEN invoices_count = 2 AND distinct_dates = 1 THEN '2_1d'
                        WHEN invoices_count = 2 AND distinct_dates = 2 THEN '2_diff'
                        WHEN invoices_count = 3 THEN '3'
                        WHEN invoices_count BETWEEN 4 AND 10 THEN '4_10'
                        WHEN invoices_count BETWEEN 11 AND 40 THEN '11_40'
                        WHEN invoices_count BETWEEN 41 AND 170 THEN '41_170'
                        ELSE '171_plus'
                    END AS freq_group
                FROM client_stats
                {where_sql}
            ),
            clients_with_cum AS (
                SELECT 
                    *,
                    SUM(goods_revenue) OVER (ORDER BY goods_revenue DESC, client_code) AS cum_revenue,
                    SUM(goods_revenue) OVER () AS total_segment_revenue
                FROM filtered_clients
            )
            SELECT 
                client_code,
                invoices_count,
                goods_revenue,
                freq_group,
                CASE
                    WHEN total_segment_revenue IS NULL OR total_segment_revenue = 0 THEN 'C'
                    WHEN cum_revenue <= total_segment_revenue * 0.80 OR (cum_revenue - goods_revenue) < total_segment_revenue * 0.80 THEN 'A'
                    WHEN cum_revenue <= total_segment_revenue * 0.95 OR (cum_revenue - goods_revenue) < total_segment_revenue * 0.95 THEN 'B'
                    ELSE 'C'
                END AS internal_class
            FROM clients_with_cum
        """)
        
        rows = db.execute(sql, {"year": year, "limit_price": limit_price}).fetchall()
        rows_prev = db.execute(sql, {"year": year - 1, "limit_price": limit_price}).fetchall()
        
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
        sql = text("""
            WITH stats AS (
                SELECT 
                    d.client_code,
                    COUNT(DISTINCT d.id) AS invoices_count,
                    COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
                FROM documents d
                JOIN sales_lines sl ON sl.document_id = d.id
                LEFT JOIN products pr ON sl.product_code = pr.code
                JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE
                WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
                GROUP BY d.client_code
            ),
            categorized AS (
                SELECT 
                    *,
                    CASE
                        WHEN goods_revenue >= 3000000 * :mult THEN 'A1'
                        WHEN goods_revenue >= 2000000 * :mult THEN 'A2'
                        WHEN goods_revenue >= 1500000 * :mult THEN 'A3'
                        WHEN goods_revenue >= 1000000 * :mult THEN 'B1'
                        WHEN goods_revenue >= 500000  * :mult THEN 'B2'
                        WHEN goods_revenue >= 150000  * :mult THEN 'C1'
                        ELSE 'C2_above'
                    END AS abc_group
                FROM stats
                WHERE goods_revenue >= :limit_price
            )
            SELECT 
                abc_group,
                COUNT(*) AS companies,
                SUM(invoices_count) AS invoices,
                SUM(goods_revenue) AS sales
            FROM categorized
            GROUP BY abc_group
            ORDER BY abc_group;
        """)
        rows = db.execute(sql, {"year": year, "mult": multiplier, "limit_price": limit_price}).fetchall()
        
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
        sql = text("""
            WITH stats AS (
                SELECT 
                    d.client_code,
                    c.name AS client_name,
                    COUNT(DISTINCT d.id) AS invoices_count,
                    COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
                FROM documents d
                JOIN sales_lines sl ON sl.document_id = d.id
                LEFT JOIN products pr ON sl.product_code = pr.code
                JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE
                WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
                GROUP BY d.client_code, c.name
            ),
            all_sales AS (
                SELECT COALESCE(SUM(goods_revenue), 1) AS grand_total FROM stats
            )
            SELECT 
                s.client_code,
                s.client_name,
                s.invoices_count,
                s.goods_revenue,
                CASE 
                    WHEN s.goods_revenue >= :limit_price THEN 'ABC' 
                    ELSE 'C2 (4+ накладных)' 
                END AS category,
                a.grand_total
            FROM stats s, all_sales a
            WHERE s.goods_revenue >= :limit_price OR s.invoices_count >= 4
            ORDER BY s.goods_revenue DESC;
        """)
        rows = db.execute(sql, {"year": year, "limit_price": limit_price}).fetchall()
        
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

        # Основной запрос без исключённого клиента
        result = db.execute(text("""
            WITH month_revenue AS (
                SELECT 
                    d.client_code,
                    COUNT(DISTINCT d.id) as invoice_count,
                    COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
                FROM documents d
                JOIN sales_lines sl ON sl.document_id = d.id
                LEFT JOIN products pr ON sl.product_code = pr.code
                WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
                  AND EXTRACT(MONTH FROM d.invoice_date) = :month
                  AND d.client_code != :exclude_client
                GROUP BY d.client_code
            ),
            status_2025 AS (
                SELECT 
                    client_code,
                    sr.status_name as status_name
                FROM client_year_activity cya
                LEFT JOIN status_rules sr ON sr.id = cya.abc_group::integer
                WHERE cya.sales_year = :year - 1
                  AND cya.is_active = TRUE
            ),
            status_2026 AS (
                SELECT 
                    c.code as client_code,
                    sr.status_name as status_name
                FROM clients c
                LEFT JOIN status_rules sr ON sr.id = c.current_status_id
                WHERE c.is_active_current = TRUE
            )
            SELECT 
                mr.client_code,
                c.name as client_name,
                mr.invoice_count,
                mr.goods_revenue,
                COALESCE(s25.status_name, '—') as status_2025,
                COALESCE(s26.status_name, '—') as status_2026
            FROM month_revenue mr
            JOIN clients c ON c.code = mr.client_code
            LEFT JOIN status_2025 s25 ON s25.client_code = mr.client_code
            LEFT JOIN status_2026 s26 ON s26.client_code = mr.client_code
            WHERE mr.goods_revenue > 0
            ORDER BY mr.goods_revenue DESC
            LIMIT :limit
        """), {
            "year": target_year,
            "month": target_month,
            "exclude_client": exclude_client,
            "limit": limit
        })
        
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
            excl_row = db.execute(text("""
                SELECT 
                    d.client_code,
                    c.name as client_name,
                    COUNT(DISTINCT d.id) as invoice_count,
                    COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
                FROM documents d
                JOIN sales_lines sl ON sl.document_id = d.id
                LEFT JOIN products pr ON sl.product_code = pr.code
                JOIN clients c ON c.code = d.client_code
                WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
                  AND EXTRACT(MONTH FROM d.invoice_date) = :month
                  AND d.client_code = :exclude_client
                GROUP BY d.client_code, c.name
            """), {
                "year": target_year,
                "month": target_month,
                "exclude_client": exclude_client
            }).fetchone()
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
