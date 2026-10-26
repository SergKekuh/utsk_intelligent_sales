-- МИГРАЦИЯ 69: Таблица порогов и индексов дефлятора ABC-анализа (abc_thresholds)
-- Дата: 2026-10-20
-- ОТКАТ: DROP TABLE IF EXISTS abc_thresholds;

BEGIN;

CREATE TABLE IF NOT EXISTS abc_thresholds (
    id SERIAL PRIMARY KEY,
    year INTEGER NOT NULL,
    category VARCHAR(10) NOT NULL,
    min_amount NUMERIC(15,2),
    max_amount NUMERIC(15,2),
    price_index NUMERIC(10,4) DEFAULT 1.0,
    UNIQUE(year, category)
);

INSERT INTO abc_thresholds (year, category, min_amount, max_amount, price_index) VALUES
    -- 2026 (Индекс 2.94)
    (2026, 'A1', 3000000.00, NULL,       2.9400),
    (2026, 'A2', 2000000.00, 3000000.00, 2.9400),
    (2026, 'A3', 1500000.00, 2000000.00, 2.9400),
    (2026, 'B1', 1000000.00, 1500000.00, 2.9400),
    (2026, 'B2',  500000.00, 1000000.00, 2.9400),
    (2026, 'C1',  150000.00,  500000.00, 2.9400),
    (2026, 'C2',       0.00,  150000.00, 2.9400),
    -- 2025 (Индекс 2.90)
    (2025, 'A1', 3000000.00, NULL,       2.9000),
    (2025, 'A2', 2000000.00, 3000000.00, 2.9000),
    (2025, 'A3', 1500000.00, 2000000.00, 2.9000),
    (2025, 'B1', 1000000.00, 1500000.00, 2.9000),
    (2025, 'B2',  500000.00, 1000000.00, 2.9000),
    (2025, 'C1',  150000.00,  500000.00, 2.9000),
    (2025, 'C2',       0.00,  150000.00, 2.9000),
    -- 2024 (Индекс 2.83)
    (2024, 'A1', 3000000.00, NULL,       2.8300),
    (2024, 'A2', 2000000.00, 3000000.00, 2.8300),
    (2024, 'A3', 1500000.00, 2000000.00, 2.8300),
    (2024, 'B1', 1000000.00, 1500000.00, 2.8300),
    (2024, 'B2',  500000.00, 1000000.00, 2.8300),
    (2024, 'C1',  150000.00,  500000.00, 2.8300),
    (2024, 'C2',       0.00,  150000.00, 2.8300)
ON CONFLICT (year, category) DO UPDATE SET
    min_amount = EXCLUDED.min_amount,
    max_amount = EXCLUDED.max_amount,
    price_index = EXCLUDED.price_index;

COMMIT;
