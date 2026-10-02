import re

with open("utsk_web/backend/app/api/classification_audit.py", "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace(
    "row = db.execute(",
    "db.execute(text('COMMIT'));\n        row = db.execute("
)
# Wait, SQLAlchemy `db.commit()` is better
content = content.replace(
    "d = dict(row._mapping)",
    "db.commit()\n        d = dict(row._mapping)"
)

with open("utsk_web/backend/app/api/classification_audit.py", "w", encoding="utf-8") as f:
    f.write(content)
