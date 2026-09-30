import re

with open('utsk_web/backend/app/api/clients.py', 'r') as f:
    content = f.read()

new_func = """@router.get("/api/invoices/{document_id}/items")
def get_invoice_items(
    document_id: int,
    token: str = Query(None),
    db: Session = Depends(get_db),
):
    \"\"\"
    Детализация накладной по document_id (PK таблицы documents).
    
    Раньше искали по doc_number — он не уникален глобально
    (совпадает у разных клиентов/лет), из-за чего склеивались
    чужие позиции. См. Проблема 3, диагностика 2026-09-29.
    \"\"\"
    verify_token(token)
    try:
        # 1. Заголовок накладной — строго по PK
        header_row = db.execute(
            text(\"\"\"
                SELECT d.id, d.doc_number, d.invoice_date,
                       d.client_code, c.name AS client_name
                FROM documents d
                LEFT JOIN clients c ON c.code = d.client_code
                WHERE d.id = :doc_id
            \"\"\"),
            {"doc_id": document_id},
        ).fetchone()

        if not header_row:
            raise HTTPException(
                status_code=404,
                detail=f"Накладная id={document_id} не найдена",
            )

        h = dict(header_row._mapping)

        # 2. Строки накладной — строго по document_id
        item_rows = db.execute(
            text(\"\"\"
                SELECT sl.id,
                       sl.product_code AS code,
                       p.name,
                       sl.quantity,
                       sl.weight AS weight_kg,
                       sl.price,
                       sl.amount AS total
                FROM sales_lines sl
                LEFT JOIN products p ON p.code = sl.product_code
                WHERE sl.document_id = :doc_id
                ORDER BY sl.id
            \"\"\"),
            {"doc_id": document_id},
        ).fetchall()

        items = []
        total_sum = 0.0
        for r in item_rows:
            m = dict(r._mapping)
            amount = float(m["total"]) if m.get("total") else 0.0
            total_sum += amount
            items.append({
                "code": m["code"],
                "name": m["name"],
                "quantity": float(m["quantity"]) if m.get("quantity") else 0.0,
                "weight_kg": float(m["weight_kg"]) if m.get("weight_kg") else 0.0,
                "price": float(m["price"]) if m.get("price") else 0.0,
                "total": amount,
            })

        return {
            "status": "ok",
            "document_id": h["id"],
            "number": h["doc_number"],
            "date": h["invoice_date"].strftime("%Y-%m-%d") if h["invoice_date"] else None,
            "client_code": h["client_code"],
            "client_name": h["client_name"],
            "total": round(total_sum, 2),
            "items": items,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Ошибка invoice-items doc_id={document_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))
"""

pattern = re.compile(r'@router\.get\("/api/invoices/\{number\}/items"\).*?(?=\n# ====== API: СТАТУСЫ ======)', re.DOTALL)
if not pattern.search(content):
    print("Could not find pattern in clients.py")
else:
    new_content = pattern.sub(new_func, content)
    with open('utsk_web/backend/app/api/clients.py', 'w') as f:
        f.write(new_content)
    print("Patched clients.py")
