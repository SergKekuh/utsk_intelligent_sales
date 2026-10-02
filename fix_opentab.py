with open("utsk_web/frontend/static/profile-pipes-analytics.html", "r", encoding="utf-8") as f:
    content = f.read()
    
import re
new_opentab = """        function openTab(tabId, btn) {
            document.querySelectorAll('.tab-btn').forEach(b => b.classList.remove('active'));
            document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
            btn.classList.add('active');
            document.getElementById(tabId).classList.add('active');

            if (tabId === 'tab-yoy') {
                loadYoYBySizes();
            }
            if (tabId === 'tab-monthly') {
                loadMonthly();
            }
        }"""
content = re.sub(r'function openTab\(tabId, btn\) \{.*?\}\s*\}', new_opentab, content, flags=re.DOTALL)

with open("utsk_web/frontend/static/profile-pipes-analytics.html", "w", encoding="utf-8") as f:
    f.write(content)
