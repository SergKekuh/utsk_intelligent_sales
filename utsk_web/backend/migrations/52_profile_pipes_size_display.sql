-- ============================================================
-- МИГРАЦИЯ 52: size_display для профильных труб
-- Дата: 2026-10-01
--
-- ЦЕЛЬ: добавить человекочитаемое название размера:
--   - Квадрат 70×70×4   (prof_w = prof_h)
--   - Прямокутник 180×100×10 (prof_w ≠ prof_h)
--
-- Не изменяет size_key (технический ключ).
-- ============================================================

DROP FUNCTION IF EXISTS get_profile_pipes_sizes(text, integer);

CREATE OR REPLACE FUNCTION get_profile_pipes_sizes(
    p_client_code TEXT,
    p_year INTEGER DEFAULT 2026
)
RETURNS TABLE(
    size_key TEXT,
    size_display TEXT,        -- NEW: человекочитаемое название
    shape TEXT,
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
        -- Человекочитаемое название
        CASE
            WHEN prof_w = prof_h AND wall IS NOT NULL
                THEN 'Квадрат ' || prof_w::TEXT || '×' || prof_h::TEXT || '×' || wall::TEXT
            WHEN prof_w = prof_h AND wall IS NULL
                THEN 'Квадрат ' || prof_w::TEXT || '×' || prof_h::TEXT
            WHEN prof_w <> prof_h AND wall IS NOT NULL
                THEN 'Прямокутник ' || prof_w::TEXT || '×' || prof_h::TEXT || '×' || wall::TEXT
            WHEN prof_w <> prof_h AND wall IS NULL
                THEN 'Прямокутник ' || prof_w::TEXT || '×' || prof_h::TEXT
            ELSE size_key  -- fallback
        END AS size_display,
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
'Список профильных типоразмеров клиента с человекочитаемым названием.';
