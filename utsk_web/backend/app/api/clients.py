from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()

# ====== API: КЛИЕНТЫ ======
@router.get("/api/clients")
def clients(token: str = Query(None), limit: int = 50, search: str = "", db: Session = Depends(get_db)):
    verify_token(token)
    result = db.execute(text("SELECT * FROM get_clients_list(:limit, :search)"), {"limit": limit, "search": search})
    data = [dict(row._mapping) for row in result]
    return {"status": "ok", "data": data, "count": len(data)}

# ====== API: АКТИВНЫЕ КЛИЕНТЫ ======
@router.get("/api/clients/active")
def active_clients(token: str = Query(None), limit: int = 20, db: Session = Depends(get_db)):
    verify_token(token)
    result = db.execute(text("SELECT * FROM get_active_clients(:limit)"), {"limit": limit})
    data = [dict(row._mapping) for row in result]
    return {"status": "ok", "data": data, "count": len(data)}

# ====== API: ТОП ПРОДАЖ (80% RULE) ======
@router.get("/api/clients/top-sales")
def get_top_clients_sales(
    token: str = Query(None),
    year: int = 2026,
    date_from: str = Query(None),
    date_to: str = Query(None),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_top_clients_80pct(:year, :date_from, :date_to)"),
            {
                "year": year,
                "date_from": date_from if date_from else None,
                "date_to": date_to if date_to else None
            }
        ).fetchall()

        if not rows:
            return {
                "status": "ok",
                "clients": [],
                "total_revenue": 0,
                "period_label": "Нет данных"
            }

        first_row = dict(rows[0]._mapping)
        total_revenue = float(first_row.get("total_revenue")) if first_row.get("total_revenue") else 0.0
        period_label = first_row.get("period_label", "")

        result = []
        for r_raw in rows:
            r = dict(r_raw._mapping)
            last_date_str = r["last_purchase_date"].strftime("%d.%m.%Y") if r.get("last_purchase_date") else "—"
            result.append({
                "code": r["code"],
                "name": r["name"] or "—",
                "status_2025": r["status_2025"] or "—",
                "status_2026": r["status_2026"] or "—",
                "goods_revenue": float(r["goods_revenue"]),
                "invoice_count": r["invoice_count"],
                "last_purchase_date": last_date_str,
                "pct_of_total": float(r["pct_of_total"]),
                "running_pct": float(r["running_pct"]),
                "is_included": bool(r.get("is_included", True))
            })

        return {
            "status": "ok",
            "clients": result,
            "total_revenue": total_revenue,
            "period_label": period_label,
            "date_from": date_from or f"{year}-01-01",
            "date_to": date_to or "сегодня"
        }
    except Exception as e:
        logger.error(f"Ошибка в get_top_clients_sales: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ====== API: РИСК ОТТОКА ======
@router.get("/api/clients/churn-risk")
def churn_risk(token: str = Query(None), limit: int = 20, db: Session = Depends(get_db)):
    verify_token(token)
    result = db.execute(text("SELECT * FROM get_churn_risk_clients(:limit)"), {"limit": limit})
    data = [dict(row._mapping) for row in result]
    return {"status": "ok", "data": data, "count": len(data)}

# ====== API: ДЕТАЛИЗАЦИЯ КЛИЕНТА ======
@router.get("/api/clients/detail/{code}")
def get_client_detail(code: str, token: str = Query(None), year: int = 2026, db: Session = Depends(get_db)):
    verify_token(token)
    try:
        q_main = text("SELECT * FROM get_client_detail(:code, :year)")
        client_res = db.execute(q_main, {"year": year, "code": code}).fetchone()
        if not client_res:
            raise HTTPException(status_code=404, detail=f"Клиент '{code}' не найден")
        
        client_data = dict(client_res._mapping)

        res_2025 = db.execute(
            text("SELECT get_client_status_2025(:code, :year_prev)"),
            {"code": code, "year_prev": year - 1}
        ).scalar()
        status_2025 = res_2025 or "—"

        monthly_rows = db.execute(
            text("SELECT * FROM get_client_monthly_dynamics(:code, :year, :year_prev)"),
            {"code": code, "year": year, "year_prev": year - 1}
        ).fetchall()
        monthly_data = [dict(m._mapping) for m in monthly_rows]
        for m in monthly_data:
            m["revenue_current"] = float(m["revenue_current"]) if m.get("revenue_current") else 0.0
            m["revenue_previous"] = float(m["revenue_previous"]) if m.get("revenue_previous") else 0.0

        q_invoices = text("SELECT * FROM get_client_invoices(:code, :year, NULL, NULL, NULL, 500)")
        invoice_rows = db.execute(q_invoices, {"code": code, "year": year}).fetchall()
        last_invoices = [dict(i._mapping) for i in invoice_rows]
        for inv in last_invoices:
            inv["total"] = float(inv["total"]) if inv.get("total") else 0.0

        last_date_str = client_data["last_purchase_date"].strftime("%d.%m.%Y") if client_data.get("last_purchase_date") else "—"

        return {
            "status": "ok",
            "client": {
                "code": client_data["code"],
                "name": client_data["name"] or "—",
                "status": client_data["status"] or "—",
                "status_2025": status_2025,
                "total_revenue": float(client_data["total_revenue"]),
                "total_invoices": client_data["total_invoices"],
                "total_positions": int(client_data.get("total_positions", 0) or 0),
                "avg_check": float(client_data["avg_check"]),
                "last_purchase_date": last_date_str,
                "monthly_data": monthly_data,
                "last_invoices": last_invoices
            }
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Ошибка get_client_detail {code}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ====== API: НАКЛАДНЫЕ КЛИЕНТА С ФИЛЬТРАМИ ======
@router.get("/api/clients/invoices/{code}")
def get_client_invoices(
    code: str,
    token: str = Query(None),
    year: int = 2026,
    month: str = "all",
    date_from: str = Query(None),
    date_to: str = Query(None),
    limit: int = 500,
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        month_int = int(month) if (month and month.isdigit() and month != "all") else None
        
        q = text("SELECT * FROM get_client_invoices(:code, :year, :month_int, :date_from, :date_to, :limit)")

        rows = db.execute(q, {
            "code": code,
            "year": year,
            "month_int": month_int,
            "date_from": date_from if date_from else None,
            "date_to": date_to if date_to else None,
            "limit": limit
        }).fetchall()

        invoices = [dict(r._mapping) for r in rows]
        total_sum = 0.0
        total_positions = 0
        for inv in invoices:
            inv_tot = float(inv["total"]) if inv.get("total") else 0.0
            inv["total"] = inv_tot
            total_sum += inv_tot
            total_positions += inv.get("positions", 0)

        return {
            "status": "ok",
            "invoices": invoices,
            "total_count": len(invoices),
            "total_sum": total_sum,
            "total_positions": total_positions,
            "invoice_filters": {
                "year": year,
                "month": month,
                "date_from": date_from,
                "date_to": date_to
            }
        }
    except Exception as e:
        logger.error(f"Ошибка get_client_invoices {code}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ====== API: ДЕТАЛИЗАЦИЯ НАКЛАДНОЙ (ITEMS) ======
@router.get("/api/invoices/{number}/items")
def get_invoice_items(number: str, token: str = Query(None), db: Session = Depends(get_db)):
    verify_token(token)
    try:
        invoice_row = db.execute(
            text("SELECT * FROM get_invoice_header(:number)"),
            {"number": number}
        ).fetchone()
        if not invoice_row:
            raise HTTPException(status_code=404, detail=f"Накладная '{number}' не найдена")
        
        inv_data = dict(invoice_row._mapping)

        q_items = text("SELECT * FROM get_invoice_items(:number)")
        item_rows = db.execute(q_items, {"number": number}).fetchall()
        items = []
        for r in item_rows:
            m = dict(r._mapping)
            items.append({
                "code": m["code"],
                "name": m["name"],
                "quantity": float(m["quantity"]) if m.get("quantity") else 0.0,
                "weight_kg": float(m["weight_kg"]) if m.get("weight_kg") else 0.0,
                "price": float(m["price"]) if m.get("price") else 0.0,
                "total": float(m["total"]) if m.get("total") else 0.0
            })

        return {
            "status": "ok",
            "date": inv_data["date"],
            "number": inv_data["number"],
            "total": float(inv_data["total"]),
            "items": items
        }
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Ошибка invoice-items {number}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ====== API: СТАТУСЫ ======
@router.get("/api/statuses")
def statuses(token: str = Query(None), db: Session = Depends(get_db)):
    verify_token(token)
    result = db.execute(text("SELECT * FROM get_statuses_distribution()"))
    data = [dict(row._mapping) for row in result]
    return {"status": "ok", "data": data, "count": len(data)}

# ====== API: ВОРОНКА ПРОДАЖ ======
@router.get("/api/funnel")
def funnel(token: str = Query(None), year: int = 2026, db: Session = Depends(get_db)):
    verify_token(token)
    try:
        result_active = db.execute(text("SELECT * FROM get_funnel_data(:year)"), {"year": year})
        
        active_funnel = []
        for row in result_active:
            r = dict(row._mapping)
            if r.get("revenue") is not None:
                r["revenue"] = round(float(r["revenue"]), 2)
            active_funnel.append(r)

        desc_sleeping = f"Нет покупок в {year}, были в {year-1}"
        desc_left = f"Нет покупок в {year} и {year-1}"
        result_lifecycle = db.execute(text("""
            SELECT 
                sr.id AS status_id,
                sr.status_name,
                COUNT(DISTINCT c.code) AS count,
                CASE sr.id
                    WHEN 8 THEN :desc_sleeping
                    WHEN 9 THEN :desc_left
                    ELSE 'Неактивные клиенты'
                END AS description
            FROM clients c
            JOIN status_rules sr ON c.current_status_id = sr.id
            WHERE c.current_status_id IN (8, 9)
              AND c.code NOT IN ('9653', '11230')
            GROUP BY sr.id, sr.status_name
            ORDER BY CASE sr.id WHEN 8 THEN 1 WHEN 9 THEN 2 ELSE 3 END
        """), {"desc_sleeping": desc_sleeping, "desc_left": desc_left})

        lifecycle = []
        for row in result_lifecycle:
            r = dict(row._mapping)
            lifecycle.append({
                "status_id": r["status_id"],
                "status_name": r["status_name"],
                "count": r["count"],
                "description": r["description"]
            })

        result_new = db.execute(text("SELECT * FROM get_new_clients_frequency(:year)"), {"year": year})

        new_clients_funnel = []
        for row in result_new:
            r = dict(row._mapping)
            new_clients_funnel.append({
                "stage": r["frequency_group"],
                "sort_order": r["sort_order"],
                "count": r["new_count"],
                "revenue": round(float(r["new_revenue"]), 2)
            })

        return {
            "status": "ok",
            "year": year,
            "funnel": active_funnel,
            "lifecycle": lifecycle,
            "new_clients_funnel": new_clients_funnel
        }
    except Exception as e:
        logger.error(f"Ошибка funnel: {e}")
        raise HTTPException(status_code=500, detail=str(e))
