CREATE OR REPLACE FUNCTION public.get_c2_detail(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(client_code character varying, invoices_count bigint, goods_revenue numeric, freq_group text, internal_class text)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
        SELECT DISTINCT cya.client_code
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year
          AND cya.is_active = TRUE
          AND cya.client_code != '9653'
    ),
    client_stats AS (
        SELECT 
            d.client_code,
            COUNT(DISTINCT d.id)::BIGINT AS invoices_count,
            COUNT(DISTINCT d.invoice_date)::BIGINT AS distinct_dates,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN active_clients ac ON d.client_code = ac.client_code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY d.client_code
    ),
    c2_clients AS (
        SELECT 
            cs.client_code,
            cs.invoices_count,
            cs.distinct_dates,
            cs.goods_revenue,
            (CASE
                WHEN cs.invoices_count = 1 THEN '1'
                WHEN cs.invoices_count = 2 AND cs.distinct_dates = 1 THEN '2_1d'
                WHEN cs.invoices_count = 2 AND cs.distinct_dates = 2 THEN '2_diff'
                WHEN cs.invoices_count = 3 THEN '3'
                WHEN cs.invoices_count BETWEEN 4 AND 10 THEN '4_10'
                WHEN cs.invoices_count BETWEEN 11 AND 40 THEN '11_40'
                ELSE '41_plus'
            END)::TEXT AS freq_group
        FROM client_stats cs
        WHERE cs.goods_revenue < p_limit_price
    ),
    c2_with_cum AS (
        SELECT 
            c2.*,
            SUM(c2.goods_revenue) OVER (ORDER BY c2.goods_revenue DESC, c2.client_code) AS cum_revenue,
            SUM(c2.goods_revenue) OVER () AS total_c2_revenue
        FROM c2_clients c2
    )
    SELECT 
        cw.client_code,
        cw.invoices_count,
        cw.goods_revenue,
        cw.freq_group,
        (CASE
            WHEN cw.total_c2_revenue IS NULL OR cw.total_c2_revenue = 0 THEN 'C'
            WHEN cw.cum_revenue <= cw.total_c2_revenue * 0.80 OR (cw.cum_revenue - cw.goods_revenue) < cw.total_c2_revenue * 0.80 THEN 'A'
            WHEN cw.cum_revenue <= cw.total_c2_revenue * 0.95 OR (cw.cum_revenue - cw.goods_revenue) < cw.total_c2_revenue * 0.95 THEN 'B'
            ELSE 'C'
        END)::TEXT AS internal_class
    FROM c2_with_cum cw;
END;
$function$
