BEGIN;

UPDATE products p
SET 
    diameter = sub.diameter,
    wall_thickness = sub.wall,
    profile_width = sub.prof_w,
    profile_height = sub.prof_h,
    is_profile = sub.is_prof,
    standard_name = sub.standard,
    weight_per_meter = COALESCE(p.weight_per_meter, sub.weight_m)
FROM (
    SELECT 
        p2.code,
        dims.diameter, dims.wall, dims.prof_w, dims.prof_h,
        dims.is_prof, dims.standard, dims.weight_m
    FROM products p2
    CROSS JOIN LATERAL parse_pipe_attributes(p2.name) dims
    WHERE dims.diameter IS NOT NULL
) sub
WHERE p.code = sub.code AND p.diameter IS NULL;

UPDATE products p
SET 
    first_purchase_date = sub.first_date,
    last_purchase_date = sub.last_date
FROM (
    SELECT sl.product_code,
        MIN(d.invoice_date) AS first_date,
        MAX(d.invoice_date) AS last_date
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    GROUP BY sl.product_code
) sub
WHERE p.code = sub.product_code;

UPDATE products 
SET is_new_arrival = TRUE 
WHERE is_new_arrival = FALSE 
  AND (first_purchase_date IS NULL OR created_at >= CURRENT_DATE - INTERVAL '90 days');

COMMIT;
