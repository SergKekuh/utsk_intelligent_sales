-- L1 Маппинг известных компаний (Топ по выручке)
UPDATE clients SET activity_direction_id = 6, direction_confidence = 1.0 
WHERE name ~* '(ютмк|усм дніпро|юнимет|альфа стіл|стальмира|минералы украины|стальные решения|статус пайп|метпрофи|леарт)';

UPDATE clients SET activity_direction_id = 11, direction_confidence = 1.0 
WHERE name ~* '(арматура вкм|спрут-украина)';

UPDATE clients SET activity_direction_id = 3, direction_confidence = 1.0 
WHERE name ~* '(оск-технолоджи)';

-- Улучшенные паттерны L3
WITH classified AS (
    SELECT 
        code,
        CASE
            WHEN name ~* '(пайп|сталь|стіл|метпроф|юнимет|ютмк|метал|метаст|сплав)' THEN 6
            WHEN name ~* '(арматура|труб|фитинг|фітинг)' THEN 11
            WHEN name ~* '(строй|буд|ремонт)' THEN 2
            WHEN name ~* '(холдинг|груп|групп)' THEN 9
            ELSE 9
        END AS new_dir_id
    FROM clients
    WHERE activity_direction_id = 9
)
UPDATE clients c
SET activity_direction_id = cl.new_dir_id,
    direction_confidence = 0.70
FROM classified cl
WHERE c.code = cl.code
  AND cl.new_dir_id <> 9;

-- Перепроверим распределение
SELECT 
    ad.id, ad.name,
    COUNT(c.code) FILTER (WHERE c.is_active_current = TRUE) AS active_clients
FROM activity_directions ad
LEFT JOIN clients c ON c.activity_direction_id = ad.id
GROUP BY ad.id, ad.name
ORDER BY active_clients DESC;
