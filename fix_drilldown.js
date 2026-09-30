const fs = require('fs');
const file = '/home/serg/Documents/SQL_postgresql/Intelligent_Sales/utsk_web/frontend/static/product-analytics.html';
let content = fs.readFileSync(file, 'utf8');

// 1. Fix toggleDrilldown to search in #sizesBody specifically
content = content.replace(
    /const targetRow = document\.querySelector\(`tr\[data-size="\$\{sizeKey\}"\]`\);/g,
    'const targetRow = document.querySelector(`#sizesBody tr[data-size="${sizeKey}"]`);'
);

// 2. Add YoY Drilldown HTML to the bottom of the YoY Tab
const yoyDrilldownHTML = `
            <!-- YOY DRILL-DOWN PANEL CONTAINER -->
            <div id="yoyDrilldownPanelContainer" style="display:none;">
                <div class="drilldown-panel" id="yoyDrilldownPanel">
                    <div class="drilldown-header">
                        <div class="drilldown-title" id="yoyDrilldownTitle">—</div>
                        <button class="drilldown-close" onclick="closeYoYDrilldown()" title="Закрыть детализацию">
                            <i class="fa-solid fa-xmark"></i>
                        </button>
                    </div>
                    <div id="yoyDrilldownContent"></div>
                </div>
            </div>
        </div>

        <!-- TAB 4: MONTHLY TRENDS -->`;
// Replace the end of Tab 3
content = content.replace(
    /        <\/div>\n\n        <!-- TAB 4: MONTHLY TRENDS -->/,
    yoyDrilldownHTML
);

// 3. Implement toggleYoYDrilldown & closeYoYDrilldown
const newYoYFunctions = `
        let currentYoYSizeKey = null;

        function closeYoYDrilldown() {
            currentYoYSizeKey = null;
            document.querySelectorAll('#yoySizesBody tr.size-row').forEach(tr => tr.classList.remove('active'));
            const panel = document.getElementById('yoyDrilldownPanel');
            const container = document.getElementById('yoyDrilldownPanelContainer');
            if (panel && container) {
                container.appendChild(panel);
                container.style.display = 'none';
            }
            const existingInlineRow = document.getElementById('yoyInlineDrilldownRow');
            if (existingInlineRow) {
                existingInlineRow.remove();
            }
        }

        async function toggleYoYDrilldown(sizeKey, displayName) {
            const targetRow = document.querySelector(\`#yoySizesBody tr[data-size="\${sizeKey}"]\`);
            
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
            // YoY table has 8 columns
            drillRow.innerHTML = '<td colspan="8" id="yoyInlineDrilldownCell"></td>';
            
            if (targetRow) {
                targetRow.after(drillRow);
            }

            const panel = document.getElementById('yoyDrilldownPanel');
            document.getElementById('yoyInlineDrilldownCell').appendChild(panel);

            document.getElementById('yoyDrilldownTitle').innerHTML = 
                \`<i class="fa-solid fa-scale-balanced" style="color:var(--accent);"></i> Порівняння товарів розміру: <b>\${displayName}</b>\`;

            const content = document.getElementById('yoyDrilldownContent');
            content.innerHTML = '<div class="loading"><i class="fa-solid fa-spinner fa-spin"></i> Завантаження...</div>';

            drillRow.scrollIntoView({ behavior: 'smooth', block: 'nearest' });

            try {
                // Call the correct API for YoY products compare
                const r = await fetch(\`/api/analytics/client-products-compare/\${CLIENT_CODE}?token=\${TOKEN}\`);
                if (!r.ok) throw new Error(\`HTTP \${r.status}\`);
                const data = await r.json();

                // We must filter the returned items by sizeKey!
                // Wait, if /api/analytics/client-products-compare returns ALL products, we filter them locally:
                const items = (data.data || data).filter(x => x.size_key === sizeKey);

                if (!items || items.length === 0) {
                    content.innerHTML = '<div class="loading">Немає товарів даного розміру у порівнянні</div>';
                    return;
                }

                let html = \`
                    <table class="sizes-table" style="margin-top:10px;">
                        <thead>
                            <tr>
                                <th>Товар (ДСТУ / Марка)</th>
                                <th class="num">2025 ₴</th>
                                <th class="num">2026 ₴</th>
                                <th class="num">Δ ₴</th>
                                <th class="num">Ріст %</th>
                            </tr>
                        </thead>
                        <tbody>
                \`;

                items.forEach(x => {
                    const arrow = x.yoy_pct >= 100 ? '<span style="color:var(--success);">↑</span>' : '<span style="color:var(--danger);">↓</span>';
                    const yoyText = x.yoy_pct != null ? \`\${arrow} \${x.yoy_pct.toFixed(0)}%\` : '—';
                    html += \`
                        <tr>
                            <td>\${x.display_name || x.product_name || '-'}</td>
                            <td class="num">\${fmtM(x.revenue_prev)}</td>
                            <td class="num">\${fmtM(x.revenue_current)}</td>
                            <td class="num">\${fmtM(x.yoy_abs)}</td>
                            <td class="num">\${yoyText}</td>
                        </tr>
                    \`;
                });

                html += '</tbody></table>';
                content.innerHTML = html;
            } catch (e) {
                console.error(e);
                content.innerHTML = '<div class="loading" style="color:var(--danger);">Ошибка загрузки: ' + e.message + '</div>';
            }
        }

        // График ТОП-10 размеров (grouped bar)
`;

content = content.replace(
    /        function toggleYoYDrilldown\(sizeKey, displayName\) \{[\s\S]*?(?=        \/\/ График ТОП-10 размеров \(grouped bar\))/,
    newYoYFunctions
);

fs.writeFileSync(file, content);
