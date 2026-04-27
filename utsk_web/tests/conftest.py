import pytest
import os
import sys
from sqlalchemy import create_engine, text

sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'backend'))

DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:root@localhost:5432/bd_intelligent_sales")

@pytest.fixture(scope="session", autouse=True)
def setup_database():
    """Создаёт тестовые таблицы перед всеми тестами"""
    engine = create_engine(DATABASE_URL)
    
    # engine.begin() гарантирует COMMIT в SQLAlchemy 2.0
    with engine.begin() as conn:
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS clients (
                code VARCHAR(50) PRIMARY KEY,
                name VARCHAR(255) NOT NULL DEFAULT 'Test',
                current_status_id INT,
                last_purchase_date DATE,
                first_purchase_date DATE,
                activity_direction_id INT,
                requires_survey BOOLEAN DEFAULT FALSE
            )
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS status_rules (
                id SERIAL PRIMARY KEY,
                status_name VARCHAR(50) NOT NULL,
                priority INT NOT NULL DEFAULT 10
            )
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS documents (
                id BIGINT PRIMARY KEY,
                client_code VARCHAR(50),
                invoice_date DATE,
                total_amount DECIMAL(15,2) DEFAULT 0
            )
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS products (
                code VARCHAR(50) PRIMARY KEY,
                name VARCHAR(255) NOT NULL DEFAULT 'Test Product',
                in_stock_balance DECIMAL DEFAULT 10
            )
        """))
        conn.execute(text("""
            CREATE TABLE IF NOT EXISTS sales_lines (
                id BIGSERIAL PRIMARY KEY,
                document_id BIGINT,
                product_code VARCHAR(50),
                quantity DECIMAL DEFAULT 1,
                amount DECIMAL DEFAULT 0
            )
        """))
        
        conn.execute(text("INSERT INTO clients (code, name) VALUES ('36', 'Test Client') ON CONFLICT DO NOTHING"))
        conn.execute(text("INSERT INTO status_rules (id, status_name, priority) VALUES (1, 'Новые', 10) ON CONFLICT DO NOTHING"))
        conn.execute(text("INSERT INTO documents (id, client_code, invoice_date, total_amount) VALUES (1, '36', '2026-01-01', 1000) ON CONFLICT DO NOTHING"))
        conn.execute(text("INSERT INTO products (code, name) VALUES ('0001', 'Test Product') ON CONFLICT DO NOTHING"))
        conn.execute(text("INSERT INTO sales_lines (document_id, product_code, amount) VALUES (1, '0001', 500) ON CONFLICT DO NOTHING"))
    
    yield
