from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()

@router.get("/api/analytics/new-clients-overview")
def new_clients_overview(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db)
):
    verify_token(token)
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

@router.get("/api/analytics/new-clients-frequency")
def new_clients_frequency(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db)
):
    verify_token(token)
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

@router.get("/api/analytics/new-clients-abc")
def new_clients_abc(
    token: str = Query(None),
    year: int = Query(2026),
    multiplier: float = Query(2.9),
    db: Session = Depends(get_db)
):
    verify_token(token)
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

@router.get("/api/analytics/new-clients-abc-compare")
def new_clients_abc_compare(
    token: str = Query(None),
    year: int = Query(2026),
    multiplier: float = Query(2.9),
    db: Session = Depends(get_db)
):
    verify_token(token)
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

@router.get("/api/analytics/new-clients-list")
def new_clients_list(
    token: str = Query(None),
    year: int = Query(2026),
    search: str = Query(None),
    abc_group: str = Query(None),
    limit: int = Query(50),
    offset: int = Query(0),
    db: Session = Depends(get_db)
):
    verify_token(token)
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
