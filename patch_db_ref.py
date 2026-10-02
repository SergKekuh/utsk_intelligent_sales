import re

with open("utsk_web/frontend/static/db_reference.html", "r", encoding="utf-8") as f:
    content = f.read()

new_block = """
<!-- ====================================================================== -->
<!-- НОВЫЕ ФУНКЦИИ И ЛОГИ (СЕССИЯ 2026-10)                                  -->
<!-- ====================================================================== -->
<h2 id="block6">🚀 БЛОК 6: НОВЫЕ ФУНКЦИИ, API И ТРИГГЕРЫ (Октябрь 2026)</h2>

<h3 id="tbl17">17. classification_audit_log — История изменения классификации</h3>
<p><strong>🎯 Для чего нужна эта таблица:</strong> Ведет полный лог изменений направления деятельности клиента (группы). Фиксирует, кто, когда и на что изменил классификацию, а также уверенность (confidence) и источник (source). Позволяет в любой момент откатить неверное изменение.</p>

<table>
    <tr><th>Параметр</th><th>Тип данных</th><th>Ограничения</th><th>Пример</th><th>Описание</th></tr>
    <tr><td><code>id</code></td><td>BIGSERIAL</td><td><span class="badge badge-pk">PRIMARY KEY</span></td><td>1</td><td>Уникальный номер записи</td></tr>
    <tr><td><code>client_code</code></td><td>VARCHAR(50)</td><td>NOT NULL</td><td>'4501'</td><td>Код клиента</td></tr>
    <tr><td><code>client_name</code></td><td>VARCHAR(500)</td><td>NULL</td><td>'ТОВ Будпром'</td><td>Название клиента</td></tr>
    <tr><td><code>changed_at</code></td><td>TIMESTAMP</td><td>DEFAULT NOW()</td><td>2026-10-01</td><td>Дата и время изменения</td></tr>
    <tr><td><code>old_direction_id</code></td><td>INT</td><td>NULL</td><td>9</td><td>Старая группа (до изменения)</td></tr>
    <tr><td><code>new_direction_id</code></td><td>INT</td><td>NULL</td><td>8</td><td>Новая группа (после изменения)</td></tr>
    <tr><td><code>old_confidence</code></td><td>NUMERIC(3,2)</td><td>NULL</td><td>0.72</td><td>Старая уверенность</td></tr>
    <tr><td><code>new_confidence</code></td><td>NUMERIC(3,2)</td><td>NULL</td><td>0.82</td><td>Новая уверенность</td></tr>
    <tr><td><code>old_source</code></td><td>VARCHAR(20)</td><td>NULL</td><td>'ML_v1'</td><td>Старый источник</td></tr>
    <tr><td><code>new_source</code></td><td>VARCHAR(20)</td><td>NULL</td><td>'MANUAL'</td><td>Новый источник</td></tr>
    <tr><td><code>change_reason</code></td><td>VARCHAR(50)</td><td>NULL</td><td>'MANUAL_UPDATE'</td><td>Причина изменения</td></tr>
    <tr><td><code>changed_by</code></td><td>VARCHAR(100)</td><td>NULL</td><td>'admin'</td><td>Кто изменил</td></tr>
    <tr><td><code>notes</code></td><td>TEXT</td><td>NULL</td><td>'...'</td><td>Дополнительные комментарии</td></tr>
</table>

<h3 id="triggers">⚙️ Новые триггеры</h3>
<ul>
    <li><strong><code>trg_clients_classification_audit</code></strong>: Срабатывает <code>AFTER UPDATE ON clients</code>. Если изменились <code>activity_direction_id</code>, <code>direction_confidence</code> или <code>direction_source</code>, автоматически добавляет запись в таблицу <code>classification_audit_log</code>.</li>
</ul>

<h3 id="sql_funcs">🛠️ Новые и обновлённые SQL-функции</h3>
<table>
    <tr><th>Название функции</th><th>Назначение</th></tr>
    <tr><td><code>get_client_diversity_index(code, year)</code></td><td>Уникальные типоразмеры труб у клиента (например, 168 для 4501)</td></tr>
    <tr><td><code>get_company_assortment_size()</code></td><td>Всего уникальных товаров и услуг в каталоге компании (4450)</td></tr>
    <tr><td><code>get_company_profile_pipes_count()</code></td><td>Общее число профильных труб в каталоге компании (475)</td></tr>
    <tr><td><code>get_profile_pipes_kpi(code, year)</code></td><td>KPI (размеры, накладные, выручка) по профильным трубам клиента</td></tr>
    <tr><td><code>get_profile_pipes_sizes(code, year)</code></td><td>Агрегированная статистика по размерам профильных труб клиента</td></tr>
    <tr><td><code>get_profile_pipes_products_by_size(code, size_key, year)</code></td><td>Drill-down: товары внутри выбранного размера профильной трубы</td></tr>
    <tr><td><code>get_profile_pipes_sizes_yoy(code, year)</code></td><td>Сравнение выручки по размерам профильных труб (Текущий год vs Прошлый)</td></tr>
    <tr><td><code>get_profile_pipes_monthly(code, year)</code></td><td>Помесячная динамика выручки профильных труб клиента</td></tr>
    <tr><td><code>revert_classification_change(audit_id)</code></td><td>Откатывает изменение классификации по ID лога, ставя <code>is_direction_manual = TRUE</code></td></tr>
    <tr style="background:#f8fafc;"><td colspan="2"><strong>Обновлённые функции (расширена сигнатура):</strong></td></tr>
    <tr><td><code>get_segmentation_current_year()</code></td><td>Добавлена метрика <code>c2_cand_count</code> (кандидаты в C2)</td></tr>
    <tr><td><code>get_segmentation_past_years()</code></td><td>Добавлены метрики <code>dubl_count</code>, <code>center_count</code>, <code>cand_count</code></td></tr>
    <tr><td><code>get_segment_detail(...)</code></td><td>Поддержка новых сегментов: <code>c2_dubl_center</code>, <code>churn_dubl_center</code>, <code>sleep_dubl_center</code></td></tr>
    <tr><td><code>get_client_invoices(...)</code></td><td>Добавлено поле <code>doc_id</code> для правильной уникальности накладных</td></tr>
</table>

<h3 id="api_endpoints">🌐 Новые API-эндпоинты</h3>
<ul>
    <li><code>GET /api/analytics/client-diversity</code> — Індекс Різоманіття клієнта</li>
    <li><code>GET /api/analytics/company-assortment</code> — Загальний асортимент компанії</li>
    <li><code>GET /api/analytics/company-profile-pipes</code> — Кількість профільних труб у каталозі</li>
    <li><code>GET /api/analytics/profile-pipes/kpi</code> — KPI профільних труб</li>
    <li><code>GET /api/analytics/profile-pipes/sizes</code> — Розміри труб</li>
    <li><code>GET /api/analytics/profile-pipes/products-by-size</code> — Drill-down по товарам</li>
    <li><code>GET /api/analytics/profile-pipes/sizes-yoy</code> — Порівняння YoY</li>
    <li><code>GET /api/analytics/profile-pipes/monthly</code> — Динаміка по місяцях</li>
</ul>

<h3 id="pages">📄 Новые страницы UI</h3>
<ul>
    <li><strong><code>profile-pipes-analytics.html</code></strong> — Аналитика профильных труб клиента. Доступна с карточки клиента (Блок 2).</li>
</ul>

<hr style="margin: 40px 0; border: 1px solid var(--border-light);">
"""

content = content.replace('<!-- ER-ДИАГРАММА СВЯЗЕЙ', new_block + '\n<!-- ER-ДИАГРАММА СВЯЗЕЙ')

# Add toc links
new_toc = """        <div class="toc-group">
            <h3>БЛОК 5: VIEWS</h3>
            <a href="#view15">15. v_smart_recommendations</a>
            <a href="#view16">16. v_manager_dashboard</a>
        </div>
        <div class="toc-group">
            <h3>БЛОК 6: СЕССИЯ 10.2026</h3>
            <a href="#tbl17">17. classification_audit_log</a>
            <a href="#triggers">Триггеры</a>
            <a href="#sql_funcs">SQL-функции</a>
            <a href="#api_endpoints">API & UI</a>
        </div>"""
content = content.replace("""        <div class="toc-group">
            <h3>БЛОК 5: VIEWS</h3>
            <a href="#view15">15. v_smart_recommendations</a>
            <a href="#view16">16. v_manager_dashboard</a>
        </div>""", new_toc)


# Add is_direction_manual to clients table
new_clients_row = """    <tr><td><code>direction_source</code></td><td>VARCHAR(20)</td><td>NULL</td><td>'ML_v1'</td><td>Источник последней классификации</td></tr>
    <tr><td><code>is_direction_manual</code></td><td>BOOLEAN</td><td>DEFAULT FALSE</td><td>TRUE</td><td>Флаг ручного изменения группы (не перезаписывается ML)</td></tr>"""
content = content.replace("    <tr><td><code>direction_source</code></td><td>VARCHAR(20)</td><td>NULL</td><td>'ML_v1'</td><td>Источник последней классификации</td></tr>", new_clients_row)

with open("utsk_web/frontend/static/db_reference.html", "w", encoding="utf-8") as f:
    f.write(content)
