import re

with open('utsk_web/backend/app/api/clients.py', 'r') as f:
    content = f.read()

bad_sql = """
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
"""

good_sql = """
                SELECT sl.id,
                       sl.product_code AS code,
                       p.name,
                       sl.quantity,
                       (COALESCE(p.weight_per_meter, 0) * COALESCE(sl.quantity, 0)) AS weight_kg,
                       (CASE WHEN COALESCE(sl.quantity, 0) > 0 THEN sl.amount / sl.quantity ELSE 0 END) AS price,
                       sl.amount AS total
                FROM sales_lines sl
                LEFT JOIN products p ON p.code = sl.product_code
                WHERE sl.document_id = :doc_id
                ORDER BY sl.id
"""

content = content.replace(bad_sql.strip(), good_sql.strip())

with open('utsk_web/backend/app/api/clients.py', 'w') as f:
    f.write(content)
print("Patched clients.py fix")
