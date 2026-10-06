"""
API для страницы «Профільні труби» — аналитика по профильным трубам клиента.
"""
from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()


def _get_client_name(db: Session, code: str) -> str:
    try:
        c_row = db.execute(text("SELECT name FROM clients WHERE code = :code"), {"code": code}).fetchone()
        return c_row.name if c_row and c_row.name else code
    except Exception:
        return code


@router.get("/api/analytics/profile-pipes/kpi")
def profile_pipes_kpi_api(
    token: str = Query(None),
    code: str = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        client_name = _get_client_name(db, code)
        row = db.execute(
            text("SELECT * FROM get_profile_pipes_kpi(:code, :yr)"),
            {"code": code, "yr": year},
        ).fetchone()
        if not row:
            return {"status": "ok", "code": code, "client_name": client_name, "year": year, "data": None}
        d = dict(row._mapping)
        return {
            "status": "ok", "code": code, "client_name": client_name, "year": year,
            "data": {
                "uniq_sizes": int(d["uniq_sizes"] or 0),
                "uniq_products": int(d["uniq_products"] or 0),
                "invoices": int(d["invoices"] or 0),
                "revenue": float(d["revenue"] or 0),
                "avg_check": float(d["avg_check"] or 0),
            },
        }
    except Exception as e:
        logger.error(f"Ошибка profile_pipes_kpi {code}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/profile-pipes/sizes")
def profile_pipes_sizes_api(
    token: str = Query(None),
    code: str = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        client_name = _get_client_name(db, code)
        rows = db.execute(
            text("SELECT * FROM get_profile_pipes_sizes(:code, :yr)"),
            {"code": code, "yr": year},
        ).fetchall()
        items = [{
            "size_key": r.size_key,
            "size_display": r.size_display,
            "shape": r.shape,
            "prof_w": float(r.prof_w) if r.prof_w is not None else None,
            "prof_h": float(r.prof_h) if r.prof_h is not None else None,
            "wall": float(r.wall) if r.wall is not None else None,
            "products_count": int(r.products_count or 0),
            "invoices": int(r.invoices or 0),
            "revenue": float(r.revenue or 0),
            "avg_price": float(r.avg_price or 0),
        } for r in rows]
        return {"status": "ok", "code": code, "client_name": client_name, "year": year, "data": items}
    except Exception as e:
        logger.error(f"Ошибка profile_pipes_sizes {code}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/profile-pipes/products-by-size")
def profile_pipes_products_by_size_api(
    token: str = Query(None),
    code: str = Query(...),
    size_key: str = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_profile_pipes_products_by_size(:code, :sk, :yr)"),
            {"code": code, "sk": size_key, "yr": year},
        ).fetchall()
        items = [{
            "product_code": r.product_code,
            "product_name": r.product_name,
            "quantity": float(r.quantity or 0),
            "revenue": float(r.revenue or 0),
            "invoices": int(r.invoices or 0),
        } for r in rows]
        return {"status": "ok", "code": code, "size_key": size_key, "data": items}
    except Exception as e:
        logger.error(f"Ошибка profile_pipes_products_by_size {code}/{size_key}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/profile-pipes/sizes-yoy")
def profile_pipes_sizes_yoy_api(
    token: str = Query(None),
    code: str = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        client_name = _get_client_name(db, code)
        rows = db.execute(
            text("SELECT * FROM get_profile_pipes_sizes_yoy(:code, :yr)"),
            {"code": code, "yr": year},
        ).fetchall()
        items = [{
            "size_key": r.size_key,
            "size_display": r.size_display,
            "revenue_cur": float(r.revenue_cur or 0),
            "revenue_prev": float(r.revenue_prev or 0),
            "delta_abs": float(r.delta_abs or 0),
            "delta_pct": float(r.delta_pct) if r.delta_pct is not None else None,
        } for r in rows]
        return {"status": "ok", "code": code, "client_name": client_name, "year": year, "data": items}
    except Exception as e:
        logger.error(f"Ошибка profile_pipes_sizes_yoy {code}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/profile-pipes/monthly")
def profile_pipes_monthly_api(
    token: str = Query(None),
    code: str = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        client_name = _get_client_name(db, code)
        rows = db.execute(
            text("SELECT * FROM get_profile_pipes_monthly(:code, :yr)"),
            {"code": code, "yr": year},
        ).fetchall()
        items = [{
            "month_num": int(r.month_num),
            "month_name": r.month_name,
            "revenue": float(r.revenue_cur or 0),
            "invoices": int(r.invoices_cur or 0),
        } for r in rows]
        return {"status": "ok", "code": code, "client_name": client_name, "year": year, "data": items}
    except Exception as e:
        logger.error(f"Ошибка profile_pipes_monthly {code}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/profile-pipes/monthly-v2")
def profile_pipes_monthly_v2_api(
    token: str = Query(None),
    code: str = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    """Расширенная помесячная динамика с YoY."""
    verify_token(token)
    try:
        client_name = _get_client_name(db, code)
        rows = db.execute(
            text("SELECT * FROM get_profile_pipes_monthly(:code, :yr)"),
            {"code": code, "yr": year},
        ).fetchall()
        items = [{
            "month_num": int(r.month_num),
            "month_name": r.month_name,
            "revenue_cur": float(r.revenue_cur or 0),
            "revenue_prev": float(r.revenue_prev or 0),
            "delta_abs": float(r.delta_abs or 0),
            "delta_pct": float(r.delta_pct) if r.delta_pct is not None else None,
            "invoices_cur": int(r.invoices_cur or 0),
            "avg_check": float(r.avg_check or 0),
        } for r in rows]
        return {"status": "ok", "code": code, "client_name": client_name, "year": year, "data": items}
    except Exception as e:
        logger.error(f"Ошибка profile-pipes/monthly-v2 {code}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/profile-pipes/monthly-kpi")
def profile_pipes_monthly_kpi_api(
    token: str = Query(None),
    code: str = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    """KPI для вкладки «Динаміка». """
    verify_token(token)
    try:
        client_name = _get_client_name(db, code)
        row = db.execute(
            text("SELECT * FROM get_profile_pipes_monthly_kpi(:code, :yr)"),
            {"code": code, "yr": year},
        ).fetchone()
        if not row:
            return {"status": "ok", "code": code, "client_name": client_name, "year": year, "data": None}
        d = dict(row._mapping)
        return {
            "status": "ok", "code": code, "client_name": client_name, "year": year,
            "data": {
                "total_revenue": float(d["total_revenue"] or 0),
                "avg_monthly": float(d["avg_monthly"] or 0),
                "best_month_num": int(d["best_month_num"]) if d["best_month_num"] else None,
                "best_month_name": d["best_month_name"],
                "best_month_revenue": float(d["best_month_revenue"] or 0),
                "worst_month_num": int(d["worst_month_num"]) if d["worst_month_num"] else None,
                "worst_month_name": d["worst_month_name"],
                "worst_month_revenue": float(d["worst_month_revenue"] or 0),
                "active_months": int(d["active_months"] or 0),
                "total_invoices": int(d["total_invoices"] or 0),
                "avg_check": float(d["avg_check"] or 0),
            },
        }
    except Exception as e:
        logger.error(f"Ошибка profile-pipes/monthly-kpi {code}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
