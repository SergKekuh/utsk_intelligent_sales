-- =============================================================================
-- MIGRATION 20: Functions get_churned_segmentation and get_sleeping_segmentation
-- Date: 2026-08-28
-- Description: Stored functions for Churned (Status ID 9) and Sleeping (Status ID 8) clients
-- =============================================================================

DROP FUNCTION IF EXISTS public.get_churned_segmentation(INT);

CREATE OR REPLACE FUNCTION public.get_churned_segmentation(
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    inv_prev BIGINT,
    invoices_count BIGINT,
    goods_revenue NUMERIC,
    services_revenue NUMERIC,
    avg_ticket NUMERIC,
    last_purchase DATE,
    days_since INT,
    last_year INT,
    abc_group VARCHAR,
    recommendation VARCHAR,
    industry VARCHAR,
    cohort VARCHAR
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH churned AS (
        SELECT c.code, c.name, c.activity_direction_id, ad.name AS industry
        FROM clients c
        LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
        WHERE c.current_status_id = 9
          AND c.code NOT IN ('9653', '11230')
    ),
    prev_stats AS (
        SELECT 
            ch.code, ch.name, ch.industry,
            COUNT(DISTINCT d.id) AS inv_prev,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS rev_prev,
            COALESCE(SUM(CASE WHEN pr.is_service = TRUE THEN sl.amount ELSE 0 END), 0) AS services_prev,
            MAX(d.invoice_date) AS last_purchase
        FROM churned ch
        JOIN documents d ON d.client_code = ch.code AND EXTRACT(YEAR FROM d.invoice_date) <= p_year - 1
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY ch.code, ch.name, ch.industry
    )
    SELECT 
        ps.code::VARCHAR,
        ps.name::VARCHAR,
        ps.inv_prev::BIGINT AS inv_prev,
        ps.inv_prev::BIGINT AS invoices_count,
        ROUND(ps.rev_prev, 2)::NUMERIC AS goods_revenue,
        ROUND(ps.services_prev, 2)::NUMERIC AS services_revenue,
        ROUND(ps.rev_prev / NULLIF(ps.inv_prev, 0), 2)::NUMERIC AS avg_ticket,
        ps.last_purchase::DATE AS last_purchase,
        (CURRENT_DATE - ps.last_purchase::DATE)::INT AS days_since,
        EXTRACT(YEAR FROM ps.last_purchase)::INT AS last_year,
        CASE 
            WHEN ps.rev_prev >= 2900000 THEN 'A'
            WHEN ps.rev_prev >= 435000 THEN 'B'
            ELSE 'C'
        END::VARCHAR AS abc_group,
        CASE 
            WHEN ps.rev_prev >= 2900000 THEN '🔥 Спробувати повернути (A-клієнт)'
            WHEN ps.rev_prev >= 435000 THEN '📞 Запросити зворотний зв''язок'
            ELSE '📋 Архів / Прогрів'
        END::VARCHAR AS recommendation,
        COALESCE(ps.industry, 'Не вказано')::VARCHAR AS industry,
        CASE 
            WHEN ps.inv_prev = 1 THEN 'Разові (1)'
            WHEN ps.inv_prev BETWEEN 2 AND 3 THEN 'Повторні (2-3)'
            WHEN ps.inv_prev BETWEEN 4 AND 10 THEN 'Квартальні (4-10)'
            WHEN ps.inv_prev BETWEEN 11 AND 40 THEN 'Місячні (11-40)'
            WHEN ps.inv_prev BETWEEN 41 AND 170 THEN 'Тижневі (41-170)'
            ELSE 'Щоденні (>170)'
        END::VARCHAR AS cohort
    FROM prev_stats ps
    ORDER BY ps.rev_prev DESC;
END;
$function$;

DROP FUNCTION IF EXISTS public.get_sleeping_segmentation(INT);

CREATE OR REPLACE FUNCTION public.get_sleeping_segmentation(
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    inv_curr BIGINT,
    invoices_count BIGINT,
    goods_revenue NUMERIC,
    services_revenue NUMERIC,
    avg_ticket NUMERIC,
    last_purchase DATE,
    days_since INT,
    abc_group VARCHAR,
    recommendation VARCHAR,
    industry VARCHAR,
    cohort VARCHAR
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH sleeping AS (
        SELECT c.code, c.name, c.activity_direction_id, ad.name AS industry
        FROM clients c
        LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
        WHERE c.current_status_id = 8
          AND c.code NOT IN ('9653', '11230')
    ),
    curr_stats AS (
        SELECT 
            sl.code, sl.name, sl.industry,
            COUNT(DISTINCT d.id) AS inv_curr,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN s.amount ELSE 0 END), 0) AS rev_curr,
            COALESCE(SUM(CASE WHEN pr.is_service = TRUE THEN s.amount ELSE 0 END), 0) AS services_curr,
            MAX(d.invoice_date) AS last_purchase
        FROM sleeping sl
        JOIN documents d ON d.client_code = sl.code
        JOIN sales_lines s ON s.document_id = d.id
        LEFT JOIN products pr ON s.product_code = pr.code
        GROUP BY sl.code, sl.name, sl.industry
    )
    SELECT 
        cs.code::VARCHAR,
        cs.name::VARCHAR,
        cs.inv_curr::BIGINT AS inv_curr,
        cs.inv_curr::BIGINT AS invoices_count,
        ROUND(cs.rev_curr, 2)::NUMERIC AS goods_revenue,
        ROUND(cs.services_curr, 2)::NUMERIC AS services_revenue,
        ROUND(cs.rev_curr / NULLIF(cs.inv_curr, 0), 2)::NUMERIC AS avg_ticket,
        cs.last_purchase::DATE AS last_purchase,
        (CURRENT_DATE - cs.last_purchase::DATE)::INT AS days_since,
        CASE 
            WHEN cs.rev_curr >= 2900000 THEN 'A'
            WHEN cs.rev_curr >= 435000 THEN 'B'
            ELSE 'C'
        END::VARCHAR AS abc_group,
        CASE 
            WHEN (CURRENT_DATE - cs.last_purchase::DATE) > 180 THEN '⚠️ Терміново повернути'
            WHEN (CURRENT_DATE - cs.last_purchase::DATE) > 90 THEN '📞 Зателефонувати'
            ELSE '📧 Нагадати про себе'
        END::VARCHAR AS recommendation,
        COALESCE(cs.industry, 'Не вказано')::VARCHAR AS industry,
        CASE 
            WHEN cs.inv_curr = 1 THEN 'Разові (1)'
            WHEN cs.inv_curr BETWEEN 2 AND 3 THEN 'Повторні (2-3)'
            WHEN cs.inv_curr BETWEEN 4 AND 10 THEN 'Квартальні (4-10)'
            WHEN cs.inv_curr BETWEEN 11 AND 40 THEN 'Місячні (11-40)'
            WHEN cs.inv_curr BETWEEN 41 AND 170 THEN 'Тижневі (41-170)'
            ELSE 'Щоденні (>170)'
        END::VARCHAR AS cohort
    FROM curr_stats cs
    ORDER BY cs.rev_curr DESC;
END;
$function$;
