-- ============================================================
-- МИГРАЦИЯ 50: функции для страницы «Профільні труби»
-- Дата: 2026-10-01
--
-- ЦЕЛЬ: аналитика по профильным трубам (is_prof = TRUE) для клиента.
--   Отдельная страница /profile-pipes-analytics.
--
-- ЛОГИКА: адаптация существующих функций с фильтром ppa.is_prof = TRUE.
-- РИСК: низкий (только добавление).
-- ОТКАТ: DROP FUNCTION каждой.
-- ============================================================

-- ============================================================
-- 1. KPI
-- ============================================================
DROP FUNCTION IF EXISTS get_profile_pipes_kpi(text, integer);

CREATE OR REPLACE FUNCTION get_profile_pipes_kpi(
    p_client_code TEXT,
    p_year INTEGER DEFAULT 2026
)
RETURNS TABLE(
    uniq_sizes BIGINT,
    uniq_products BIGINT,
    invoices BIGINT,
    revenue NUMERIC,
    avg_check NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    WITH data AS (
        SELECT
            sl.product_code,
            sl.document_id,
            sl.amount,
            CASE
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                ELSE NULL
            END AS size_key
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON p.code = sl.product_code
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND COALESCE(p.is_service, FALSE) = FALSE
          AND ppa.is_prof = TRUE
          AND ppa.prof_w IS NOT NULL
          AND ppa.prof_h IS NOT NULL
          AND sl.amount > 0
    )
    SELECT
        COUNT(DISTINCT size_key)::BIGINT,
        COUNT(DISTINCT product_code)::BIGINT,
        COUNT(DISTINCT document_id)::BIGINT,
        ROUND(COALESCE(SUM(amount), 0)::NUMERIC, 2),
        ROUND(COALESCE(SUM(amount) / NULLIF(COUNT(DISTINCT document_id), 0), 0)::NUMERIC, 2)
    FROM data
    WHERE size_key IS NOT NULL;
$$;

COMMENT ON FUNCTION get_profile_pipes_kpi(text, integer) IS
'KPI по профильным трубам клиента за год.';

-- ============================================================
-- 2. Размеры + drill-down
-- ============================================================
DROP FUNCTION IF EXISTS get_profile_pipes_sizes(text, integer);

CREATE OR REPLACE FUNCTION get_profile_pipes_sizes(
    p_client_code TEXT,
    p_year INTEGER DEFAULT 2026
)
RETURNS TABLE(
    size_key TEXT,
    shape TEXT,               -- 'square' | 'rect'
    prof_w NUMERIC,
    prof_h NUMERIC,
    wall NUMERIC,
    products_count BIGINT,
    invoices BIGINT,
    revenue NUMERIC,
    avg_price NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        size_key,
        CASE
            WHEN prof_w = prof_h THEN 'square'
            ELSE 'rect'
        END AS shape,
        prof_w, prof_h, wall,
        COUNT(DISTINCT product_code)::BIGINT AS products_count,
        COUNT(DISTINCT document_id)::BIGINT AS invoices,
        ROUND(SUM(amount)::NUMERIC, 2) AS revenue,
        ROUND((SUM(amount) / NULLIF(SUM(quantity), 0))::NUMERIC, 2) AS avg_price
    FROM (
        SELECT
            sl.product_code,
            sl.document_id,
            sl.amount,
            sl.quantity,
            ppa.prof_w,
            ppa.prof_h,
            ppa.wall,
            CASE
                WHEN ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                ELSE 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
            END AS size_key
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON p.code = sl.product_code
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND COALESCE(p.is_service, FALSE) = FALSE
          AND ppa.is_prof = TRUE
          AND ppa.prof_w IS NOT NULL
          AND ppa.prof_h IS NOT NULL
          AND sl.amount > 0
    ) t
    GROUP BY size_key, prof_w, prof_h, wall
    ORDER BY revenue DESC;
$$;

COMMENT ON FUNCTION get_profile_pipes_sizes(text, integer) IS
'Список профильных типоразмеров клиента с выручкой.';

-- ============================================================
-- 3. Drill-down: товары внутри размера
-- ============================================================
DROP FUNCTION IF EXISTS get_profile_pipes_products_by_size(text, text, integer);

CREATE OR REPLACE FUNCTION get_profile_pipes_products_by_size(
    p_client_code TEXT,
    p_size_key TEXT,
    p_year INTEGER DEFAULT 2026
)
RETURNS TABLE(
    product_code TEXT,
    product_name TEXT,
    quantity NUMERIC,
    revenue NUMERIC,
    invoices BIGINT
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        sl.product_code,
        p.name AS product_name,
        ROUND(SUM(sl.quantity)::NUMERIC, 3) AS quantity,
        ROUND(SUM(sl.amount)::NUMERIC, 2) AS revenue,
        COUNT(DISTINCT sl.document_id)::BIGINT AS invoices
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    JOIN products p ON p.code = sl.product_code
    CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
    WHERE d.client_code = p_client_code
      AND EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND COALESCE(p.is_service, FALSE) = FALSE
      AND ppa.is_prof = TRUE
      AND sl.amount > 0
      AND CASE
            WHEN ppa.wall IS NOT NULL
                THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
            ELSE 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
          END = p_size_key
    GROUP BY sl.product_code, p.name
    ORDER BY revenue DESC;
$$;

COMMENT ON FUNCTION get_profile_pipes_products_by_size(text, text, integer) IS
'Drill-down: товары внутри профильного размера.';

-- ============================================================
-- 4. YoY по размерам
-- ============================================================
DROP FUNCTION IF EXISTS get_profile_pipes_sizes_yoy(text, integer);

CREATE OR REPLACE FUNCTION get_profile_pipes_sizes_yoy(
    p_client_code TEXT,
    p_year INTEGER DEFAULT 2026
)
RETURNS TABLE(
    size_key TEXT,
    revenue_cur NUMERIC,
    revenue_prev NUMERIC,
    delta_abs NUMERIC,
    delta_pct NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    WITH cur AS (
        SELECT size_key, SUM(amount)::NUMERIC AS revenue
        FROM (
            SELECT sl.amount,
                CASE
                    WHEN ppa.wall IS NOT NULL
                        THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                    ELSE 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                END AS size_key
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            JOIN products p ON p.code = sl.product_code
            CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
            WHERE d.client_code = p_client_code
              AND EXTRACT(YEAR FROM d.invoice_date) = p_year
              AND COALESCE(p.is_service, FALSE) = FALSE
              AND ppa.is_prof = TRUE
              AND sl.amount > 0
        ) t
        GROUP BY size_key
    ),
    prev AS (
        SELECT size_key, SUM(amount)::NUMERIC AS revenue
        FROM (
            SELECT sl.amount,
                CASE
                    WHEN ppa.wall IS NOT NULL
                        THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                    ELSE 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                END AS size_key
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            JOIN products p ON p.code = sl.product_code
            CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
            WHERE d.client_code = p_client_code
              AND EXTRACT(YEAR FROM d.invoice_date) = p_year - 1
              AND COALESCE(p.is_service, FALSE) = FALSE
              AND ppa.is_prof = TRUE
              AND sl.amount > 0
        ) t
        GROUP BY size_key
    )
    SELECT
        COALESCE(cur.size_key, prev.size_key) AS size_key,
        ROUND(COALESCE(cur.revenue, 0), 2) AS revenue_cur,
        ROUND(COALESCE(prev.revenue, 0), 2) AS revenue_prev,
        ROUND(COALESCE(cur.revenue, 0) - COALESCE(prev.revenue, 0), 2) AS delta_abs,
        ROUND(
            (COALESCE(cur.revenue, 0) - COALESCE(prev.revenue, 0))
            / NULLIF(prev.revenue, 0) * 100, 2
        ) AS delta_pct
    FROM cur
    FULL OUTER JOIN prev ON cur.size_key = prev.size_key
    ORDER BY COALESCE(cur.revenue, 0) DESC;
$$;

COMMENT ON FUNCTION get_profile_pipes_sizes_yoy(text, integer) IS
'YoY по профильным размерам клиента.';

-- ============================================================
-- 5. Динамика по месяцам
-- ============================================================
DROP FUNCTION IF EXISTS get_profile_pipes_monthly(text, integer);

CREATE OR REPLACE FUNCTION get_profile_pipes_monthly(
    p_client_code TEXT,
    p_year INTEGER DEFAULT 2026
)
RETURNS TABLE(
    month_num INTEGER,
    month_name TEXT,
    revenue NUMERIC,
    invoices BIGINT
)
LANGUAGE SQL
STABLE
AS $$
    SELECT
        m.month_num,
        TO_CHAR(TO_DATE(m.month_num::TEXT, 'MM'), 'Mon') AS month_name,
        ROUND(COALESCE(SUM(sl.amount), 0)::NUMERIC, 2) AS revenue,
        COUNT(DISTINCT sl.document_id)::BIGINT AS invoices
    FROM generate_series(1, 12) AS m(month_num)
    LEFT JOIN documents d
        ON EXTRACT(MONTH FROM d.invoice_date) = m.month_num
       AND EXTRACT(YEAR FROM d.invoice_date) = p_year
       AND d.client_code = p_client_code
    LEFT JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products p ON p.code = sl.product_code
    LEFT JOIN LATERAL parse_pipe_attributes(p.name) ppa ON TRUE
    WHERE (COALESCE(p.is_service, FALSE) = FALSE OR sl.id IS NULL)
      AND (ppa.is_prof = TRUE OR sl.id IS NULL)
      AND (sl.amount > 0 OR sl.id IS NULL)
    GROUP BY m.month_num
    ORDER BY m.month_num;
$$;

COMMENT ON FUNCTION get_profile_pipes_monthly(text, integer) IS
'Помесячная динамика профильных труб клиента.';
