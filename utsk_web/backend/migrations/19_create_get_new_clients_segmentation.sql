-- =============================================================================
-- MIGRATION 19: Functions get_new_clients_segmentation and get_new_clients_monthly_revenue
-- Date: 2026-08-28
-- Description: Functions for new clients (status_id = 1) segmentation by frequency
-- =============================================================================

DROP FUNCTION IF EXISTS public.get_new_clients_segmentation(INT);

CREATE OR REPLACE FUNCTION public.get_new_clients_segmentation(
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
    first_purchase DATE,
    last_purchase DATE,
    abc_group VARCHAR,
    industry VARCHAR,
    status_name VARCHAR,
    current_status_id INT,
    cohort VARCHAR
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH new_clients AS (
        SELECT c.code, c.name, c.activity_direction_id, ad.name AS industry,
               c.current_status_id, COALESCE(sr.status_name, 'Новий') AS status_name
        FROM clients c
        JOIN client_year_activity cya ON c.code = cya.client_code 
            AND cya.sales_year = p_year AND cya.is_active = TRUE
        LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        WHERE c.current_status_id = 1
          AND c.code NOT IN ('9653', '11230')
    ),
    client_stats AS (
        SELECT 
            nc.code, nc.name, nc.industry, nc.status_name, nc.current_status_id,
            COUNT(DISTINCT d.id) AS inv_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
            COALESCE(SUM(CASE WHEN pr.is_service = TRUE THEN sl.amount ELSE 0 END), 0) AS services_revenue,
            MIN(d.invoice_date) AS first_purchase,
            MAX(d.invoice_date) AS last_purchase
        FROM new_clients nc
        JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY nc.code, nc.name, nc.industry, nc.status_name, nc.current_status_id
    )
    SELECT 
        cs.code::VARCHAR,
        cs.name::VARCHAR,
        cs.inv_count::BIGINT AS inv_count,
        cs.inv_count::BIGINT AS invoices_count,
        ROUND(cs.goods_revenue, 2)::NUMERIC AS goods_revenue,
        ROUND(cs.services_revenue, 2)::NUMERIC AS services_revenue,
        ROUND(cs.goods_revenue / NULLIF(cs.inv_count, 0), 2)::NUMERIC AS avg_ticket,
        cs.first_purchase::DATE AS first_purchase,
        cs.last_purchase::DATE AS last_purchase,
        CASE 
            WHEN cs.goods_revenue >= 8700000 THEN 'A1'
            WHEN cs.goods_revenue >= 5800000 THEN 'A2'
            WHEN cs.goods_revenue >= 4350000 THEN 'A3'
            WHEN cs.goods_revenue >= 2900000 THEN 'B1'
            WHEN cs.goods_revenue >= 1450000 THEN 'B2'
            WHEN cs.goods_revenue >= 435000 THEN 'C1'
            ELSE 'C2'
        END::VARCHAR AS abc_group,
        COALESCE(cs.industry, 'Не вказано')::VARCHAR AS industry,
        cs.status_name::VARCHAR,
        cs.current_status_id::INT,
        CASE 
            WHEN cs.inv_count = 1 THEN 'Разові (1)'
            WHEN cs.inv_count BETWEEN 2 AND 3 THEN 'Повторні (2-3)'
            WHEN cs.inv_count BETWEEN 4 AND 10 THEN 'Квартальні (4-10)'
            WHEN cs.inv_count BETWEEN 11 AND 40 THEN 'Місячні (11-40)'
            WHEN cs.inv_count BETWEEN 41 AND 170 THEN 'Тижневі (41-170)'
            ELSE 'Щоденні (>170)'
        END::VARCHAR AS cohort
    FROM client_stats cs
    ORDER BY cs.goods_revenue DESC;
END;
$function$;

DROP FUNCTION IF EXISTS public.get_new_clients_monthly_revenue(INT);

CREATE OR REPLACE FUNCTION public.get_new_clients_monthly_revenue(
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    month_num INT,
    revenue NUMERIC,
    invoices_count BIGINT,
    active_clients BIGINT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH new_clients AS (
        SELECT c.code
        FROM clients c
        JOIN client_year_activity cya ON c.code = cya.client_code 
            AND cya.sales_year = p_year AND cya.is_active = TRUE
        WHERE c.current_status_id = 1
          AND c.code NOT IN ('9653', '11230')
    )
    SELECT 
        EXTRACT(MONTH FROM d.invoice_date)::INT AS month_num,
        ROUND(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0), 2)::NUMERIC AS revenue,
        COUNT(DISTINCT d.id)::BIGINT AS invoices_count,
        COUNT(DISTINCT nc.code)::BIGINT AS active_clients
    FROM new_clients nc
    JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    GROUP BY EXTRACT(MONTH FROM d.invoice_date)
    ORDER BY month_num;
END;
$function$;
