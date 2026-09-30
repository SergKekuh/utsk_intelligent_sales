CREATE OR REPLACE FUNCTION public.get_segmentation_current_year(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(sort_order integer, freq_group character varying, freq_name character varying, freq_range character varying, total_count bigint, total_revenue numeric, new_count bigint, c2_count bigint, c2_revenue numeric, retained_count bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH freq_defs(sort_order, freq_group, freq_name, freq_range) AS (
        VALUES 
            (1, 'raz'::VARCHAR, 'РАЗОВІ'::VARCHAR, '1'::VARCHAR),
            (2, 'povt'::VARCHAR, 'ПОВТОРНІ'::VARCHAR, '2-3'::VARCHAR),
            (3, 'kvart'::VARCHAR, 'КВАРТАЛЬНІ'::VARCHAR, '4-10'::VARCHAR),
            (4, 'mes'::VARCHAR, 'МІСЯЧНІ'::VARCHAR, '11-40'::VARCHAR),
            (5, 'ned'::VARCHAR, 'ТИЖНЕВІ'::VARCHAR, '41-170'::VARCHAR),
            (6, 'den'::VARCHAR, 'ЩОДЕННІ'::VARCHAR, '>170'::VARCHAR)
    ),
    active_clients AS (
        SELECT c.code
        FROM clients c
        JOIN client_year_activity cya ON c.code = cya.client_code 
            AND cya.sales_year = p_year AND cya.is_active = TRUE
        WHERE c.code NOT IN ('9653', '11230')
    ),
    frequency AS (
        SELECT 
            ac.code,
            COUNT(DISTINCT d.id) AS inv_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
            EXISTS(SELECT 1 FROM clients WHERE code = ac.code AND current_status_id = 1) AS is_new,
            EXISTS(SELECT 1 FROM documents d_prev WHERE d_prev.client_code = ac.code AND EXTRACT(YEAR FROM d_prev.invoice_date) = p_year - 1) AS is_retained
        FROM active_clients ac
        JOIN documents d ON d.client_code = ac.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY ac.code
    ),
    agg AS (
        SELECT 
            CASE 
                WHEN f.inv_count = 1 THEN 'raz'
                WHEN f.inv_count BETWEEN 2 AND 3 THEN 'povt'
                WHEN f.inv_count BETWEEN 4 AND 10 THEN 'kvart'
                WHEN f.inv_count BETWEEN 11 AND 40 THEN 'mes'
                WHEN f.inv_count BETWEEN 41 AND 170 THEN 'ned'
                ELSE 'den'
            END AS freq_group,
            COUNT(*)::BIGINT AS total_count,
            ROUND(SUM(f.goods_revenue), 2)::NUMERIC AS total_revenue,
            SUM(CASE WHEN f.is_new THEN 1 ELSE 0 END)::BIGINT AS new_count,
            SUM(CASE WHEN f.goods_revenue <= p_limit_price THEN 1 ELSE 0 END)::BIGINT AS c2_count,
            ROUND(SUM(CASE WHEN f.goods_revenue <= p_limit_price THEN f.goods_revenue ELSE 0 END), 2)::NUMERIC AS c2_revenue,
            SUM(CASE WHEN f.is_retained THEN 1 ELSE 0 END)::BIGINT AS retained_count
        FROM frequency f
        GROUP BY 
            CASE 
                WHEN f.inv_count = 1 THEN 'raz'
                WHEN f.inv_count BETWEEN 2 AND 3 THEN 'povt'
                WHEN f.inv_count BETWEEN 4 AND 10 THEN 'kvart'
                WHEN f.inv_count BETWEEN 11 AND 40 THEN 'mes'
                WHEN f.inv_count BETWEEN 41 AND 170 THEN 'ned'
                ELSE 'den'
            END
    )
    SELECT 
        fd.sort_order,
        fd.freq_group,
        fd.freq_name,
        fd.freq_range,
        COALESCE(a.total_count, 0)::BIGINT AS total_count,
        COALESCE(a.total_revenue, 0.00)::NUMERIC AS total_revenue,
        COALESCE(a.new_count, 0)::BIGINT AS new_count,
        COALESCE(a.c2_count, 0)::BIGINT AS c2_count,
        COALESCE(a.c2_revenue, 0.00)::NUMERIC AS c2_revenue,
        COALESCE(a.retained_count, 0)::BIGINT AS retained_count
    FROM freq_defs fd
    LEFT JOIN agg a ON fd.freq_group = a.freq_group
    ORDER BY fd.sort_order;
END;
$function$
