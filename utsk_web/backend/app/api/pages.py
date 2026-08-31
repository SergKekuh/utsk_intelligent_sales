import os
from fastapi import APIRouter, HTTPException, Query, Request, Depends
from fastapi.responses import HTMLResponse
from ..deps import verify_token, find_file
from ..config import FRONTEND_DIR, PROJECT_DIR, ROOT_DIR

router = APIRouter()

def get_search_dirs():
    return [FRONTEND_DIR, os.path.join(PROJECT_DIR, "frontend", "static"), os.path.join(ROOT_DIR, "frontend", "static")]

@router.get("/", response_class=HTMLResponse)
async def index(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("index.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Главная страница не найдена")

@router.get("/plan", response_class=HTMLResponse)
async def plan_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("plan.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница плана не найдена")

@router.get("/db-reference", response_class=HTMLResponse)
async def db_reference_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("db_reference.html", get_search_dirs()) or find_file("db-reference.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница справки БД не найдена")

@router.get("/client-detail", response_class=HTMLResponse)
async def client_detail_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("client-detail.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница клиента не найдена")

@router.get("/segment-detail", response_class=HTMLResponse)
async def segment_detail_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("segment-detail.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница детализации сегмента не найдена")

@router.get("/general-segmentation", response_class=HTMLResponse)
async def general_segmentation_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("general-segmentation.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница общей сегментации не найдена")

@router.get("/repeat-segmentation", response_class=HTMLResponse)
async def repeat_segmentation_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("repeat-segmentation.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница повторной сегментации не найдена")

@router.get("/consolidated-segmentation", response_class=HTMLResponse)
async def consolidated_segmentation_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("consolidated-segmentation.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница консолидированной сегментации не найдена")

@router.get("/c2-segmentation", response_class=HTMLResponse)
async def c2_segmentation_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("c2-segmentation.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница анализа C2 мелких клиентов не найдена")

@router.get("/new-clients-segmentation", response_class=HTMLResponse)
async def new_clients_segmentation_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("new-clients-segmentation.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница сегментации новых клиентов не найдена")

@router.get("/churned-segmentation", response_class=HTMLResponse)
async def churned_segmentation_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("churned-segmentation.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница анализа вибулих клієнтів не найдена")

@router.get("/sleeping-segmentation", response_class=HTMLResponse)
async def sleeping_segmentation_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("sleeping-segmentation.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница анализа спячих клієнтів не найдена")

@router.get("/product-analytics", response_class=HTMLResponse)
async def product_analytics_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("product-analytics.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница товарного анализа не найдена")

@router.get("/product-recommendations", response_class=HTMLResponse)
async def product_recommendations_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("product-recommendations.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница рекомендаций не найдена")

@router.get("/analytics", response_class=HTMLResponse)
async def analytics_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("analytics.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница аналитики не найдена")

@router.get("/comparison", response_class=HTMLResponse)
async def comparison_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("comparison.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница сравнения не найдена")

@router.get("/avg-check", response_class=HTMLResponse)
async def avg_check_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("avg-check.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница среднего чека не найдена")

@router.get("/advanced", response_class=HTMLResponse)
async def advanced_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("advanced.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница расширенного анализа не найдена")

@router.get("/monthly", response_class=HTMLResponse)
async def monthly_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("monthly.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница помесячного анализа не найдена")

@router.get("/abc-structure", response_class=HTMLResponse)
async def abc_structure_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("abc_structure.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница ABC структуры не найдена")

@router.get("/new-clients-analytics", response_class=HTMLResponse)
async def new_clients_analytics_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("new-clients-analytics.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница анализа новых клиентов не найдена")

@router.get("/inactive-clients-analytics", response_class=HTMLResponse)
async def inactive_clients_analytics_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("inactive-clients-analytics.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница анализа неактивных клиентов не найдена")

@router.get("/top-sales-analytics", response_class=HTMLResponse)
async def top_sales_analytics_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("top-sales-analytics.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница визуализации ТОП продаж не найдена")

@router.get("/client-revenue-analytics", response_class=HTMLResponse)
async def client_revenue_analytics_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("client-revenue-analytics.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница анализа выручки не найдена")

@router.get("/client-invoices-analytics", response_class=HTMLResponse)
async def client_invoices_analytics_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("client-invoices-analytics.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница анализа накладных не найдена")

@router.get("/client-avg-check-analytics", response_class=HTMLResponse)
async def client_avg_check_analytics_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("client-avg-check-analytics.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница анализа среднего чека не найдена")

@router.get("/client-last-purchase-analytics", response_class=HTMLResponse)
async def client_last_purchase_analytics_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("client-last-purchase-analytics.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница анализа последней покупки не найдена")

@router.get("/client-invoices-month", response_class=HTMLResponse)
async def client_invoices_month_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("client-invoices-month.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница накладных за месяц не найдена")

@router.get("/client-month-analytics", response_class=HTMLResponse)
async def client_month_analytics_page(request: Request, token: str = Query(None)):
    verify_token(token)
    filepath = find_file("client-month-analytics.html", get_search_dirs())
    if filepath:
        with open(filepath, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    raise HTTPException(status_code=404, detail="Страница анализа месяца не найдена")
