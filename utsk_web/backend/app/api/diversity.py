from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()


def fmt_dim(val):
    if val is None:
        return ""
    f = float(val)
    return str(int(f)) if f.is_integer() else str(f)


@router.get("/api/analytics/diversity-kpi")
def diversity_kpi(
    token: str = Query(None),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        row = db.execute(text("""
            SELECT 
                COUNT(*) AS total_products,
                COUNT(*) FILTER (WHERE is_profile = FALSE AND diameter IS NOT NULL) AS round_count,
                COUNT(*) FILTER (WHERE is_profile = TRUE AND profile_width = profile_height) AS square_count,
                COUNT(*) FILTER (WHERE is_profile = TRUE AND profile_width != profile_height) AS rect_count,
                COALESCE(SUM(in_stock_balance), 0) AS total_stock,
                COUNT(*) FILTER (WHERE in_stock_balance > 0) AS with_stock
            FROM products
            WHERE COALESCE(is_service, FALSE) = FALSE
        """)).mappings().first()

        total = int(row["total_products"])
        rnd = int(row["round_count"])
        sq = int(row["square_count"])
        rc = int(row["rect_count"])

        return {
            "status": "ok",
            "data": {
                "total_products": total,
                "by_category": {
                    "round": rnd,
                    "square_prof": sq,
                    "rect_prof": rc,
                    "other": total - rnd - sq - rc,
                },
                "total_stock": float(row["total_stock"]),
                "with_stock": int(row["with_stock"]),
            },
        }
    except Exception as e:
        logger.error(f"Ошибка diversity_kpi: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/analytics/diversity-list")
def diversity_list(
    token: str = Query(None),
    year: int = Query(2026),
    category: str = Query(None),
    has_stock: bool = Query(None),
    search: str = Query(None),
    limit: int = Query(50, le=200),
    offset: int = Query(0),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        where = ["COALESCE(is_service, FALSE) = FALSE"]
        params = {"limit": limit, "offset": offset}

        if has_stock:
            where.append("in_stock_balance > 0")

        if search:
            where.append("name ILIKE :search")
            params["search"] = f"%{search}%"

        if category == "round":
            where.append("is_profile = FALSE AND diameter IS NOT NULL")
        elif category == "square_prof":
            where.append("is_profile = TRUE AND profile_width = profile_height")
        elif category == "rect_prof":
            where.append("is_profile = TRUE AND profile_width != profile_height")

        where_sql = " AND ".join(where)

        total = db.execute(
            text(f"SELECT COUNT(*) FROM products WHERE {where_sql}"),
            params,
        ).scalar()

        rows = db.execute(text(f"""
            SELECT 
                code, name, standard_name, material_grade,
                diameter, wall_thickness, profile_width, profile_height,
                is_profile, in_stock_balance
            FROM products
            WHERE {where_sql}
            ORDER BY code
            LIMIT :limit OFFSET :offset
        """), params).mappings().all()

        items = []
        for r in rows:
            if r["is_profile"]:
                if r["profile_width"] == r["profile_height"]:
                    cat = "square_prof"
                else:
                    cat = "rect_prof"
                if r["profile_width"] and r["profile_height"] and r["wall_thickness"]:
                    size_key = f"prof_{fmt_dim(r['profile_width'])}x{fmt_dim(r['profile_height'])}x{fmt_dim(r['wall_thickness'])}"
                else:
                    size_key = None
            elif r["diameter"]:
                cat = "round"
                if r["diameter"] and r["wall_thickness"]:
                    size_key = f"round_{fmt_dim(r['diameter'])}x{fmt_dim(r['wall_thickness'])}"
                else:
                    size_key = None
            else:
                cat = "other"
                size_key = None

            items.append({
                "code": r["code"],
                "name": r["name"],
                "standard_name": r["standard_name"],
                "material_grade": r["material_grade"],
                "category": cat,
                "diameter": float(r["diameter"]) if r["diameter"] else None,
                "wall": float(r["wall_thickness"]) if r["wall_thickness"] else None,
                "profile_width": float(r["profile_width"]) if r["profile_width"] else None,
                "profile_height": float(r["profile_height"]) if r["profile_height"] else None,
                "size_key": size_key,
                "stock_balance": float(r["in_stock_balance"] or 0),
            })

        return {
            "status": "ok",
            "total": int(total),
            "data": items,
        }
    except Exception as e:
        logger.error(f"Ошибка diversity_list: {e}")
        raise HTTPException(status_code=500, detail=str(e))
