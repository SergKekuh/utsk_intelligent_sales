-- ============================================================
-- МИГРАЦИЯ 53: get_profile_pipes_sizes_yoy — добавить size_display
-- Дата: 2026-10-05
--
-- ЦЕЛЬ: Устранить асимметрию между get_profile_pipes_sizes и
--       get_profile_pipes_sizes_yoy. Оба эндпоинта (/sizes и
--       /sizes-yoy) должны отдавать человекочитаемое поле
--       size_display.
--
-- ПРИЧИНА: get_profile_pipes_sizes_yoy был написан до миграции 52
--          и группирует только по size_key. Из-за этого фронт
--          вынужден использовать JS-fallback formatSizeDisplay().
--          Устраняем долг (правило №10 — единый источник правды).
--
-- РИСК: низкий (только добавляем колонку в RETURNS TABLE).
-- ОТКАТ: DROP FUNCTION + восстановить из бэкапа:
--        /tmp/sizes_yoy_before.sql
-- ============================================================

-- БЭКАП (текущее определение функции)
CREATE TABLE IF NOT EXISTS backup_functions_20261005_sizes_yoy AS
SELECT
    proname,
    pg_get_functiondef(oid) AS definition,
    now() AS backup_at
FROM pg_proc
WHERE proname = 'get_profile_pipes_sizes_yoy';

-- ПЕРЕСОЗДАТЬ ФУНКЦИЮ С ДОБАВЛЕННЫМ size_display
DROP FUNCTION IF EXISTS public.get_profile_pipes_sizes_yoy(text, integer);

CREATE OR REPLACE FUNCTION public.get_profile_pipes_sizes_yoy(
    p_client_code text,
    p_year integer DEFAULT 2026
)
RETURNS TABLE(
    size_key text,
    size_display text,        -- ← НОВОЕ
    revenue_cur numeric,
    revenue_prev numeric,
    delta_abs numeric,
    delta_pct numeric
)
LANGUAGE sql
STABLE
AS $function$
    WITH cur AS (
        SELECT
            size_key,
            prof_w,
            prof_h,
            wall,
            SUM(amount)::NUMERIC AS revenue
        FROM (
            SELECT
                sl.amount,
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
              AND sl.amount > 0
        ) t
        GROUP BY size_key, prof_w, prof_h, wall
    ),
    prev AS (
        SELECT
            size_key,
            prof_w,
            prof_h,
            wall,
            SUM(amount)::NUMERIC AS revenue
        FROM (
            SELECT
                sl.amount,
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
              AND EXTRACT(YEAR FROM d.invoice_date) = p_year - 1
              AND COALESCE(p.is_service, FALSE) = FALSE
              AND ppa.is_prof = TRUE
              AND sl.amount > 0
        ) t
        GROUP BY size_key, prof_w, prof_h, wall
    )
    SELECT
        COALESCE(cur.size_key, prev.size_key) AS size_key,
        -- Человекочитаемое название (та же логика, что в get_profile_pipes_sizes)
        CASE
            WHEN COALESCE(cur.prof_w, prev.prof_w) = COALESCE(cur.prof_h, prev.prof_h)
                 AND COALESCE(cur.wall, prev.wall) IS NOT NULL
                THEN 'Квадрат '
                     || COALESCE(cur.prof_w, prev.prof_w)::TEXT || '×'
                     || COALESCE(cur.prof_h, prev.prof_h)::TEXT || '×'
                     || COALESCE(cur.wall, prev.wall)::TEXT
            WHEN COALESCE(cur.prof_w, prev.prof_w) = COALESCE(cur.prof_h, prev.prof_h)
                THEN 'Квадрат '
                     || COALESCE(cur.prof_w, prev.prof_w)::TEXT || '×'
                     || COALESCE(cur.prof_h, prev.prof_h)::TEXT
            WHEN COALESCE(cur.prof_w, prev.prof_w) <> COALESCE(cur.prof_h, prev.prof_h)
                 AND COALESCE(cur.wall, prev.wall) IS NOT NULL
                THEN 'Прямокутник '
                     || COALESCE(cur.prof_w, prev.prof_w)::TEXT || '×'
                     || COALESCE(cur.prof_h, prev.prof_h)::TEXT || '×'
                     || COALESCE(cur.wall, prev.wall)::TEXT
            WHEN COALESCE(cur.prof_w, prev.prof_w) <> COALESCE(cur.prof_h, prev.prof_h)
                THEN 'Прямокутник '
                     || COALESCE(cur.prof_w, prev.prof_w)::TEXT || '×'
                     || COALESCE(cur.prof_h, prev.prof_h)::TEXT
            ELSE COALESCE(cur.size_key, prev.size_key)
        END AS size_display,
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
$function$;

-- ПРОВЕРКА
SELECT
    'OK' AS status,
    pg_get_function_arguments(oid) AS args,
    pg_get_function_result(oid) AS result
FROM pg_proc
WHERE proname = 'get_profile_pipes_sizes_yoy';
