-- ============================================================
-- МИГРАЦИЯ 60: get_client_size_matrix & get_client_size_matrix_kpi
-- Дата: 2026-10-07
--
-- ЦЕЛЬ:
--   1. get_client_size_matrix(p_client_code, p_year):
--      Возвращает ВСЮ матрицу типоразмеров труб компании (круглые + профильные),
--      объединённую с фактическими покупками конкретного клиента за указанный год.
--      Позволяет клиенту/менеджеру видеть весь ассортимент и то, что клиент уже покупал.
--
--   2. get_client_size_matrix_kpi(p_client_code, p_year):
--      Сводные KPI: всего в каталоге, типоразмеров в каталоге (круглые/профильные),
--      куплено клиентом (типоразмеров, выручка, объем) и позиции с остатком на складе.
--
-- ОТКАТ:
--   DROP FUNCTION IF EXISTS get_client_size_matrix_kpi(TEXT, INT);
--   DROP FUNCTION IF EXISTS get_client_size_matrix(TEXT, INT);
-- ============================================================

-- 1. ОСНОВНАЯ ФУНКЦИЯ МАТРИЦЫ
DROP FUNCTION IF EXISTS get_client_size_matrix(TEXT, INT);

CREATE OR REPLACE FUNCTION get_client_size_matrix(
    p_client_code TEXT,
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    size_key TEXT,
    size_display TEXT,
    is_prof BOOLEAN,
    diameter NUMERIC,
    prof_w NUMERIC,
    prof_h NUMERIC,
    wall NUMERIC,
    catalog_products_count INT,
    stock_total NUMERIC,
    has_stock BOOLEAN,
    client_bought BOOLEAN,
    client_revenue NUMERIC,
    client_quantity NUMERIC,
    client_invoices_count BIGINT
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN QUERY
    WITH catalog_sizes AS (
        SELECT 
            p.code AS product_code,
            COALESCE(p.in_stock_balance, 0)::NUMERIC AS stock,
            ppa.diameter,
            ppa.wall,
            ppa.prof_w,
            ppa.prof_h,
            ppa.is_prof,
            CASE 
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
            END AS size_display
        FROM products p
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE COALESCE(p.is_service, FALSE) = FALSE
          AND (
              (NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL)
              OR (ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL)
          )
    ),
    catalog_agg AS (
        SELECT 
            cs.size_key,
            MAX(cs.size_display) AS size_display,
            BOOL_OR(cs.is_prof) AS is_prof,
            MAX(cs.diameter) AS diameter,
            MAX(cs.prof_w) AS prof_w,
            MAX(cs.prof_h) AS prof_h,
            MAX(cs.wall) AS wall,
            COUNT(DISTINCT cs.product_code)::INT AS catalog_products_count,
            SUM(cs.stock)::NUMERIC AS stock_total,
            BOOL_OR(cs.stock > 0)::BOOLEAN AS has_stock
        FROM catalog_sizes cs
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
        JOIN catalog_sizes cs ON cs.product_code = sl.product_code
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND sl.amount > 0
        GROUP BY cs.size_key
    )
    SELECT 
        ca.size_key,
        ca.size_display,
        ca.is_prof,
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
    ORDER BY ca.is_prof, ca.diameter, ca.prof_w, ca.prof_h, ca.wall;
END;
$$;

COMMENT ON FUNCTION get_client_size_matrix(TEXT, INT) IS
'Полная матрица типоразмеров компании с подсветкой покупок конкретного клиента за год.';


-- 2. СВОДНЫЕ KPI ДЛЯ МАТРИЦЫ КЛИЕНТА
DROP FUNCTION IF EXISTS get_client_size_matrix_kpi(TEXT, INT);

CREATE OR REPLACE FUNCTION get_client_size_matrix_kpi(
    p_client_code TEXT,
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    client_name VARCHAR,
    catalog_positions_total BIGINT,
    catalog_sizes_total BIGINT,
    catalog_round_sizes BIGINT,
    catalog_prof_sizes BIGINT,
    client_sizes_bought BIGINT,
    client_round_bought BIGINT,
    client_prof_bought BIGINT,
    client_revenue_total NUMERIC,
    client_quantity_total NUMERIC,
    sizes_in_stock_count BIGINT
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
    v_client_name VARCHAR;
    v_catalog_positions BIGINT;
BEGIN
    SELECT COALESCE(name, p_client_code) INTO v_client_name FROM clients WHERE code = p_client_code;
    SELECT COUNT(*)::BIGINT INTO v_catalog_positions FROM products;

    RETURN QUERY
    WITH matrix AS (
        SELECT * FROM get_client_size_matrix(p_client_code, p_year)
    )
    SELECT
        v_client_name,
        v_catalog_positions,
        COUNT(*)::BIGINT AS catalog_sizes_total,
        COUNT(CASE WHEN NOT is_prof THEN 1 END)::BIGINT AS catalog_round_sizes,
        COUNT(CASE WHEN is_prof THEN 1 END)::BIGINT AS catalog_prof_sizes,
        COUNT(CASE WHEN client_bought THEN 1 END)::BIGINT AS client_sizes_bought,
        COUNT(CASE WHEN NOT is_prof AND client_bought THEN 1 END)::BIGINT AS client_round_bought,
        COUNT(CASE WHEN is_prof AND client_bought THEN 1 END)::BIGINT AS client_prof_bought,
        COALESCE(SUM(client_revenue), 0)::NUMERIC AS client_revenue_total,
        COALESCE(SUM(client_quantity), 0)::NUMERIC AS client_quantity_total,
        COUNT(CASE WHEN has_stock THEN 1 END)::BIGINT AS sizes_in_stock_count
    FROM matrix;
END;
$$;

COMMENT ON FUNCTION get_client_size_matrix_kpi(TEXT, INT) IS
'Сводные KPI для матрицы типоразмеров клиента: каталог, покупки, склад.';
