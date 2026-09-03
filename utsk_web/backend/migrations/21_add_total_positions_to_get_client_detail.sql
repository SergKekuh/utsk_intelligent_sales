-- Migration 21: Add total_positions to get_client_detail()
DROP FUNCTION IF EXISTS public.get_client_detail(TEXT, INT);
DROP FUNCTION IF EXISTS public.get_client_detail(TEXT);

CREATE OR REPLACE FUNCTION public.get_client_detail(
    p_code TEXT,
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    status VARCHAR,
    total_revenue NUMERIC,
    total_invoices BIGINT,
    total_positions BIGINT,
    avg_check NUMERIC,
    last_purchase_date DATE
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        c.code,
        c.name,
        sr.status_name AS status,
        COALESCE(ROUND(SUM(sl.amount)::numeric, 0), 0) AS total_revenue,
        COUNT(DISTINCT d.id)::BIGINT AS total_invoices,
        COUNT(sl.id)::BIGINT AS total_positions,
        COALESCE(ROUND(AVG(sl.amount)::numeric, 0), 0) AS avg_check,
        MAX(d.invoice_date) AS last_purchase_date
    FROM clients c
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    LEFT JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    LEFT JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE c.code = p_code AND COALESCE(pr.is_service, FALSE) = FALSE AND (sl.amount IS NULL OR sl.amount > 0)
    GROUP BY c.code, c.name, sr.status_name;
END;
$function$;
