"""
UTSK Intelligent Sales — Web Demo Server Entrypoint
Запуск: python backend/app.py
Доступ: http://0.0.0.0:5000
"""

import uvicorn
from app.main import app
from app.config import HOST, PORT, DEMO_TOKEN

if __name__ == "__main__":
    print("=" * 60)
    print("🚀 UTSK Intelligent Sales — Web Demo Server")
    print("=" * 60)
    print(f"📍 Доступ: http://{HOST}:{PORT}")
    print(f"🔑 Токен: {DEMO_TOKEN}")
    print("=" * 60)
    uvicorn.run(app, host=HOST, port=PORT, log_level="info")
