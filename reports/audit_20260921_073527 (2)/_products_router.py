from fastapi import APIRouter, HTTPException, Query, Depends
from sqlalchemy import text
from sqlalchemy.orm import Session
from ..deps import get_db, verify_token
from ..config import logger

router = APIRouter()

# ====== API: ТОВАРЫ ======
@router.get("/api/products")
def products(token: str = Query(None), limit: int = 50, search: str = "", db: Session = Depends(get_db)):
    verify_token(token)
    result = db.execute(text("SELECT * FROM get_products_list(:limit, :search)"), {"limit": limit, "search": search})
    data = [dict(row._mapping) for row in result]
    return {"status": "ok", "data": data, "count": len(data)}

# ====== API: РЕКОМЕНДАЦИИ ДЛЯ КЛИЕНТА (4 БЛОКА + FALLBACK) ======
@router.get("/api/recommendations/{client_code}")
def recommendations_for_client(client_code: str, token: str = Query(None), db: Session = Depends(get_db)):
    verify_token(token)
    try:
        client = db.execute(
            text("SELECT code, name, activity_direction_id FROM clients WHERE code = :code"),
            {"code": client_code}
        ).first()
        
        if not client:
            raise HTTPException(status_code=404, detail=f"Клиент '{client_code}' не найден")

        recommendations = []
        
        result = db.execute(text("SELECT * FROM get_recommendations_for_client(:client_code)"), {"client_code": client_code})

        for row in result:
            r = dict(row._mapping)
            r['purchases_current_year'] = int(r.get('purchases_current_year') or 0)
            r['purchases_prev_year'] = int(r.get('purchases_prev_year') or 0)
            r['pct_current_year'] = float(r.get('pct_current_year') or 0.0)
            r['pct_prev_year'] = float(r.get('pct_prev_year') or 0.0)
            r['revenue_current_year'] = float(r.get('revenue_current_year') or 0.0)
            r['revenue_prev_year'] = float(r.get('revenue_prev_year') or 0.0)
            r['in_stock'] = float(r.get('in_stock') or 0.0)
            r['days_since_last'] = int(r.get('days_since_last') or 0)
            r['purchase_count'] = int(r.get('purchase_count_total') or 0)
            r['purchase_count_total'] = int(r.get('purchase_count_total') or 0)
            r['priority'] = 1
            r['reason'] = 'Часто покупаете'
            recommendations.append(r)
        
        if client.activity_direction_id:
            result = db.execute(
                text("SELECT * FROM get_recommendations_block2(:direction_id, :client_code)"),
                {"direction_id": client.activity_direction_id, "client_code": client_code}
            )
            for row in result:
                recommendations.append(dict(row._mapping))
        
        result = db.execute(
            text("SELECT * FROM get_recommendations_block3(:client_code)"),
            {"client_code": client_code}
        )
        for row in result:
            recommendations.append(dict(row._mapping))
        
        result = db.execute(
            text("SELECT * FROM get_recommendations_block4(:client_code)"),
            {"client_code": client_code}
        )
        for row in result:
            recommendations.append(dict(row._mapping))
        
        recommendations.sort(key=lambda r: (
            r.get('priority', 99),
            -float(r.get('pct_current_year', 0) or 0),
            -int(r.get('purchases_current_year', 0) or r.get('purchase_count_total', 0) or 0)
        ))
        
        recommendations = recommendations[:5]
        
        if not recommendations:
            result = db.execute(text("SELECT * FROM get_recommendations_fallback()"))
            for row in result:
                recommendations.append(dict(row._mapping))
        
        return {
            "status": "ok",
            "client_code": client.code,
            "client_name": client.name,
            "recommendations": recommendations,
            "count": len(recommendations)
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Ошибка рекомендаций для {client_code}: {e}")
        raise HTTPException(status_code=500, detail=str(e))

# ====== API: РЕКОМЕНДАЦИИ ПО РАЗМЕРУ ДЛЯ КЛИЕНТА ======
@router.get("/api/recommendations-by-size/{client_code}")
@router.get("/recommendations-by-size/{client_code}")
def get_recommendations_by_size_endpoint(
    client_code: str,
    token: str = Query(...),
    limit: int = Query(5, ge=1, le=20),
    db: Session = Depends(get_db),
):
    """
    ТОП покупок клиента, агрегированный по размеру трубы.
    Возвращает: {size_key, display_name, count, pct, stock}.
    """
    verify_token(token)

    try:
        rows = db.execute(
            text("""
                SELECT 
                    size_key,
                    size_display,
                    pipe_type_ua,
                    display_name,
                    purchase_count_current,
                    revenue_current,
                    pct_of_client_total,
                    purchase_count_prev,
                    revenue_prev,
                    stock_balance_total
                FROM get_recommendations_by_size(:code, :lim)
            """),
            {"code": client_code, "lim": limit},
        ).mappings().all()

        items = []
        for r in rows:
            items.append({
                "size_key": r["size_key"],
                "size_display": r["size_display"],
                "pipe_type_ua": r["pipe_type_ua"],
                "display_name": r["display_name"],
                "count": int(r["purchase_count_current"] or 0),
                "pct": float(r["pct_of_client_total"] or 0),
                "revenue": float(r["revenue_current"] or 0),
                "count_prev": int(r["purchase_count_prev"] or 0),
                "revenue_prev": float(r["revenue_prev"] or 0),
                "stock": float(r["stock_balance_total"] or 0),
                "reason": "Часто покупаете",
            })

        return {
            "status": "ok",
            "client_code": client_code,
            "year": 2026,
            "count": len(items),
            "items": items,
        }
    except Exception as e:
        logger.error(f"Ошибка get_recommendations_by_size_endpoint: {e}")
        raise HTTPException(status_code=500, detail=f"SQL error: {str(e)}")

# ====== API: ВСЕ РАЗМЕРЫ ТРУБ КЛИЕНТА (С АГРЕГАЦИЕЙ) ======
@router.get("/api/client-products-by-size/{client_code}")
@router.get("/client-products-by-size/{client_code}")
def get_client_products_by_size(
    client_code: str,
    token: str = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    """
    Все размеры труб клиента за год (агрегировано).
    Используется на /product-analytics.
    """
    verify_token(token)
    
    try:
        rows = db.execute(
            text("""
                SELECT 
                    size_key,
                    size_display,
                    pipe_type,
                    pipe_type_ua,
                    display_name,
                    purchase_count,
                    revenue,
                    pct_of_client_total,
                    stock_balance_total,
                    products_count,
                    has_stock
                FROM get_all_sizes_for_client(:code, :yr)
            """),
            {"code": client_code, "yr": year},
        ).mappings().all()
        
        items = []
        for r in rows:
            items.append({
                "size_key": r["size_key"],
                "size_display": r["size_display"],
                "pipe_type": r["pipe_type"],
                "pipe_type_ua": r["pipe_type_ua"],
                "display_name": r["display_name"],
                "purchase_count": int(r["purchase_count"] or 0),
                "revenue": float(r["revenue"] or 0),
                "pct": float(r["pct_of_client_total"] or 0),
                "stock_total": float(r["stock_balance_total"] or 0),
                "products_count": int(r["products_count"] or 0),
                "has_stock": bool(r["has_stock"]),
            })
        
        client_row = db.execute(
            text("SELECT name FROM clients WHERE code = :code"),
            {"code": client_code}
        ).first()
        client_name = client_row[0] if client_row and client_row[0] else client_code

        return {
            "status": "ok",
            "client_code": client_code,
            "client_name": client_name,
            "year": year,
            "count": len(items),
            "items": items,
        }
    except Exception as e:
        logger.error(f"Ошибка get_client_products_by_size: {e}")
        raise HTTPException(status_code=500, detail=f"SQL error: {str(e)}")


@router.get("/api/client-products-by-size/{client_code}/{size_key}")
@router.get("/client-products-by-size/{client_code}/{size_key}")
def get_client_products_by_size_drilldown(
    client_code: str,
    size_key: str,
    token: str = Query(...),
    year: int = Query(2026),
    db: Session = Depends(get_db),
):
    """
    Drill-down: все товары (ГОСТ × сталь) с заданным размером.
    """
    verify_token(token)
    
    try:
        rows = db.execute(
            text("""
                SELECT 
                    product_code,
                    product_name,
                    standard,
                    is_purchased,
                    purchase_count,
                    quantity,
                    revenue,
                    last_purchase_date,
                    days_since_last,
                    stock_balance,
                    is_prof,
                    size_display
                FROM get_products_by_size_for_client(:code, :size_key, :yr)
            """),
            {"code": client_code, "size_key": size_key, "yr": year},
        ).mappings().all()
        
        items = []
        for r in rows:
            items.append({
                "product_code": r["product_code"],
                "product_name": r["product_name"],
                "standard": r["standard"],
                "is_purchased": bool(r["is_purchased"]),
                "purchase_count": int(r["purchase_count"] or 0),
                "quantity": float(r["quantity"] or 0),
                "revenue": float(r["revenue"] or 0),
                "last_purchase_date": r["last_purchase_date"].isoformat() if r["last_purchase_date"] else None,
                "days_since_last": r["days_since_last"],
                "stock_balance": float(r["stock_balance"] or 0),
                "is_prof": bool(r["is_prof"]),
                "size_display": r["size_display"],
            })
        
        return {
            "status": "ok",
            "client_code": client_code,
            "size_key": size_key,
            "year": year,
            "count": len(items),
            "items": items,
        }
    except Exception as e:
        logger.error(f"Ошибка get_client_products_by_size_drilldown: {e}")
        raise HTTPException(status_code=500, detail=f"SQL error: {str(e)}")


# ====== API: ТОП РЕКОМЕНДАЦИЙ (общие) ======
@router.get("/api/recommendations")
def top_recommendations(token: str = Query(None), limit: int = 10, db: Session = Depends(get_db)):
    verify_token(token)
    result = db.execute(
        text("SELECT * FROM get_top_recommendations(:limit)"),
        {"limit": limit}
    )
    data = [dict(row._mapping) for row in result]
    return {"status": "ok", "data": data, "count": len(data)}

@router.get("/api/analytics/client-products/{client_code}")
def client_products_analytics(
    client_code: str,
    token: str = Query(None),
    year: int = 2026,
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        client = db.execute(
            text("SELECT name FROM clients WHERE code = :code"),
            {"code": client_code}
        ).fetchone()
        client_name = client[0] if client else client_code

        services_rev = db.execute(text("""
            SELECT COALESCE(SUM(sl.amount), 0)
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            JOIN products p ON sl.product_code = p.code
            WHERE d.client_code = :code
              AND EXTRACT(YEAR FROM d.invoice_date) = :year
              AND p.is_service = TRUE
        """), {"code": client_code, "year": year}).scalar() or 0.0

        rows = db.execute(
            text("SELECT * FROM get_client_products(:code, :year)"),
            {"code": client_code, "year": year}
        ).fetchall()

        stock_rows = db.execute(text("SELECT code, COALESCE(in_stock_balance, 0) as in_stock FROM products")).fetchall()
        stock_map = {r.code: float(r.in_stock or 0) for r in stock_rows}

        goods_rev = sum(float(r._mapping['total_sales'] or 0) for r in rows)
        total_rev = goods_rev + float(services_rev)

        products = []
        cum_rev = 0.0
        for r in rows:
            rm = dict(r._mapping)
            sales = float(rm.get('total_sales') or 0)
            cum_rev += sales
            
            if goods_rev > 0:
                pct = round(sales / goods_rev * 100, 1)
                prev_cum = cum_rev - sales
                if cum_rev <= goods_rev * 0.80 or prev_cum < goods_rev * 0.80:
                    abc_grp = 'A'
                elif cum_rev <= goods_rev * 0.95 or prev_cum < goods_rev * 0.95:
                    abc_grp = 'B'
                else:
                    abc_grp = 'C'
            else:
                pct = 0.0
                abc_grp = 'C'

            rm['pct_of_total'] = pct
            rm['abc_group'] = abc_grp
            rm['in_stock'] = stock_map.get(rm['product_code'], 0.0)
            rm['total_sales'] = round(sales, 2)
            rm['total_quantity'] = round(float(rm.get('total_quantity') or 0), 2)
            rm['invoice_count'] = int(rm.get('invoice_count') or 0)
            products.append(rm)

        return {
            "status": "ok",
            "client_code": client_code,
            "client_name": client_name,
            "year": year,
            "total_revenue": round(total_rev, 2),
            "goods_revenue": round(goods_rev, 2),
            "services_revenue": round(float(services_rev), 2),
            "unique_products": len(products),
            "products": products,
            "count": len(products)
        }
    except Exception as e:
        logger.error(f"Ошибка client_products_analytics: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/client-products-compare/{client_code}")
def client_products_compare(
    client_code: str,
    token: str = Query(None),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        rows = db.execute(
            text("SELECT * FROM get_client_products_compare(:code)"),
            {"code": client_code}
        ).fetchall()

        products = []
        for r in rows:
            rm = dict(r._mapping)
            rev_2026 = float(rm.get('revenue_curr') or 0.0)
            rev_2025 = float(rm.get('revenue_prev') or 0.0)
            diff = rev_2026 - rev_2025
            if rev_2025 > 0:
                growth_pct = round(diff / rev_2025 * 100, 1)
            elif rev_2026 > 0:
                growth_pct = 100.0
            else:
                growth_pct = 0.0

            products.append({
                "product_code": rm.get('product_code'),
                "product_name": rm.get('product_name'),
                "sales_2025": round(rev_2025, 2),
                "sales_2026": round(rev_2026, 2),
                "qty_2025": round(float(rm.get('qty_prev') or 0.0), 2),
                "qty_2026": round(float(rm.get('qty_curr') or 0.0), 2),
                "diff": round(diff, 2),
                "growth_pct": growth_pct
            })

        return {
            "status": "ok",
            "client_code": client_code,
            "products": products,
            "count": len(products)
        }
    except Exception as e:
        logger.error(f"Ошибка client_products_compare: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/api/analytics/client-products-recommendations/{client_code}")
def client_products_recommendations(
    client_code: str,
    token: str = Query(None),
    db: Session = Depends(get_db)
):
    verify_token(token)
    try:
        cross_rows = db.execute(
            text("SELECT * FROM get_client_cross_sell_pipes(:code)"),
            {"code": client_code}
        ).fetchall()

        similar_rows = db.execute(
            text("SELECT * FROM get_client_similar_sizes(:code)"),
            {"code": client_code}
        ).fetchall()

        if len(similar_rows) < 10:
            existing = {s.product_code for s in similar_rows}
            fallback_rows = db.execute(
                text("SELECT * FROM get_client_similar_fallback(:code)"),
                {"code": client_code}
            ).fetchall()
            for r in fallback_rows:
                if r.product_code not in existing:
                    similar_rows.append(r)

        dir_rows = db.execute(
            text("SELECT * FROM get_client_direction_variety(:code)"),
            {"code": client_code}
        ).fetchall()

        # Parse pipe attributes for all candidate product codes
        all_codes = list({r.product_code for r in (cross_rows + similar_rows + dir_rows)})
        parsed_map = {}
        if all_codes:
            p_rows = db.execute(text("""
                SELECT 
                    p.code,
                    p.name,
                    CASE 
                        WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                            THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                        WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                            THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                        WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                            THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                        ELSE NULL
                    END AS size_key,
                    CASE 
                        WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                            THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT || '×' || ppa.wall::TEXT
                        WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                            THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT
                        WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                            THEN ppa.diameter::TEXT || '×' || ppa.wall::TEXT
                        ELSE NULL
                    END AS size_display,
                    CASE 
                        WHEN ppa.is_prof AND ppa.prof_w = ppa.prof_h THEN 'Квадратная труба'
                        WHEN ppa.is_prof AND ppa.prof_w <> ppa.prof_h THEN 'Прямоугольная труба'
                        WHEN NOT ppa.is_prof THEN 'Круглая труба'
                        ELSE 'Труба'
                    END AS pipe_type_ua
                FROM products p
                CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
                WHERE p.code = ANY(:codes)
            """), {"codes": all_codes}).fetchall()

            for pr in p_rows:
                parsed_map[pr.code] = {
                    "size_key": pr.size_key,
                    "display_name": f"{pr.pipe_type_ua} {pr.size_display}" if pr.size_key else pr.name
                }

        def aggregate_block(rows, block_type):
            seen_sizes = set()
            items = []
            for r in rows:
                p_info = parsed_map.get(r.product_code, {})
                s_key = p_info.get("size_key") or f"sku_{r.product_code}"
                if s_key in seen_sizes:
                    continue
                seen_sizes.add(s_key)

                d_name = p_info.get("display_name") or r.product_name
                raw_reason = getattr(r, "reason", "") or ""
                if block_type == "cross":
                    reason = "Ранее покупали" if "ранее" in raw_reason.lower() else "Сопутствующий размер"
                elif block_type == "similar":
                    reason = "Ближайший типоразмер"
                else:
                    reason = "Топ продаж 2026"

                items.append({
                    "product_code": r.product_code,
                    "size_key": s_key,
                    "display_name": d_name,
                    "product_name": d_name,
                    "reason": reason,
                    "in_stock": float(getattr(r, "in_stock", 0) or 0)
                })
                if len(items) == 5:
                    break
            return items

        cross_sell = aggregate_block(cross_rows, "cross")
        similar_size = aggregate_block(similar_rows, "similar")
        direction_variety = aggregate_block(dir_rows, "direction")

        # Fetch warehouse total stock for all distinct size_keys
        all_size_keys = list({
            item["size_key"] for item in (cross_sell + similar_size + direction_variety)
            if item["size_key"] and not item["size_key"].startswith("sku_")
        })

        if all_size_keys:
            stock_rows = db.execute(text("""
                WITH parsed AS (
                    SELECT 
                        COALESCE(p.in_stock_balance, 0)::NUMERIC AS stock,
                        CASE 
                            WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                                THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                            WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                                THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                            WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                                THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                            ELSE NULL
                        END AS size_key
                    FROM products p
                    CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
                    WHERE COALESCE(p.is_service, FALSE) = FALSE AND COALESCE(p.in_stock_balance, 0) > 0
                )
                SELECT size_key, SUM(stock) AS total_stock
                FROM parsed
                WHERE size_key = ANY(:keys)
                GROUP BY size_key
            """), {"keys": all_size_keys}).fetchall()
            stock_map = {sr.size_key: float(sr.total_stock) for sr in stock_rows}

            for block in [cross_sell, similar_size, direction_variety]:
                for item in block:
                    if item["size_key"] in stock_map:
                        item["in_stock"] = round(stock_map[item["size_key"]], 3)

        services = [
            {"product_name": "Послуги порізки та різання металопрокату", "usage_count": "Рекомендовано", "code": "service_cut"},
            {"product_name": "Послуги доставки по Україні", "usage_count": "Рекомендовано", "code": "service_delivery"},
            {"product_name": "Послуги бронювання", "usage_count": "Рекомендовано", "code": "service_reserve"},
            {"product_name": "Послуги розрахунок профільної труби", "usage_count": "Рекомендовано", "code": "service_profile"}
        ]

        return {
            "status": "ok", "client_code": client_code,
            "cross_sell": cross_sell, "similar_size": similar_size,
            "direction_variety": direction_variety, "services": services
        }
    except Exception as e:
        logger.error(f"Ошибка client_products_recommendations: {e}")
        raise HTTPException(status_code=500, detail=str(e))

