import re

with open('utsk_web/frontend/static/client-invoices-month.html', 'r') as f:
    content = f.read()

# fetch replace
new_fetch = """
    const res = await fetch(`/api/invoices/${docId}/items?token=${TOKEN}`);
    if (!res.ok) {
        const errText = await res.text();
        console.error(`[Invoice] HTTP ${res.status}: ${errText.substring(0, 200)}`);
        return;
    }
"""
content = re.sub(r'const res = await fetch\(`/api/invoices/\$\{encodeURIComponent\(docNumber\)\}/items\?token=\$\{TOKEN\}`\);\s+const data = await res.json\(\);', new_fetch.strip() + '\n    const data = await res.json();', content)

with open('utsk_web/frontend/static/client-invoices-month.html', 'w') as f:
    f.write(content)

print("Patched client-invoices-month.html")
