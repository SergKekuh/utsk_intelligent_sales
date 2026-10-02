import re

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "r", encoding="utf-8") as f:
    content = f.read()

# Add loadMonthly and renderMonthlyChart and loadKPI
js_addition = """
        // ====== ВКЛАДКА MONTHLY: динамика по месяцам ======
        async function loadMonthly() {
            try {
                const res = await fetch(`/api/analytics/profile-pipes/monthly?token=${TOKEN}&code=${CLIENT_CODE}&year=${YEAR}`);
                if (!res.ok) {
                    console.error('[MONTHLY] HTTP', res.status);
                    return;
                }
                const json = await res.json();
                const rows = json.data || [];
                renderMonthlyChart(rows);
            } catch (e) {
                console.error('[MONTHLY] error:', e);
            }
        }

        function renderMonthlyChart(rows) {
            const canvas = document.getElementById('chartMonthly');
            if (!canvas) return;
            if (window._chartMonthlyInstance) window._chartMonthlyInstance.destroy();
            
            const labels = rows.map(r => r.month_name);
            const data = rows.map(r => Number(r.revenue) || 0);
            
            window._chartMonthlyInstance = new Chart(canvas, {
                type: 'bar',
                data: {
                    labels: labels,
                    datasets: [{
                        label: 'Виручка, ₴',
                        data: data,
                        backgroundColor: '#4f46e5',
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: { beginAtZero: true, ticks: { callback: v => (v/1e6).toFixed(1) + 'M' } }
                    }
                }
            });
        }

        async function loadKPI() {
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
"""
content = content.replace("</script>", js_addition + "\n    </script>")

# Call loadKPI in DOMContentLoaded
content = content.replace("loadSizes();", "loadSizes();\n            loadKPI();")
# also replace loadKPI() if it's already called in loadSizes... wait, let's just put it in DOMContentLoaded.
# The original code might call loadKPI inside loadSizes() or separately.
# Let's remove any existing `loadKPI` or `renderKPI` definitions just in case.
content = re.sub(r'function loadKPI\(\) \{.*?\n        \}\n', '', content, flags=re.DOTALL)
# wait, my js_addition has async function loadKPI, which is fine if I stripped the old one.

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "w", encoding="utf-8") as f:
    f.write(content)
