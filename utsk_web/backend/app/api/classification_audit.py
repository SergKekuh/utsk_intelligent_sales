"""
API для страницы «Аудит класифікації» — просмотр и откат изменений.
"""
from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session

from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()

@router.get("/api/analytics/classification-audit/list")
def classification_audit_list_api(
    token: str = Query(None),
    client_code: str = Query(None),
    change_reason: str = Query(None),
    date_from: str = Query(None),
    date_to: str = Query(None),
    limit: int = Query(100),
    offset: int = Query(0),
    db: Session = Depends(get_db),
):
    """
    Список записей аудита с фильтрами.
    """
    verify_token(token)
    try:
        where = ["1=1"]
        params = {"lim": limit, "off": offset}

        if client_code:
            where.append("client_code ILIKE :cc")
            params["cc"] = f"%{client_code}%"
        if change_reason:
            where.append("change_reason = :cr")
            params["cr"] = change_reason
        if date_from:
            where.append("changed_at >= :df")
            params["df"] = date_from
        if date_to:
            where.append("changed_at <= :dt")
            params["dt"] = date_to + " 23:59:59"

        where_sql = " AND ".join(where)

        rows = db.execute(
            text(f"""
                SELECT id, client_code, client_name,
                       old_direction_id, new_direction_id,
                       old_confidence, new_confidence,
                       old_source, new_source,
                       change_reason, changed_by, notes,
                       TO_CHAR(changed_at, 'YYYY-MM-DD HH24:MI:SS') AS changed_at,
                       COUNT(*) OVER() AS total_count
                FROM classification_audit_log
                WHERE {where_sql}
                ORDER BY changed_at DESC
                LIMIT :lim OFFSET :off
            """),
            params,
        ).fetchall()

        items = []
        total = 0
        for r in rows:
            total = int(r.total_count or 0)
            items.append({
                "id": int(r.id),
                "client_code": r.client_code,
                "client_name": r.client_name,
                "old_direction_id": int(r.old_direction_id) if r.old_direction_id is not None else None,
                "new_direction_id": int(r.new_direction_id) if r.new_direction_id is not None else None,
                "old_confidence": float(r.old_confidence) if r.old_confidence is not None else None,
                "new_confidence": float(r.new_confidence) if r.new_confidence is not None else None,
                "old_source": r.old_source,
                "new_source": r.new_source,
                "change_reason": r.change_reason,
                "changed_by": r.changed_by,
                "notes": r.notes,
                "changed_at": r.changed_at,
            })

        return {"status": "ok", "total": total, "limit": limit, "offset": offset, "data": items}
    except Exception as e:
        logger.error(f"Ошибка classification-audit/list: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/classification-audit/kpi")
def classification_audit_kpi_api(
    token: str = Query(None),
    db: Session = Depends(get_db),
):
    """
    KPI по логу: всего записей, за сегодня, откатов, источников.
    """
    verify_token(token)
    try:
        db.execute(text('COMMIT'));
        row = db.execute(text("""
            SELECT
                COUNT(*) AS total_rows,
                COUNT(*) FILTER (WHERE changed_at::date = CURRENT_DATE) AS today_rows,
                COUNT(*) FILTER (WHERE change_reason = 'revert') AS reverts,
                COUNT(DISTINCT client_code) AS uniq_clients,
                COUNT(*) FILTER (WHERE change_reason = 'auto_name') AS by_auto_name,
                COUNT(*) FILTER (WHERE change_reason = 'basket') AS by_basket,
                COUNT(*) FILTER (WHERE change_reason = 'manual') AS by_manual
            FROM classification_audit_log
        """)).fetchone()

        db.commit()
        d = dict(row._mapping)
        return {
            "status": "ok",
            "data": {
                "total_rows": int(d["total_rows"] or 0),
                "today_rows": int(d["today_rows"] or 0),
                "reverts": int(d["reverts"] or 0),
                "uniq_clients": int(d["uniq_clients"] or 0),
                "by_auto_name": int(d["by_auto_name"] or 0),
                "by_basket": int(d["by_basket"] or 0),
                "by_manual": int(d["by_manual"] or 0),
            },
        }
    except Exception as e:
        logger.error(f"Ошибка classification-audit/kpi: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/api/analytics/classification-audit/revert/{audit_id}")
def classification_audit_revert_api(
    audit_id: int,
    token: str = Query(None),
    db: Session = Depends(get_db),
):
    """
    Откат изменения классификации по ID записи аудита.
    """
    verify_token(token)
    try:
        db.execute(text('COMMIT'));
        row = db.execute(
            text("SELECT * FROM revert_classification_change(:id)"),
            {"id": audit_id},
        ).fetchone()

        if not row:
            raise HTTPException(status_code=404, detail="Запись не найдена")

        db.commit()
        d = dict(row._mapping)
        return {
            "status": "ok",
            "success": bool(d["success"]),
            "client_code": d["client_code"],
            "message": d["message"],
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Ошибка classification-audit/revert {audit_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
