"""
API для страницы «Матриця розмірів клієнта» (/client-size-matrix).
Предоставляет полную матрицу типоразмеров компании с разбивкой по 4 категориям
(round, prof, welded, sheet) и подсветкой покупок конкретного клиента.
"""
from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from typing import Optional

from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()


@router.get("/api/analytics/client-size-matrix")
def get_client_size_matrix_api(
    code: Optional[str] = Query(None),
    client_code: Optional[str] = Query(None),
    year: int = Query(2026),
    category: Optional[str] = Query(None),  # round / prof / welded / sheet
    token: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    """
    Возвращает матрицу типоразмеров каталога и сводные KPI с подсветкой покупок клиента.
    Поддерживает фильтрацию по категории: round, prof, welded, sheet.
    """
    verify_token(token)
    target_code = code or client_code  # Може бути None — загальна матриця
    client_name = None

    try:
        if target_code:
            # Назва клієнта
            client_row = db.execute(
                text("SELECT name FROM clients WHERE code = :code"),
                {"code": target_code},
            ).fetchone()
            client_name = client_row[0] if client_row and client_row[0] else target_code

        # 1. Получаем KPI (14 полей)
        kpi_row = db.execute(
            text("SELECT * FROM get_client_size_matrix_kpi(:code, :y)"),
            {"code": target_code, "y": year},
        ).fetchone()

        kpi_dict = {}
        if kpi_row:
            m = kpi_row._mapping
            kpi_dict = {
                "client_name": client_name,
                "total_catalog_products": int(m["total_catalog_products"] or 0),
                "total_catalog_sizes": int(m["total_catalog_sizes"] or 0),
                "round_sizes": int(m["round_sizes"] or 0),
                "prof_sizes": int(m["prof_sizes"] or 0),
                "welded_sizes": int(m["welded_sizes"] or 0),
                "sheet_sizes": int(m["sheet_sizes"] or 0),
                "client_bought_sizes": int(m["client_bought_sizes"] or 0),
                "client_round_sizes": int(m["client_round_sizes"] or 0),
                "client_prof_sizes": int(m["client_prof_sizes"] or 0),
                "client_welded_sizes": int(m["client_welded_sizes"] or 0),
                "client_sheet_sizes": int(m["client_sheet_sizes"] or 0),
                "client_revenue": float(m["client_revenue"] or 0),
                "client_quantity": float(m["client_quantity"] or 0),
                "stock_sizes": int(m["stock_sizes"] or 0),
                # Алиасы для обратной совместимости
                "catalog_positions_total": int(m["total_catalog_products"] or 0),
                "catalog_sizes_total": int(m["total_catalog_sizes"] or 0),
                "catalog_round_sizes": int(m["round_sizes"] or 0),
                "catalog_prof_sizes": int(m["prof_sizes"] or 0),
                "client_sizes_bought": int(m["client_bought_sizes"] or 0),
                "client_round_bought": int(m["client_round_sizes"] or 0),
                "client_prof_bought": int(m["client_prof_sizes"] or 0),
                "client_revenue_total": float(m["client_revenue"] or 0),
                "client_quantity_total": float(m["client_quantity"] or 0),
                "sizes_in_stock_count": int(m["stock_sizes"] or 0),
            }

        # 2. Получаем строки матрицы
        matrix_rows = db.execute(
            text("SELECT * FROM get_client_size_matrix(:code, :y)"),
            {"code": target_code, "y": year},
        ).mappings().all()

        # 3. Получаем size_key типоразмеров, у которых хотя бы один товар имеет сертификаты
        raw_cur = db.connection().connection.cursor()
        raw_cur.execute("""
            WITH cert_products AS (
                -- Актуальна схема: certs_registry / cert_product_links -> product_sales_registry
                -- (старі product_certificates / product_certificate_links перейменовані в *_archive)
                SELECT DISTINCT ltrim(psr.product_code, '0') AS product_code
                FROM cert_product_links cpl
                JOIN product_sales_registry psr ON psr.id = cpl.sale_id
                WHERE psr.product_code IS NOT NULL
                  AND cpl.is_verified = TRUE
            ),
            pipe_certs AS (
                SELECT
                    CASE
                        WHEN p.name ~* 'сварн|электросварн|електрозварн|ГОСТ 10704|ГОСТ 10705|ГОСТ 20295'
                            THEN 'welded_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                        WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                            THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                        WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                            THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                        ELSE NULL
                    END AS size_key
                FROM products p
                JOIN cert_products cp ON cp.product_code = p.code
                CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
                WHERE COALESCE(p.is_service, FALSE) = FALSE
                  AND (
                      (NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL)
                      OR (ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL)
                  )
                  AND p.name !~* 'лист|ДСТУ 8540|ГОСТ 19903|ЛСТ'
            ),
            sheet_certs AS (
                SELECT
                    'sheet_' || sh.wall::TEXT || 'x' || sh.prof_w::TEXT || 'x' || sh.prof_h::TEXT AS size_key
                FROM products p
                JOIN cert_products cp ON cp.product_code = p.code
                CROSS JOIN LATERAL (
                    SELECT
                        CASE 
                            WHEN m3 IS NOT NULL THEN replace(m3[1], ',', '.')::numeric
                            WHEN m1 IS NOT NULL THEN replace(m1[1], ',', '.')::numeric
                            WHEN m2 IS NOT NULL THEN replace(m2[1], ',', '.')::numeric
                            ELSE NULL
                        END AS wall,
                        CASE 
                            WHEN m3 IS NOT NULL THEN replace(m3[2], ',', '.')::numeric
                            WHEN m2 IS NOT NULL THEN replace(m2[1], ',', '.')::numeric
                            ELSE 1500::numeric
                        END AS prof_w,
                        CASE 
                            WHEN m3 IS NOT NULL THEN replace(m3[3], ',', '.')::numeric
                            WHEN m2 IS NOT NULL THEN replace(m2[2], ',', '.')::numeric
                            ELSE 6000::numeric
                        END AS prof_h
                    FROM (
                        SELECT
                            regexp_match(p.name, '(\\d+(?:[.,]\\d+)?)\\s*[xх×*]\\s*(\\d+(?:[.,]\\d+)?)\\s*[xх×*]\\s*(\\d+(?:[.,]\\d+)?)') as m3,
                            regexp_match(p.name, '(\\d+(?:[.,]\\d+)?)\\s*[xх×*]\\s*(\\d+(?:[.,]\\d+)?)') as m2,
                            regexp_match(p.name, '(?i)(?:б-|б\\s+|г/к\\s*|лист\\s+)(\\d+(?:[.,]\\d+)?)\\s*(?:мм)?') as m1
                    ) sub
                ) sh
                WHERE COALESCE(p.is_service, FALSE) = FALSE
                  AND (p.name ~* 'лист|ДСТУ 8540|ГОСТ 19903|ЛСТ')
                  AND p.name !~* 'машинко|корпус'
                  AND sh.wall IS NOT NULL
            )
            SELECT DISTINCT size_key FROM pipe_certs WHERE size_key IS NOT NULL
            UNION
            SELECT DISTINCT size_key FROM sheet_certs WHERE size_key IS NOT NULL
        """)
        cert_size_rows = raw_cur.fetchall()
        raw_cur.close()
        cert_size_keys = {row[0] for row in cert_size_rows if row[0]}

        items = []
        for r in matrix_rows:
            cat = r.get("product_category")
            # Фильтр по category, если задан
            if category and cat != category:
                continue

            s_key = r["size_key"]
            items.append({
                "size_key": s_key,
                "size_display": r["size_display"],
                "is_prof": bool(r["is_prof"]),
                "product_category": cat,
                "diameter": float(r["diameter"]) if r["diameter"] is not None else None,
                "prof_w": float(r["prof_w"]) if r["prof_w"] is not None else None,
                "prof_h": float(r["prof_h"]) if r["prof_h"] is not None else None,
                "wall": float(r["wall"]) if r["wall"] is not None else None,
                "catalog_products_count": int(r["catalog_products_count"] or 0),
                "stock_total": float(r["stock_total"] or 0),
                "has_stock": bool(r["has_stock"]),
                "has_certificates": s_key in cert_size_keys,
                "client_bought": bool(r["client_bought"]),
                "client_revenue": float(r["client_revenue"] or 0),
                "client_quantity": float(r["client_quantity"] or 0),
                "client_invoices_count": int(r["client_invoices_count"] or 0),
            })

        return {
            "status": "ok",
            "client_code": target_code,
            "client_name": client_name,
            "year": year,
            "category": category,
            "kpi": kpi_dict,
            "count": len(items),
            "data": items,
        }

    except Exception as e:
        logger.error(f"Помилка get_client_size_matrix_api: {e}")
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")


@router.get("/api/analytics/client-size-matrix/kpi")
def get_client_size_matrix_kpi_api(
    code: Optional[str] = Query(None),
    client_code: Optional[str] = Query(None),
    year: int = Query(2026),
    token: Optional[str] = Query(None),
    db: Session = Depends(get_db),
):
    """
    Легковесный эндпоинт для получения сводных 14 KPI матрицы клиента.
    """
    verify_token(token)
    target_code = code or client_code  # Може бути None
    client_name = None

    try:
        if target_code:
            client_row = db.execute(
                text("SELECT name FROM clients WHERE code = :code"),
                {"code": target_code},
            ).fetchone()
            client_name = client_row[0] if client_row and client_row[0] else target_code

        row = db.execute(
            text("SELECT * FROM get_client_size_matrix_kpi(:code, :y)"),
            {"code": target_code, "y": year},
        ).fetchone()

        if not row:
            return {"status": "ok", "data": None}

        m = row._mapping
        return {
            "status": "ok",
            "client_code": target_code,
            "client_name": client_name,
            "year": year,
            "data": {
                "client_name": client_name,
                "total_catalog_products": int(m["total_catalog_products"] or 0),
                "total_catalog_sizes": int(m["total_catalog_sizes"] or 0),
                "round_sizes": int(m["round_sizes"] or 0),
                "prof_sizes": int(m["prof_sizes"] or 0),
                "welded_sizes": int(m["welded_sizes"] or 0),
                "sheet_sizes": int(m["sheet_sizes"] or 0),
                "client_bought_sizes": int(m["client_bought_sizes"] or 0),
                "client_round_sizes": int(m["client_round_sizes"] or 0),
                "client_prof_sizes": int(m["client_prof_sizes"] or 0),
                "client_welded_sizes": int(m["client_welded_sizes"] or 0),
                "client_sheet_sizes": int(m["client_sheet_sizes"] or 0),
                "client_revenue": float(m["client_revenue"] or 0),
                "client_quantity": float(m["client_quantity"] or 0),
                "stock_sizes": int(m["stock_sizes"] or 0),
                # Алиасы
                "catalog_positions_total": int(m["total_catalog_products"] or 0),
                "catalog_sizes_total": int(m["total_catalog_sizes"] or 0),
                "catalog_round_sizes": int(m["round_sizes"] or 0),
                "catalog_prof_sizes": int(m["prof_sizes"] or 0),
                "client_sizes_bought": int(m["client_bought_sizes"] or 0),
                "client_round_bought": int(m["client_round_sizes"] or 0),
                "client_prof_bought": int(m["client_prof_sizes"] or 0),
                "client_revenue_total": float(m["client_revenue"] or 0),
                "client_quantity_total": float(m["client_quantity"] or 0),
                "sizes_in_stock_count": int(m["stock_sizes"] or 0),
            },
        }
    except Exception as e:
        logger.error(f"Помилка get_client_size_matrix_kpi_api: {e}")
        raise HTTPException(status_code=500, detail=str(e))
