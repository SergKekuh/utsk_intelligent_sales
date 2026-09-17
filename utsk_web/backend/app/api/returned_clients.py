from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()

@router.get("/api/analytics/returned-clients-overview")
def returned_clients_overview(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        sql = text("SELECT * FROM get_returned_clients_overview(:year)")
        row = db.execute(sql, {"year": year}).fetchone()
        if not row:
            return {
                "status": "ok",
                "year": year,
                "total_returned": 0,
                "total_revenue": 0.0,
                "total_invoices": 0,
                "avg_revenue_per_client": 0.0,
                "avg_ticket": 0.0,
                "pct_of_active_clients": 0.0,
                "avg_break_period": "1 год"
            }
        
        r = dict(row._mapping)
        return {
            "status": "ok",
            "year": year,
            "total_returned": int(r["total_returned"] or 0),
            "total_revenue": float(r["total_revenue"] or 0.0),
            "total_invoices": int(r["total_invoices"] or 0),
            "avg_revenue_per_client": float(r["avg_revenue_per_client"] or 0.0),
            "avg_ticket": float(r["avg_ticket"] or 0.0),
            "pct_of_active_clients": float(r["pct_of_active_clients"] or 0.0),
            "avg_break_period": str(r["avg_break_period"] or "1 год")
        }
    except Exception as e:
        logger.error(f"Ошибка returned_clients_overview: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/returned-clients-frequency")
def returned_clients_frequency(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        sql = text("SELECT * FROM get_returned_clients_frequency(:year)")
        result = db.execute(sql, {"year": year}).fetchall()
        data = []
        for row in result:
            r = dict(row._mapping)
            data.append({
                "frequency_group": r["frequency_group"],
                "sort_order": int(r["sort_order"]),
                "returned_count": int(r["returned_count"] or 0),
                "returned_revenue": float(r["returned_revenue"] or 0.0),
                "avg_ticket": float(r["avg_ticket"] or 0.0),
                "returned_pct": float(r["returned_pct"] or 0.0)
            })
        return {
            "status": "ok",
            "year": year,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка returned_clients_frequency: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/returned-clients-abc")
def returned_clients_abc(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        sql = text("SELECT * FROM get_returned_clients_abc(:year)")
        result = db.execute(sql, {"year": year}).fetchall()
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
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка returned_clients_abc: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/returned-clients-compare-new")
def returned_clients_compare_new(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        sql = text("SELECT * FROM get_returned_clients_compare_new(:year)")
        result = db.execute(sql, {"year": year}).fetchall()
        data = []
        for row in result:
            r = dict(row._mapping)
            data.append({
                "frequency_group": r["frequency_group"],
                "sort_order": int(r["sort_order"]),
                "returned_count": int(r["returned_count"] or 0),
                "returned_revenue": float(r["returned_revenue"] or 0.0),
                "returned_avg_ticket": float(r["returned_avg_ticket"] or 0.0),
                "new_count": int(r["new_count"] or 0),
                "new_revenue": float(r["new_revenue"] or 0.0),
                "new_avg_ticket": float(r["new_avg_ticket"] or 0.0)
            })
        return {
            "status": "ok",
            "year": year,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка returned_clients_compare_new: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/returned-clients-list")
def returned_clients_list(
    token: str = Query(None),
    year: int = Query(2026),
    search: str = Query(None),
    abc_group: str = Query(None),
    limit: int = Query(100),
    offset: int = Query(0),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        sql = text("SELECT * FROM get_returned_clients_list(:year, :search, :abc_group, :limit, :offset)")
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
                "abc_group": r["abc_group"],
                "frequency_group": r["frequency_group"]
            })
            
        return {
            "status": "ok",
            "year": year,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка returned_clients_list: {e}")
        raise HTTPException(status_code=500, detail=str(e))
