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
            GROUP BY c.code, c.name, sr.status_name, c.last_purchase_date
            ORDER BY total_revenue DESC LIMIT :limit
        """), {"limit": limit})
        return [dict(row._mapping) for row in result]
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
def funnel(token: str = Query(None)):
    verify_token(token)
    db = get_db()
    try:
        result = db.execute(text("""
            SELECT sr.status_name as stage, COUNT(*) as count,
                   COALESCE(SUM(d.total_amount), 0) as revenue
            FROM clients c
            JOIN status_rules sr ON c.current_status_id = sr.id
            LEFT JOIN documents d ON d.client_code = c.code
            GROUP BY sr.status_name, sr.priority ORDER BY sr.priority
        """))
        return [dict(row._mapping) for row in result]
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
