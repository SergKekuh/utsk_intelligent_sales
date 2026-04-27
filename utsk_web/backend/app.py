"""
UTSK Intelligent Sales — Web Demo Server
Запуск: python backend/app.py
Доступ: http://0.0.0.0:5000
"""

from fastapi import FastAPI, HTTPException, Query, Request
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.responses import HTMLResponse
from sqlalchemy import create_engine, text
from sqlalchemy.orm import Session
import os
import uvicorn

# Конфигурация
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:root@localhost:5432/bd_intelligent_sales")
DEMO_TOKEN = os.getenv("DEMO_TOKEN", "utsk2026")
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", 5000))

# Приложение
app = FastAPI(title="UTSK Intelligent Sales API", version="1.0.0")

# Подключение к БД
engine = create_engine(DATABASE_URL)

def get_db():
    return Session(engine)

# Статика
app.mount("/static", StaticFiles(directory="frontend/static"), name="static")

# ====== АУТЕНТИФИКАЦИЯ ======
def check_token(token: str = Query(None)):
    if token != DEMO_TOKEN:
        raise HTTPException(status_code=403, detail="Неверный токен доступа")

# ====== API: ДАШБОРД ======
@app.get("/api/dashboard")
def dashboard(token: str = Query(None)):
    check_token(token)
    db = get_db()
    try:
        result = db.execute(text("""
            SELECT 
                COUNT(DISTINCT c.code) as total_clients,
                COUNT(DISTINCT CASE WHEN c.last_purchase_date >= CURRENT_DATE - INTERVAL '30 days' THEN c.code END) as active_30d,
                COALESCE(SUM(d.total_amount), 0) as total_revenue
            FROM clients c LEFT JOIN documents d ON d.client_code = c.code
        """)).first()
        return {
            "total_clients": result.total_clients,
            "active_30d": result.active_30d,
            "total_revenue": round(float(result.total_revenue), 2)
        }
    finally:
        db.close()

# ====== API: КЛИЕНТЫ ======
@app.get("/api/clients")
def clients(token: str = Query(None), limit: int = 50, search: str = ""):
    check_token(token)
    db = get_db()
    try:
        result = db.execute(text("""
            SELECT c.code, c.name, sr.status_name as status, c.last_purchase_date
            FROM clients c
            LEFT JOIN status_rules sr ON c.current_status_id = sr.id
            WHERE c.name ILIKE :search OR c.code ILIKE :search
            ORDER BY c.last_purchase_date DESC NULLS LAST
            LIMIT :limit
        """), {"search": f"%{search}%", "limit": limit})
        return [dict(row._mapping) for row in result]
    finally:
        db.close()

# ====== API: СТАТУСЫ ======
@app.get("/api/statuses")
def statuses(token: str = Query(None)):
    check_token(token)
    db = get_db()
    try:
        result = db.execute(text("""
            SELECT sr.status_name, COUNT(*) as count
            FROM clients c
            JOIN status_rules sr ON c.current_status_id = sr.id
            GROUP BY sr.status_name, sr.priority
            ORDER BY sr.priority
        """))
        return [dict(row._mapping) for row in result]
    finally:
        db.close()

# ====== API: РЕКОМЕНДАЦИИ ======
@app.get("/api/recommendations/{client_code}")
def recommendations(client_code: str, token: str = Query(None)):
    check_token(token)
    db = get_db()
    try:
        client = db.execute(text("SELECT name FROM clients WHERE code = :code"), {"code": client_code}).first()
        if not client:
            return {"error": "Клиент не найден"}
        
        result = db.execute(text("""
            SELECT p.code, p.name, 'Часто покупаете' as reason, p.in_stock_balance
            FROM clients c
            JOIN documents d ON d.client_code = c.code
            JOIN sales_lines sl ON sl.document_id = d.id
            JOIN products p ON sl.product_code = p.code
            WHERE c.code = :client_code AND COALESCE(p.in_stock_balance, 0) > 0
            GROUP BY p.code, p.name, p.in_stock_balance
            HAVING COUNT(sl.id) >= 2
            ORDER BY COUNT(sl.id) DESC LIMIT 5
        """), {"client_code": client_code})
        
        return {
            "client_name": client.name,
            "recommendations": [dict(row._mapping) for row in result]
        }
    finally:
        db.close()

# ====== ГЛАВНАЯ СТРАНИЦА ======
@app.get("/", response_class=HTMLResponse)
def index(request: Request, token: str = Query(None)):
    check_token(token)
    with open("frontend/static/index.html", "r", encoding="utf-8") as f:
        return HTMLResponse(content=f.read())

# ====== ЗАПУСК ======
if __name__ == "__main__":
    print("=" * 60)
    print("🚀 UTSK Intelligent Sales — Web Demo Server")
    print("=" * 60)
    print(f"📍 Доступ: http://{HOST}:{PORT}")
    print(f"🔑 Токен: {DEMO_TOKEN}")
    print("=" * 60)
    uvicorn.run(app, host=HOST, port=PORT, log_level="info")
