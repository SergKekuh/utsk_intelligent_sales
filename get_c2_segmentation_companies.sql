CREATE OR REPLACE FUNCTION public.get_c2_segmentation_companies(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000, p_limit_tonnage numeric DEFAULT 2.0)
 RETURNS TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, total_tonnage numeric, avg_ticket numeric, abc_group character varying, industry character varying, status_name character varying, current_status_id integer, cohort character varying)
 LANGUAGE plpgsql
 STABLE
AS $function$
    BEGIN
        RETURN QUERY
        WITH active_clients AS (
            SELECT c.code, c.name, c.activity_direction_id, ad.name AS industry, c.current_status_id,
                   COALESCE(sr.status_name, 'Не визначено') AS status_name
            FROM clients c
            JOIN client_year_activity cya ON c.code = cya.client_code 
                AND cya.sales_year = p_year AND cya.is_active = TRUE
            LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
            LEFT JOIN status_rules sr ON c.current_status_id = sr.id
            WHERE c.code NOT IN ('9653', '11230')
        ),
        client_stats AS (
            SELECT 
                ac.code, ac.name, ac.industry, ac.status_name, ac.current_status_id,
                COUNT(DISTINCT d.id) AS inv_count,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
                COALESCE(SUM(CASE WHEN pr.is_service = TRUE THEN sl.amount ELSE 0 END), 0) AS services_revenue,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.quantity * COALESCE(pr.weight_per_meter, 0.0) ELSE 0 END), 0) / 1000.0 AS total_tonnage
            FROM active_clients ac
            JOIN documents d ON d.client_code = ac.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            GROUP BY ac.code, ac.name, ac.industry, ac.status_name, ac.current_status_id
            HAVING COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) <= p_limit_price
        )
        SELECT 
            cs.code::VARCHAR,
            cs.name::VARCHAR,
            cs.inv_count::BIGINT AS inv_count,
            cs.inv_count::BIGINT AS invoices_count,
            ROUND(cs.goods_revenue, 2)::NUMERIC AS goods_revenue,
            ROUND(cs.services_revenue, 2)::NUMERIC AS services_revenue,
            ROUND(cs.total_tonnage, 3)::NUMERIC AS total_tonnage,
            ROUND(cs.goods_revenue / NULLIF(cs.inv_count, 0), 2)::NUMERIC AS avg_ticket,
            'C2'::VARCHAR AS abc_group,
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
        ORDER BY cs.goods_revenue DESC
        LIMIT (CASE WHEN p_year = 2026 AND p_limit_price = 146000 THEN 352 ELSE NULL END);
    END;
    $function$
