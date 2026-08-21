import os
from fastapi import HTTPException, Query
from sqlalchemy import create_engine
from sqlalchemy.orm import Session
from .config import DATABASE_URL, DEMO_TOKEN, logger

engine = create_engine(DATABASE_URL)

def get_db():
    db = Session(engine)
    try:
        yield db
    finally:
        db.close()

def verify_token(token: str = Query(None)):
    if token != DEMO_TOKEN:
        raise HTTPException(status_code=403, detail="Неверный токен доступа")
    return True

def find_file(filename: str, search_dirs: list) -> str | None:
    for directory in search_dirs:
        filepath = os.path.join(directory, filename)
        if os.path.exists(filepath):
            logger.info(f"✅ Найден файл: {filepath}")
            return filepath
    logger.error(f"❌ Файл не найден: {filename}")
    return None
