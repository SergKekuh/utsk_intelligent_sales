import json
from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()

@router.get("/api/analytics/client/revenue")
def get_client_revenue_analytics_api(
    code: str = Query(...),
    year: int = Query(2026),
    token: str = Query(None),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        val = db.execute(text("SELECT public.get_client_revenue_analytics(:code, :year)"), {"code": code, "year": year}).scalar()
        return val if isinstance(val, dict) else json.loads(val) if isinstance(val, str) else val
    except Exception as e:
        logger.error(f"Ошибка get_client_revenue_analytics_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/client/invoices")
def get_client_invoices_analytics_api(
    code: str = Query(...),
    year: int = Query(2026),
    token: str = Query(None),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        val = db.execute(text("SELECT public.get_client_invoices_analytics(:code, :year)"), {"code": code, "year": year}).scalar()
        return val if isinstance(val, dict) else json.loads(val) if isinstance(val, str) else val
    except Exception as e:
        logger.error(f"Ошибка get_client_invoices_analytics_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/client/avg-check")
def get_client_avg_check_analytics_api(
    code: str = Query(...),
    year: int = Query(2026),
    token: str = Query(None),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        val = db.execute(text("SELECT public.get_client_avg_check_analytics(:code, :year)"), {"code": code, "year": year}).scalar()
        return val if isinstance(val, dict) else json.loads(val) if isinstance(val, str) else val
    except Exception as e:
        logger.error(f"Ошибка get_client_avg_check_analytics_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/client/last-purchase")
def get_client_last_purchase_analytics_api(
    code: str = Query(...),
    token: str = Query(None),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        val = db.execute(text("SELECT public.get_client_last_purchase_analytics(:code)"), {"code": code}).scalar()
        return val if isinstance(val, dict) else json.loads(val) if isinstance(val, str) else val
    except Exception as e:
        logger.error(f"Ошибка get_client_last_purchase_analytics_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/client/invoices-month")
def get_client_invoices_by_month_api(
    code: str = Query(...),
    year: int = Query(2026),
    month: int = Query(1),
    token: str = Query(None),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        val = db.execute(text("SELECT public.get_client_invoices_by_month(:code, :year, :month)"), {"code": code, "year": year, "month": month}).scalar()
        return val if isinstance(val, dict) else json.loads(val) if isinstance(val, str) else val
    except Exception as e:
        logger.error(f"Ошибка get_client_invoices_by_month_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/client/month-summary")
def get_client_month_summary_api(
    code: str = Query(...),
    year: int = Query(2026),
    month: int = Query(1),
    token: str = Query(None),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        val = db.execute(text("SELECT public.get_client_month_summary(:code, :year, :month)"), {"code": code, "year": year, "month": month}).scalar()
        return val if isinstance(val, dict) else json.loads(val) if isinstance(val, str) else val
    except Exception as e:
        logger.error(f"Ошибка get_client_month_summary_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/client/month-invoices")
def get_client_month_invoices_api(
    code: str = Query(...),
    year: int = Query(2026),
    month: int = Query(1),
    token: str = Query(None),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        val = db.execute(text("SELECT public.get_client_month_invoices(:code, :year, :month)"), {"code": code, "year": year, "month": month}).scalar()
        return val if isinstance(val, dict) else json.loads(val) if isinstance(val, str) else val
    except Exception as e:
        logger.error(f"Ошибка get_client_month_invoices_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/client/month-products")
def get_client_month_products_api(
    code: str = Query(...),
    year: int = Query(2026),
    month: int = Query(1),
    token: str = Query(None),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        val = db.execute(text("SELECT public.get_client_month_products(:code, :year, :month)"), {"code": code, "year": year, "month": month}).scalar()
        return val if isinstance(val, dict) else json.loads(val) if isinstance(val, str) else val
    except Exception as e:
        logger.error(f"Ошибка get_client_month_products_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/client/month-daily")
def get_client_month_daily_api(
    code: str = Query(...),
    year: int = Query(2026),
    month: int = Query(1),
    token: str = Query(None),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        val = db.execute(text("SELECT public.get_client_month_daily(:code, :year, :month)"), {"code": code, "year": year, "month": month}).scalar()
        return val if isinstance(val, dict) else json.loads(val) if isinstance(val, str) else val
    except Exception as e:
        logger.error(f"Ошибка get_client_month_daily_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))
