-- ============================================================
-- ФУНКЦИЯ: get_all_sizes_for_client(p_client_code, p_year)
-- Все размеры, которые клиент покупал за год
-- ============================================================

CREATE OR REPLACE FUNCTION get_all_sizes_for_client(
    p_client_code TEXT,
    p_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT
)
RETURNS TABLE(
    size_key TEXT,
    size_display TEXT,
    pipe_type TEXT,             -- 'round' | 'square' | 'rect'
    pipe_type_ua TEXT,          -- 'Круглая труба' / ...
    display_name TEXT,          -- 'Круглая труба 76×5'
    purchase_count BIGINT,      -- накладных с этим размером
    revenue NUMERIC,            -- выручка по размеру
    pct_of_client_total NUMERIC,-- % от бюджета клиента
    stock_balance_total NUMERIC,-- сумма остатков по всем ГОСТ/сталь
    products_count INT,         -- сколько уникальных товаров (ГОСТ × сталь)
    has_stock BOOLEAN           -- есть ли хоть 1 товар размера на складе
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
    v_total_revenue NUMERIC;
BEGIN
    -- Общая выручка клиента за год
    SELECT COALESCE(SUM(sl.amount), 0)
    INTO v_total_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.client_code = p_client_code
      AND EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    RETURN QUERY
    WITH parsed AS (
        SELECT 
            p.code AS product_code,
            COALESCE(p.in_stock_balance, 0)::NUMERIC AS stock,
            ppa.diameter, ppa.wall, ppa.prof_w, ppa.prof_h, ppa.is_prof,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                ELSE NULL
            END AS size_key,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT || '×' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.diameter::TEXT || '×' || ppa.wall::TEXT
                ELSE NULL
            END AS size_display,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w = ppa.prof_h THEN 'square'
                WHEN ppa.is_prof AND ppa.prof_w <> ppa.prof_h THEN 'rect'
                WHEN NOT ppa.is_prof THEN 'round'
                ELSE NULL
            END AS pipe_type,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w = ppa.prof_h THEN 'Квадратная труба'
                WHEN ppa.is_prof AND ppa.prof_w <> ppa.prof_h THEN 'Прямоугольная труба'
                WHEN NOT ppa.is_prof THEN 'Круглая труба'
                ELSE NULL
            END AS pipe_type_ua
        FROM products p
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE COALESCE(p.is_service, FALSE) = FALSE
    ),
    stock_per_size AS (
        SELECT 
            par.size_key,
            SUM(par.stock) AS stock_total,
            COUNT(*) AS products_count,
            BOOL_OR(par.stock > 0) AS has_stock
        FROM parsed par
        WHERE par.size_key IS NOT NULL
        GROUP BY par.size_key
    ),
    exploded AS (
        SELECT 
            d.id AS doc_id,
            sl.amount,
            par.size_key,
            par.size_display,
            par.pipe_type,
            par.pipe_type_ua,
            par.product_code
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN parsed par ON par.product_code = sl.product_code
        WHERE d.client_code = p_client_code
          AND sl.amount > 0
          AND par.size_key IS NOT NULL
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    ),
    by_size AS (
        SELECT 
            e.size_key,
            MAX(e.size_display) AS size_display,
            MAX(e.pipe_type) AS pipe_type,
            MAX(e.pipe_type_ua) AS pipe_type_ua,
            COUNT(DISTINCT e.doc_id) AS purchase_count,
            SUM(e.amount) AS revenue,
            COUNT(DISTINCT e.product_code) AS products_count_client
        FROM exploded e
        GROUP BY e.size_key
    )
    SELECT 
        bs.size_key,
        bs.size_display,
        bs.pipe_type,
        bs.pipe_type_ua,
        bs.pipe_type_ua || ' ' || bs.size_display AS display_name,
        bs.purchase_count,
        bs.revenue,
        ROUND(bs.revenue / NULLIF(v_total_revenue, 0) * 100, 2) AS pct_of_client_total,
        COALESCE(sps.stock_total, 0) AS stock_balance_total,
        COALESCE(sps.products_count, 0)::INT AS products_count,
        COALESCE(sps.has_stock, FALSE) AS has_stock
    FROM by_size bs
    LEFT JOIN stock_per_size sps ON sps.size_key = bs.size_key
    ORDER BY bs.revenue DESC;
END;
$$;

COMMENT ON FUNCTION get_all_sizes_for_client(TEXT, INT) IS 
    'Все размеры труб, купленные клиентом за год, с суммарными метриками и остатком.';
