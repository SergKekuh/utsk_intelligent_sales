-- 1. Итоговое распределение по 16 отраслям
\echo '=== DISTRIBUTION ==='
SELECT 
    ad.id, ad.name,
    COUNT(c.code) FILTER (WHERE c.is_active_current = TRUE) AS active_clients,
    ROUND(
        COUNT(c.code) FILTER (WHERE c.is_active_current = TRUE)::NUMERIC
        / NULLIF((SELECT COUNT(*) FROM clients WHERE is_active_current = TRUE), 0) * 100, 1
    ) AS pct
FROM activity_directions ad
LEFT JOIN clients c ON c.activity_direction_id = ad.id
GROUP BY ad.id, ad.name
ORDER BY active_clients DESC;

-- 2. Baseline
\echo '=== BASELINE ==='
SELECT 'clients_active_current' AS metric, COUNT(*)::TEXT AS value 
FROM clients WHERE is_active_current = TRUE
UNION ALL
SELECT 'revenue_2026_goods',
    ROUND(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 2)::TEXT
FROM documents d
JOIN sales_lines sl ON sl.document_id = d.id
LEFT JOIN products pr ON sl.product_code = pr.code
WHERE EXTRACT(YEAR FROM d.invoice_date) = 2026;

-- 3. Confidence stats
\echo '=== CONFIDENCE STATS ==='
SELECT 
    COUNT(*) FILTER (WHERE is_direction_manual = TRUE) AS manual,
    COUNT(*) FILTER (WHERE direction_confidence >= 1.0) AS high_confidence,
    COUNT(*) FILTER (WHERE direction_confidence < 1.0 AND direction_confidence >= 0.7) AS medium,
    COUNT(*) FILTER (WHERE direction_confidence < 0.7) AS low
FROM clients
WHERE is_active_current = TRUE;

-- 4. Top 20 Машиностроение
\echo '=== TOP 20 GROUP 11 ==='
SELECT 
    c.code,
    c.name,
    c.edrpou,
    c.direction_confidence,
    cya.goods_revenue
FROM clients c
JOIN client_year_activity cya 
    ON cya.client_code = c.code 
    AND cya.sales_year = 2026
WHERE c.activity_direction_id = 11
  AND c.is_active_current = TRUE
ORDER BY cya.goods_revenue DESC NULLS LAST
LIMIT 20;

-- 5. Пограничные клиенты (< 0.7)
\echo '=== LOW CONFIDENCE ==='
SELECT 
    c.code,
    c.name,
    c.activity_direction_id,
    ad.name AS direction,
    c.direction_confidence
FROM clients c
LEFT JOIN activity_directions ad ON ad.id = c.activity_direction_id
LEFT JOIN client_year_activity cya 
    ON cya.client_code = c.code AND cya.sales_year = 2026
WHERE c.is_active_current = TRUE
  AND c.direction_confidence < 0.7
  AND c.code NOT IN ('9653', '11230', '8814')
ORDER BY cya.goods_revenue DESC NULLS LAST
LIMIT 20;
