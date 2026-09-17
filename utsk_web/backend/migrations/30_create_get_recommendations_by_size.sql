-- ============================================================
-- 30_create_get_recommendations_by_size.sql
-- ФУНКЦИЯ: get_recommendations_by_size(p_client_code, p_limit)
-- ТОП покупок клиента, агрегированный по РАЗМЕРУ трубы
-- Использует parse_pipe_attributes (усиленную)
-- ============================================================

CREATE OR REPLACE FUNCTION get_recommendations_by_size(
    p_client_code TEXT,
    p_limit INT DEFAULT 5
)
RETURNS TABLE(
    size_key TEXT,                -- для ссылки: "round_76x4" / "square_40x40x3"
    size_display TEXT,            -- для UI: "76×4" / "40×40×3"
    pipe_type_ua TEXT,            -- "Круглая труба" / "Квадратная труба" / "Прямоугольная труба"
    display_name TEXT,            -- "Круглая труба 76×4"
    purchase_count_current BIGINT,
    revenue_current NUMERIC,
    pct_of_client_total NUMERIC,
    purchase_count_prev BIGINT,
    revenue_prev NUMERIC,
    stock_balance_total NUMERIC
)
LANGUAGE plpgsql STABLE AS $$
DECLARE
    v_year INT := EXTRACT(YEAR FROM CURRENT_DATE)::INT;
    v_total_revenue NUMERIC;
BEGIN
    -- 1. Общая товарная выручка клиента за текущий год (%)
    SELECT COALESCE(SUM(sl.amount), 0)
    INTO v_total_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.client_code = p_client_code
      AND EXTRACT(YEAR FROM d.invoice_date) = v_year
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    -- 2. Основной запрос
    RETURN QUERY
    WITH parsed AS (
        SELECT 
            p.code AS product_code,
            COALESCE(p.in_stock_balance, 0)::NUMERIC AS stock,
            ppa.diameter,
            ppa.wall,
            ppa.prof_w,
            ppa.prof_h,
            ppa.is_prof,
            -- Формируем ключ размера
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                ELSE NULL
            END AS size_key,
            -- Отображаемый размер
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT || '×' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.diameter::TEXT || '×' || ppa.wall::TEXT
                ELSE NULL
            END AS size_display,
            -- Тип трубы
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
    -- Остатки: сумма по уникальным product_code в разрезе размера
    stock_per_size AS (
        SELECT 
            par.size_key,
            SUM(par.stock) AS stock_total
        FROM parsed par
        WHERE par.size_key IS NOT NULL
        GROUP BY par.size_key
    ),
    -- Продажи клиента: разворачиваем на размеры
    exploded AS (
        SELECT 
            d.id AS doc_id,
            EXTRACT(YEAR FROM d.invoice_date)::INT AS yr,
            sl.amount,
            par.size_key,
            par.size_display,
            par.pipe_type_ua
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN parsed par ON par.product_code = sl.product_code
        WHERE d.client_code = p_client_code
          AND sl.amount > 0
          AND par.size_key IS NOT NULL
          AND EXTRACT(YEAR FROM d.invoice_date) BETWEEN (v_year - 1) AND v_year
    ),
    by_size AS (
        SELECT 
            e.size_key,
            MAX(e.size_display) AS size_display,
            MAX(e.pipe_type_ua) AS pipe_type_ua,
            COUNT(DISTINCT e.doc_id) FILTER (WHERE e.yr = v_year) AS purchase_count_current,
            COALESCE(SUM(e.amount) FILTER (WHERE e.yr = v_year), 0) AS revenue_current,
            COUNT(DISTINCT e.doc_id) FILTER (WHERE e.yr = v_year - 1) AS purchase_count_prev,
            COALESCE(SUM(e.amount) FILTER (WHERE e.yr = v_year - 1), 0) AS revenue_prev
        FROM exploded e
        GROUP BY e.size_key
    )
    SELECT 
        bs.size_key,
        bs.size_display,
        bs.pipe_type_ua,
        bs.pipe_type_ua || ' ' || bs.size_display AS display_name,
        bs.purchase_count_current,
        bs.revenue_current,
        ROUND(bs.revenue_current / NULLIF(v_total_revenue, 0) * 100, 1) AS pct_of_client_total,
        bs.purchase_count_prev,
        bs.revenue_prev,
        COALESCE(sps.stock_total, 0) AS stock_balance_total
    FROM by_size bs
    LEFT JOIN stock_per_size sps ON sps.size_key = bs.size_key
    WHERE bs.purchase_count_current > 0
    ORDER BY 
        bs.revenue_current DESC,
        bs.purchase_count_current DESC
    LIMIT p_limit;
END;
$$;

COMMENT ON FUNCTION get_recommendations_by_size(TEXT, INT) IS 
    'ТОП покупок клиента, агрегированный по размеру трубы. Круглая/квадратная/прямоугольная. Остаток — сумма по всем ГОСТам/сталям размера.';
