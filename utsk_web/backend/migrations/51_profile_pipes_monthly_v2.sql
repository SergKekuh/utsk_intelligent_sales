-- ============================================================
-- МИГРАЦИЯ 51: расширенная помесячная динамика профильных труб
-- Дата: 2026-10-01
-- ============================================================

-- БЭКАП
CREATE TABLE IF NOT EXISTS backup_functions_20261001_17 AS
SELECT proname, pg_get_functiondef(oid) AS definition, now() AS backup_at
FROM pg_proc
WHERE proname IN ('get_profile_pipes_monthly', 'get_profile_pipes_monthly_kpi');

-- 1. get_profile_pipes_monthly (расширенная)
DROP FUNCTION IF EXISTS get_profile_pipes_monthly(text, integer);

CREATE OR REPLACE FUNCTION get_profile_pipes_monthly(
    p_client_code TEXT,
    p_year INTEGER DEFAULT 2026
)
RETURNS TABLE(
    month_num INTEGER,
    month_name TEXT,
    revenue_cur NUMERIC,
    revenue_prev NUMERIC,
    delta_abs NUMERIC,
    delta_pct NUMERIC,
    invoices_cur BIGINT,
    avg_check NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    WITH months AS (
        SELECT generate_series(1, 12) AS m
    ),
    month_names AS (
        SELECT ARRAY['Січ', 'Лют', 'Бер', 'Кві', 'Тра', 'Чер',
                     'Лип', 'Сер', 'Вер', 'Жов', 'Лис', 'Гру'] AS names
    ),
    cur AS (
        SELECT
            EXTRACT(MONTH FROM d.invoice_date)::INT AS m,
            SUM(sl.amount)::NUMERIC AS revenue,
            COUNT(DISTINCT sl.document_id)::BIGINT AS invoices
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
        GROUP BY EXTRACT(MONTH FROM d.invoice_date)
    ),
    prev AS (
        SELECT
            EXTRACT(MONTH FROM d.invoice_date)::INT AS m,
            SUM(sl.amount)::NUMERIC AS revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON p.code = sl.product_code
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year - 1
          AND COALESCE(p.is_service, FALSE) = FALSE
          AND ppa.is_prof = TRUE
          AND ppa.prof_w IS NOT NULL
          AND ppa.prof_h IS NOT NULL
          AND sl.amount > 0
        GROUP BY EXTRACT(MONTH FROM d.invoice_date)
    )
    SELECT
        m.m AS month_num,
        (SELECT names[m.m] FROM month_names) AS month_name,
        ROUND(COALESCE(c.revenue, 0)::NUMERIC, 2) AS revenue_cur,
        ROUND(COALESCE(pv.revenue, 0)::NUMERIC, 2) AS revenue_prev,
        ROUND((COALESCE(c.revenue, 0) - COALESCE(pv.revenue, 0))::NUMERIC, 2) AS delta_abs,
        CASE
            WHEN COALESCE(pv.revenue, 0) > 0
                THEN ROUND(((COALESCE(c.revenue, 0) - COALESCE(pv.revenue, 0)) / pv.revenue * 100)::NUMERIC, 2)
            ELSE NULL
        END AS delta_pct,
        COALESCE(c.invoices, 0)::BIGINT AS invoices_cur,
        CASE
            WHEN COALESCE(c.invoices, 0) > 0
                THEN ROUND((COALESCE(c.revenue, 0) / c.invoices)::NUMERIC, 2)
            ELSE 0
        END AS avg_check
    FROM months m
    LEFT JOIN cur c ON c.m = m.m
    LEFT JOIN prev pv ON pv.m = m.m
    ORDER BY m.m;
$$;

COMMENT ON FUNCTION get_profile_pipes_monthly(text, integer) IS
'Помесячная динамика профильных труб клиента с YoY и средним чеком.';

-- 2. get_profile_pipes_monthly_kpi (KPI для вкладки)
DROP FUNCTION IF EXISTS get_profile_pipes_monthly_kpi(text, integer);

CREATE OR REPLACE FUNCTION get_profile_pipes_monthly_kpi(
    p_client_code TEXT,
    p_year INTEGER DEFAULT 2026
)
RETURNS TABLE(
    total_revenue NUMERIC,
    avg_monthly NUMERIC,
    best_month_num INTEGER,
    best_month_name TEXT,
    best_month_revenue NUMERIC,
    worst_month_num INTEGER,
    worst_month_name TEXT,
    worst_month_revenue NUMERIC,
    active_months BIGINT,
    total_invoices BIGINT,
    avg_check NUMERIC
)
LANGUAGE SQL
STABLE
AS $$
    WITH m AS (
        SELECT * FROM get_profile_pipes_monthly(p_client_code, p_year)
    ),
    active AS (SELECT * FROM m WHERE revenue_cur > 0),
    best AS (SELECT * FROM active ORDER BY revenue_cur DESC LIMIT 1),
    worst AS (SELECT * FROM active ORDER BY revenue_cur ASC LIMIT 1)
    SELECT
        ROUND(COALESCE((SELECT SUM(revenue_cur) FROM m), 0)::NUMERIC, 2),
        ROUND(COALESCE((SELECT AVG(revenue_cur) FROM active), 0)::NUMERIC, 2),
        (SELECT month_num FROM best),
        (SELECT month_name FROM best),
        ROUND(COALESCE((SELECT revenue_cur FROM best), 0)::NUMERIC, 2),
        (SELECT month_num FROM worst),
        (SELECT month_name FROM worst),
        ROUND(COALESCE((SELECT revenue_cur FROM worst), 0)::NUMERIC, 2),
        (SELECT COUNT(*) FROM active)::BIGINT,
        COALESCE((SELECT SUM(invoices_cur) FROM m), 0)::BIGINT,
        ROUND(
            COALESCE((SELECT SUM(revenue_cur) FROM m), 0)::NUMERIC
            / NULLIF((SELECT SUM(invoices_cur) FROM m), 0),
            2
        );
$$;

COMMENT ON FUNCTION get_profile_pipes_monthly_kpi(text, integer) IS
'KPI для вкладки «Динаміка по місяцях» (виручка, пік, середній чек).';
