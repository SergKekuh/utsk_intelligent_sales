-- ============================================================
-- МИГРАЦИЯ 66: Импорт сортамента ТУ
-- ============================================================

-- Добавление дополнительных геометрических характеристик (если отсутствуют)
ALTER TABLE squares_catalog ADD COLUMN IF NOT EXISTS wpl_x_cm3 NUMERIC(10, 3);
ALTER TABLE squares_catalog ADD COLUMN IF NOT EXISTS ik_cm4 NUMERIC(10, 3);
ALTER TABLE squares_catalog ADD COLUMN IF NOT EXISTS wk_cm3 NUMERIC(10, 3);

ALTER TABLE rectangles_catalog ADD COLUMN IF NOT EXISTS wpl_x_cm3 NUMERIC(10, 3);
ALTER TABLE rectangles_catalog ADD COLUMN IF NOT EXISTS wpl_y_cm3 NUMERIC(10, 3);
ALTER TABLE rectangles_catalog ADD COLUMN IF NOT EXISTS ik_cm4 NUMERIC(10, 3);
ALTER TABLE rectangles_catalog ADD COLUMN IF NOT EXISTS wk_cm3 NUMERIC(10, 3);

-- Очистка перед импортом
TRUNCATE squares_catalog;
TRUNCATE rectangles_catalog;

-- Импорт квадратов
\copy squares_catalog(h, t, area_cm2, ix_cm4, wx_cm3, wpl_x_cm3, ik_cm4, wk_cm3, weight_m) FROM 'date/squares.csv' WITH (FORMAT csv, HEADER true);

-- Импорт прямоугольников
\copy rectangles_catalog(h, b, t, area_cm2, ix_cm4, iy_cm4, wx_cm3, wy_cm3, wpl_x_cm3, wpl_y_cm3, ik_cm4, wk_cm3, weight_m) FROM 'date/rectangles.csv' WITH (FORMAT csv, HEADER true);

-- ПРОВЕРКА
SELECT 'Квадратов' AS tbl, COUNT(*) FROM squares_catalog
UNION ALL
SELECT 'Прямоугольников', COUNT(*) FROM rectangles_catalog;
