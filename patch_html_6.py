import re

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "r", encoding="utf-8") as f:
    content = f.read()

new_drilldown = """
        // ---- Drill-down logic (Inline Accordion) ----
        async function toggleDrilldown(sizeKey, displayName) {
            const currentActive = document.querySelector('#sizesBody tr.size-row.active');
            const targetRow = document.querySelector(`tr[data-size="${sizeKey}"]`);

            if (currentSizeKey === sizeKey) {
                closeDrilldown();
                return;
            }

            closeDrilldown();
            currentSizeKey = sizeKey;

            if (targetRow) {
                targetRow.classList.add('active');
            }

            const drillRow = document.createElement('tr');
            drillRow.id = 'inlineDrilldownRow';
            drillRow.className = 'drilldown-row active';
            drillRow.innerHTML = '<td colspan="6" id="inlineDrilldownCell" style="padding:0;"></td>';
            
            if (targetRow) {
                targetRow.after(drillRow);
            }

            const panel = document.getElementById('drilldownPanel');
            document.getElementById('inlineDrilldownCell').appendChild(panel);
            document.getElementById('drilldownPanelContainer').style.display = 'block';

            document.getElementById('drilldownTitle').innerHTML = 
                `<i class="fa-solid fa-box-open" style="color:var(--accent);"></i> Товари розміру: <b>${displayName}</b>`;

            const content = document.getElementById('drilldownContent');
            content.innerHTML = '<div class="loading"><i class="fa-solid fa-spinner fa-spin"></i> Завантаження...</div>';

            try {
                const r = await fetch(`/api/analytics/profile-pipes/products-by-size?token=${TOKEN}&code=${CLIENT_CODE}&size_key=${encodeURIComponent(sizeKey)}&year=${YEAR}`);
                if (!r.ok) throw new Error(`HTTP ${r.status}`);
                const json = await r.json();
                const data = json.data || [];

                if (data.length === 0) {
                    content.innerHTML = '<div class="loading">Немає товарів цього розміру</div>';
                    return;
                }

                let html = `
                        <table class="products-table" style="margin-top: 10px;">
                            <thead>
                                <tr>
                                    <th style="width:80px;">Код</th>
                                    <th>Найменування</th>
                                    <th class="num">Накладні</th>
                                    <th class="num">Кількість (т)</th>
                                    <th class="num">Виручка</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${data.map(p => `
                                    <tr>
                                        <td><code style="font-family:'JetBrains Mono',monospace;font-size:12px;color:#475569;">${p.product_code}</code></td>
                                        <td><b>${p.product_name}</b></td>
                                        <td class="num">${p.invoices} накл.</td>
                                        <td class="num">${fmtNum(p.quantity, 3)}</td>
                                        <td class="num" style="font-weight:700;">${fmtMoney(p.revenue)}</td>
                                    </tr>
                                `).join('')}
                            </tbody>
                        </table>
                `;

                content.innerHTML = html;
            } catch (e) {
                content.innerHTML = `<div class="error"><i class="fa-solid fa-triangle-exclamation"></i> Помилка: ${e.message}</div>`;
            }
        }
"""
content = re.sub(r'// ---- Drill-down logic.*?function closeDrilldown', new_drilldown + '\n        function closeDrilldown', content, flags=re.DOTALL)

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "w", encoding="utf-8") as f:
    f.write(content)
