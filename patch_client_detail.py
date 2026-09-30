import re

with open('utsk_web/frontend/static/client-detail.html', 'r') as f:
    content = f.read()

# Replace button onclick
content = content.replace("showInvoiceDetail('${inv.number}')", "showInvoiceDetail(${inv.doc_id}, '${inv.number}')")

# Replace function signature
content = content.replace("async function showInvoiceDetail(invoiceNumber) {", "async function showInvoiceDetail(docId, invoiceNumber) {")

# Replace fetch
new_fetch = """
    const resp = await fetch(`/api/invoices/${docId}/items?token=${TOKEN}`);
    if (!resp.ok) {
        const errText = await resp.text();
        console.error(`[Invoice] HTTP ${resp.status}: ${errText.substring(0, 200)}`);
        return;
    }
"""
content = re.sub(r'const resp = await fetch\(`/api/invoices/\$\{encodeURIComponent\(invoiceNumber\)\}/items\?token=\$\{TOKEN\}`\);\s+if \(!resp.ok\) throw new Error\(resp.status\);', new_fetch.strip(), content)

with open('utsk_web/frontend/static/client-detail.html', 'w') as f:
    f.write(content)

print("Patched client-detail.html")
