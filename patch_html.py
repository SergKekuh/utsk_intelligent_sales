import re

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Title and H1
content = content.replace("<title>UTSK — Продуктовая аналитика клиента</title>", "<title>UTSK — Профільні труби</title>")
content = content.replace("📦 Продуктова аналітика", "📐 Профільні труби")
content = content.replace("Продуктовая аналитика:", "📐 Профільні труби:")

# 2. Tabs
content = re.sub(
    r'<div class="tabs">.*?</div>',
    """<div class="tabs">
            <button class="tab-btn active" onclick="openTab('tab-sizes', this)">
                <i class="fa-solid fa-ruler-combined"></i> 📐 Розміри
            </button>
            <button class="tab-btn" onclick="openTab('tab-yoy', this)">
                <i class="fa-solid fa-arrows-split-up-and-left"></i> 📊 YoY
            </button>
            <button class="tab-btn" onclick="openTab('tab-monthly', this)">
                <i class="fa-solid fa-calendar-days"></i> 📅 Динаміка по місяцях
            </button>
        </div>""",
    content,
    flags=re.DOTALL
)

# 3. KPI Grid
content = re.sub(
    r'<div class="kpi-grid" id="kpiGrid">.*?<div class="filter-bar">',
    """<div class="kpi-grid" id="kpiGrid">
                <div class="kpi-card" style="border-top-color:#3b82f6">
                    <div class="kpi-label"><i class="fa-solid fa-ruler"></i> 📐 Унікальних розмірів</div>
                    <div class="kpi-value" id="kpiSizes">—</div>
                </div>
                <div class="kpi-card" style="border-top-color:#10b981">
                    <div class="kpi-label"><i class="fa-solid fa-box"></i> 📦 Товарів</div>
                    <div class="kpi-value" id="kpiProducts">—</div>
                </div>
                <div class="kpi-card" style="border-top-color:#f59e0b">
                    <div class="kpi-label"><i class="fa-solid fa-file-invoice"></i> 🧾 Накладних</div>
                    <div class="kpi-value" id="kpiInvoices">—</div>
                </div>
                <div class="kpi-card" style="border-top-color:#8b5cf6">
                    <div class="kpi-label"><i class="fa-solid fa-sack-dollar"></i> 💰 Виручка</div>
                    <div class="kpi-value" id="kpiRevenue" style="color:#047857;">—</div>
                </div>
            </div>

            <!-- FILTER & SEARCH BAR -->
            <div class="filter-bar">""",
    content,
    flags=re.DOTALL
)

# 4. Remove Portfolio tab content
content = re.sub(
    r'<!-- TAB 2: PORTFOLIO -->.*?<!-- TAB 3: YoY COMPARE -->',
    '<!-- TAB 3: YoY COMPARE -->',
    content,
    flags=re.DOTALL
)

# 5. Remove ML tab content and Modal
content = re.sub(
    r'<!-- TAB 4: ML RECOMMENDATIONS -->.*?<script>',
    '<script>',
    content,
    flags=re.DOTALL
)

# 6. openTab
content = re.sub(
    r"if \(tabId === 'tab-portfolio' \|\| tabId === 'tab-ml'\) \{.*?\}",
    "",
    content,
    flags=re.DOTALL
)

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "w", encoding="utf-8") as f:
    f.write(content)
