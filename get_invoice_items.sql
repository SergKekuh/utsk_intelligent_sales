CREATE OR REPLACE FUNCTION public.get_invoice_items(p_number text)
 RETURNS TABLE(code character varying, name character varying, quantity numeric, total numeric, weight_kg numeric, price numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        sl.product_code AS code,
        COALESCE(pr.name, sl.product_code) AS name,
        COALESCE(sl.quantity, 0)::NUMERIC AS quantity,
        COALESCE(sl.amount, 0)::NUMERIC AS total,
        (COALESCE(pr.weight_per_meter, 0) * COALESCE(sl.quantity, 0))::NUMERIC AS weight_kg,
        (CASE WHEN COALESCE(sl.quantity, 0) > 0 THEN sl.amount / sl.quantity ELSE 0 END)::NUMERIC AS price
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.doc_number = p_number
    ORDER BY sl.id;
END;
$function$
