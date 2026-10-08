-- ============================================================
-- МИГРАЦИЯ 62: Расширение get_client_size_matrix (product_category)
-- Дата: 2026-10-07
-- ЦЕЛЬ: Добавить поле product_category (round/prof/welded/sheet)
--       Разбить каталог по 4 категориям продукции:
--       - round: круглые бесшовные трубы (Ø × t)
--       - prof: профильные трубы (A×B × S)
--       - welded: электросварные трубы (Ø × t)
--       - sheet: листовой прокат (s × Ш×Д)
-- ============================================================

-- БЭКАП
CREATE TABLE IF NOT EXISTS backup_functions_20261007_size_matrix_v2 AS
SELECT proname, pg_get_functiondef(oid) AS definition, now() AS backup_at
FROM pg_proc
WHERE proname IN ('get_client_size_matrix', 'get_client_size_matrix_kpi');

-- ═══════════════════════════════════════════════════════════
-- ПАТЧ get_client_size_matrix — добавить product_category
-- ═══════════════════════════════════════════════════════════

DROP FUNCTION IF EXISTS public.get_client_size_matrix_kpi(text, integer);
DROP FUNCTION IF EXISTS public.get_client_size_matrix(text, integer);

CREATE OR REPLACE FUNCTION public.get_client_size_matrix(p_client_code text, p_year integer DEFAULT 2026)
RETURNS TABLE(
    size_key text,
    size_display text,
    is_prof boolean,
    product_category varchar,     -- round / prof / welded / sheet
    diameter numeric,
    prof_w numeric,
    prof_h numeric,
    wall numeric,
    catalog_products_count integer,
    stock_total numeric,
    has_stock boolean,
    client_bought boolean,
    client_revenue numeric,
    client_quantity numeric,
    client_invoices_count bigint
)
LANGUAGE plpgsql
STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH pipe_catalog AS (
        SELECT
            p.code AS product_code,
            p.name AS product_name,
            COALESCE(p.in_stock_balance, 0)::NUMERIC AS stock,
            ppa.diameter,
            ppa.wall,
            ppa.prof_w,
            ppa.prof_h,
            ppa.is_prof,
            CASE
                WHEN p.name ~* 'сварн|электросварн|електрозварн|ГОСТ 10704|ГОСТ 10705|ГОСТ 20295'
                    THEN 'welded_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                ELSE NULL
            END AS size_key,
            CASE
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT || '×' || ppa.wall::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.diameter::TEXT || '×' || ppa.wall::TEXT
                ELSE NULL
            END AS size_display,
            CASE
                WHEN p.name ~* 'сварн|электросварн|електрозварн|ГОСТ 10704|ГОСТ 10705|ГОСТ 20295' THEN 'welded'
                WHEN ppa.is_prof = TRUE THEN 'prof'
                WHEN ppa.is_prof = FALSE AND ppa.diameter IS NOT NULL THEN 'round'
                ELSE NULL
            END::varchar AS product_category
        FROM products p
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE COALESCE(p.is_service, FALSE) = FALSE
          AND (
              (NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL)
              OR (ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL)
          )
          AND p.name !~* 'лист|ДСТУ 8540|ГОСТ 19903|ЛСТ'
    ),
    sheet_catalog AS (
        SELECT
            p.code AS product_code,
            p.name AS product_name,
            COALESCE(p.in_stock_balance, 0)::NUMERIC AS stock,
            NULL::NUMERIC AS diameter,
            sh.wall,
            sh.prof_w,
            sh.prof_h,
            FALSE AS is_prof,
            'sheet_' || sh.wall::TEXT || 'x' || sh.prof_w::TEXT || 'x' || sh.prof_h::TEXT AS size_key,
            sh.wall::TEXT || '×' || sh.prof_w::TEXT || '×' || sh.prof_h::TEXT AS size_display,
            'sheet'::varchar AS product_category
        FROM products p
        CROSS JOIN LATERAL (
            SELECT
                CASE 
                    WHEN m3 IS NOT NULL THEN replace(m3[1], ',', '.')::numeric
                    WHEN m1 IS NOT NULL THEN replace(m1[1], ',', '.')::numeric
                    WHEN m2 IS NOT NULL THEN replace(m2[1], ',', '.')::numeric
                    ELSE NULL
                END AS wall,
                CASE 
                    WHEN m3 IS NOT NULL THEN replace(m3[2], ',', '.')::numeric
                    WHEN m2 IS NOT NULL THEN replace(m2[1], ',', '.')::numeric
                    ELSE 1500::numeric
                END AS prof_w,
                CASE 
                    WHEN m3 IS NOT NULL THEN replace(m3[3], ',', '.')::numeric
                    WHEN m2 IS NOT NULL THEN replace(m2[2], ',', '.')::numeric
                    ELSE 6000::numeric
                END AS prof_h
            FROM (
                SELECT
                    regexp_match(p.name, '(\d+(?:[.,]\d+)?)\s*[xх×*]\s*(\d+(?:[.,]\d+)?)\s*[xх×*]\s*(\d+(?:[.,]\d+)?)') as m3,
                    regexp_match(p.name, '(\d+(?:[.,]\d+)?)\s*[xх×*]\s*(\d+(?:[.,]\d+)?)') as m2,
                    regexp_match(p.name, '(?i)(?:б-|б\s+|г/к\s*|лист\s+)(\d+(?:[.,]\d+)?)\s*(?:мм)?') as m1
            ) sub
        ) sh
        WHERE COALESCE(p.is_service, FALSE) = FALSE
          AND (p.name ~* 'лист|ДСТУ 8540|ГОСТ 19903|ЛСТ')
          AND p.name !~* 'машинко|корпус'
          AND sh.wall IS NOT NULL
    ),
    all_catalog AS (
        SELECT * FROM pipe_catalog
        UNION ALL
        SELECT * FROM sheet_catalog
    ),
    catalog_agg AS (
        SELECT
            cs.size_key,
            MAX(cs.size_display) AS size_display,
            BOOL_OR(cs.is_prof) AS is_prof,
            MAX(cs.product_category)::varchar AS product_category,
            MAX(cs.diameter) AS diameter,
            MAX(cs.prof_w) AS prof_w,
            MAX(cs.prof_h) AS prof_h,
            MAX(cs.wall) AS wall,
            COUNT(DISTINCT cs.product_code)::INT AS catalog_products_count,
            SUM(cs.stock)::NUMERIC AS stock_total,
            BOOL_OR(cs.stock > 0)::BOOLEAN AS has_stock
        FROM all_catalog cs
        GROUP BY cs.size_key
    ),
    client_sales AS (
        SELECT
            cs.size_key,
            COALESCE(SUM(sl.amount), 0)::NUMERIC AS client_revenue,
            COALESCE(SUM(sl.quantity), 0)::NUMERIC AS client_quantity,
            COUNT(DISTINCT d.id)::BIGINT AS client_invoices_count
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN all_catalog cs ON cs.product_code = sl.product_code
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND sl.amount > 0
        GROUP BY cs.size_key
    )
    SELECT
        ca.size_key,
        ca.size_display,
        ca.is_prof,
        ca.product_category::varchar,
        ca.diameter,
        ca.prof_w,
        ca.prof_h,
        ca.wall,
        ca.catalog_products_count,
        COALESCE(ca.stock_total, 0)::NUMERIC AS stock_total,
        COALESCE(ca.has_stock, FALSE)::BOOLEAN AS has_stock,
        (cls.client_revenue IS NOT NULL AND cls.client_revenue > 0)::BOOLEAN AS client_bought,
        COALESCE(cls.client_revenue, 0)::NUMERIC AS client_revenue,
        COALESCE(cls.client_quantity, 0)::NUMERIC AS client_quantity,
        COALESCE(cls.client_invoices_count, 0)::BIGINT AS client_invoices_count
    FROM catalog_agg ca
    LEFT JOIN client_sales cls ON cls.size_key = ca.size_key
    ORDER BY ca.product_category, ca.is_prof, ca.diameter, ca.prof_w, ca.prof_h, ca.wall;
END;
$function$;

-- ═══════════════════════════════════════════════════════════
-- ПАТЧ get_client_size_matrix_kpi — разбивка по 4 категориям
-- ═══════════════════════════════════════════════════════════

CREATE OR REPLACE FUNCTION public.get_client_size_matrix_kpi(p_client_code text, p_year integer DEFAULT 2026)
RETURNS TABLE(
    total_catalog_products bigint,
    total_catalog_sizes bigint,
    round_sizes bigint,
    prof_sizes bigint,
    welded_sizes bigint,
    sheet_sizes bigint,
    client_bought_sizes bigint,
    client_round_sizes bigint,
    client_prof_sizes bigint,
    client_welded_sizes bigint,
    client_sheet_sizes bigint,
    client_revenue numeric,
    client_quantity numeric,
    stock_sizes bigint
)
LANGUAGE sql
STABLE
AS $function$
    WITH matrix AS (
        SELECT * FROM get_client_size_matrix(p_client_code, p_year)
    ),
    catalog AS (
        SELECT COUNT(*)::BIGINT AS total_catalog_products FROM products WHERE COALESCE(is_service, FALSE) = FALSE
    )
    SELECT
        (SELECT total_catalog_products FROM catalog)::bigint,
        COUNT(*)::bigint AS total_catalog_sizes,
        COUNT(*) FILTER (WHERE product_category = 'round')::bigint AS round_sizes,
        COUNT(*) FILTER (WHERE product_category = 'prof')::bigint AS prof_sizes,
        COUNT(*) FILTER (WHERE product_category = 'welded')::bigint AS welded_sizes,
        COUNT(*) FILTER (WHERE product_category = 'sheet')::bigint AS sheet_sizes,
        COUNT(*) FILTER (WHERE client_bought)::bigint AS client_bought_sizes,
        COUNT(*) FILTER (WHERE client_bought AND product_category = 'round')::bigint AS client_round_sizes,
        COUNT(*) FILTER (WHERE client_bought AND product_category = 'prof')::bigint AS client_prof_sizes,
        COUNT(*) FILTER (WHERE client_bought AND product_category = 'welded')::bigint AS client_welded_sizes,
        COUNT(*) FILTER (WHERE client_bought AND product_category = 'sheet')::bigint AS client_sheet_sizes,
        ROUND(COALESCE(SUM(client_revenue), 0), 2)::numeric AS client_revenue,
        ROUND(COALESCE(SUM(client_quantity), 0), 3)::numeric AS client_quantity,
        COUNT(*) FILTER (WHERE has_stock)::bigint AS stock_sizes
    FROM matrix;
$function$;

COMMENT ON FUNCTION get_client_size_matrix(text, integer) IS
'Матрица типоразмеров компании с разбивкой по 4 категориям (round, prof, welded, sheet) и подсветкой покупок клиента';

COMMENT ON FUNCTION get_client_size_matrix_kpi(text, integer) IS
'Сводные KPI для матрицы клиента с детализацией по 4 категориям продукции';
