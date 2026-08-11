-- ============================================================================
-- UTSK Intelligent Sales — Миграция 04: 4 Функции ML-Рекомендаций
-- ============================================================================

-- 1. Функция 1: Сопутствующие товары (Cross-sell) по категориям труб
CREATE OR REPLACE FUNCTION public.get_client_cross_sell_pipes(
    p_client_code VARCHAR
)
RETURNS TABLE(
    product_code VARCHAR,
    product_name VARCHAR,
    reason TEXT,
    in_stock NUMERIC
)
LANGUAGE plpgsql
STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH pipe_categories AS (
        SELECT code, name, COALESCE(in_stock_balance, 0) AS in_stock_balance,
            CASE 
                WHEN name ILIKE '%проф%' OR name ILIKE '%квадрат%' OR name ILIKE '%прямокут%' THEN 'Профильная труба'
                WHEN name ILIKE '%електрозвар%' OR name ILIKE '%звар%' OR name ILIKE '%шов%' THEN 'Сварная труба'
                WHEN name ILIKE '%труб%' THEN 'Круглая труба'
                ELSE 'Другие'
            END AS pipe_type
        FROM products 
        WHERE COALESCE(in_stock_balance, 0) > 0 AND COALESCE(is_service, FALSE) = FALSE
    ),
    client_purchased AS (
        SELECT DISTINCT sl.product_code
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        WHERE d.client_code = p_client_code
    )
    SELECT 
        pc.code::VARCHAR,
        pc.name::VARCHAR,
        (CASE WHEN cp.product_code IS NOT NULL THEN 'Ранее покупали (' || pc.pipe_type || ')' ELSE 'Сопутствующий товар (' || pc.pipe_type || ')' END)::TEXT,
        pc.in_stock_balance::NUMERIC
    FROM pipe_categories pc
    LEFT JOIN client_purchased cp ON pc.code = cp.product_code
    WHERE pc.pipe_type IN ('Сварная труба', 'Профильная труба', 'Круглая труба')
    ORDER BY CASE WHEN cp.product_code IS NOT NULL THEN 1 ELSE 2 END, RANDOM()
    LIMIT 5;
END;
$function$;

-- 2. Функция 2: Похожие типоразмеры
CREATE OR REPLACE FUNCTION public.get_client_similar_sizes(
    p_client_code VARCHAR
)
RETURNS TABLE(
    product_code VARCHAR,
    product_name VARCHAR,
    diameter NUMERIC,
    wall_thickness NUMERIC,
    reason TEXT,
    in_stock NUMERIC
)
LANGUAGE plpgsql
STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH client_top_sizes AS (
        SELECT p.diameter, p.wall_thickness, p.standard_name, COUNT(DISTINCT d.id) AS purchase_count
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON sl.product_code = p.code
        WHERE d.client_code = p_client_code AND p.diameter IS NOT NULL AND p.diameter > 0
        GROUP BY p.diameter, p.wall_thickness, p.standard_name
        ORDER BY purchase_count DESC
        LIMIT 5
    ),
    similar_products AS (
        SELECT DISTINCT 
            p.code, p.name, p.diameter, p.wall_thickness, 
            COALESCE(p.in_stock_balance, 0) AS in_stock,
            ABS(p.diameter - cts.diameter) AS diam_diff,
            ABS(p.wall_thickness - cts.wall_thickness) AS wall_diff
        FROM products p
        CROSS JOIN client_top_sizes cts
        WHERE p.diameter BETWEEN cts.diameter * 0.85 AND cts.diameter * 1.15
          AND p.wall_thickness BETWEEN cts.wall_thickness * 0.8 AND cts.wall_thickness * 1.2
          AND COALESCE(p.in_stock_balance, 0) > 0
          AND COALESCE(p.is_service, FALSE) = FALSE
          AND p.code NOT IN (
              SELECT DISTINCT sl2.product_code FROM sales_lines sl2
              JOIN documents d2 ON sl2.document_id = d2.id WHERE d2.client_code = p_client_code
          )
    )
    SELECT 
        sp.code::VARCHAR,
        sp.name::VARCHAR,
        sp.diameter::NUMERIC,
        sp.wall_thickness::NUMERIC,
        ('Ближайший типоразмер (⌀' || sp.diameter || 'х' || sp.wall_thickness || ')')::TEXT,
        sp.in_stock::NUMERIC
    FROM similar_products sp
    ORDER BY (sp.diam_diff + sp.wall_diff) ASC
    LIMIT 5;
END;
$function$;

-- 3. Функция 3: Популярные товары в сегменте
CREATE OR REPLACE FUNCTION public.get_client_direction_variety(
    p_client_code VARCHAR
)
RETURNS TABLE(
    product_code VARCHAR,
    product_name VARCHAR,
    popularity BIGINT,
    reason TEXT,
    in_stock NUMERIC
)
LANGUAGE plpgsql
STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.code::VARCHAR,
        p.name::VARCHAR,
        COUNT(DISTINCT d.id)::BIGINT,
        'Топ продаж 2026'::TEXT,
        COALESCE(p.in_stock_balance, 0)::NUMERIC
    FROM products p
    JOIN sales_lines sl ON sl.product_code = p.code
    JOIN documents d ON d.id = sl.document_id
    JOIN client_year_activity cya ON d.client_code = cya.client_code 
        AND cya.sales_year = EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER 
        AND cya.is_active = TRUE
    WHERE COALESCE(p.is_service, FALSE) = FALSE
      AND COALESCE(p.in_stock_balance, 0) > 0
      AND p.code NOT IN (
          SELECT DISTINCT sl2.product_code FROM sales_lines sl2
          JOIN documents d2 ON sl2.document_id = d2.id WHERE d2.client_code = p_client_code
      )
    GROUP BY p.code, p.name, p.in_stock_balance
    ORDER BY COUNT(DISTINCT d.id) DESC
    LIMIT 5;
END;
$function$;

-- 4. Функция 4: Fallback — популярные типоразмеры на складе
CREATE OR REPLACE FUNCTION public.get_client_similar_fallback(
    p_client_code VARCHAR
)
RETURNS TABLE(
    product_code VARCHAR,
    product_name VARCHAR,
    diameter NUMERIC,
    wall_thickness NUMERIC,
    reason TEXT,
    in_stock NUMERIC
)
LANGUAGE plpgsql
STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.code::VARCHAR,
        p.name::VARCHAR,
        p.diameter::NUMERIC,
        p.wall_thickness::NUMERIC,
        'Аналогичный популярный типоразмер'::TEXT,
        COALESCE(p.in_stock_balance, 0)::NUMERIC
    FROM products p
    WHERE COALESCE(p.in_stock_balance, 0) > 0 
      AND COALESCE(p.is_service, FALSE) = FALSE
      AND p.code NOT IN (
          SELECT DISTINCT sl2.product_code FROM sales_lines sl2 
          JOIN documents d2 ON sl2.document_id = d2.id WHERE d2.client_code = p_client_code
      )
    ORDER BY COALESCE(p.in_stock_balance, 0) DESC
    LIMIT 10;
END;
$function$;
