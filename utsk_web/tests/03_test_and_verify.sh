#!/bin/bash
# ============================================================
# ТЕСТЫ после исправления drill-down
# ============================================================

TOKEN="utsk2026"
BASE="http://localhost:5000"
CLIENT="4501"
SIZE="round_76x5"

echo '=========================================='
echo '1. Drill-down для round_76x5'
echo '=========================================='
curl -s "$BASE/api/client-products-by-size/$CLIENT/$SIZE?token=$TOKEN&year=2026" \
    | python3 -c "
import sys, json
d = json.load(sys.stdin)
if d.get('status') != 'ok':
    print('FAIL:', d); sys.exit(1)
items = d['items']
purchased = [x for x in items if x['is_purchased']]
not_p = [x for x in items if not x['is_purchased']]
zero_stock = [x for x in items if x['stock_balance'] == 0]
print(f'OK: {len(items)} товаров')
print(f'   куплено:      {len(purchased)}')
print(f'   на складе:    {len(not_p)}')
print(f'   с 0-остатком: {len(zero_stock)}')
if zero_stock:
    print()
    print('❌ ВНИМАНИЕ: есть товары с 0-остатком (должны быть скрыты):')
    for x in zero_stock:
        print(f\"   {x['product_code']}: {x['product_name'][:50]} → stock={x['stock_balance']}\")
else:
    print()
    print('✅ Все товары имеют остаток > 0 или куплены клиентом')
print()
print('Детали:')
for x in items:
    flag = '✓' if x['is_purchased'] else ' '
    print(f\"   {flag} {x['product_code']:<8} {x['product_name'][:50]:<50} stock={x['stock_balance']:>7} rev={x['revenue']}\")
"

echo ''
echo '=========================================='
echo '2. Проверить, что 2025 покупки НЕ попадают в 2026'
echo '=========================================='
PGPASSWORD=root psql -h localhost -U postgres -d bd_intelligent_sales -t -c "
SELECT EXTRACT(YEAR FROM d.invoice_date)::INT AS yr, COUNT(*) AS purchases
FROM documents d
JOIN sales_lines sl ON sl.document_id = d.id
WHERE d.client_code = '4501' 
  AND sl.product_code IN (SELECT code FROM products WHERE name ILIKE '%76%5%')
GROUP BY yr
ORDER BY yr DESC;
"

echo ''
echo '=========================================='
echo '3. Общая сумма остатков = остаток в основной таблице'
echo '=========================================='
curl -s "$BASE/api/client-products-by-size/$CLIENT/$SIZE?token=$TOKEN&year=2026" \
    | python3 -c "
import sys, json
d = json.load(sys.stdin)
total_stock = sum(x['stock_balance'] for x in d['items'])
print(f'Сумма остатков в drill-down: {total_stock:.3f} т')
"

curl -s "$BASE/api/client-products-by-size/$CLIENT?token=$TOKEN&year=2026" \
    | python3 -c "
import sys, json
d = json.load(sys.stdin)
match = [x for x in d['items'] if x['size_key'] == '$SIZE'][0]
print(f'Остаток в основной таблице:   {match[\"stock_total\"]:.3f} т')
"
