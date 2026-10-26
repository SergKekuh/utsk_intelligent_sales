import os
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from fastapi.responses import FileResponse
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..deps import get_db

router = APIRouter(prefix="/api/certificates", tags=["certificates"])

CERTS_DIR = "/home/serg/Documents/SQL_postgresql/Intelligent_Sales/date/sertf"
STATIC_CERTS_DIR = "/home/serg/Documents/SQL_postgresql/Intelligent_Sales/utsk_web/frontend/static/certs"


@router.get("")
def list_certificates(
    product_code: Optional[str] = Query(None),
    cert_number: Optional[str] = Query(None),
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """Список сертификатов с фильтрами."""
    where = []
    params = {"limit": limit, "offset": offset}

    if product_code:
        where.append("""
            (pc.product_code = :product_code OR pc.id IN (
                SELECT certificate_id FROM product_certificate_links WHERE product_code = :product_code
            ))
        """)
        params["product_code"] = product_code

    if cert_number:
        where.append("pc.cert_number ILIKE :cert_number")
        params["cert_number"] = f"%{cert_number}%"

    where_sql = ("WHERE " + " AND ".join(where)) if where else ""

    rows = db.execute(
        text(f"""
            SELECT pc.id, pc.cert_number, pc.doc_number, pc.cert_date,
                   pc.file_name, pc.file_path, pc.product_info,
                   pc.doc_1c_number, pc.organization, pc.product_code
            FROM product_certificates pc
            {where_sql}
            ORDER BY pc.cert_date DESC NULLS LAST, pc.id DESC
            LIMIT :limit OFFSET :offset
        """),
        params,
    ).mappings().all()

    total = db.execute(
        text(f"SELECT COUNT(*) AS n FROM product_certificates pc {where_sql}"),
        params,
    ).scalar()

    items = []
    for r in rows:
        d = dict(r)
        if d.get("cert_date") is not None:
            d["cert_date"] = str(d["cert_date"])
        items.append(d)

    return {
        "total": total or 0,
        "limit": limit,
        "offset": offset,
        "items": items,
    }


@router.get("/{filename}")
def get_cert_pdf(filename: str):
    """PDF сертификата."""
    safe_name = os.path.basename(filename)
    for folder in (CERTS_DIR, STATIC_CERTS_DIR):
        path = os.path.join(folder, safe_name)
        if os.path.exists(path):
            return FileResponse(path, media_type="application/pdf")
    raise HTTPException(status_code=404, detail="PDF не найден")
