\echo '=== TOP SIZES GROUP 9 ==='
WITH group9_clients AS (
    SELECT code 
    FROM clients 
    WHERE activity_direction_id = 9
      AND is_active_current = TRUE
      AND code NOT IN ('9653', '11230', '8814')
),
exploded AS (
    SELECT 
        nps.size_key,
        nps.size_display,
        nps.pipe_type_ua,
        sl.amount
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    JOIN products p ON sl.product_code = p.code
    CROSS JOIN LATERAL parse_pipe_attributes(p.name) pa
    CROSS JOIN LATERAL (
        SELECT 
            CASE 
                WHEN pa.is_prof AND pa.prof_w IS NOT NULL AND pa.prof_h IS NOT NULL AND pa.wall IS NOT NULL
                    THEN 'prof_' || pa.prof_w::TEXT || 'x' || pa.prof_h::TEXT || 'x' || pa.wall::TEXT
                WHEN pa.is_prof AND pa.prof_w IS NOT NULL AND pa.prof_h IS NOT NULL
                    THEN 'prof_' || pa.prof_w::TEXT || 'x' || pa.prof_h::TEXT
                WHEN NOT pa.is_prof AND pa.diameter IS NOT NULL AND pa.wall IS NOT NULL
                    THEN 'round_' || pa.diameter::TEXT || 'x' || pa.wall::TEXT
                ELSE NULL
            END AS size_key,
            CASE 
                WHEN pa.is_prof AND pa.prof_w IS NOT NULL AND pa.prof_h IS NOT NULL AND pa.wall IS NOT NULL
                    THEN pa.prof_w::TEXT || '×' || pa.prof_h::TEXT || '×' || pa.wall::TEXT
                WHEN pa.is_prof AND pa.prof_w IS NOT NULL AND pa.prof_h IS NOT NULL
                    THEN pa.prof_w::TEXT || '×' || pa.prof_h::TEXT
                WHEN NOT pa.is_prof AND pa.diameter IS NOT NULL AND pa.wall IS NOT NULL
                    THEN pa.diameter::TEXT || '×' || pa.wall::TEXT
                ELSE NULL
            END AS size_display,
            CASE 
                WHEN pa.is_prof AND pa.prof_w = pa.prof_h THEN 'Квадратная труба'
                WHEN pa.is_prof AND pa.prof_w <> pa.prof_h THEN 'Прямоугольная труба'
                WHEN NOT pa.is_prof THEN 'Круглая труба'
                ELSE NULL
            END AS pipe_type_ua
    ) nps
    WHERE d.client_code IN (SELECT code FROM group9_clients)
      AND EXTRACT(YEAR FROM d.invoice_date) = 2026
      AND COALESCE(p.is_service, FALSE) = FALSE
      AND nps.size_key IS NOT NULL
)
SELECT 
    size_display,
    pipe_type_ua,
    SUM(amount) AS revenue,
    COUNT(*) AS purchases
FROM exploded
GROUP BY size_key, size_display, pipe_type_ua
ORDER BY revenue DESC
LIMIT 10;
