import os
import logging

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:root@localhost:5432/bd_intelligent_sales")
DEMO_TOKEN = os.getenv("DEMO_TOKEN", "utsk2026")
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", 5000))

# Absolute paths
BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PROJECT_DIR = os.path.dirname(BACKEND_DIR)
ROOT_DIR = os.path.dirname(PROJECT_DIR)
FRONTEND_DIR = os.path.join(PROJECT_DIR, "frontend", "static")
DOCS_DIR = os.path.join(ROOT_DIR, "docs")

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("utsk_sales")
