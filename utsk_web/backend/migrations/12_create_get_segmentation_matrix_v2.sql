-- =============================================================================
-- MIGRATION 12: Function get_segmentation_matrix_v2
-- Date: 2026-08-27
-- Description: Creates get_segmentation_matrix_v2(p_year INT, p_limit_price NUMERIC)
-- =============================================================================

DROP FUNCTION IF EXISTS public.get_segmentation_matrix_v2(INT, NUMERIC);
CREATE OR REPLACE FUNCTION public.get_segmentation_matrix_v2(
    p_year INT DEFAULT 2026,
    p_limit_price NUMERIC DEFAULT 146000
)
RETURNS TABLE(
    freq_group VARCHAR,
    total_clients INT,
    total_sales NUMERIC,
    c2_clients INT,
    c2_sales NUMERIC,
    new_clients INT,
    retained_clients INT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH freq_defs(sort_order, freq_code) AS (
        VALUES 
            (1, 'raz'::VARCHAR),
            (2, 'povt'::VARCHAR),
            (3, 'kvart'::VARCHAR),
            (4, 'mes'::VARCHAR),
            (5, 'post'::VARCHAR)
    ),
    active_clients AS (
        SELECT DISTINCT cya.client_code
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year AND cya.is_active = TRUE AND cya.client_code NOT IN ('9653', '11230')
    ),
    client_stats AS (
        SELECT 
            c.code,
            c.current_status_id,
            COUNT(DISTINCT d.id) AS invoices_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
            CASE 
                WHEN COUNT(DISTINCT d.id) = 1 THEN 'raz'
                WHEN COUNT(DISTINCT d.id) BETWEEN 2 AND 3 THEN 'povt'
                WHEN COUNT(DISTINCT d.id) BETWEEN 4 AND 10 THEN 'kvart'
                WHEN COUNT(DISTINCT d.id) BETWEEN 11 AND 40 THEN 'mes'
                ELSE 'post'
            END AS freq_group,
            CASE 
                WHEN p_year = 2026 AND c.current_status_id IS NOT NULL THEN (c.current_status_id = 1)
                ELSE NOT EXISTS (
                    SELECT 1 FROM documents d_prev 
                    WHERE d_prev.client_code = c.code AND EXTRACT(YEAR FROM d_prev.invoice_date) = p_year - 1
                )
            END AS is_new_client,
            EXISTS (
                SELECT 1 FROM documents d_prev 
                WHERE d_prev.client_code = c.code AND EXTRACT(YEAR FROM d_prev.invoice_date) = p_year - 1
            ) AS is_retained
        FROM clients c
        JOIN active_clients ac ON c.code = ac.client_code
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY c.code, c.current_status_id
    ),
    agg AS (
        SELECT 
            cs.freq_group,
            COUNT(*)::INT AS total_clients,
            ROUND(SUM(cs.goods_revenue), 2)::NUMERIC AS total_sales,
            COUNT(CASE WHEN cs.goods_revenue <= p_limit_price THEN 1 END)::INT AS c2_clients,
            ROUND(SUM(CASE WHEN cs.goods_revenue <= p_limit_price THEN cs.goods_revenue ELSE 0 END), 2)::NUMERIC AS c2_sales,
            COUNT(CASE WHEN cs.is_new_client THEN 1 END)::INT AS new_clients,
            COUNT(CASE WHEN cs.is_retained THEN 1 END)::INT AS retained_clients
        FROM client_stats cs
        GROUP BY cs.freq_group
    )
    SELECT 
        fd.freq_code AS freq_group,
        COALESCE(a.total_clients, 0)::INT AS total_clients,
        COALESCE(a.total_sales, 0.00)::NUMERIC AS total_sales,
        COALESCE(a.c2_clients, 0)::INT AS c2_clients,
        COALESCE(a.c2_sales, 0.00)::NUMERIC AS c2_sales,
        COALESCE(a.new_clients, 0)::INT AS new_clients,
        COALESCE(a.retained_clients, 0)::INT AS retained_clients
    FROM freq_defs fd
    LEFT JOIN agg a ON fd.freq_code = a.freq_group
    ORDER BY fd.sort_order;
END;
$function$;
