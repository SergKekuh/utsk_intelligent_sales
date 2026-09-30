CREATE OR REPLACE FUNCTION public.get_segmentation_kpi(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(total_clients bigint, repeat_loyal_clients bigint, repeat_loyal_pct numeric, c2_clients bigint, c2_pct numeric, new_clients bigint, new_pct numeric, total_revenue numeric, total_invoices bigint, avg_check numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
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
                WHEN p_year = 2026 AND c.current_status_id IS NOT NULL THEN (c.current_status_id = 1)
                ELSE NOT EXISTS (
                    SELECT 1 FROM documents d_prev 
                    WHERE d_prev.client_code = c.code AND EXTRACT(YEAR FROM d_prev.invoice_date) = p_year - 1
                )
            END AS is_new_client
        FROM clients c
        JOIN active_clients ac ON c.code = ac.client_code
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY c.code, c.current_status_id
    )
    SELECT 
        COUNT(*)::BIGINT AS total_clients,
        COUNT(CASE WHEN cs.invoices_count >= 2 THEN 1 END)::BIGINT AS repeat_loyal_clients,
        ROUND(COUNT(CASE WHEN cs.invoices_count >= 2 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 1)::NUMERIC AS repeat_loyal_pct,
        COUNT(CASE WHEN cs.goods_revenue <= p_limit_price THEN 1 END)::BIGINT AS c2_clients,
        ROUND(COUNT(CASE WHEN cs.goods_revenue <= p_limit_price THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 1)::NUMERIC AS c2_pct,
        COUNT(CASE WHEN cs.is_new_client THEN 1 END)::BIGINT AS new_clients,
        ROUND(COUNT(CASE WHEN cs.is_new_client THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 1)::NUMERIC AS new_pct,
        ROUND(SUM(cs.goods_revenue)::NUMERIC, 2) AS total_revenue,
        SUM(cs.invoices_count)::BIGINT AS total_invoices,
        ROUND((SUM(cs.goods_revenue) / NULLIF(SUM(cs.invoices_count), 0))::NUMERIC, 2) AS avg_check
    FROM client_stats cs;
END;
$function$
