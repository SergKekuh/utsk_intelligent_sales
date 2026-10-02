with open("utsk_web/frontend/static/profile-pipes-analytics.html", "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace("async \n    </script>", """async function loadKPI() {
            try {
                const res = await fetch(`/api/analytics/profile-pipes/kpi?token=${TOKEN}&code=${CLIENT_CODE}&year=${YEAR}`);
                if (!res.ok) return;
                const json = await res.json();
                const d = json.data || {};
                document.getElementById('kpiSizes').textContent = d.uniq_sizes || 0;
                document.getElementById('kpiProducts').textContent = d.uniq_products || 0;
                document.getElementById('kpiInvoices').textContent = d.invoices || 0;
                document.getElementById('kpiRevenue').textContent = fmtMoney(d.revenue || 0);
            } catch (e) {
                console.error('[KPI] error:', e);
            }
        }
    </script>""")

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "w", encoding="utf-8") as f:
    f.write(content)
