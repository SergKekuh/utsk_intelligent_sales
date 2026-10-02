import re

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "r", encoding="utf-8") as f:
    content = f.read()

# Fix loadSizes
new_load_sizes = """        async function loadSizes() {
            const tbody = document.getElementById('sizesBody');
            tbody.innerHTML = '<tr><td colspan="6" class="loading"><i class="fa-solid fa-spinner fa-spin"></i> Загрузка размеров труб...</td></tr>';
            closeDrilldown();

            try {
                const r = await fetch(`/api/analytics/profile-pipes/sizes?token=${TOKEN}&code=${CLIENT_CODE}&year=${YEAR}`);
                if (!r.ok) throw new Error(`HTTP ${r.status}`);
                const json = await r.json();
                allSizes = json.data || [];

                document.getElementById('clientName').textContent = CLIENT_CODE;
                document.getElementById('clientCode').textContent = CLIENT_CODE;
                document.getElementById('backBtn').href = `/client-detail?token=${TOKEN}&code=${CLIENT_CODE}`;

                if (document.getElementById('totalSizesBadge')) {
                    document.getElementById('totalSizesBadge').textContent = allSizes.length;
                }

                if (allSizes.length === 0) {
                    tbody.innerHTML = '<tr><td colspan="6" class="loading">Нет закупок труб за выбранный год</td></tr>';
                    return;
                }

                applyFilters();

            } catch (e) {
                tbody.innerHTML = `<tr><td colspan="6" class="error"><i class="fa-solid fa-triangle-exclamation"></i> Ошибка: ${e.message}</td></tr>`;
            }
        }"""
content = re.sub(r'async function loadSizes\(\) \{.*?\n        \}', new_load_sizes, content, flags=re.DOTALL)

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "w", encoding="utf-8") as f:
    f.write(content)
