-- ============================================================
-- МИГРАЦИЯ 64: Таблицы для расчёта профилирования (ВНИТИ)
-- Дата: 2026-10-09
-- ============================================================

-- 1. squares_catalog
CREATE TABLE IF NOT EXISTS squares_catalog (
    id BIGSERIAL PRIMARY KEY,
    h INTEGER NOT NULL,
    t NUMERIC(5, 2) NOT NULL,
    area_cm2 NUMERIC(10, 3),
    ix_cm4 NUMERIC(10, 3),
    wx_cm3 NUMERIC(10, 3),
    weight_m NUMERIC(10, 3),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(h, t)
);
CREATE INDEX IF NOT EXISTS idx_squares_h_t ON squares_catalog(h, t);

-- 2. rectangles_catalog
CREATE TABLE IF NOT EXISTS rectangles_catalog (
    id BIGSERIAL PRIMARY KEY,
    h INTEGER NOT NULL,
    b INTEGER NOT NULL,
    t NUMERIC(5, 2) NOT NULL,
    area_cm2 NUMERIC(10, 3),
    ix_cm4 NUMERIC(10, 3),
    iy_cm4 NUMERIC(10, 3),
    wx_cm3 NUMERIC(10, 3),
    wy_cm3 NUMERIC(10, 3),
    weight_m NUMERIC(10, 3),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(h, b, t)
);
CREATE INDEX IF NOT EXISTS idx_rectangles_h_b_t ON rectangles_catalog(h, b, t);

-- 3. tu_coefficients
CREATE TABLE IF NOT EXISTS tu_coefficients (
    id BIGSERIAL PRIMARY KEY,
    t_min NUMERIC(5, 2),
    t_max NUMERIC(5, 2),
    k_min NUMERIC(6, 4),
    k_max NUMERIC(6, 4),
    r_min_coef NUMERIC(4, 2),
    r_max_coef NUMERIC(4, 2),
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(t_min, t_max)
);

INSERT INTO tu_coefficients (t_min, t_max, k_min, k_max, r_min_coef, r_max_coef)
VALUES
    (0.0, 6.0, 1.235, 1.258, 1.6, 2.4),
    (6.0, 10.0, 1.220, 1.246, 2.0, 3.0),
    (10.0, 999.0, 1.205, 1.235, 2.4, 3.6)
ON CONFLICT DO NOTHING;

SELECT 'Migration 64 applied' AS status;
SELECT * FROM tu_coefficients;
