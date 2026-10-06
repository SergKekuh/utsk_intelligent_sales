-- ============================================================
-- МИГРАЦИЯ 59: Функции для страницы «Рекомендації — Огляд»
-- Дата: 2026-10-06
-- ЦЕЛЬ: 4 функции для 5 вкладок
-- РИСК: низкий (только новые функции)
-- ============================================================

-- БЭКАП
CREATE TABLE IF NOT EXISTS backup_functions_20261006_rec_overview AS
SELECT proname, pg_get_functiondef(oid) AS definition, now() AS backup_at
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND proname = 'get_recommendations_by_size';

-- ═══════════════════════════════════════════════════════════
-- ФУНКЦИЯ 1: get_recommendations_overview_kpi
-- Сводка по 5 топовым размерам
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_recommendations_overview_kpi(
    p_client_code text,
    p_year integer DEFAULT 2026,
    p_limit integer DEFAULT 5
)
RETURNS TABLE(
    client_name varchar,
    top_sizes_count bigint,
    total_revenue numeric,
    total_invoices bigint,
    avg_check numeric,
    share_of_client_pct numeric,
    top_size_display varchar,
    top_size_revenue numeric
)
LANGUAGE sql
STABLE
AS $function$
    WITH top_sizes AS (
        SELECT * FROM get_recommendations_by_size(p_client_code, p_limit)
    ),
    client_total AS (
        SELECT COALESCE(SUM(sl.amount), 0) AS client_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON p.code = sl.product_code
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND COALESCE(p.is_service, FALSE) = FALSE
          AND sl.amount > 0
    ),
    summary AS (
        SELECT
            SUM(revenue_current) AS total_revenue,
            SUM(purchase_count_current) AS total_invoices,
            ROUND(AVG(revenue_current), 2) AS avg_check
        FROM top_sizes
    )
    SELECT
        c.name::varchar AS client_name,
        (SELECT COUNT(*) FROM top_sizes)::bigint AS top_sizes_count,
        ROUND(COALESCE(s.total_revenue, 0), 2)::numeric AS total_revenue,
        COALESCE(s.total_invoices, 0)::bigint AS total_invoices,
        ROUND(COALESCE(s.avg_check, 0), 2)::numeric AS avg_check,
        ROUND(
            COALESCE(s.total_revenue, 0) / NULLIF(ct.client_revenue, 0) * 100,
            2
        )::numeric AS share_of_client_pct,
        (SELECT display_name FROM top_sizes ORDER BY revenue_current DESC LIMIT 1)::varchar AS top_size_display,
        (SELECT revenue_current FROM top_sizes ORDER BY revenue_current DESC LIMIT 1)::numeric AS top_size_revenue
    FROM clients c
    CROSS JOIN summary s
    CROSS JOIN client_total ct
    WHERE c.code = p_client_code;
$function$;

-- ═══════════════════════════════════════════════════════════
-- ФУНКЦИЯ 2: get_recommendations_overview_monthly
-- Помесячные продажи 5 размеров (2026 vs 2025)
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_recommendations_overview_monthly(
    p_client_code text,
    p_year integer DEFAULT 2026,
    p_limit integer DEFAULT 5
)
RETURNS TABLE(
    size_key varchar,
    display_name varchar,
    month_num int,
    month_name varchar,
    revenue_cur numeric,
    revenue_prev numeric
)
LANGUAGE sql
STABLE
AS $function$
    WITH top_sizes AS (
        SELECT size_key, display_name
        FROM get_recommendations_by_size(p_client_code, p_limit)
    ),
    month_series AS (
        SELECT generate_series(1, 12) AS m
    ),
    base AS (
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
            EXTRACT(MONTH FROM d.invoice_date)::int AS month_num,
            EXTRACT(YEAR FROM d.invoice_date)::int AS year_num,
            sl.amount
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON p.code = sl.product_code
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) IN (p_year, p_year - 1)
          AND COALESCE(p.is_service, FALSE) = FALSE
          AND sl.amount > 0
    )
    SELECT
        ts.size_key::varchar,
        ts.display_name::varchar,
        ms.m AS month_num,
        (ARRAY['Січ','Лют','Бер','Кві','Тра','Чер','Лип','Сер','Вер','Жов','Лис','Гру'])[ms.m]::varchar AS month_name,
        ROUND(COALESCE((
            SELECT SUM(b.amount) FROM base b
            WHERE b.size_key = ts.size_key AND b.month_num = ms.m AND b.year_num = p_year
        ), 0), 2)::numeric AS revenue_cur,
        ROUND(COALESCE((
            SELECT SUM(b.amount) FROM base b
            WHERE b.size_key = ts.size_key AND b.month_num = ms.m AND b.year_num = p_year - 1
        ), 0), 2)::numeric AS revenue_prev
    FROM top_sizes ts
    CROSS JOIN month_series ms
    ORDER BY ts.size_key, ms.m;
$function$;

-- ═══════════════════════════════════════════════════════════
-- ФУНКЦИЯ 3: get_recommendations_overview_abc
-- ABC-анализ по размерам
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_recommendations_overview_abc(
    p_client_code text,
    p_year integer DEFAULT 2026,
    p_limit integer DEFAULT 5
)
RETURNS TABLE(
    rank int,
    size_key varchar,
    display_name varchar,
    revenue numeric,
    share_pct numeric,
    cumulative_pct numeric,
    abc_class varchar
)
LANGUAGE sql
STABLE
AS $function$
    WITH sizes AS (
        SELECT
            size_key,
            display_name,
            revenue_current AS revenue
        FROM get_recommendations_by_size(p_client_code, p_limit)
    ),
    ranked AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY revenue DESC)::int AS rank,
            size_key,
            display_name,
            revenue,
            SUM(revenue) OVER () AS total_revenue
        FROM sizes
    )
    SELECT
        rank,
        size_key::varchar,
        display_name::varchar,
        ROUND(revenue, 2)::numeric,
        ROUND(revenue / NULLIF(total_revenue, 0) * 100, 2)::numeric AS share_pct,
        ROUND(
            SUM(revenue) OVER (ORDER BY revenue DESC) / NULLIF(total_revenue, 0) * 100,
            2
        )::numeric AS cumulative_pct,
        CASE
            WHEN SUM(revenue) OVER (ORDER BY revenue DESC) / NULLIF(total_revenue, 0) <= 0.80 THEN 'A'
            WHEN SUM(revenue) OVER (ORDER BY revenue DESC) / NULLIF(total_revenue, 0) <= 0.95 THEN 'B'
            ELSE 'C'
        END::varchar AS abc_class
    FROM ranked
    ORDER BY rank;
$function$;

-- ═══════════════════════════════════════════════════════════
-- ФУНКЦИЯ 4: get_recommendations_overview_crosssell
-- Матрица cross-sell
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_recommendations_overview_crosssell(
    p_client_code text,
    p_year integer DEFAULT 2026,
    p_limit integer DEFAULT 5
)
RETURNS TABLE(
    size_key_a varchar,
    display_name_a varchar,
    size_key_b varchar,
    display_name_b varchar,
    same_invoice_count bigint,
    affinity_pct numeric
)
LANGUAGE sql
STABLE
AS $function$
    WITH top_sizes AS (
        SELECT size_key, display_name
        FROM get_recommendations_by_size(p_client_code, p_limit)
    ),
    invoice_sizes AS (
        SELECT
            d.id AS document_id,
            CASE
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                ELSE NULL
            END AS size_key
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON p.code = sl.product_code
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND COALESCE(p.is_service, FALSE) = FALSE
          AND sl.amount > 0
    ),
    pairs AS (
        SELECT
            a.size_key AS size_a,
            b.size_key AS size_b,
            COUNT(DISTINCT a.document_id) AS common_invoices
        FROM invoice_sizes a
        JOIN invoice_sizes b ON a.document_id = b.document_id AND a.size_key < b.size_key
        GROUP BY a.size_key, b.size_key
    ),
    size_totals AS (
        SELECT size_key, COUNT(DISTINCT document_id) AS total_docs
        FROM invoice_sizes
        GROUP BY size_key
    )
    SELECT
        p.size_a::varchar,
        tsa.display_name::varchar,
        p.size_b::varchar,
        tsb.display_name::varchar,
        p.common_invoices::bigint,
        ROUND(p.common_invoices::numeric / NULLIF(st.total_docs, 0) * 100, 2)::numeric AS affinity_pct
    FROM pairs p
    JOIN top_sizes tsa ON tsa.size_key = p.size_a
    JOIN top_sizes tsb ON tsb.size_key = p.size_b
    LEFT JOIN size_totals st ON st.size_key = p.size_a
    ORDER BY p.common_invoices DESC
    LIMIT 20;
$function$;
