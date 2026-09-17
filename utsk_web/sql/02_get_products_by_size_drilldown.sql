-- ============================================================
-- ИСПРАВЛЕННАЯ функция: get_products_by_size_for_client
-- Изменения:
--   1. Явный фильтр продаж по p_year
--   2. Скрываем 0-остатки (если не куплено клиентом в этом году)
--   3. Сортировка: purchased (куплено) → available (на складе)
-- ============================================================

CREATE OR REPLACE FUNCTION get_products_by_size_for_client(
    p_client_code TEXT,
    p_size_key TEXT,
    p_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT
)
RETURNS TABLE(
    product_code TEXT,
    product_name TEXT,
    standard TEXT,
    is_purchased BOOLEAN,
    purchase_count BIGINT,
    quantity NUMERIC,
    revenue NUMERIC,
    last_purchase_date DATE,
    days_since_last INT,
    stock_balance NUMERIC,
    is_prof BOOLEAN,
    size_display TEXT
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN QUERY
    WITH matching_products AS (
        SELECT 
            p.code::TEXT AS product_code,
            p.name::TEXT AS product_name,
            GREATEST(COALESCE(p.in_stock_balance, 0)::NUMERIC, 0) AS stock_balance,
            ppa.standard::TEXT AS standard,
            ppa.is_prof,
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
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                ELSE NULL
            END AS size_key
        FROM products p
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE COALESCE(p.is_service, FALSE) = FALSE
    ),
    client_purchases AS (
        SELECT 
            sl.product_code::TEXT AS product_code,
            COUNT(DISTINCT d.id) AS purchase_count,
            SUM(sl.quantity) AS quantity,
            SUM(sl.amount) AS revenue,
            MAX(d.invoice_date) AS last_purchase_date
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY sl.product_code
    )
    SELECT 
        mp.product_code,
        mp.product_name,
        mp.standard,
        (cp.product_code IS NOT NULL) AS is_purchased,
        COALESCE(cp.purchase_count, 0) AS purchase_count,
        COALESCE(cp.quantity, 0) AS quantity,
        COALESCE(cp.revenue, 0) AS revenue,
        cp.last_purchase_date,
        CASE 
            WHEN cp.last_purchase_date IS NOT NULL 
            THEN (CURRENT_DATE - cp.last_purchase_date::DATE)::INT
            ELSE NULL
        END AS days_since_last,
        mp.stock_balance,
        mp.is_prof,
        mp.size_display
    FROM matching_products mp
    LEFT JOIN client_purchases cp ON cp.product_code = mp.product_code
    WHERE mp.size_key = p_size_key
      AND (
          cp.product_code IS NOT NULL
          OR mp.stock_balance > 0
      )
    ORDER BY 
        (cp.product_code IS NOT NULL) DESC,
        COALESCE(cp.revenue, 0) DESC,
        mp.stock_balance DESC,
        mp.product_code;
END;
$$;

COMMENT ON FUNCTION get_products_by_size_for_client(TEXT, TEXT, INT) IS 
    'Drill-down по размеру. Скрывает 0-остатки, если клиент не покупал в этом году. Сортировка: purchased → available.';
