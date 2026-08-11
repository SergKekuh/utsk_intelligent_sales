-- ============================================================================
-- UTSK Intelligent Sales — Миграция 05: Функция get_invoice_header
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_invoice_header(
    p_number VARCHAR
)
RETURNS TABLE(
    date TEXT,
    number VARCHAR,
    total NUMERIC
)
LANGUAGE plpgsql
STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(d.invoice_date, 'DD.MM.YYYY')::TEXT,
        d.doc_number::VARCHAR,
        COALESCE(ROUND(SUM(sl.amount)::numeric, 0), 0)::NUMERIC
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    WHERE d.doc_number = p_number
    GROUP BY d.id, d.invoice_date, d.doc_number;
END;
$function$;
