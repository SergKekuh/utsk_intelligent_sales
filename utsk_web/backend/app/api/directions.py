import json
from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()

@router.get("/api/analytics/directions/kpi")
def get_directions_kpi_api(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        row = db.execute(text("SELECT * FROM get_directions_kpi(:year)"), {"year": year}).fetchone()
        if not row:
            return {
                "status": "ok",
                "year": year,
                "data": {
                    "total_revenue": 0.0,
                    "total_clients": 0,
                    "total_invoices": 0,
                    "avg_ticket": 0.0,
                    "top_direction_id": 0,
                    "top_direction_name": "—",
                    "top_direction_revenue": 0.0,
                    "top_direction_share_pct": 0.0,
                    "active_directions_count": 0
                }
            }
        d = dict(row._mapping)
        return {
            "status": "ok",
            "year": year,
            "data": {
                "total_revenue": float(d["total_revenue"] or 0),
                "total_clients": int(d["total_clients"] or 0),
                "total_invoices": int(d["total_invoices"] or 0),
                "avg_ticket": float(d["avg_ticket"] or 0),
                "top_direction_id": int(d["top_direction_id"] or 0),
                "top_direction_name": d["top_direction_name"] or "—",
                "top_direction_revenue": float(d["top_direction_revenue"] or 0),
                "top_direction_share_pct": float(d["top_direction_share_pct"] or 0),
                "active_directions_count": int(d["active_directions_count"] or 0)
            }
        }
    except Exception as e:
        logger.error(f"Ошибка get_directions_kpi_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/directions/summary")
def get_directions_summary_api(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        rows = db.execute(text("SELECT * FROM get_directions_summary(:year)"), {"year": year}).fetchall()
        data = []
        for r in rows:
            m = dict(r._mapping)
            data.append({
                "id": int(m["id"]),
                "name": m["name"],
                "icon": m["icon"],
                "color": m["color"],
                "clients_count": int(m["clients_count"] or 0),
                "total_clients_in_base": int(m["total_clients_in_base"] or 0),
                "invoices_count": int(m["invoices_count"] or 0),
                "goods_revenue": float(m["goods_revenue"] or 0),
                "avg_ticket": float(m["avg_ticket"] or 0),
                "revenue_share_pct": float(m["revenue_share_pct"] or 0),
                "clients_share_pct": float(m["clients_share_pct"] or 0)
            })
        return {
            "status": "ok",
            "year": year,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка get_directions_summary_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/directions/monthly")
def get_directions_monthly_api(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        rows = db.execute(text("SELECT * FROM get_directions_monthly_dynamics(:year)"), {"year": year}).fetchall()
        data = []
        for r in rows:
            m = dict(r._mapping)
            data.append({
                "direction_id": int(m["direction_id"]),
                "direction_name": m["direction_name"],
                "month_num": int(m["month_num"]),
                "month_name": m["month_name"],
                "goods_revenue": float(m["goods_revenue"] or 0),
                "clients_count": int(m["clients_count"] or 0)
            })
        return {
            "status": "ok",
            "year": year,
            "data": data,
            "count": len(data)
        }
    except Exception as e:
        logger.error(f"Ошибка get_directions_monthly_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/directions/companies")
def get_direction_companies_api(
    token: str = Query(None),
    direction_id: int = Query(0),
    year: int = Query(2026),
    limit: int = Query(50),
    offset: int = Query(0),
    search: str = Query(None),
    abc_group: str = Query(None),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_direction_companies(:dir_id, :year, :limit, :offset, :search, :abc)"),
            {
                "dir_id": direction_id,
                "year": year,
                "limit": limit,
                "offset": offset,
                "search": search.strip() if search else None,
                "abc": abc_group.strip() if abc_group else None
            }
        ).fetchall()

        data = []
        total_matching = 0
        for r in rows:
            m = dict(r._mapping)
            total_matching = int(m.get("total_matching_count", 0))
            data.append({
                "code": m["code"],
                "name": m["name"],
                "status_name": m["status_name"],
                "goods_revenue": float(m["goods_revenue"] or 0),
                "invoices_count": int(m["invoices_count"] or 0),
                "avg_ticket": float(m["avg_ticket"] or 0),
                "abc_group": m["abc_group"],
                "edrpou": m["edrpou"],
                "ipn": m["ipn"],
                "last_purchase_date": m["last_purchase_date"]
            })

        return {
            "status": "ok",
            "year": year,
            "direction_id": direction_id,
            "data": data,
            "count": len(data),
            "total_matching": total_matching
        }
    except Exception as e:
        logger.error(f"Ошибка get_direction_companies_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/directions/revenue-analytics")
def get_revenue_analytics(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        res = db.execute(
            text("SELECT get_directions_revenue_analytics(:year)"),
            {"year": year},
        ).scalar()
        if isinstance(res, str):
            res = json.loads(res)
        return {"status": "ok", "year": year, "data": res}
    except Exception as e:
        logger.error(f"Ошибка get_revenue_analytics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/directions/clients-analytics")
def get_clients_analytics(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        res = db.execute(
            text("SELECT get_directions_clients_analytics(:year)"),
            {"year": year},
        ).scalar()
        if isinstance(res, str):
            res = json.loads(res)
        return {"status": "ok", "year": year, "data": res}
    except Exception as e:
        logger.error(f"Ошибка get_clients_analytics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/directions/invoices-analytics")
def get_invoices_analytics(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        res = db.execute(
            text("SELECT get_directions_invoices_analytics(:year)"),
            {"year": year},
        ).scalar()
        if isinstance(res, str):
            res = json.loads(res)
        return {"status": "ok", "year": year, "data": res}
    except Exception as e:
        logger.error(f"Ошибка get_invoices_analytics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/directions/avg-check-analytics")
def get_avg_check_analytics(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        res = db.execute(
            text("SELECT get_directions_avg_check_analytics(:year)"),
            {"year": year},
        ).scalar()
        if isinstance(res, str):
            res = json.loads(res)
        return {"status": "ok", "year": year, "data": res}
    except Exception as e:
        logger.error(f"Ошибка get_avg_check_analytics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/directions/leader-analytics")
def get_leader_analytics(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        res = db.execute(
            text("SELECT get_directions_leader_analytics(:year)"),
            {"year": year},
        ).scalar()
        if isinstance(res, str):
            res = json.loads(res)
        return {"status": "ok", "year": year, "data": res}
    except Exception as e:
        logger.error(f"Ошибка get_leader_analytics: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ============================================================
# DIRECTION-DETAIL: 7 новых эндпоинтов
# ============================================================

@router.get("/api/analytics/direction/kpi")
def get_direction_detail_kpi(
    token: str = Query(None),
    direction_id: int = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        row = db.execute(
            text("SELECT * FROM get_direction_detail_kpi(:did, :year)"),
            {"did": direction_id, "year": year},
        ).fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Направление не найдено")
        return {"status": "ok", "year": year, "data": dict(row._mapping)}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Ошибка get_direction_detail_kpi: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/direction/top-clients")
def get_direction_top_clients(
    token: str = Query(None),
    direction_id: int = Query(...),
    year: int = Query(2026),
    limit: int = Query(10, ge=1, le=50),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_direction_top_clients(:did, :year, :lim)"),
            {"did": direction_id, "year": year, "lim": limit},
        ).fetchall()
        return {"status": "ok", "year": year, "data": [dict(r._mapping) for r in rows]}
    except Exception as e:
        logger.error(f"Ошибка get_direction_top_clients: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/direction/clients")
def get_direction_clients(
    token: str = Query(None),
    direction_id: int = Query(...),
    year: int = Query(2026),
    search: str = Query(None),
    abc_group: str = Query(None),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        rows = db.execute(
            text("""SELECT * FROM get_direction_clients_list(
                :did, :year, :search, :abc, :lim, :off)"""),
            {
                "did": direction_id,
                "year": year,
                "search": search or None,
                "abc": abc_group or None,
                "lim": limit,
                "off": offset,
            },
        ).fetchall()
        total_count = rows[0].total_count if rows else 0
        return {
            "status": "ok",
            "year": year,
            "total_count": int(total_count),
            "data": [dict(r._mapping) for r in rows],
        }
    except Exception as e:
        logger.error(f"Ошибка get_direction_clients: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/direction/products-by-size")
@router.get("/api/analytics/directions/products-by-size")
def get_direction_products_by_size(
    token: str = Query(None),
    direction_id: int = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_direction_products_by_size(:did, :year)"),
            {"did": direction_id, "year": year},
        ).fetchall()
        return {"status": "ok", "year": year, "data": [dict(r._mapping) for r in rows]}
    except Exception as e:
        logger.error(f"Ошибка get_direction_products_by_size: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/direction/size-drilldown")
@router.get("/api/analytics/directions/size-drilldown")
def get_direction_size_drilldown_api(
    token: str = Query(None),
    direction_id: int = Query(...),
    year: int = Query(2026),
    size_key: str = Query(...),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_direction_size_drilldown(:did, :size_key, :year)"),
            {
                "did": direction_id,
                "size_key": size_key,
                "year": year,
            },
        ).fetchall()
        return {"status": "ok", "year": year, "data": [dict(r._mapping) for r in rows]}
    except Exception as e:
        logger.error(f"Ошибка get_direction_size_drilldown: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/direction/clients-yoy")
def get_direction_clients_yoy(
    token: str = Query(None),
    direction_id: int = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_direction_clients_yoy(:did, :year)"),
            {"did": direction_id, "year": year},
        ).fetchall()
        return {"status": "ok", "year": year, "data": [dict(r._mapping) for r in rows]}
    except Exception as e:
        logger.error(f"Ошибка get_direction_clients_yoy: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/direction/sizes-yoy")
@router.get("/api/analytics/directions/sizes-yoy")
def get_direction_sizes_yoy_api(
    token: str = Query(None),
    direction_id: int = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_direction_sizes_yoy(:did, :year)"),
            {"did": direction_id, "year": year},
        ).fetchall()
        return {"status": "ok", "year": year, "data": [dict(r._mapping) for r in rows]}
    except Exception as e:
        logger.error(f"Ошибка get_direction_sizes_yoy: {e}")
        raise HTTPException(status_code=500, detail=str(e))
