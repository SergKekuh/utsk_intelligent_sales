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
