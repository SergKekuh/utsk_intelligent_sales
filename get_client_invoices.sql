CREATE OR REPLACE FUNCTION public.get_client_invoices(p_code text, p_year integer DEFAULT 2026, p_month_int integer DEFAULT NULL::integer, p_date_from date DEFAULT NULL::date, p_date_to date DEFAULT NULL::date, p_limit integer DEFAULT 500)
 RETURNS TABLE(date text, number character varying, total numeric, positions bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(d.invoice_date, 'DD.MM.YYYY') AS date,
        d.doc_number AS number,
        ROUND(SUM(sl.amount)::numeric, 0) AS total,
        COUNT(sl.id)::BIGINT AS positions
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.client_code = p_code
      AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
      AND (
          (p_date_from IS NOT NULL AND p_date_to IS NOT NULL AND d.invoice_date BETWEEN p_date_from AND p_date_to)
          OR
          (p_date_from IS NULL AND p_month_int IS NOT NULL AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND EXTRACT(MONTH FROM d.invoice_date) = p_month_int)
          OR
          (p_date_from IS NULL AND p_month_int IS NULL AND EXTRACT(YEAR FROM d.invoice_date) = p_year)
      )
    GROUP BY d.id, d.invoice_date, d.doc_number
    ORDER BY d.invoice_date DESC
    LIMIT COALESCE(p_limit, 500);
END;
$function$
