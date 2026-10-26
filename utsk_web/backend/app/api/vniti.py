"""
API-роутер для Profile Rolling Engine (методика ВНИТИ).
Промт №61 v2 — Итерация 2: API + базовый расчёт.

Эндпоинты:
  1. GET /api/analytics/vniti/enumerate          — перебор профилей из заготовки
  2. GET /api/analytics/vniti/direct             — прямая задача (профиль → заготовка)
  3. GET /api/analytics/vniti/section-properties — прочностные характеристики
  4. GET /api/analytics/vniti/tu-lookup          — поиск в каталоге ТУ
  5. GET /api/analytics/billet-detail            — сводка по заготовке
"""
from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()


# ═══════════════════════════════════════════════════════════════════
# 1. Перебор профилей из заготовки
#    vniti_enumerate_profiles(p_diameter, p_wall, p_k10, p_shape,
#                             p_step_mm, p_max_aspect, p_limit)
#    → TABLE(a, b, r_calc, r_prod, k_real, k_min, k_max,
#            fits_tu, delta_diameter)
# ═══════════════════════════════════════════════════════════════════
@router.get("/api/analytics/vniti/enumerate")
def vniti_enumerate(
    token: str = Query(None),
    diameter: float = Query(..., description="Диаметр заготовки, мм"),
    wall: float = Query(..., description="Толщина стенки, мм"),
    k10: float = Query(22.0, description="Базовый радиус калибра (мм)"),
    shape: str = Query("square", description="square | rect"),
    step_mm: float = Query(1.0, description="Шаг перебора (1.0 квадрат / 5.0 прямоуг.)"),
    max_aspect: float = Query(4.0, description="Макс. отношение сторон"),
    limit: int = Query(50, description="Лимит строк"),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        rows = db.execute(
            text("""
                SELECT * FROM vniti_enumerate_profiles(
                    :d, :w, :k10, :shape, :step, :aspect, :lim
                )
            """),
            {
                "d": diameter, "w": wall, "k10": k10, "shape": shape,
                "step": step_mm, "aspect": max_aspect, "lim": limit,
            },
        ).mappings().all()

        items = [
            {
                "a": float(r["a"]),
                "b": float(r["b"]),
                "r_calc": float(r["r_calc"]),
                "r_prod": float(r["r_prod"]),
                "k_real": float(r["k_real"]),
                "k_min": float(r["k_min"]),
                "k_max": float(r["k_max"]),
                "fits_tu": bool(r["fits_tu"]),
                "delta_diameter": float(r["delta_diameter"]),
            }
            for r in rows
        ]
        return {
            "status": "ok",
            "count": len(items),
            "params": {
                "diameter": diameter, "wall": wall, "k10": k10,
                "shape": shape, "step_mm": step_mm,
                "max_aspect": max_aspect, "limit": limit,
            },
            "data": items,
        }
    except Exception as e:
        logger.error(f"Ошибка vniti_enumerate: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ═══════════════════════════════════════════════════════════════════
# 2. Прямая задача: профиль (A×B, S) → заготовка
#    Использует:
#      vniti_calc_contact_radius(p_a, p_b, p_s, p_k10) → numeric
#      vniti_calc_billet_diameter(p_a, p_b, p_s, p_r_calc) → numeric
#      vniti_round_production_radius(p_r_calc, p_s) → numeric
#      vniti_get_k_range(p_s) → TABLE(k_min, k_max, r_min_coef, r_max_coef)
#      vniti_calc_k(p_diameter, p_a, p_b) → numeric
# ═══════════════════════════════════════════════════════════════════
@router.get("/api/analytics/vniti/direct")
def vniti_direct(
    token: str = Query(None),
    a: float = Query(..., description="Сторона A профиля, мм"),
    b: float = Query(..., description="Сторона B профиля, мм"),
    s: float = Query(..., description="Толщина стенки, мм"),
    k10: float = Query(22.0, description="Базовый радиус калибра (мм)"),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        r_calc = db.execute(
            text("SELECT vniti_calc_contact_radius(:a, :b, :s, :k10)"),
            {"a": a, "b": b, "s": s, "k10": k10},
        ).scalar()

        d_billet = db.execute(
            text("SELECT vniti_calc_billet_diameter(:a, :b, :s, :r)"),
            {"a": a, "b": b, "s": s, "r": r_calc},
        ).scalar()

        r_prod = db.execute(
            text("SELECT vniti_round_production_radius(:r, :s)"),
            {"r": r_calc, "s": s},
        ).scalar()

        k_range = db.execute(
            text("SELECT * FROM vniti_get_k_range(:s)"),
            {"s": s},
        ).mappings().first()

        k_real = db.execute(
            text("SELECT vniti_calc_k(:d, :a, :b)"),
            {"d": d_billet, "a": a, "b": b},
        ).scalar()

        k_min = float(k_range["k_min"])
        k_max = float(k_range["k_max"])
        k_real_f = float(k_real)

        return {
            "status": "ok",
            "data": {
                "a": a, "b": b, "s": s, "k10": k10,
                "r_calc": float(r_calc),
                "r_prod": float(r_prod),
                "d_billet": float(d_billet),
                "k_real": k_real_f,
                "k_min": k_min,
                "k_max": k_max,
                "r_min_coef": float(k_range["r_min_coef"]),
                "r_max_coef": float(k_range["r_max_coef"]),
                "fits_tu": k_min <= k_real_f <= k_max,
            },
        }
    except Exception as e:
        logger.error(f"Ошибка vniti_direct: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ═══════════════════════════════════════════════════════════════════
# 3. Прочностные характеристики сечения
#    vniti_calc_section_properties(p_h, p_b, p_t)
#    → TABLE(area_cm2, weight_m, ix_cm4, iy_cm4, wx_cm3, wy_cm3,
#            wpl_x_cm3, wpl_y_cm3, ix_rad_cm, iy_rad_cm, ik_cm4, wk_cm3)
# ═══════════════════════════════════════════════════════════════════
@router.get("/api/analytics/vniti/section-properties")
def vniti_section_properties(
    token: str = Query(None),
    h: float = Query(..., description="Высота, мм"),
    b: float = Query(..., description="Ширина, мм"),
    t: float = Query(..., description="Толщина стенки, мм"),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        row = db.execute(
            text("SELECT * FROM vniti_calc_section_properties(:h, :b, :t)"),
            {"h": h, "b": b, "t": t},
        ).mappings().first()

        if not row:
            return {"status": "ok", "data": None}

        data = {k: (float(v) if v is not None else None) for k, v in row.items()}
        return {"status": "ok", "data": data}
    except Exception as e:
        logger.error(f"Ошибка vniti_section_properties: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ═══════════════════════════════════════════════════════════════════
# 4. Поиск в каталоге ТУ
#    shape = 'square' → squares_catalog (h = :h)
#    shape = 'rect'   → rectangles_catalog (h = :h AND b = :b)
# ═══════════════════════════════════════════════════════════════════
@router.get("/api/analytics/vniti/tu-lookup")
def vniti_tu_lookup(
    token: str = Query(None),
    shape: str = Query(..., description="square | rect"),
    h: int = Query(..., description="Высота, мм"),
    b: int = Query(None, description="Ширина (только для rect)"),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        if shape == "square":
            rows = db.execute(
                text("SELECT * FROM squares_catalog WHERE h = :h ORDER BY t"),
                {"h": h},
            ).mappings().all()
        elif shape == "rect":
            if b is None:
                raise HTTPException(status_code=400, detail="Для rect обязателен параметр b")
            rows = db.execute(
                text("SELECT * FROM rectangles_catalog WHERE h = :h AND b = :b ORDER BY t"),
                {"h": h, "b": b},
            ).mappings().all()
        else:
            raise HTTPException(status_code=400, detail="shape должен быть square или rect")

        items = []
        for r in rows:
            item = {}
            for k, v in r.items():
                if k == "created_at" and v is not None:
                    item[k] = v.isoformat()
                elif hasattr(v, "__float__"):
                    item[k] = float(v)
                else:
                    item[k] = v
            items.append(item)

        return {"status": "ok", "count": len(items), "data": items}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Ошибка vniti_tu_lookup: {e}")
        raise HTTPException(status_code=500, detail=str(e))


# ═══════════════════════════════════════════════════════════════════
# 5. Сводка по заготовке + расчёт + сортамент
#    Логика:
#      1. Тянем строку из get_client_size_matrix по size_key.
#      2. Если product_category = 'round' → считаем ВНИТИ.
#      3. Иначе → calculation = {supported: false, reason: ...}.
# ═══════════════════════════════════════════════════════════════════
@router.get("/api/analytics/billet-detail")
def billet_detail(
    token: str = Query(None),
    code: str = Query(..., description="Код клиента (1С)"),
    size_key: str = Query(..., description="Ключ типоразмера, напр. round_76x5"),
    year: int = Query(2026),
    k10: float = Query(22.0, description="Базовый радиус калибра (мм)"),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        # ─── 1. Наличие из матрицы ────────────────────────────────
        row = db.execute(
            text("""
                SELECT size_key, size_display, is_prof, product_category,
                       diameter, prof_w, prof_h, wall,
                       catalog_products_count,
                       stock_total, has_stock,
                       client_bought, client_revenue, client_quantity,
                       client_invoices_count
                FROM get_client_size_matrix(:code, :year)
                WHERE size_key = :size_key
            """),
            {"code": code, "year": year, "size_key": size_key},
        ).mappings().first()

        if not row:
            return {
                "status": "ok",
                "data": None,
                "message": f"Типоразмер {size_key} не найден для клиента {code} в {year} году",
            }

        category = row["product_category"]
        diameter = row["diameter"]
        wall = row["wall"]
        prof_w = row["prof_w"]
        prof_h = row["prof_h"]

        # ─── 2. Расчёт ВНИТИ (только для round) ───────────────────
        calculation = None
        if category == "round" and diameter and wall:
            s = float(wall)
            d = float(diameter)

            # ─── Целевой профиль: квадрат со стороной A = D / 1.25 ──────
            # Из заготовки ∅D получается профиль с коэффициентом обжатия ~1.25.
            a_target = round(d / 1.25)   # для D=50 → 40
            a = float(a_target)
            b = float(a_target)

            # ─── Физичный радиус калибра k10 ≈ 2 × S ────────────────────
            k10_physical = 2.0 * s       # для S=4 → 8.0

            r_calc = db.execute(
                text("SELECT vniti_calc_contact_radius(:a, :b, :s, :k10)"),
                {"a": a, "b": b, "s": s, "k10": k10_physical},
            ).scalar()

            r_prod = db.execute(
                text("SELECT vniti_round_production_radius(:r, :s)"),
                {"r": r_calc, "s": s},
            ).scalar()

            d_billet = db.execute(
                text("SELECT vniti_calc_billet_diameter(:a, :b, :s, :r)"),
                {"a": a, "b": b, "s": s, "r": r_calc},
            ).scalar()

            k_range = db.execute(
                text("SELECT * FROM vniti_get_k_range(:s)"),
                {"s": s},
            ).mappings().first()

            k_real = db.execute(
                text("SELECT vniti_calc_k(:d, :a, :b)"),
                {"d": d, "a": a, "b": b},
            ).scalar()

            k_min = float(k_range["k_min"])
            k_max = float(k_range["k_max"])
            k_real_f = float(k_real)

            calculation = {
                "supported": True,
                "target_profile": f"{int(a_target)}×{int(a_target)}×{int(s)}",
                "target_a": a,
                "target_b": b,
                "a": a,
                "b": b,
                "s": s,
                "d_input": d,
                "k10": k10_physical,
                "r_calc": float(r_calc),
                "r_prod": float(r_prod),
                "d_billet": float(d_billet),
                "k_real": k_real_f,
                "k_min": k_min,
                "k_max": k_max,
                "r_min_coef": float(k_range["r_min_coef"]),
                "r_max_coef": float(k_range["r_max_coef"]),
                "fits_tu": k_min <= k_real_f <= k_max,
            }
        else:
            reason = (
                f"Расчёт ВНИТИ применим только к круглым трубам. "
                f"Категория: {category}."
            )
            if category == "round" and (not diameter or not wall):
                reason = "Недостаточно данных: отсутствует diameter или wall."
            calculation = {
                "supported": False,
                "reason": reason,
                "category": category,
            }

        # ─── 3. Собираем ответ ─────────────────────────────────────
        return {
            "status": "ok",
            "data": {
                "size_key": row["size_key"],
                "size_display": row["size_display"],
                "product_category": category,
                "is_prof": bool(row["is_prof"]),
                "diameter": float(diameter) if diameter is not None else None,
                "prof_w": float(prof_w) if prof_w is not None else None,
                "prof_h": float(prof_h) if prof_h is not None else None,
                "wall": float(wall) if wall is not None else None,
                "catalog_products_count": int(row["catalog_products_count"] or 0),
                "stock": {
                    "stock_total": float(row["stock_total"] or 0),
                    "has_stock": bool(row["has_stock"]),
                },
                "client": {
                    "bought": bool(row["client_bought"]),
                    "revenue": float(row["client_revenue"] or 0),
                    "quantity": float(row["client_quantity"] or 0),
                    "invoices_count": int(row["client_invoices_count"] or 0),
                },
                "calculation": calculation,
            },
        }
    except Exception as e:
        logger.error(f"Ошибка billet_detail: {e}")
        raise HTTPException(status_code=500, detail=str(e))
