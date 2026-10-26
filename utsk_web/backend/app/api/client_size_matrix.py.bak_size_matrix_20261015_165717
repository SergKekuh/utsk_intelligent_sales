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
    target_code = code or client_code
    if not target_code:
        raise HTTPException(status_code=400, detail="Параметр 'code' або 'client_code' обов'язковий")

    try:
        # Название клиента
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

        items = []
        for r in matrix_rows:
            cat = r.get("product_category")
            # Фильтр по category, если задан
            if category and cat != category:
                continue

            items.append({
                "size_key": r["size_key"],
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
    target_code = code or client_code
    if not target_code:
        raise HTTPException(status_code=400, detail="Параметр 'code' або 'client_code' обов'язковий")

    try:
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
