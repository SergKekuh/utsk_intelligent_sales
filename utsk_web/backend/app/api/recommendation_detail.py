"""
API для страницы «Деталізація рекомендації» — глубокая аналитика по конкретному размеру трубы.
"""
from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()


@router.get("/api/analytics/recommendation-detail/kpi")
def recommendation_detail_kpi(
    token: str = Query(None),
    code: str = Query(...),
    size_key: str = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        row = db.execute(
            text("SELECT * FROM get_recommendation_detail_kpi(:code, :sk, :y)"),
            {"code": code, "sk": size_key, "y": year},
        ).fetchone()
        if not row:
            return {"status": "ok", "data": None}
        d = dict(row._mapping)
        return {
            "status": "ok",
            "data": {
                "client_name": d["client_name"],
                "size_display": d["size_display"],
                "shape": d["shape"],
                "pipe_type_ua": d["pipe_type_ua"],
                "purchase_count": int(d["purchase_count"] or 0),
                "total_revenue": float(d["total_revenue"] or 0),
                "total_quantity": float(d["total_quantity"] or 0),
                "share_pct": float(d["share_pct"] or 0),
                "avg_price": float(d["avg_price"] or 0),
                "last_purchase_date": d["last_purchase_date"].strftime("%d.%m.%Y") if d["last_purchase_date"] else None,
                "stock_tonnage": float(d["stock_tonnage"] or 0),
                "segment_share_pct": float(d["segment_share_pct"] or 0),
                "segment_clients_count": int(d["segment_clients_count"] or 0),
            },
        }
    except Exception as e:
        logger.error(f"Ошибка recommendation_detail_kpi: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/recommendation-detail/monthly")
def recommendation_detail_monthly(
    token: str = Query(None),
    code: str = Query(...),
    size_key: str = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_recommendation_detail_monthly(:code, :sk, :y)"),
            {"code": code, "sk": size_key, "y": year},
        ).fetchall()
        items = [{
            "month_num": int(r.month_num),
            "month_name": r.month_name,
            "revenue_cur": float(r.revenue_cur or 0),
            "revenue_prev": float(r.revenue_prev or 0),
            "delta_abs": float(r.delta_abs or 0),
            "delta_pct": float(r.delta_pct) if r.delta_pct is not None else None,
        } for r in rows]
        return {"status": "ok", "year": year, "data": items}
    except Exception as e:
        logger.error(f"Ошибка recommendation_detail_monthly: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/recommendation-detail/segment")
def recommendation_detail_segment(
    token: str = Query(None),
    code: str = Query(...),
    size_key: str = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_recommendation_detail_segment(:code, :sk, :y)"),
            {"code": code, "sk": size_key, "y": year},
        ).fetchall()
        items = [{
            "scope": r.scope,
            "revenue": float(r.revenue or 0),
            "quantity": float(r.quantity or 0),
            "avg_price": float(r.avg_price or 0),
            "clients_count": int(r.clients_count or 0),
            "invoices_count": int(r.invoices_count or 0),
        } for r in rows]
        return {"status": "ok", "data": items}
    except Exception as e:
        logger.error(f"Ошибка recommendation_detail_segment: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/recommendation-detail/products")
def recommendation_detail_products(
    token: str = Query(None),
    code: str = Query(...),
    size_key: str = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_recommendation_detail_products(:code, :sk, :y)"),
            {"code": code, "sk": size_key, "y": year},
        ).fetchall()
        items = [{
            "product_code": r.product_code,
            "product_name": r.product_name,
            "quantity": float(r.quantity or 0),
            "revenue": float(r.revenue or 0),
            "avg_price": float(r.avg_price or 0),
            "invoices": int(r.invoices or 0),
            "stock_tonnage": float(r.stock_tonnage or 0),
            "last_purchase": r.last_purchase.strftime("%d.%m.%Y") if r.last_purchase else None,
        } for r in rows]
        return {"status": "ok", "data": items}
    except Exception as e:
        logger.error(f"Ошибка recommendation_detail_products: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/recommendation-detail/similar")
def recommendation_detail_similar(
    token: str = Query(None),
    code: str = Query(...),
    size_key: str = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_recommendation_detail_similar(:code, :sk, :y)"),
            {"code": code, "sk": size_key, "y": year},
        ).fetchall()
        items = [{
            "similar_size_key": r.similar_size_key,
            "size_display": r.size_display,
            "pipe_type_ua": r.pipe_type_ua,
            "similarity_reason": r.similarity_reason,
            "client_bought": bool(r.client_bought),
            "segment_revenue": float(r.segment_revenue or 0),
            "stock_tonnage": float(r.stock_tonnage or 0),
        } for r in rows]
        return {"status": "ok", "data": items}
    except Exception as e:
        logger.error(f"Ошибка recommendation_detail_similar: {e}")
        raise HTTPException(status_code=500, detail=str(e))
