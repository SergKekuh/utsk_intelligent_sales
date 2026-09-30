TOKEN="utsk2026"
BASE="http://localhost:5000"

echo "=== API направления ==="
curl -s "$BASE/api/analytics/directions/kpi?token=$TOKEN&year=2026" \
    | python3 -c "
import sys, json
d = json.load(sys.stdin)['data']
print(f\"total_clients: {d['total_clients']} (должно быть 729)\")
assert d['total_clients'] == 729
print('✅ KPI OK')
"

echo "=== Сводка 16 отраслей ==="
curl -s "$BASE/api/analytics/directions/summary?token=$TOKEN&year=2026" \
    | python3 -c "
import sys, json
d = json.load(sys.stdin)['data']
print(f'Отраслей: {len(d)}')
for x in d[:5]:
    print(f\"  {x['icon']} {x['name']}: {x['clients_count']} клиентов\")
"

echo "=== Direction-detail (отрасль 11 — Машиностроение) ==="
curl -s "$BASE/api/analytics/directions/detail-kpi?token=$TOKEN&direction_id=11&year=2026" \
    | python3 -m json.tool | head -20

echo "=== Страницы HTTP 200 ==="
for pg in directions-analytics direction-detail analytics index monthly c2-segmentation general-segmentation; do
    http=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/$pg?token=$TOKEN")
    echo "  $pg → $http"
done
