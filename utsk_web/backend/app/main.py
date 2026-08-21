import os
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from .config import FRONTEND_DIR, PROJECT_DIR
from .api import (
    pages,
    dashboard,
    clients,
    products,
    analytics,
    new_clients,
    inactive_clients,
    top_sales,
    client_analytics
)

app = FastAPI(title="UTSK Intelligent Sales API", version="1.0.0")

# Static files
if os.path.exists(FRONTEND_DIR):
    app.mount("/static", StaticFiles(directory=FRONTEND_DIR), name="static")

# Include Routers
app.include_router(pages.router)
app.include_router(dashboard.router)
app.include_router(clients.router)
app.include_router(products.router)
app.include_router(analytics.router)
app.include_router(new_clients.router)
app.include_router(inactive_clients.router)
app.include_router(top_sales.router)
app.include_router(client_analytics.router)
