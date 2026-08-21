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
        cross_sell = [
            {"product_code": r.product_code, "product_name": r.product_name, 
             "reason": r.reason, "in_stock": float(r.in_stock or 0)} 
            for r in cross_rows
        ]

        similar_rows = db.execute(
            text("SELECT * FROM get_client_similar_sizes(:code)"),
            {"code": client_code}
        ).fetchall()
        similar_size = [
            {"product_code": r.product_code, "product_name": r.product_name,
             "diameter": float(r.diameter) if r.diameter is not None else None,
             "wall_thickness": float(r.wall_thickness) if r.wall_thickness is not None else None,
             "reason": r.reason, "in_stock": float(r.in_stock or 0)} 
            for r in similar_rows
        ]

        if len(similar_size) < 5:
            existing = {s["product_code"] for s in similar_size}
            fallback_rows = db.execute(
                text("SELECT * FROM get_client_similar_fallback(:code)"),
                {"code": client_code}
            ).fetchall()
            for r in fallback_rows:
                if r.product_code not in existing and len(similar_size) < 5:
                    similar_size.append({
                        "product_code": r.product_code, "product_name": r.product_name,
                        "diameter": float(r.diameter) if r.diameter is not None else None,
                        "wall_thickness": float(r.wall_thickness) if r.wall_thickness is not None else None,
                        "reason": r.reason, "in_stock": float(r.in_stock or 0)
                    })

        dir_rows = db.execute(
            text("SELECT * FROM get_client_direction_variety(:code)"),
            {"code": client_code}
        ).fetchall()
        direction_variety = [
            {"product_code": r.product_code, "product_name": r.product_name,
             "popularity": int(r.popularity or 0), "reason": r.reason, 
             "in_stock": float(r.in_stock or 0)} 
            for r in dir_rows
        ]

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
