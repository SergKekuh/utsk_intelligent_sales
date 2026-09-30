-- 1. Восстановить из бэкапа
UPDATE clients c
SET 
    activity_direction_id = b.activity_direction_id,
    direction_confidence = b.direction_confidence
FROM clients_direction_backup_v4 b
WHERE c.code = b.code;

-- Fix bugs in restored data
UPDATE clients SET direction_confidence = 1.0 WHERE direction_confidence = 100.0;
UPDATE clients SET direction_source = NULL;

-- 1.5 Ручной L1 (восстановление)
UPDATE clients SET activity_direction_id = 6, direction_confidence = 1.0, direction_source = 'manual'
WHERE name ~* '(ютмк|усм дніпро|юнимет|альфа стіл|стальмира|минералы украины|стальные решения|статус пайп|метпрофи|леарт|вартис|викант)';

UPDATE clients SET activity_direction_id = 11, direction_confidence = 1.0, direction_source = 'manual'
WHERE name ~* '(арматура вкм|спрут-украина)';

UPDATE clients SET activity_direction_id = 3, direction_confidence = 1.0, direction_source = 'manual'
WHERE name ~* '(оск-технолоджи)';

-- 2. Применить исправленные функции
SELECT 'L3 fix' AS step, * FROM classify_clients_directions(FALSE);
SELECT 'L4 fix' AS step, * FROM classify_clients_by_basket();

-- 3. Проверить результат
\echo '=== NEW DISTRIBUTION ==='
SELECT 
    ad.id, ad.name,
    COUNT(c.code) FILTER (WHERE c.is_active_current = TRUE) AS clients
FROM activity_directions ad
LEFT JOIN clients c ON c.activity_direction_id = ad.id
GROUP BY ad.id, ad.name
ORDER BY clients DESC;

-- 4. Топ-20 Машиностроения
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

-- 5. Топ-20 Трейдеров
\echo '=== NEW TOP 20 GROUP 6 ==='
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
WHERE c.activity_direction_id = 6
  AND c.is_active_current = TRUE
ORDER BY cya.goods_revenue DESC NULLS LAST
LIMIT 20;
