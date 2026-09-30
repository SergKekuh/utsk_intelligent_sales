SELECT 'L3 fix' AS step, * FROM classify_clients_directions(FALSE);
SELECT 'L4 fix' AS step, * FROM classify_clients_by_basket();

\echo '=== FINAL DISTRIBUTION ==='
SELECT 
    ad.id, ad.name,
    COUNT(c.code) FILTER (WHERE c.is_active_current = TRUE) AS clients
FROM activity_directions ad
LEFT JOIN clients c ON c.activity_direction_id = ad.id
GROUP BY ad.id, ad.name
ORDER BY clients DESC;

\echo '=== NEW TOP 20 GROUP 11 ==='
SELECT 
    c.code,
    c.name,
    c.direction_confidence,
    c.direction_source,
    cya.goods_revenue
FROM clients c
JOIN client_year_activity cya 
    ON cya.client_code = c.code 
    AND cya.sales_year = 2026
WHERE c.activity_direction_id = 11
  AND c.is_active_current = TRUE
ORDER BY cya.goods_revenue DESC NULLS LAST
LIMIT 20;
