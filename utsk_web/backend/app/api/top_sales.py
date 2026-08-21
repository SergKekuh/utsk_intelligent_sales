from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()

@router.get("/api/analytics/top-sales/overview")
def get_top_sales_overview_api(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        rows = db.execute(text("SELECT * FROM get_top_revenue_core(:year, 80)"), {"year": year}).fetchall()
        companies = [dict(r._mapping) for r in rows]

        def find_running_pct(rk):
            for c in companies:
                if c["rank"] == rk:
                    return float(c["running_pct"])
            return 0.0

        top1_pct = find_running_pct(1)
        top5_pct = find_running_pct(5)
        top10_pct = find_running_pct(10)
        top25_pct = find_running_pct(25)
        top50_pct = find_running_pct(50)
        top70_pct = find_running_pct(70)

        last_comp = companies[-1] if companies else None
        top80_pct = float(last_comp["running_pct"]) if last_comp else 0.0
        top80_clients = len(companies)
        top80_revenue = sum(float(c["goods_revenue"] or 0) for c in companies)

        return {
            "status": "ok",
            "year": year,
            "top1_pct": top1_pct,
            "top5_pct": top5_pct,
            "top10_pct": top10_pct,
            "top25_pct": top25_pct,
            "top50_pct": top50_pct,
            "top70_pct": top70_pct,
            "top80_pct": top80_pct,
            "top80_clients": top80_clients,
            "top80_revenue": round(top80_revenue, 2)
        }
    except Exception as e:
        logger.error(f"Ошибка в get_top_sales_overview_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/top-sales/kpi")
def get_top_sales_kpi_api(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        row = db.execute(text("SELECT * FROM get_top_sales_kpi(:year)"), {"year": year}).fetchone()
        if not row:
            return {
                "status": "ok",
                "year": year,
                "total_revenue": 0.0,
                "active_clients_count": 0,
                "top1_share_pct": 0.0,
                "top10_share_pct": 0.0,
                "clients_for_80pct": 0,
                "avg_check": 0.0
            }
        r = dict(row._mapping)
        return {
            "status": "ok",
            "year": year,
            "total_revenue": float(r["total_revenue"] or 0.0),
            "active_clients_count": int(r["active_clients_count"] or 0),
            "top1_share_pct": float(r["top1_share_pct"] or 0.0),
            "top10_share_pct": float(r["top10_share_pct"] or 0.0),
            "clients_for_80pct": int(r["clients_for_80pct"] or 0),
            "avg_check": float(r["avg_check"] or 0.0)
        }
    except Exception as e:
        logger.error(f"Ошибка в get_top_sales_kpi_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/top-sales/companies")
def get_top_companies_api(
    token: str = Query(None),
    year: int = Query(2026),
    limit: int = Query(25),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        rows = db.execute(text("SELECT * FROM get_top_companies(:year, :limit)"), {"year": year, "limit": limit}).fetchall()
        result = []
        for r_raw in rows:
            r = dict(r_raw._mapping)
            result.append({
                "rank": int(r["rank"]),
                "code": str(r["code"]),
                "name": str(r["name"] or "—"),
                "goods_revenue": float(r["goods_revenue"] or 0.0),
                "pct_of_total": float(r["pct_of_total"] or 0.0),
                "running_pct": float(r["running_pct"] or 0.0),
                "status_name": str(r["status_name"] or "—"),
                "invoice_count": int(r["invoice_count"] or 0),
                "avg_check": float(r["avg_check"] or 0.0),
                "prev_year_revenue": float(r["prev_year_revenue"] or 0.0),
                "growth_yoy_pct": float(r["growth_yoy_pct"]) if r.get("growth_yoy_pct") is not None else None,
                "abc_group": str(r["abc_group"] or "—")
            })
        return {
            "status": "ok",
            "year": year,
            "limit": limit,
            "companies": result
        }
    except Exception as e:
        logger.error(f"Ошибка в get_top_companies_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/top-sales/company-detail")
def get_top_company_detail_api(
    token: str = Query(None),
    code: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        target_code = code if isinstance(code, str) and code and not hasattr(code, "default") else None
        if not target_code:
            top1 = db.execute(text("SELECT code FROM get_top_companies(:year, 1)"), {"year": year}).fetchone()
            if top1:
                target_code = str(top1[0])
            else:
                raise HTTPException(status_code=404, detail="ТОП-1 компания не найдена")
        data = db.execute(text("SELECT get_top_company_detail(:code, :year)"), {"code": target_code, "year": year}).scalar()
        return {
            "status": "ok",
            "data": data
        }
    except Exception as e:
        logger.error(f"Ошибка в get_top_company_detail_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/top-sales/core")
def get_top_revenue_core_api(
    token: str = Query(None),
    year: int = Query(2026),
    pct: float = Query(80.0),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        rows = db.execute(text("SELECT * FROM get_top_revenue_core(:year, :pct)"), {"year": year, "pct": pct}).fetchall()
        result = []
        for r_raw in rows:
            r = dict(r_raw._mapping)
            result.append({
                "rank": int(r["rank"]),
                "code": str(r["code"]),
                "name": str(r["name"] or "—"),
                "goods_revenue": float(r["goods_revenue"] or 0.0),
                "pct_of_total": float(r["pct_of_total"] or 0.0),
                "running_pct": float(r["running_pct"] or 0.0),
                "status_name": str(r["status_name"] or "—"),
                "invoice_count": int(r["invoice_count"] or 0),
                "avg_check": float(r["avg_check"] or 0.0),
                "abc_group": str(r["abc_group"] or "—"),
                "prev_year_revenue": float(r["prev_year_revenue"] or 0.0),
                "growth_yoy_pct": float(r["growth_yoy_pct"]) if r.get("growth_yoy_pct") is not None else None
            })
        
        prev_rows = db.execute(text("SELECT COUNT(*) FROM get_top_revenue_core(:prev_year, :pct)"), {"prev_year": year - 1, "pct": pct}).scalar()

        return {
            "status": "ok",
            "year": year,
            "pct": pct,
            "count": len(result),
            "prev_year_count": int(prev_rows or 0),
            "companies": result
        }
    except Exception as e:
        logger.error(f"Ошибка в get_top_revenue_core_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/top-sales/compare-yoy")
def get_top_compare_yoy_api(
    token: str = Query(None),
    year: int = Query(2026),
    limit: int = Query(10),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        data = db.execute(text("SELECT get_top_compare_yoy(:year, :limit)"), {"year": year, "limit": limit}).scalar()
        return {
            "status": "ok",
            "data": data
        }
    except Exception as e:
        logger.error(f"Ошибка в get_top_compare_yoy_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))
