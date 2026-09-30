-- ============================================================
-- Migration 34: Fix get_directions_kpi (748→729) + add 8814 exclusion
-- Задачи 2 (KPI clients count) + 3 (exclusion 8814)
-- 
-- ИЗМЕНЕНИЯ:
--   1. tot_clients: фильтр через client_year_activity.is_active = TRUE
--   2. dir_sales: исключения NOT IN ('9653','11230','8814')
--   3. get_directions_summary: аналогичные фильтры + 8814
-- ============================================================

-- БЭКАП
CREATE TABLE IF NOT EXISTS backup_get_directions_kpi_20260921 AS
SELECT proname, pg_get_functiondef(oid) AS def 
FROM pg_proc 
WHERE proname IN ('get_directions_kpi', 'get_directions_summary')
  AND pronamespace = 'public'::regnamespace;

SELECT proname, LENGTH(def) AS backup_len FROM backup_get_directions_kpi_20260921;

-- ============================================================
-- ФУНКЦИЯ 1: get_directions_kpi — ИСПРАВЛЕННАЯ
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_directions_kpi(p_year integer DEFAULT 2026)
 RETURNS TABLE(
    total_revenue numeric, 
    total_clients bigint, 
    total_invoices bigint, 
    avg_ticket numeric, 
    top_direction_id integer, 
    top_direction_name text, 
    top_direction_revenue numeric, 
    top_direction_share_pct numeric, 
    active_directions_count bigint
 )
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH dir_sales AS (
        SELECT 
            ad.id AS dir_id,
            ad.name AS dir_name,
            COUNT(DISTINCT c.code) AS dir_clients,
            COUNT(DISTINCT d.id) AS dir_invoices,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS dir_revenue
        FROM activity_directions ad
        JOIN clients c ON c.activity_direction_id = ad.id
        JOIN documents d ON d.client_code = c.code 
            AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230', '8814')
        GROUP BY ad.id, ad.name
    ),
    totals AS (
        SELECT 
            COALESCE(SUM(dir_revenue), 0) AS tot_rev,
            COALESCE(SUM(dir_invoices), 0) AS tot_inv,
            -- ИСПРАВЛЕНИЕ: считаем через client_year_activity.is_active = TRUE
            (SELECT COUNT(DISTINCT cya.client_code) 
             FROM client_year_activity cya
             WHERE cya.sales_year = p_year 
               AND cya.is_active = TRUE
               AND cya.client_code NOT IN ('9653', '11230', '8814')) AS tot_clients,
            COUNT(*) FILTER (WHERE dir_revenue > 0) AS active_dirs
        FROM dir_sales
    ),
    top_dir AS (
        SELECT dir_id, dir_name, dir_revenue
        FROM dir_sales
        ORDER BY dir_revenue DESC
        LIMIT 1
    )
    SELECT 
        ROUND(t.tot_rev, 2)::NUMERIC AS total_revenue,
        t.tot_clients::BIGINT AS total_clients,
        t.tot_inv::BIGINT AS total_invoices,
        ROUND(t.tot_rev / NULLIF(t.tot_inv, 0), 2)::NUMERIC AS avg_ticket,
        td.dir_id::INTEGER AS top_direction_id,
        td.dir_name::TEXT AS top_direction_name,
        ROUND(td.dir_revenue, 2)::NUMERIC AS top_direction_revenue,
        ROUND(td.dir_revenue * 100.0 / NULLIF(t.tot_rev, 0), 2)::NUMERIC AS top_direction_share_pct,
        t.active_dirs::BIGINT AS active_directions_count
    FROM totals t
    CROSS JOIN top_dir td;
END;
$function$;

COMMENT ON FUNCTION public.get_directions_kpi(integer) IS 
    'KPI направлений. Активных клиентов считает через client_year_activity.is_active = TRUE. Исключены: 9653, 11230, 8814.';

-- ============================================================
-- ФУНКЦИЯ 2: get_directions_summary — добавить 8814 + правильный знаменатель
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_directions_summary(p_year integer DEFAULT 2026)
 RETURNS TABLE(
    id integer, 
    name character varying, 
    icon character varying, 
    color character varying, 
    clients_count bigint, 
    total_clients_in_base bigint, 
    invoices_count bigint, 
    goods_revenue numeric, 
    avg_ticket numeric, 
    revenue_share_pct numeric, 
    clients_share_pct numeric
 )
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH overall AS (
        SELECT 
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS tot_rev,
            -- Используем client_year_activity для точного счётчика активных
            (SELECT COUNT(DISTINCT cya.client_code)
             FROM client_year_activity cya
             WHERE cya.sales_year = p_year 
               AND cya.is_active = TRUE
               AND cya.client_code NOT IN ('9653', '11230', '8814')) AS tot_clients
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND d.client_code NOT IN ('9653', '11230', '8814')
    )
    SELECT 
        ad.id::INTEGER,
        ad.name::VARCHAR,
        COALESCE(ad.icon, '🌐')::VARCHAR AS icon,
        COALESCE(ad.color, '#64748b')::VARCHAR AS color,
        COUNT(DISTINCT CASE WHEN d.id IS NOT NULL THEN c.code END)::BIGINT AS clients_count,
        COUNT(DISTINCT c.code)::BIGINT AS total_clients_in_base,
        COUNT(DISTINCT d.id)::BIGINT AS invoices_count,
        ROUND(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0), 2)::NUMERIC AS goods_revenue,
        ROUND(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) / NULLIF(COUNT(DISTINCT d.id), 0), 2)::NUMERIC AS avg_ticket,
        ROUND(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) * 100.0 / NULLIF(MAX(ov.tot_rev), 0), 2)::NUMERIC AS revenue_share_pct,
        ROUND(COUNT(DISTINCT CASE WHEN d.id IS NOT NULL THEN c.code END) * 100.0 / NULLIF(MAX(ov.tot_clients), 0), 2)::NUMERIC AS clients_share_pct
    FROM activity_directions ad
    CROSS JOIN overall ov
    LEFT JOIN clients c ON c.activity_direction_id = ad.id
        AND c.code NOT IN ('9653', '11230', '8814')
    LEFT JOIN documents d ON d.client_code = c.code 
        AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    LEFT JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    GROUP BY ad.id, ad.name, ad.icon, ad.color
    ORDER BY goods_revenue DESC, clients_count DESC;
END;
$function$;

COMMENT ON FUNCTION public.get_directions_summary(integer) IS 
    'Сводная матрица отраслей. clients_share_pct считается от 729 активных. Исключены: 9653, 11230, 8814.';

-- ============================================================
-- ПРОВЕРКА
-- ============================================================
SELECT 'Ожидается 729' AS expected, 
       (SELECT total_clients FROM get_directions_kpi(2026)) AS actual,
       729 - (SELECT total_clients FROM get_directions_kpi(2026)) AS diff;
