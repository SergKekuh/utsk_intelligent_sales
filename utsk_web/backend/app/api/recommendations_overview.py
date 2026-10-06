"""
API для страницы «Рекомендації — Огляд» — сводка по 5 топовым размерам клиента.
"""
from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()


@router.get("/api/analytics/recommendations-overview/kpi")
def recommendations_overview_kpi(
    token: str = Query(None),
    code: str = Query(...),
    year: int = Query(2026),
    limit: int = Query(5),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        row = db.execute(
            text("SELECT * FROM get_recommendations_overview_kpi(:code, :y, :lim)"),
            {"code": code, "y": year, "lim": limit},
        ).fetchone()
        if not row:
            return {"status": "ok", "data": None}
        d = dict(row._mapping)
        return {
            "status": "ok",
            "data": {
                "client_name": d["client_name"],
                "top_sizes_count": int(d["top_sizes_count"] or 0),
                "total_revenue": float(d["total_revenue"] or 0),
                "total_invoices": int(d["total_invoices"] or 0),
                "avg_check": float(d["avg_check"] or 0),
                "share_of_client_pct": float(d["share_of_client_pct"] or 0),
                "top_size_display": d["top_size_display"],
                "top_size_revenue": float(d["top_size_revenue"] or 0),
            },
        }
    except Exception as e:
        logger.error(f"Ошибка recommendations_overview_kpi: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/recommendations-overview/monthly")
def recommendations_overview_monthly(
    token: str = Query(None),
    code: str = Query(...),
    year: int = Query(2026),
    limit: int = Query(5),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_recommendations_overview_monthly(:code, :y, :lim)"),
            {"code": code, "y": year, "lim": limit},
        ).fetchall()
        items = [{
            "size_key": r.size_key,
            "display_name": r.display_name,
            "month_num": int(r.month_num),
            "month_name": r.month_name,
            "revenue_cur": float(r.revenue_cur or 0),
            "revenue_prev": float(r.revenue_prev or 0),
        } for r in rows]
        return {"status": "ok", "year": year, "data": items}
    except Exception as e:
        logger.error(f"Ошибка recommendations_overview_monthly: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/recommendations-overview/abc")
def recommendations_overview_abc(
    token: str = Query(None),
    code: str = Query(...),
    year: int = Query(2026),
    limit: int = Query(5),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_recommendations_overview_abc(:code, :y, :lim)"),
            {"code": code, "y": year, "lim": limit},
        ).fetchall()
        items = [{
            "rank": int(r.rank),
            "size_key": r.size_key,
            "display_name": r.display_name,
            "revenue": float(r.revenue or 0),
            "share_pct": float(r.share_pct or 0),
            "cumulative_pct": float(r.cumulative_pct or 0),
            "abc_class": r.abc_class,
        } for r in rows]
        return {"status": "ok", "data": items}
    except Exception as e:
        logger.error(f"Ошибка recommendations_overview_abc: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/recommendations-overview/crosssell")
def recommendations_overview_crosssell(
    token: str = Query(None),
    code: str = Query(...),
    year: int = Query(2026),
    limit: int = Query(5),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_recommendations_overview_crosssell(:code, :y, :lim)"),
            {"code": code, "y": year, "lim": limit},
        ).fetchall()
        items = [{
            "size_key_a": r.size_key_a,
            "display_name_a": r.display_name_a,
            "size_key_b": r.size_key_b,
            "display_name_b": r.display_name_b,
            "same_invoice_count": int(r.same_invoice_count or 0),
            "affinity_pct": float(r.affinity_pct or 0),
        } for r in rows]
        return {"status": "ok", "data": items}
    except Exception as e:
        logger.error(f"Ошибка recommendations_overview_crosssell: {e}")
        raise HTTPException(status_code=500, detail=str(e))
