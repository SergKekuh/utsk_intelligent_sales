from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()

@router.get("/api/analytics/inactive-clients-overview")
def inactive_clients_overview(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db)
):
    verify_token(token)
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

@router.get("/api/analytics/inactive-clients-list")
def inactive_clients_list(
    token: str = Query(None),
    status_id: int = Query(8),
    search: str = Query(None),
    abc_group: str = Query(None),
    days_min: int = Query(None),
    days_max: int = Query(None),
    limit: int = Query(50),
    offset: int = Query(0),
    db: Session = Depends(get_db)
):
    verify_token(token)
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

@router.get("/api/analytics/inactive-clients-distribution")
def inactive_clients_distribution(
    token: str = Query(None),
    status_id: int = Query(8),
    db: Session = Depends(get_db)
):
    verify_token(token)
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

@router.get("/api/analytics/inactive-clients-abc")
def inactive_clients_abc(
    token: str = Query(None),
    status_id: int = Query(8),
    year_prev: int = Query(2025),
    db: Session = Depends(get_db)
):
    verify_token(token)
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
