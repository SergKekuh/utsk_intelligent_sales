-- ============================================================
-- МИГРАЦИЯ 36: get_client_sizes_compare
-- YoY-сравнение размеров труб клиента (агрегация по size_key)
-- Создано: 2026-09-22
-- ============================================================

CREATE OR REPLACE FUNCTION get_client_sizes_compare(
    p_client_code TEXT,
    p_year INT DEFAULT EXTRACT(YEAR FROM CURRENT_DATE)::INT
)
RETURNS TABLE(
    size_key        TEXT,       -- round_76x5
    size_display    TEXT,       -- 76×5
    pipe_type       TEXT,       -- 'round' | 'square' | 'rect'
    pipe_type_ua    TEXT,       -- 'Круглая труба'
    display_name    TEXT,       -- 'Круглая труба 76×5'
    -- Текущий год (p_year)
    revenue_current NUMERIC,   -- Выручка 2026
    qty_current     NUMERIC,   -- Тоннаж 2026
    invoices_current BIGINT,   -- Накладных с этим размером 2026
    -- Прошлый год (p_year - 1)
    revenue_prev    NUMERIC,   -- Выручка 2025
    qty_prev        NUMERIC,   -- Тоннаж 2025
    invoices_prev   BIGINT,    -- Накладных 2025
    -- Дельта и тренд
    yoy_abs         NUMERIC,   -- 2026 - 2025 (в ₴)
    yoy_pct         NUMERIC,   -- 2026 / 2025 * 100
    yoy_qty_abs     NUMERIC,   -- 2026 - 2025 (в тоннах)
    trend           TEXT       -- 📈 Рост / 📉 Спад / ➡️ Стабильно / 🆕 Новый / ❌ Ушёл
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN QUERY
    WITH exploded AS (
        -- Разворачиваем все продажи клиента на размеры
        SELECT
            EXTRACT(YEAR FROM d.invoice_date)::INT AS yr,
            d.id                                   AS doc_id,
            sl.amount,
            sl.quantity,
            nps.size_key,
            nps.size_display,
            nps.pipe_type,
            nps.pipe_type_ua
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products    p  ON sl.product_code = p.code
        CROSS JOIN LATERAL (
            SELECT
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
                    WHEN ppa.is_prof AND ppa.prof_w = ppa.prof_h          THEN 'square'
                    WHEN ppa.is_prof AND ppa.prof_w <> ppa.prof_h         THEN 'rect'
                    WHEN NOT ppa.is_prof                                   THEN 'round'
                    ELSE NULL
                END AS pipe_type,
                CASE
                    WHEN ppa.is_prof AND ppa.prof_w = ppa.prof_h          THEN 'Квадратна труба'
                    WHEN ppa.is_prof AND ppa.prof_w <> ppa.prof_h         THEN 'Прямокутна труба'
                    WHEN NOT ppa.is_prof                                   THEN 'Кругла труба'
                    ELSE NULL
                END AS pipe_type_ua
            FROM parse_pipe_attributes(p.name) ppa
        ) nps
        WHERE d.client_code = p_client_code
          AND COALESCE(p.is_service, FALSE) = FALSE
          AND sl.amount > 0
          AND nps.size_key IS NOT NULL
          AND EXTRACT(YEAR FROM d.invoice_date) BETWEEN (p_year - 1) AND p_year
    ),
    by_size AS (
        SELECT
            e.size_key,
            MAX(e.size_display)                                                    AS size_display,
            MAX(e.pipe_type)                                                       AS pipe_type,
            MAX(e.pipe_type_ua)                                                    AS pipe_type_ua,
            COALESCE(SUM(e.amount)   FILTER (WHERE e.yr = p_year),     0)         AS revenue_curr,
            COALESCE(SUM(e.quantity) FILTER (WHERE e.yr = p_year),     0)         AS qty_curr,
            COUNT(DISTINCT e.doc_id) FILTER (WHERE e.yr = p_year)                 AS invoices_curr,
            COALESCE(SUM(e.amount)   FILTER (WHERE e.yr = p_year - 1), 0)         AS revenue_prev,
            COALESCE(SUM(e.quantity) FILTER (WHERE e.yr = p_year - 1), 0)         AS qty_prev,
            COUNT(DISTINCT e.doc_id) FILTER (WHERE e.yr = p_year - 1)             AS invoices_prev
        FROM exploded e
        GROUP BY e.size_key
    )
    SELECT
        bs.size_key,
        bs.size_display,
        bs.pipe_type,
        bs.pipe_type_ua,
        bs.pipe_type_ua || ' ' || bs.size_display                                 AS display_name,
        bs.revenue_curr,
        bs.qty_curr,
        bs.invoices_curr,
        bs.revenue_prev,
        bs.qty_prev,
        bs.invoices_prev,
        (bs.revenue_curr - bs.revenue_prev)                                        AS yoy_abs,
        CASE
            WHEN bs.revenue_prev > 0
            THEN ROUND(bs.revenue_curr / bs.revenue_prev * 100, 1)
            ELSE NULL
        END                                                                        AS yoy_pct,
        (bs.qty_curr - bs.qty_prev)                                                AS yoy_qty_abs,
        CASE
            WHEN bs.revenue_prev = 0 AND bs.revenue_curr > 0 THEN '🆕 Новий'
            WHEN bs.revenue_curr = 0 AND bs.revenue_prev > 0 THEN '❌ Пішов'
            WHEN bs.revenue_curr > bs.revenue_prev            THEN '📈 Зростання'
            WHEN bs.revenue_curr < bs.revenue_prev            THEN '📉 Спад'
            ELSE '➡️ Стабільно'
        END                                                                        AS trend
    FROM by_size bs
    -- Сортировка: от самых покупаемых (по выручке текущего года) к менее
    -- Размеры, которые были в прошлом году но не в текущем, идут в конце
    ORDER BY
        bs.revenue_curr DESC NULLS LAST,
        bs.revenue_prev DESC;
END;
$$;

COMMENT ON FUNCTION get_client_sizes_compare(TEXT, INT) IS
    'YoY-сравнение размеров труб клиента. Агрегация по size_key (без учёта ГОСТ/стали). Сортировка по выручке текущего года DESC.';

-- ============================================================
-- ТЕСТ для клиента 4501
-- ============================================================

SELECT
    display_name,
    invoices_current AS "раз 2026",
    revenue_current  AS "выручка 2026",
    revenue_prev     AS "выручка 2025",
    yoy_abs          AS "Δ ₴",
    yoy_pct          AS "рост %",
    trend
FROM get_client_sizes_compare('4501', 2026)
LIMIT 10;
