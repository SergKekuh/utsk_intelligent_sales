from fastapi import APIRouter, HTTPException, Query, Depends
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()

CAT_NAMES = {
    "A1": "A1 (≥3 млн)",
    "A2": "A2 (2–3 млн)",
    "A3": "A3 (1.5–2 млн)",
    "B1": "B1 (1–1.5 млн)",
    "B2": "B2 (0.5–1 млн)",
    "C1": "C1 (150–500 тис)",
    "C2": "C2 (0–150 тис)",
}

CAT_ORDER = ["A1", "A2", "A3", "B1", "B2", "C1", "C2"]

DIRECTION_UA_NAMES = {
    "Сельское хозяйство": "Сільське господарство",
    "Строительство": "Будівництво",
    "Промышленность / Нефтегаз": "Промисловість / Нафтогаз",
    "ЖКХ и Водоканалы": "ЖКГ та Водоканали",
    "Дорожное строительство": "Дорожнє будівництво",
    "Трейдер": "Трейдер",
    "Конечный потребитель": "Кінцевий споживач",
    "Трейдер с производством": "Трейдер з виробництвом",
    "Универсальный/Смешанное": "Універсальний / Змішане",
    "Металлоконструкции": "Металоконструкції",
    "Машиностроение": "Машинобудування",
    "Энергетика": "Енергетика",
    "Автомобильная отрасль / Спецтехника": "Автомобільна галузь / Спецтехніка",
    "Логистика / Транспорт": "Логістика / Транспорт",
    "Госструктуры / Ритейл": "Держструктури / Рітейл",
    "Не определено": "Не визначено",
}


def _compute_year_abc(db: Session, year: int, max_month: int) -> dict:
    # 1. Получаем пороги и индекс цен для выбранного года из abc_thresholds
    thr_rows = db.execute(
        text("""
            SELECT category, min_amount, max_amount, price_index
            FROM abc_thresholds
            WHERE year = :year
            ORDER BY min_amount DESC NULLS LAST
        """),
        {"year": year},
    ).mappings().all()

    if not thr_rows:
        price_index = 1.0
    else:
        price_index = float(thr_rows[0]["price_index"] or 1.0)

    # 2. Группируем продажи по активным клиентам за нужный период и классифицируем по порогам abc_thresholds
    cat_rows = db.execute(
        text("""
            WITH thr AS (
                SELECT category, min_amount, max_amount, price_index
                FROM abc_thresholds
                WHERE year = :year
            ),
            client_sales AS (
                SELECT
                    d.client_code,
                    COALESCE(SUM(sl.amount), 0) AS rev
                FROM documents d
                JOIN sales_lines sl ON sl.document_id = d.id
                JOIN clients c ON c.code = d.client_code
                JOIN client_year_activity cya
                    ON cya.client_code = c.code
                   AND cya.sales_year = :year
                   AND cya.is_active = TRUE
                WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
                  AND EXTRACT(MONTH FROM d.invoice_date) <= :max_month
                  AND (:year != 2026 OR c.is_active_current = TRUE)
                GROUP BY d.client_code
                HAVING COALESCE(SUM(sl.amount), 0) >= 1000.00
            )
            SELECT
                t.category AS cat,
                COUNT(cs.client_code) AS cnt,
                COALESCE(ROUND(SUM(cs.rev), 2), 0) AS sum_rev
            FROM thr t
            LEFT JOIN client_sales cs
                ON (cs.rev / NULLIF(t.price_index, 0)) >= t.min_amount
               AND (t.max_amount IS NULL OR (cs.rev / NULLIF(t.price_index, 0)) < t.max_amount)
            GROUP BY t.category, t.min_amount
            ORDER BY t.min_amount DESC NULLS LAST
        """),
        {"year": year, "max_month": max_month},
    ).mappings().all()

    by_cat = {r["cat"]: {"sum": float(r["sum_rev"] or 0.0), "count": int(r["cnt"] or 0)} for r in cat_rows}

    total_sum = round(sum(v["sum"] for v in by_cat.values()), 2)
    total_clients = sum(v["count"] for v in by_cat.values())

    categories = []
    for code in CAT_ORDER:
        item = by_cat.get(code, {"sum": 0.0, "count": 0})
        categories.append({
            "cat": code,
            "name": CAT_NAMES.get(code, code),
            "sum": round(item["sum"], 2),
            "count": item["count"],
            "total_sum": total_sum,
            "total_clients": total_clients,
        })

    return {
        "year": year,
        "price_index": price_index,
        "total_sum": total_sum,
        "total_clients": total_clients,
        "categories": categories,
    }


@router.get("/api/abc-analysis")
def get_abc_analysis(
    year: int = Query(2026, ge=2011, le=2030),
    period: str = Query("9m"),
    price_mode: str = Query("fact"),
    years: str = Query(None),
    token: str = Query("utsk2026"),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        period_map = {"6m": 6, "9m": 9, "12m": 12}
        max_month = period_map.get(period, 9)

        target_years = [2026, 2025, 2024]
        if years:
            parsed = [int(y.strip()) for y in years.split(",") if y.strip().isdigit()]
            if parsed:
                for y in parsed:
                    if y not in target_years:
                        target_years.append(y)
        if year not in target_years:
            target_years.append(year)

        years_data = {}
        for y in target_years:
            years_data[str(y)] = _compute_year_abc(db, y, max_month)

        current_year_data = years_data[str(year)]

        # Получаем все пороги из таблицы abc_thresholds для вкладки "Довідник меж та дефляторів"
        all_thr_rows = db.execute(
            text("""
                SELECT year, category, min_amount, max_amount, price_index
                FROM abc_thresholds
                ORDER BY year DESC, min_amount DESC NULLS LAST
            """)
        ).mappings().all()

        thresholds_list = [
            {
                "year": int(r["year"]),
                "category": r["category"],
                "min": float(r["min_amount"]) if r["min_amount"] is not None else 0.0,
                "max": float(r["max_amount"]) if r["max_amount"] is not None else None,
                "index": float(r["price_index"] or 1.0),
            }
            for r in all_thr_rows
        ]

        # Агрегация по отраслям из справочника activity_directions
        ind_rows = db.execute(
            text("""
                WITH client_sales AS (
                    SELECT
                        d.client_code,
                        COALESCE(c.activity_direction_id, c.direction_id, 16) AS direction_id,
                        COALESCE(SUM(sl.amount), 0) AS client_rev
                    FROM documents d
                    JOIN sales_lines sl ON sl.document_id = d.id
                    JOIN clients c ON c.code = d.client_code
                    JOIN client_year_activity cya
                        ON cya.client_code = c.code
                       AND cya.sales_year = :year
                       AND cya.is_active = TRUE
                    WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
                      AND EXTRACT(MONTH FROM d.invoice_date) <= :period_months
                      AND (:year != 2026 OR c.is_active_current = TRUE)
                    GROUP BY d.client_code, c.activity_direction_id, c.direction_id
                    HAVING COALESCE(SUM(sl.amount), 0) >= 1000.00
                )
                SELECT
                    ad.id,
                    COALESCE(ad.icon, '🌐') AS icon,
                    COALESCE(ad.color, '#2563eb') AS color,
                    COALESCE(ad.name, 'Не определено') AS direction_name,
                    COUNT(DISTINCT cs.client_code) AS clients,
                    ROUND(SUM(cs.client_rev), 2) AS sum,
                    ROUND(SUM(cs.client_rev) / NULLIF(COUNT(DISTINCT cs.client_code), 0), 2) AS avg_check
                FROM client_sales cs
                LEFT JOIN activity_directions ad ON ad.id = cs.direction_id
                GROUP BY ad.id, ad.icon, ad.color, ad.name
                ORDER BY sum DESC
            """),
            {"year": year, "period_months": max_month},
        ).mappings().all()

        industries_list = []
        for r in ind_rows:
            raw_name = r["direction_name"]
            ua_name = DIRECTION_UA_NAMES.get(raw_name, raw_name)
            industries_list.append({
                "id": int(r["id"] or 16),
                "icon": r["icon"],
                "color": r["color"],
                "name": ua_name,
                "sum": float(r["sum"] or 0.0),
                "clients": int(r["clients"] or 0),
                "avg_check": float(r["avg_check"] or 0.0),
            })

        total_industries_sum = round(sum(item["sum"] for item in industries_list), 2)
        total_industries_clients = sum(item["clients"] for item in industries_list)

        return {
            "status": "ok",
            "year": year,
            "period": period,
            "price_mode": price_mode,
            "price_index": current_year_data["price_index"],
            "total_sum": current_year_data["total_sum"],
            "total_clients": current_year_data["total_clients"],
            "categories": current_year_data["categories"],
            "years_data": years_data,
            "thresholds": thresholds_list,
            "industries": industries_list,
            "total_industries_sum": total_industries_sum,
            "total_industries_clients": total_industries_clients,
        }
    except Exception as e:
        logger.error(f"Ошибка get_abc_analysis: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/api/abc-analysis/details")
def get_abc_year_details(
    year: int = Query(2026, ge=2011, le=2030),
    token: str = Query("utsk2026"),
    db: Session = Depends(get_db),
):
    """
    Drill-down по місяцях для року (Промт №94).

    Помісячні виручка / документи / клієнти рахуються на тій самій базі, що й ABC
    (клієнти з client_year_activity.is_active; для 2026 ще й is_active_current),
    але без порога 1000 грн (він діє лише на сумі за період).
    Категорії A1..C2 для місяця N — накопичувальна (YTD) класифікація за місяці 1..N,
    тобто _compute_year_abc(year, N); summary 6m/9m/12m = ті самі цифри, що в картках.
    Місяці без даних повертаються з нулями та has_data=false.
    """
    verify_token(token)
    try:
        rows = db.execute(
            text("""
                SELECT
                    EXTRACT(MONTH FROM d.invoice_date)::int AS month,
                    COUNT(DISTINCT d.id) AS docs,
                    COUNT(DISTINCT d.client_code) AS clients,
                    COALESCE(ROUND(SUM(sl.amount), 2), 0) AS revenue
                FROM documents d
                LEFT JOIN sales_lines sl ON sl.document_id = d.id
                JOIN clients c ON c.code = d.client_code
                JOIN client_year_activity cya
                    ON cya.client_code = c.code
                   AND cya.sales_year = :year
                   AND cya.is_active = TRUE
                WHERE EXTRACT(YEAR FROM d.invoice_date) = :year
                  AND (:year != 2026 OR c.is_active_current = TRUE)
                GROUP BY 1
            """),
            {"year": year},
        ).mappings().all()
        by_month = {int(r["month"]): r for r in rows}

        months = []
        cumulative = {}
        for m in range(1, 13):
            r = by_month.get(m)
            has_data = bool(r and int(r["docs"] or 0) > 0)
            categories = {}
            if has_data:
                cum = _compute_year_abc(db, year, m)
                cumulative[m] = cum
                categories = {c["cat"]: c["count"] for c in cum["categories"]}
            months.append({
                "month": m,
                "has_data": has_data,
                "revenue": float(r["revenue"] or 0) if r else 0,
                "docs": int(r["docs"] or 0) if r else 0,
                "clients": int(r["clients"] or 0) if r else 0,
                "categories": categories,
            })

        period_data = {n: (cumulative.get(n) or _compute_year_abc(db, year, n)) for n in (6, 9, 12)}

        summary = {}
        for n, cum in period_data.items():
            summary[f"{n}m"] = {
                "revenue": cum["total_sum"],
                "clients": cum["total_clients"],
                "docs": sum(x["docs"] for x in months if x["month"] <= n),
            }

        # Промт №97: категорії × періоди 6/9/12 (виручка та кількість клієнтів у категорії)
        categories = []
        for code in CAT_ORDER:
            item = {"name": code, "label": CAT_NAMES.get(code, code)}
            for n, cum in period_data.items():
                c = next((x for x in cum["categories"] if x["cat"] == code), None)
                item[f"rev_{n}m"] = c["sum"] if c else 0.0
                item[f"cnt_{n}m"] = c["count"] if c else 0
            categories.append(item)

        return {
            "status": "ok",
            "year": year,
            "months_with_data": [x["month"] for x in months if x["has_data"]],
            "months": months,
            "summary": summary,
            "categories": categories,
        }
    except Exception as e:
        logger.error(f"Ошибка get_abc_year_details: {e}")
        raise HTTPException(status_code=500, detail=str(e))


class ThresholdUpdatePayload(BaseModel):
    year: int
    price_index: float


@router.post("/api/abc-analysis/thresholds")
def update_abc_thresholds(
    payload: ThresholdUpdatePayload,
    token: str = Query("utsk2026"),
    db: Session = Depends(get_db),
):
    verify_token(token)
    try:
        db.execute(
            text("""
                UPDATE abc_thresholds
                SET price_index = :price_index
                WHERE year = :year
            """),
            {"year": payload.year, "price_index": payload.price_index},
        )
        db.commit()
        return {"status": "ok", "year": payload.year, "price_index": payload.price_index}
    except Exception as e:
        db.rollback()
        logger.error(f"Ошибка update_abc_thresholds: {e}")
        raise HTTPException(status_code=500, detail=str(e))
