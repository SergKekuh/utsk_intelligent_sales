#!/bin/bash
# ============================================================
# ТЕСТЫ для новой продуктовой аналитики
# ============================================================

TOKEN="utsk2026"
BASE="http://localhost:5000"
CLIENT="4501"

echo '=========================================='
echo '1. API: список размеров клиента'
echo '=========================================='
curl -s "$BASE/api/client-products-by-size/$CLIENT?token=$TOKEN&year=2026" \
    | python3 -c "
import sys, json
d = json.load(sys.stdin)
if d.get('status') != 'ok':
    print('FAIL:', d); sys.exit(1)
print(f\"OK: {d['count']} размеров\")
for x in d['items'][:5]:
    print(f\"  {x['display_name']:<30} {x['purchase_count']:>3} раз  {x['pct']:>5.1f}%  остаток {x['stock_total']:>8.1f} т\")
"

echo ''
echo '=========================================='
echo '2. API: drill-down по размеру'
echo '=========================================='
# Найти первый size_key из предыдущего запроса
SIZE_KEY=$(curl -s "$BASE/api/client-products-by-size/$CLIENT?token=$TOKEN&year=2026" \
    | python3 -c "import sys,json; print(json.load(sys.stdin)['items'][0]['size_key'])")

echo "Тестируем size_key=$SIZE_KEY"
curl -s "$BASE/api/client-products-by-size/$CLIENT/$SIZE_KEY?token=$TOKEN&year=2026" \
    | python3 -c "
import sys, json
d = json.load(sys.stdin)
if d.get('status') != 'ok':
    print('FAIL:', d); sys.exit(1)
purchased = [x for x in d['items'] if x['is_purchased']]
not_p = [x for x in d['items'] if not x['is_purchased']]
print(f\"OK: {len(purchased)} купленных, {len(not_p)} на складе\")
for x in purchased[:5]:
    print(f\"  ✓ {x['product_code']:<8} {x['product_name'][:50]:<50} {x['purchase_count']} раз, остаток {x['stock_balance']}\")
"

echo ''
echo '=========================================='
echo '3. HTML-страница'
echo '=========================================='
HTTP=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/product-analytics?token=$TOKEN&code=$CLIENT")
echo "GET /product-analytics → HTTP $HTTP"

echo ''
echo '=========================================='
echo '4. Проверка маркеров на странице'
echo '=========================================='
HTML=$(curl -s "$BASE/product-analytics?token=$TOKEN&code=$CLIENT")
echo "sizesTable:      $(echo "$HTML" | grep -c 'sizesTable')"
echo "drilldownPanel:  $(echo "$HTML" | grep -c 'drilldownPanel')"
echo "client-products-by-size: $(echo "$HTML" | grep -c 'client-products-by-size')"
