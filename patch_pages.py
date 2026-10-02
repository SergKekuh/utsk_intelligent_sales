import re

with open("utsk_web/backend/app/api/pages.py", "r", encoding="utf-8") as f:
    content = f.read()

new_page = """@router.get("/classification-audit", response_class=HTMLResponse)
async def classification_audit_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("classification-audit.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница не найдена")

"""

# Let's insert it right before the last function or at the end
# Since pages.py has many functions, we can append it at the bottom.
with open("utsk_web/backend/app/api/pages.py", "a", encoding="utf-8") as f:
    f.write("\n" + new_page)
