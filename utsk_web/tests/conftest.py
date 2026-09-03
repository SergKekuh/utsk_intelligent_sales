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
        
        # Тестовые данные
        conn.execute(text("INSERT INTO status_rules (id, status_name, priority) VALUES (1, 'Новые', 10) ON CONFLICT DO NOTHING"))
        # ✅ ТЕСТОВЫЙ КЛИЕНТ (используем TEST_999999, чтобы не затирать реальных клиентов)
        conn.execute(text("INSERT INTO clients (code, name, current_status_id) VALUES ('TEST_999999', 'Test Client', 1) ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, current_status_id = 1"))
        conn.execute(text("INSERT INTO documents (id, client_code, invoice_date, total_amount) VALUES (999999999, 'TEST_999999', '2026-01-01', 1000) ON CONFLICT DO NOTHING"))
        conn.execute(text("INSERT INTO products (code, name) VALUES ('TEST_PROD_999', 'Test Product') ON CONFLICT DO NOTHING"))
        conn.execute(text("INSERT INTO sales_lines (document_id, product_code, quantity, amount) VALUES (999999999, 'TEST_PROD_999', 1, 500) ON CONFLICT DO NOTHING"))
    
    yield

    # Cleanup после тестов
    with engine.begin() as conn:
        conn.execute(text("DELETE FROM sales_lines WHERE document_id = 999999999"))
        conn.execute(text("DELETE FROM documents WHERE client_code = 'TEST_999999' OR id = 999999999"))
        conn.execute(text("DELETE FROM products WHERE code = 'TEST_PROD_999'"))
        conn.execute(text("DELETE FROM clients WHERE code = 'TEST_999999'"))
