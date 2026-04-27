#!/bin/bash

# =============================================================================
# СКРИПТ ПОЛНОЙ НАСТРОЙКИ БАЗЫ ДАННЫХ UTSK v7.1
# (Расширение для размеров труб + ИМПОРТ 1С WIN1251 + Генерация связей)
# ИСПРАВЛЕННАЯ ВЕРСИЯ: все ошибки исправлены
# =============================================================================

set -e

# --- НАСТРОЙКИ ---
DB_HOST="localhost"
DB_PORT="5432"
DB_NAME="bd_intelligent_sales"
DB_USER="postgres"
export PGPASSWORD="root"

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="/home/serg/Documents/SQL_postgresql/Intelligent_Sales"
SQL_DIR="$PROJECT_DIR/SQL"

echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}     НАСТРОЙКА БАЗЫ ДАННЫХ UTSK v7.1 (ИСПРАВЛЕННАЯ)${NC}"
echo -e "${BLUE}======================================================================${NC}"
echo ""

# Проверка подключения
echo -e "${YELLOW}📡 Проверка подключения к PostgreSQL...${NC}"
if ! psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -c "SELECT 1" > /dev/null 2>&1; then
    echo -e "${RED}❌ Не удалось подключиться к PostgreSQL!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Подключение успешно${NC}"
echo ""

mkdir -p "$SQL_DIR"
cd "$SQL_DIR"

# =============================================================================
# ШАГ 1: РАСШИРЕНИЕ ТАБЛИЦЫ products
# =============================================================================
echo -e "${BLUE}  ШАГ 1/6: РАСШИРЕНИЕ ТАБЛИЦЫ products${NC}"

cat > "$SQL_DIR/01_extend_products.sql" << 'SQLEOF'
BEGIN;
ALTER TABLE products ADD COLUMN IF NOT EXISTS diameter NUMERIC(10,2);
ALTER TABLE products ADD COLUMN IF NOT EXISTS wall_thickness NUMERIC(10,2);
ALTER TABLE products ADD COLUMN IF NOT EXISTS profile_width NUMERIC(10,2);
ALTER TABLE products ADD COLUMN IF NOT EXISTS profile_height NUMERIC(10,2);
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_profile BOOLEAN DEFAULT FALSE;
ALTER TABLE products ADD COLUMN IF NOT EXISTS standard_name VARCHAR(100);
ALTER TABLE products ADD COLUMN IF NOT EXISTS weight_per_meter NUMERIC(10,3);
ALTER TABLE products ADD COLUMN IF NOT EXISTS first_purchase_date DATE;
ALTER TABLE products ADD COLUMN IF NOT EXISTS last_purchase_date DATE;
ALTER TABLE products ADD COLUMN IF NOT EXISTS unit VARCHAR(20) DEFAULT 'т';
COMMIT;
SQLEOF
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_DIR/01_extend_products.sql" > /dev/null
echo -e "${GREEN}✓ Шаг 1 выполнен${NC}"

# =============================================================================
# ШАГ 2: ФУНКЦИЯ ПАРСИНГА НАЗВАНИЙ
# =============================================================================
echo -e "${BLUE}  ШАГ 2/6: СОЗДАНИЕ ФУНКЦИИ ПАРСИНГА НАЗВАНИЙ ТРУБ${NC}"

cat > "$SQL_DIR/02_parse_function.sql" << 'SQLEOF'
CREATE OR REPLACE FUNCTION parse_pipe_attributes(p_name VARCHAR)
RETURNS TABLE(
    diameter NUMERIC, wall NUMERIC, prof_w NUMERIC, prof_h NUMERIC,
    is_prof BOOLEAN, standard VARCHAR, weight_m NUMERIC
) AS $$
DECLARE
    dims TEXT[];
BEGIN
    standard := substring(p_name from '(ГОСТ\s*\d+[-\s]*\d*|ДСТУ\s*\d+[:\d]*|GB/T\s*\d+[:\d]*|EN\s*\d+[-\d]*)');
    
    IF p_name ~* 'проф|profile' THEN
        is_prof := TRUE;
        dims := regexp_matches(p_name, '(\d+(?:\.\d+)?)\s*[xх×]\s*(\d+(?:\.\d+)?)\s*[xх×]\s*(\d+(?:\.\d+)?)');
        IF dims IS NOT NULL THEN
            prof_w := dims[1]::NUMERIC;
            prof_h := dims[2]::NUMERIC;
            wall := dims[3]::NUMERIC;
            diameter := GREATEST(prof_w, prof_h);
        END IF;
    ELSE
        is_prof := FALSE;
        dims := regexp_matches(p_name, '(\d+(?:\.\d+)?)\s*[xх×]\s*(\d+(?:\.\d+)?)');
        IF dims IS NOT NULL THEN
            diameter := dims[1]::NUMERIC;
            wall := dims[2]::NUMERIC;
        END IF;
    END IF;
    
    IF diameter IS NOT NULL AND wall IS NOT NULL AND NOT is_prof THEN
        weight_m := ROUND((PI() * (diameter - wall) * wall * 7850 / 1000000)::NUMERIC, 3);
    END IF;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;
SQLEOF
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_DIR/02_parse_function.sql" > /dev/null
echo -e "${GREEN}✓ Шаг 2 выполнен${NC}"

# =============================================================================
# ШАГ 3: ЗАПОЛНЕНИЕ РАЗМЕРОВ (ИСПРАВЛЕННЫЙ)
# =============================================================================
echo -e "${BLUE}  ШАГ 3/6: ЗАПОЛНЕНИЕ РАЗМЕРОВ СУЩЕСТВУЮЩИХ ТОВАРОВ${NC}"

cat > "$SQL_DIR/03_fill_dimensions.sql" << 'SQLEOF'
BEGIN;

UPDATE products p
SET 
    diameter = sub.diameter,
    wall_thickness = sub.wall,
    profile_width = sub.prof_w,
    profile_height = sub.prof_h,
    is_profile = sub.is_prof,
    standard_name = sub.standard,
    weight_per_meter = COALESCE(p.weight_per_meter, sub.weight_m)
FROM (
    SELECT 
        p2.code,
        dims.diameter, dims.wall, dims.prof_w, dims.prof_h,
        dims.is_prof, dims.standard, dims.weight_m
    FROM products p2
    CROSS JOIN LATERAL parse_pipe_attributes(p2.name) dims
    WHERE dims.diameter IS NOT NULL
) sub
WHERE p.code = sub.code AND p.diameter IS NULL;

UPDATE products p
SET 
    first_purchase_date = sub.first_date,
    last_purchase_date = sub.last_date
FROM (
    SELECT sl.product_code,
        MIN(d.invoice_date) AS first_date,
        MAX(d.invoice_date) AS last_date
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    GROUP BY sl.product_code
) sub
WHERE p.code = sub.product_code;

UPDATE products 
SET is_new_arrival = TRUE 
WHERE is_new_arrival = FALSE 
  AND (first_purchase_date IS NULL OR created_at >= CURRENT_DATE - INTERVAL '90 days');

COMMIT;
SQLEOF
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_DIR/03_fill_dimensions.sql" > /dev/null
echo -e "${GREEN}✓ Шаг 3 выполнен${NC}"

# =============================================================================
# ШАГ 4: ТАБЛИЦА СВЯЗЕЙ
# =============================================================================
echo -e "${BLUE}  ШАГ 4/6: СОЗДАНИЕ ТАБЛИЦЫ product_similarities${NC}"

cat > "$SQL_DIR/04_similarities.sql" << 'SQLEOF'
BEGIN;
CREATE TABLE IF NOT EXISTS product_similarities (
    id BIGSERIAL PRIMARY KEY,
    source_product_code VARCHAR(50) NOT NULL REFERENCES products(code) ON DELETE CASCADE,
    similar_product_code VARCHAR(50) NOT NULL REFERENCES products(code) ON DELETE CASCADE,
    similarity_score DECIMAL(5,2) DEFAULT 0,
    match_type VARCHAR(50) NOT NULL,
    source_diameter NUMERIC(10,2), source_wall NUMERIC(10,2),
    similar_diameter NUMERIC(10,2), similar_wall NUMERIC(10,2),
    UNIQUE(source_product_code, similar_product_code)
);
COMMIT;
SQLEOF
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_DIR/04_similarities.sql" > /dev/null
echo -e "${GREEN}✓ Шаг 4 выполнен${NC}"

# =============================================================================
# ШАГ 5: ИМПОРТ CSV ИЗ 1С (ИСПРАВЛЕННЫЙ)
# =============================================================================
echo -e "${BLUE}  ШАГ 5/6: ИМПОРТ ДАННЫХ ИЗ 1С (CSV WIN1251)${NC}"

CSV_FILE="$SQL_DIR/nomenclature_from_1c.csv"

if [ -f "$CSV_FILE" ]; then
    echo -e "${YELLOW}📄 Найден CSV-файл, выполняем импорт...${NC}"
    
    cat > "$SQL_DIR/05_import_1c_csv.sql" << 'SQLEOF'
BEGIN;

CREATE TEMP TABLE tmp_1c_products (
    code VARCHAR(50), name VARCHAR(255),
    in_stock_balance VARCHAR(50), created_at VARCHAR(20), is_weight VARCHAR(10)
);

\copy tmp_1c_products FROM 'nomenclature_from_1c.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'WIN1251');

UPDATE products p
SET in_stock_balance = tmp.in_stock_balance::NUMERIC
FROM tmp_1c_products tmp
WHERE p.code = tmp.code;

INSERT INTO products (code, name, in_stock_balance, created_at, is_new_arrival)
SELECT tmp.code, LEFT(tmp.name, 255), tmp.in_stock_balance::NUMERIC,
       TO_DATE(tmp.created_at, 'YYYY-MM-DD'), TRUE
FROM tmp_1c_products tmp
WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.code = tmp.code);

UPDATE products p
SET 
    diameter = sub.diameter, wall_thickness = sub.wall,
    profile_width = sub.prof_w, profile_height = sub.prof_h,
    is_profile = sub.is_prof, standard_name = sub.standard,
    weight_per_meter = COALESCE(p.weight_per_meter, sub.weight_m)
FROM (
    SELECT p2.code, dims.diameter, dims.wall, dims.prof_w, dims.prof_h,
           dims.is_prof, dims.standard, dims.weight_m
    FROM products p2
    CROSS JOIN LATERAL parse_pipe_attributes(p2.name) dims
    WHERE dims.diameter IS NOT NULL
) sub
WHERE p.code = sub.code AND p.diameter IS NULL;

COMMIT;
SQLEOF

    psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_DIR/05_import_1c_csv.sql"
    echo -e "${GREEN}✓ Шаг 5 выполнен!${NC}"
else
    echo -e "${RED}❌ CSV-файл не найден: $CSV_FILE${NC}"
    echo -e "${YELLOW}Положите nomenclature_from_1c.csv в папку $SQL_DIR и запустите скрипт заново.${NC}"
fi
echo ""

# =============================================================================
# ШАГ 6: ГЕНЕРАЦИЯ СВЯЗЕЙ ПОХОЖИХ ТРУБ
# =============================================================================
echo -e "${BLUE}  ШАГ 6/6: ГЕНЕРАЦИЯ СВЯЗЕЙ ПОХОЖИХ ТРУБ${NC}"

cat > "$SQL_DIR/06_generate_links.sql" << 'SQLEOF'
BEGIN;

DELETE FROM product_similarities;

WITH pipes AS (
    SELECT code, diameter, wall_thickness, is_profile
    FROM products WHERE diameter IS NOT NULL AND COALESCE(in_stock_balance, 0) > 0
)
INSERT INTO product_similarities (
    source_product_code, similar_product_code, similarity_score, match_type,
    source_diameter, source_wall, similar_diameter, similar_wall
)
SELECT 
    a.code, b.code,
    ROUND(100 - LEAST(ABS(a.diameter - b.diameter) * 1.5, 40) - LEAST(ABS(a.wall_thickness - b.wall_thickness) * 8, 40) - CASE WHEN a.is_profile != b.is_profile THEN 30 ELSE 0 END, 2) AS score,
    CASE 
        WHEN a.is_profile = b.is_profile AND ABS(a.diameter - b.diameter) < 2 AND ABS(a.wall_thickness - b.wall_thickness) > 0 THEN 'same_diameter'
        WHEN a.is_profile = b.is_profile AND ABS(a.diameter - b.diameter) > 0 AND ABS(a.wall_thickness - b.wall_thickness) < 0.5 THEN 'same_wall'
        WHEN a.is_profile = b.is_profile AND ABS(a.diameter - b.diameter) <= 20 THEN 'same_profile'
        WHEN b.diameter >= a.diameter AND b.wall_thickness >= a.wall_thickness THEN 'upgrade'
        WHEN b.diameter <= a.diameter AND b.wall_thickness <= a.wall_thickness THEN 'downgrade'
        ELSE 'similar'
    END,
    a.diameter, a.wall_thickness, b.diameter, b.wall_thickness
FROM pipes a CROSS JOIN pipes b
WHERE a.code != b.code AND ABS(a.diameter - b.diameter) <= 30 AND ABS(a.wall_thickness - b.wall_thickness) <= 4
  AND ROUND(100 - LEAST(ABS(a.diameter - b.diameter) * 1.5, 40) - LEAST(ABS(a.wall_thickness - b.wall_thickness) * 8, 40) - CASE WHEN a.is_profile != b.is_profile THEN 30 ELSE 0 END, 2) > 50
ON CONFLICT DO NOTHING;

COMMIT;
SQLEOF
psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" -f "$SQL_DIR/06_generate_links.sql" > /dev/null
echo -e "${GREEN}✓ Шаг 6 выполнен${NC}"
echo ""

# =============================================================================
# ИТОГОВАЯ СТАТИСТИКА (ИСПРАВЛЕННАЯ)
# =============================================================================
echo -e "${BLUE}======================================================================${NC}"
echo -e "${BLUE}  ИТОГОВАЯ СТАТИСТИКА${NC}"
echo -e "${BLUE}======================================================================${NC}"

psql -h "$DB_HOST" -U "$DB_USER" -d "$DB_NAME" << 'SQLEOF'
SELECT 'ТОВАРЫ' AS категория, COUNT(*) AS всего FROM products
UNION ALL
SELECT 'С размерами', COUNT(*) FROM products WHERE diameter IS NOT NULL
UNION ALL
SELECT 'Профильных', COUNT(*) FROM products WHERE is_profile = TRUE;

SELECT 'СВЯЗИ ПОХОЖИХ ТРУБ' AS категория, COUNT(*) AS всего FROM product_similarities;
SELECT match_type AS тип_связи, COUNT(*) AS количество FROM product_similarities GROUP BY match_type ORDER BY COUNT(*) DESC;
SQLEOF

echo ""
echo -e "${GREEN}======================================================================${NC}"
echo -e "${GREEN}                    ✅ ВСЕ ГОТОВО!${NC}"
echo -e "${GREEN}======================================================================${NC}"
echo ""
echo -e "${YELLOW}📋 Дальнейшие действия:${NC}"
echo -e "   cd $PROJECT_DIR/utsk_intelligent_sales"
echo -e "   cmake --build build -j \$(nproc)"
echo -e "   ./build/utsk_console"
