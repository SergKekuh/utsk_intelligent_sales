-- Аудит 1: Создание бекапа
CREATE TABLE IF NOT EXISTS clients_direction_backup_v4 AS
SELECT code, name, activity_direction_id, direction_confidence, is_direction_manual
FROM clients;

-- Аудит 2: Наличие КВЕД
\echo '=== KVED COLUMNS ==='
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'clients'
  AND (
      column_name ILIKE '%kved%' OR column_name ILIKE '%okved%'
      OR column_name ILIKE '%activity_type%' OR column_name ILIKE '%industry%'
  );

-- Аудит 3: Топ-20 клиентов группы 9
\echo '=== TOP 20 GROUP 9 CLIENTS ==='
SELECT 
    c.code, c.name, c.edrpou, cya.goods_revenue
FROM clients c
JOIN client_year_activity cya 
    ON cya.client_code = c.code 
    AND cya.sales_year = 2026
WHERE c.activity_direction_id = 9
  AND c.is_active_current = TRUE
  AND c.code NOT IN ('9653', '11230', '8814')
ORDER BY cya.goods_revenue DESC
LIMIT 20;

-- Аудит 4: Топ размеры для группы 9
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
    CROSS JOIN LATERAL parse_pipe_attributes(p.name) nps
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
