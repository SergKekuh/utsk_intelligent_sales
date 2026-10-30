"""
Сертификаты — Промт №84.
Чтение из НОВЫХ таблиц: certs_registry, cert_product_links, product_sales_registry.
Старые product_certificates / product_certificate_links не используются в API
(остаются в БД для аудита, is_deprecated уже проставлен в №82).
Сохраняем обратную совместимость:
- GET /api/certificates           — список (тот же формат ответа)
- GET /api/certificates/by-product/{code}
- GET /api/certificates/by-doc/{doc_number}
- GET/HEAD /api/certificates/{fname} — PDF (404 / 410 / 200)
"""
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


# ---------- 1. Список сертификатов (совместимый ответ) ----------
@router.get("")
def list_certificates(
    product_code: Optional[str] = Query(None),
    cert_number: Optional[str] = Query(None),
    limit: int = Query(100, ge=1, le=1000),
    offset: int = Query(0, ge=0),
    db: Session = Depends(get_db),
):
    """
    Список сертификатов. Источник — certs_registry.
    product_code фильтрует через cert_product_links → product_sales_registry.
    """
    where = []
    params = {"limit": limit, "offset": offset}

    base_from = """
        FROM certs_registry cr
        LEFT JOIN cert_product_links cpl ON cpl.cert_id = cr.id
        LEFT JOIN product_sales_registry psr ON psr.id = cpl.sale_id
    """

    if product_code:
        where.append("ltrim(psr.product_code, '0') = :product_code")
        params["product_code"] = product_code.lstrip("0") or product_code

    if cert_number:
        where.append("cr.cert_number ILIKE :cert_number")
        params["cert_number"] = f"%{cert_number}%"

    where_sql = ("WHERE " + " AND ".join(where)) if where else ""

    rows = db.execute(
        text(f"""
            SELECT DISTINCT cr.id, cr.cert_number, cr.doc_number,
                   cr.cert_date, cr.cert_filename AS file_name,
                   cr.cert_path_linux AS file_path,
                   cr.organization, cr.pdf_exists
            {base_from}
            {where_sql}
            ORDER BY cr.cert_date DESC NULLS LAST, cr.id DESC
            LIMIT :limit OFFSET :offset
        """),
        params,
    ).mappings().all()

    total = db.execute(
        text(f"SELECT COUNT(DISTINCT cr.id) AS n {base_from} {where_sql}"),
        {k: v for k, v in params.items() if k not in ("limit", "offset")},
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


# ---------- 2. Сертификаты по коду товара ----------
@router.get("/by-product/{product_code}")
def certs_by_product(product_code: str, db: Session = Depends(get_db)):
    code = product_code.lstrip("0") or product_code
    rows = db.execute(
        text("""
            SELECT DISTINCT cr.id, cr.cert_number, cr.cert_filename,
                   cr.cert_date, cr.doc_number,
                   cr.organization, cr.pdf_exists,
                   cpl.link_type, cpl.is_verified
            FROM certs_registry cr
            JOIN cert_product_links cpl ON cpl.cert_id = cr.id
            JOIN product_sales_registry psr ON psr.id = cpl.sale_id
            WHERE ltrim(psr.product_code, '0') = :code
            ORDER BY cr.cert_date DESC NULLS LAST, cr.cert_number
        """),
        {"code": code},
    ).mappings().all()

    items = []
    for r in rows:
        d = dict(r)
        if d.get("cert_date") is not None:
            d["cert_date"] = str(d["cert_date"])
        items.append(d)
    return items


# ---------- 3. Сертификаты по накладной ----------
@router.get("/by-doc/{doc_number}")
def certs_by_doc(doc_number: str, db: Session = Depends(get_db)):
    rows = db.execute(
        text("""
            SELECT DISTINCT cr.id, cr.cert_number, cr.cert_filename,
                   cr.cert_date, cr.doc_number,
                   cr.organization, cr.pdf_exists,
                   cpl.link_type, cpl.is_verified
            FROM certs_registry cr
            LEFT JOIN cert_product_links cpl ON cpl.cert_id = cr.id
            WHERE cr.doc_number = :doc
            ORDER BY cr.cert_date DESC NULLS LAST, cr.cert_number
        """),
        {"doc": doc_number},
    ).mappings().all()

    items = []
    for r in rows:
        d = dict(r)
        if d.get("cert_date") is not None:
            d["cert_date"] = str(d["cert_date"])
        items.append(d)
    return items


# ---------- 4. PDF по имени файла (200 / 410 / 404) ----------
@router.api_route("/{filename}", methods=["GET", "HEAD"])
def get_cert_pdf(filename: str, db: Session = Depends(get_db)):
    """
    - 404: нет в certs_registry
    - 410: есть, но pdf_exists=false (файл ещё не загружен)
    - 200: есть и физически на диске
    """
    safe_name = os.path.basename(filename)

    row = db.execute(
        text("""
            SELECT id, cert_number, cert_filename, cert_date,
                   doc_number, organization, pdf_exists
            FROM certs_registry
            WHERE cert_filename = :fn
            LIMIT 1
        """),
        {"fn": safe_name},
    ).mappings().first()

    if not row:
        raise HTTPException(status_code=404, detail="Сертифікат не знайдено в реєстрі")

    # Поиск файла: сначала CERTS_DIR, потом STATIC_CERTS_DIR (как раньше)
    found_path = None
    for folder in (CERTS_DIR, STATIC_CERTS_DIR):
        p = os.path.join(folder, safe_name)
        if os.path.isfile(p):
            found_path = p
            break

    # 410 — если в БД pdf_exists=false ИЛИ файла физически нет
    if not row["pdf_exists"] or not found_path:
        cert_date_str = str(row["cert_date"]) if row.get("cert_date") is not None else None
        raise HTTPException(
            status_code=410,
            detail={
                "status": "file_missing",
                "cert_number": row["cert_number"],
                "cert_date": cert_date_str,
                "doc_number": row["doc_number"],
                "organization": row["organization"],
                "expected_path": os.path.join(CERTS_DIR, safe_name),
                "message": "PDF-файл ще не завантажено в архів. Зверніться до адміністратора.",
            },
        )

    return FileResponse(found_path, media_type="application/pdf", filename=safe_name)
