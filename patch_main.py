import re

with open("utsk_web/backend/app/main.py", "r", encoding="utf-8") as f:
    content = f.read()

content = content.replace(
    "profile_pipes\n)",
    "profile_pipes,\n    classification_audit\n)"
)

content = content.replace(
    "app.include_router(profile_pipes.router)",
    "app.include_router(profile_pipes.router)\napp.include_router(classification_audit.router)"
)

with open("utsk_web/backend/app/main.py", "w", encoding="utf-8") as f:
    f.write(content)
