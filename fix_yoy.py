import re

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "r", encoding="utf-8") as f:
    content = f.read()

# Fix thead
new_thead = """                            <thead>
                                <tr>
                                    <th style="width:36px;text-align:center;"></th>
                                    <th>Розмір</th>
                                    <th class="num">2025 ₴</th>
                                    <th class="num">2026 ₴</th>
                                    <th class="num">Δ ₴</th>
                                    <th class="num">Ріст %</th>
                                </tr>
                            </thead>
                            <tbody id="yoySizesBody">
                                <tr><td colspan="6" class="loading"><i class="fa-solid fa-spinner fa-spin"></i> Завантаження порівняння розмірів...</td></tr>
                            </tbody>"""

content = re.sub(r'<thead>.*?</tr>\s*</thead>\s*<tbody id="yoySizesBody">\s*<tr>.*?</tr>\s*</tbody>', new_thead, content, flags=re.DOTALL)


# Fix renderYoYSizesTable
new_render_yoy = """        function renderYoYSizesTable(items) {
            const tbody = document.getElementById('yoySizesBody');

            tbody.innerHTML = items.map(x => {
                const deltaClass = x.delta_abs > 0 ? 'positive' : x.delta_abs < 0 ? 'negative' : '';
                const deltaText = x.delta_abs === 0 ? '—' : (x.delta_abs > 0 ? '+' : '') + fmtFullMoney(x.delta_abs);

                let yoyText = '—';
                let trendClass = '';
                if (x.delta_pct != null) {
                    const arrow = x.delta_pct >= 0 ? '↑' : '↓';
                    yoyText = arrow + ' ' + x.delta_pct.toFixed(0) + '%';
                    trendClass = x.delta_pct >= 0 ? 'positive' : 'negative';
                }

                const safeName = (x.size_key || '').replace(/'/g, "\\\\'");
                
                let shapeIcon = '📐';
                if (x.size_key.includes('x') && x.size_key.split('x').length === 2) shapeIcon = '🟩';
                else if (x.size_key.includes('x') && x.size_key.split('x').length === 3) shapeIcon = '🟦';

                return `
                    <tr class="size-row"
                        onclick="toggleYoYDrilldown('${safeName}', '${safeName}')"
                        data-size="${x.size_key}"
                        style="cursor:pointer;"
                        title="Клік для деталізації">
                        <td class="expand-cell" style="text-align:center;color:var(--text-muted);">
                            <i class="fa-solid fa-chevron-right expand-icon" style="font-size:10px;"></i>
                        </td>
                        <td>
                            <div style="display:flex;align-items:center;gap:8px;">
                                <span style="font-size:14px;">${shapeIcon}</span>
                                <b>${x.size_key}</b>
                            </div>
                        </td>
                        <td class="num" style="color:var(--text-muted);">${fmtFullMoney(x.revenue_prev)}</td>
                        <td class="num" style="font-weight:700;">${fmtFullMoney(x.revenue_cur)}</td>
                        <td class="num ${deltaClass}">${deltaText}</td>
                        <td class="num ${trendClass}">${yoyText}</td>
                    </tr>
                `;
            }).join('');
        }"""
content = re.sub(r'function renderYoYSizesTable.*?\}\n        \}\n', new_render_yoy + '\n', content, flags=re.DOTALL)

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "w", encoding="utf-8") as f:
    f.write(content)
