import re

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "r", encoding="utf-8") as f:
    content = f.read()

new_load_yoy = """        async function loadYoYBySizes() {
            const tbody = document.getElementById('yoySizesBody');
            if (!tbody) return;

            tbody.innerHTML = `<tr><td colspan="6" class="loading"><i class="fa-solid fa-spinner fa-spin"></i> Завантаження порівняння розмірів...</td></tr>`;

            try {
                const res = await fetch(`/api/analytics/profile-pipes/sizes-yoy?token=${TOKEN}&code=${CLIENT_CODE}&year=${YEAR}`);
                if (!res.ok) throw new Error(`HTTP ${res.status}`);
                const json = await res.json();
                const items = json.data || [];

                if (items.length === 0) {
                    tbody.innerHTML = `<tr><td colspan="6" class="loading">Немає даних для порівняння за ${YEAR} / ${parseInt(YEAR) - 1}</td></tr>`;
                    return;
                }

                renderYoYSizesTable(items);
                renderYoYSizesChart(items);
            } catch (e) {
                console.error('loadYoYBySizes error:', e);
                tbody.innerHTML = `<tr><td colspan="6" class="loading" style="color:var(--danger);"><i class="fa-solid fa-triangle-exclamation"></i> Помилка: ${e.message}</td></tr>`;
            }
        }"""
content = re.sub(r'async function loadYoYBySizes\(\) \{.*?\n        \}\n', new_load_yoy + '\n', content, flags=re.DOTALL)

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "w", encoding="utf-8") as f:
    f.write(content)
