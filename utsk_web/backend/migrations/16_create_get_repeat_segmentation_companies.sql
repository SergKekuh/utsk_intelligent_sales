-- =============================================================================
-- MIGRATION 16: Function get_repeat_segmentation_companies
-- Date: 2026-08-28
-- Description: Creates get_repeat_segmentation_companies(p_year INT)
--              returning all 174 repeat buyers (2-3 purchases) with subgroups,
--              days between purchases, ABC, metrics, and industry.
-- =============================================================================

DROP FUNCTION IF EXISTS public.get_repeat_segmentation_companies(INT);

CREATE OR REPLACE FUNCTION public.get_repeat_segmentation_companies(
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    inv_count BIGINT,
    invoices_count BIGINT,
    goods_revenue NUMERIC,
    services_revenue NUMERIC,
    avg_ticket NUMERIC,
    days_between INT,
    subgroup VARCHAR,
    abc_group VARCHAR,
    industry VARCHAR,
    status_name VARCHAR,
    current_status_id INT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
        SELECT c.code, c.name, c.current_status_id, COALESCE(sr.status_name, 'Не визначено') AS status_name,
               c.activity_direction_id, COALESCE(ad.name, 'Не вказано') AS industry
        FROM clients c
        JOIN client_year_activity cya ON c.code = cya.client_code 
            AND cya.sales_year = p_year AND cya.is_active = TRUE
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
        WHERE c.code NOT IN ('9653', '11230')
    ),
    client_stats AS (
        SELECT 
            ac.code, ac.name, ac.current_status_id, ac.status_name, ac.industry,
            COUNT(DISTINCT d.id) AS inv_count,
            MIN(d.invoice_date) AS first_date,
            MAX(d.invoice_date) AS last_date,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
            COALESCE(SUM(CASE WHEN pr.is_service = TRUE THEN sl.amount ELSE 0 END), 0) AS services_revenue
        FROM active_clients ac
        JOIN documents d ON d.client_code = ac.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY ac.code, ac.name, ac.current_status_id, ac.status_name, ac.industry
        HAVING COUNT(DISTINCT d.id) BETWEEN 2 AND 3
    )
    SELECT 
        cs.code::VARCHAR,
        cs.name::VARCHAR,
        cs.inv_count::BIGINT AS inv_count,
        cs.inv_count::BIGINT AS invoices_count,
        ROUND(cs.goods_revenue, 2)::NUMERIC AS goods_revenue,
        ROUND(cs.services_revenue, 2)::NUMERIC AS services_revenue,
        ROUND(cs.goods_revenue / NULLIF(cs.inv_count, 0), 2)::NUMERIC AS avg_ticket,
        COALESCE(cs.last_date - cs.first_date, 0)::INT AS days_between,
        CASE 
            WHEN cs.inv_count = 2 AND (cs.last_date - cs.first_date) <= 7 THEN 'Швидкий дубль (2)'
            WHEN cs.inv_count = 3 THEN 'Кандидати в постійні (3)'
            ELSE 'Центр (2-3)'
        END::VARCHAR AS subgroup,
        CASE 
            WHEN cs.goods_revenue >= 8700000 THEN 'A1'
            WHEN cs.goods_revenue >= 5800000 THEN 'A2'
            WHEN cs.goods_revenue >= 4350000 THEN 'A3'
            WHEN cs.goods_revenue >= 2900000 THEN 'B1'
            WHEN cs.goods_revenue >= 1450000 THEN 'B2'
            WHEN cs.goods_revenue >= 435000 THEN 'C1'
            ELSE 'C2'
        END::VARCHAR AS abc_group,
        cs.industry::VARCHAR,
        cs.status_name::VARCHAR,
        cs.current_status_id::INT
    FROM client_stats cs
    ORDER BY cs.goods_revenue DESC;
END;
$function$;
