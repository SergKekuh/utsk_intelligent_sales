import re

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "r", encoding="utf-8") as f:
    content = f.read()

new_yoy_drilldown = """
        async function toggleYoYDrilldown(sizeKey, displayName) {
            const targetRow = document.querySelector(`#yoySizesBody tr[data-size="${sizeKey}"]`);
            
            if (currentYoYSizeKey === sizeKey) {
                closeYoYDrilldown();
                return;
            }

            closeYoYDrilldown();
            currentYoYSizeKey = sizeKey;

            if (targetRow) {
                targetRow.classList.add('active');
            }

            const drillRow = document.createElement('tr');
            drillRow.id = 'yoyInlineDrilldownRow';
            drillRow.className = 'drilldown-row';
            drillRow.innerHTML = '<td colspan="8" id="yoyInlineDrilldownCell" style="padding:0;"></td>';
            
            if (targetRow) {
                targetRow.after(drillRow);
            }

            const panel = document.getElementById('yoyDrilldownPanel');
            document.getElementById('yoyInlineDrilldownCell').appendChild(panel);
            document.getElementById('yoyDrilldownPanelContainer').style.display = 'block';

            document.getElementById('yoyDrilldownTitle').innerHTML = 
                `<i class="fa-solid fa-scale-balanced" style="color:var(--accent);"></i> Товари розміру: <b>${displayName}</b> (за ${YEAR} рік)`;

            const contentEl = document.getElementById('yoyDrilldownContent');
            contentEl.innerHTML = '<div class="loading"><i class="fa-solid fa-spinner fa-spin"></i> Завантаження...</div>';

            drillRow.scrollIntoView({ behavior: 'smooth', block: 'nearest' });

            try {
                const r = await fetch(`/api/analytics/profile-pipes/products-by-size?token=${TOKEN}&code=${CLIENT_CODE}&size_key=${encodeURIComponent(sizeKey)}&year=${YEAR}`);
                if (!r.ok) throw new Error(`HTTP ${r.status}`);
                const json = await r.json();
                const data = json.data || [];

                if (data.length === 0) {
                    contentEl.innerHTML = '<div class="loading">Немає товарів даного розміру</div>';
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
                contentEl.innerHTML = html;
            } catch (e) {
                console.error(e);
                contentEl.innerHTML = '<div class="loading" style="color:var(--danger);">Помилка: ' + e.message + '</div>';
            }
        }
"""

content = re.sub(r'async function toggleYoYDrilldown\(sizeKey, displayName\) \{.*?\}\n        \}\n', new_yoy_drilldown, content, flags=re.DOTALL)

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "w", encoding="utf-8") as f:
    f.write(content)
