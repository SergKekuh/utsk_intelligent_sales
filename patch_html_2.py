import re

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "r", encoding="utf-8") as f:
    content = f.read()

# 1. Add Monthly tab HTML before <script>
monthly_html = """
        <!-- TAB MONTHLY -->
        <div id="tab-monthly" class="tab-content" style="display:none;">
            <div class="card">
                <div class="card-header">
                    <h2 class="card-title">📅 Динаміка по місяцях</h2>
                </div>
                <div class="chart-container" style="position:relative; height:400px; padding:20px;">
                    <canvas id="chartMonthly"></canvas>
                </div>
            </div>
        </div>
    </div>
"""
content = re.sub(
    r'</div>\s*<script>',
    monthly_html + '\n    <script>',
    content
)

# 2. Update openTab
content = content.replace(
    "if (tabId === 'tab-yoy') {",
    """if (tabId === 'tab-yoy') {
                loadYoYBySizes();
            }
            if (tabId === 'tab-monthly') {
                loadMonthly();
            }
            if (false) {"""
)

# 3. Update Fetch Calls
# 3.1. Sizes
content = content.replace(
    "fetch(`/api/client-products-by-size/${CLIENT_CODE}?token=${TOKEN}&year=${YEAR}`)",
    "fetch(`/api/analytics/profile-pipes/sizes?token=${TOKEN}&code=${CLIENT_CODE}&year=${YEAR}`)"
)
# Wait, the response might be different. Let's see how it parses sizes.
# sizes = json.data
content = content.replace(
    "const rows = await r.json();",
    "const json = await r.json();\n                const rows = json.data || [];"
)
content = content.replace(
    "allSizes = rows;",
    "allSizes = rows;"
)
# It used to be just an array for `client-products-by-size`. I handled it!

# 3.2. Drill-down
content = content.replace(
    "fetch(`/api/client-products-by-size/${CLIENT_CODE}/${sizeKey}?token=${TOKEN}&year=${YEAR}`)",
    "fetch(`/api/analytics/profile-pipes/products-by-size?token=${TOKEN}&code=${CLIENT_CODE}&size_key=${encodeURIComponent(sizeKey)}&year=${YEAR}`)"
)
content = content.replace(
    "const data = await r.json();",
    "const json = await r.json();\n                const data = json.data || [];"
)

# 3.3. YoY
content = content.replace(
    "fetch(`/api/analytics/client-sizes-compare/${CLIENT_CODE}?token=${TOKEN}&year=${YEAR}`)",
    "fetch(`/api/analytics/profile-pipes/sizes-yoy?token=${TOKEN}&code=${CLIENT_CODE}&year=${YEAR}`)"
)

# 3.4. YoY Drill-down
content = content.replace(
    "fetch(`/api/analytics/client-products-compare/${CLIENT_CODE}?token=${TOKEN}`)",
    "fetch(`/api/analytics/profile-pipes/products-by-size?token=${TOKEN}&code=${CLIENT_CODE}&size_key=${encodeURIComponent(sizeKey)}&year=${YEAR}`)"
)

# 3.5. Remove loadPortfolio and loadML entirely
content = re.sub(r'async function loadLegacyAnalytics\(\) \{.*?\n        \}', '', content, flags=re.DOTALL)
content = re.sub(r'function renderPortfolio.*?\}\n\n', '', content, flags=re.DOTALL)
content = re.sub(r'function renderML.*?\}\n\n', '', content, flags=re.DOTALL)
content = re.sub(r'async function openMLModal.*?\}\n\n', '', content, flags=re.DOTALL)
content = re.sub(r'function closeMLModal.*?\}\n\n', '', content, flags=re.DOTALL)
content = re.sub(r'function handleMLBackdropClick.*?\}\n\n', '', content, flags=re.DOTALL)


with open("utsk_web/frontend/static/profile-pipes-analytics.html", "w", encoding="utf-8") as f:
    f.write(content)
