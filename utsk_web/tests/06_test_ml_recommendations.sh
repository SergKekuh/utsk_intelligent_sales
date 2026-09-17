#!/bin/bash
# ============================================================
# 06_test_ml_recommendations.sh
# Тестирование ML-рекомендаций с агрегацией по размерам и drill-down
# ============================================================

TOKEN="utsk2026"
BASE="http://localhost:5000"
CLIENT="4501"

echo "=========================================="
echo "1. Тест API ML-рекомендаций (/api/analytics/client-products-recommendations/$CLIENT)"
echo "=========================================="
curl -s "$BASE/api/analytics/client-products-recommendations/$CLIENT?token=$TOKEN" \
    | python3 -c "
import sys, json

d = json.load(sys.stdin)
if d.get('status') != 'ok':
    print('FAIL: status not ok', d)
    sys.exit(1)

blocks = ['cross_sell', 'similar_size', 'direction_variety']
block_names = {
    'cross_sell': '1. Сопутствующие товары (Cross-sell)',
    'similar_size': '2. Похожие типоразмеры',
    'direction_variety': '3. Популярное в сегменте'
}

for b in blocks:
    items = d.get(b, [])
    print(f'\n{block_names[b]} (всего: {len(items)}):')
    if not items:
        print('  FAIL: Пустой блок!')
        sys.exit(1)
    
    seen_keys = set()
    for item in items:
        s_key = item.get('size_key')
        d_name = item.get('display_name')
        reason = item.get('reason')
        stock = item.get('in_stock')
        
        # Проверка дубликатов
        if s_key in seen_keys:
            print(f'  FAIL: Дубликат size_key: {s_key}')
            sys.exit(1)
        seen_keys.add(s_key)
        
        # Проверка отсутствия технического мусора
        for garbage in ['7304', 'ГОСТ', 'ДСТУ', 'GB/T', 'ст20', 'ст45', 'ст09Г2С', '⌀']:
            if garbage in d_name:
                print(f'  FAIL: Технический мусор в названии {d_name}: {garbage}')
                sys.exit(1)
            if garbage in reason:
                print(f'  FAIL: Технический мусор в причине {reason}: {garbage}')
                sys.exit(1)

        print(f'  ✓ {s_key:<20} | {d_name:<32} | {reason:<22} | {stock:>6.2f} т')

print('\n4. Услуги:')
for s in d.get('services', []):
    print(f'  ✓ {s.get(\"product_name\"):<50} | {s.get(\"usage_count\")}')

print('\n✅ Все 3 блока рекомендаций успешно агрегированы по размерам!')
"

echo ""
echo "=========================================="
echo "2. Тест Drill-down для размеров из рекомендаций"
echo "=========================================="
curl -s "$BASE/api/analytics/client-products-recommendations/$CLIENT?token=$TOKEN" \
    | python3 -c "
import sys, json, urllib.request

d = json.load(sys.stdin)
sample_keys = [
    d['cross_sell'][0]['size_key'],
    d['similar_size'][0]['size_key'],
    d['direction_variety'][0]['size_key']
]

for key in sample_keys:
    url = f'$BASE/api/client-products-by-size/$CLIENT/{key}?token=$TOKEN&year=2026'
    req = urllib.request.urlopen(url)
    res = json.loads(req.read().decode('utf-8'))
    items = res.get('items', [])
    purchased = [x for x in items if x['is_purchased']]
    not_p = [x for x in items if not x['is_purchased'] and x['stock_balance'] > 0]
    print(f'✓ {key:<20} → {len(items)} товаров (куплено: {len(purchased)}, на складе: {len(not_p)})')

print('\n✅ Drill-down API работает для всех типов рекомендаций!')
"

echo ""
echo "=========================================="
echo "3. Проверка HTML элементов и скриптов"
echo "=========================================="
HTML_FILE="frontend/static/product-analytics.html"
for marker in "mlModalBackdrop" "openMLModal" "closeMLModal" "ml-grid" "ml-row-clickable"; do
    count=$(grep -c "$marker" "$HTML_FILE")
    if [ "$count" -gt 0 ]; then
        echo "  ✓ Маркер '$marker' найден ($count раз)"
    else
        echo "  ❌ ОШИБКА: Маркер '$marker' не найден в $HTML_FILE"
        exit 1
    fi
done

echo ""
echo "=========================================="
echo "🎉 ВСЕ ПРОВЕРКИ ПРОЙДЕНЫ УСПЕШНО!"
echo "=========================================="
