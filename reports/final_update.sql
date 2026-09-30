-- L1 Маппинг известных компаний (Топ по выручке)
UPDATE clients SET activity_direction_id = 6, direction_confidence = 1.0 
WHERE name ~* '(ютмк|усм дніпро|юнимет|альфа стіл|стальмира|минералы украины|стальные решения|статус пайп|метпрофи|леарт)';

UPDATE clients SET activity_direction_id = 11, direction_confidence = 1.0 
WHERE name ~* '(арматура вкм|спрут-украина)';

UPDATE clients SET activity_direction_id = 3, direction_confidence = 1.0 
WHERE name ~* '(оск-технолоджи)';

-- L3 Расширенные паттерны
SELECT * FROM classify_clients_directions();

-- L4 Корзина
SELECT * FROM classify_clients_by_basket();

-- Регрессия
SELECT 
    ad.id, ad.name,
    COUNT(c.code) FILTER (WHERE c.is_active_current = TRUE) AS active_clients
FROM activity_directions ad
LEFT JOIN clients c ON c.activity_direction_id = ad.id
GROUP BY ad.id, ad.name
ORDER BY active_clients DESC;
