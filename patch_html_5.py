import re

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "r", encoding="utf-8") as f:
    content = f.read()

new_filters_render = """
        function applyFilters() {
            const search = (document.getElementById('sizeSearch').value || '').trim().toLowerCase();
            const filtered = allSizes.filter(item => {
                // filters like 'round' won't be used, only 'square' or 'rect' make sense here
                if (currentFilter === 'square' && item.shape !== 'square') return false;
                if (currentFilter === 'rect' && item.shape !== 'rect') return false;

                if (search) {
                    const haystack = `${item.size_key}`.toLowerCase();
                    return haystack.includes(search);
                }
                return true;
            });

            if (document.getElementById('filteredCountLabel')) {
                document.getElementById('filteredCountLabel').textContent = `Показано: ${filtered.length} из ${allSizes.length}`;
            }
            renderSizesTable(filtered);
        }

        function renderSizesTable(items) {
            const tbody = document.getElementById('sizesBody');
            closeDrilldown();

            if (items.length === 0) {
                tbody.innerHTML = '<tr><td colspan="6" class="loading">Нет размеров, удовлетворяющих условиям фильтра</td></tr>';
                return;
            }

            tbody.innerHTML = items.map(x => {
                const isActive = (currentSizeKey === x.size_key);
                const safeName = x.size_key.replace(/'/g, "\\'");
                const shapeIcon = x.shape === 'square' ? '🟩' : (x.shape === 'rect' ? '🟦' : '📐');

                return `
                    <tr onclick="toggleDrilldown('${x.size_key}', '${safeName}')" data-size="${x.size_key}" class="size-row ${isActive ? 'active' : ''}">
                        <td class="expand-cell"><i class="fa-solid fa-chevron-right expand-icon"></i></td>
                        <td>${shapeIcon} <b>${x.size_key}</b></td>
                        <td class="num">${x.invoices} накл.</td>
                        <td class="num">${fmtMoney(x.revenue)}</td>
                        <td class="num">${fmtMoney(x.avg_price)}</td>
                        <td class="num">${x.products_count}</td>
                    </tr>
                `;
            }).join('');
        }
"""
content = re.sub(r'function applyFilters\(\).*?\}\n\n        // ---- Drill-down logic', new_filters_render + '\n        // ---- Drill-down logic', content, flags=re.DOTALL)

# Need to update Table Headers for sizes-table
# The original header was:
# <th>Размер</th> <th class="num">Закупки</th> <th class="num">Вклад (выручка)</th> <th class="num">Остаток</th> <th class="num">SKU</th>
new_thead = """                            <thead>
                                <tr>
                                    <th style="width: 40px;"></th>
                                    <th>Розмір</th>
                                    <th class="num">Накладні</th>
                                    <th class="num">Виручка</th>
                                    <th class="num">Середній чек</th>
                                    <th class="num">Товарів</th>
                                </tr>
                            </thead>"""
content = re.sub(r'<thead>\s*<tr>\s*<th style="width: 40px;">.*?</tr>\s*</thead>', new_thead, content, flags=re.DOTALL)

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "w", encoding="utf-8") as f:
    f.write(content)
