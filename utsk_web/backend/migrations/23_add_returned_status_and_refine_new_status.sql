-- =============================================================================
-- MIGRATION 23: Add 'Вернувшиеся' status and refine 'Новые' logic (Final Version 3)
-- Date: 2026-09-04
-- Database: bd_intelligent_sales, Schema: public
-- Description:
--   - Add 10th status 'Вернувшиеся' (id=10, priority=25)
--   - 'Вернувшиеся': purchases in current year (>= 1), 0 in previous year,
--                    purchases in year before last (>= 1).
--   - 'Новые': purchases in current year (>= 1), 0 in previous year,
--              0 in year before last (2 years without purchases, prior history does not matter).
--   - Update status descriptions and priorities
--   - Recalculate client analytics
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- ШАГ 0: БЭКАП ТАБЛИЦ
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS status_rules_backup_20260904 AS SELECT * FROM status_rules;
CREATE TABLE IF NOT EXISTS clients_backup_20260904 AS SELECT * FROM clients;

-- -----------------------------------------------------------------------------
-- ШАГ 1: ДОБАВИТЬ ЗАПИСЬ «Вернувшиеся» В status_rules
-- -----------------------------------------------------------------------------
INSERT INTO status_rules (id, status_name, min_current_year, max_current_year, min_prev_year, max_prev_year, priority, description)
VALUES 
(10, 'Вернувшиеся', 1, 9999, 0, 0, 25, 'Покупали в позапрошлом году, пропустили прошлый, вернулись в текущем')
ON CONFLICT (id) DO UPDATE SET
    status_name = EXCLUDED.status_name,
    min_current_year = EXCLUDED.min_current_year,
    max_current_year = EXCLUDED.max_current_year,
    min_prev_year = EXCLUDED.min_prev_year,
    max_prev_year = EXCLUDED.max_prev_year,
    priority = EXCLUDED.priority,
    description = EXCLUDED.description;

-- Синхронизация sequence
SELECT setval('status_rules_id_seq', GREATEST((SELECT MAX(id) FROM status_rules), 10));

-- Обновление всех приоритетов (1..10)
UPDATE status_rules SET priority = CASE id
    WHEN 9 THEN 10   -- Ушедшие
    WHEN 8 THEN 20   -- Спящие
    WHEN 10 THEN 25  -- Вернувшиеся (новый)
    WHEN 1 THEN 30   -- Новые
    WHEN 2 THEN 40   -- Разовые
    WHEN 3 THEN 50   -- Повторные
    WHEN 4 THEN 60   -- Ежеквартальные
    WHEN 5 THEN 70   -- Ежемесячные
    WHEN 6 THEN 80   -- Еженедельные
    WHEN 7 THEN 90   -- Ежедневные
END WHERE id IN (1,2,3,4,5,6,7,8,9,10);

-- -----------------------------------------------------------------------------
-- ШАГ 2: ОБНОВИТЬ ОПИСАНИЯ ПРАВИЛ
-- -----------------------------------------------------------------------------
UPDATE status_rules 
SET description = '2 года не покупали (прошлый и позапрошлый), но появились в текущем'
WHERE status_name = 'Новые';

UPDATE status_rules 
SET description = 'Покупали в позапрошлом году, пропустили прошлый, вернулись в текущем'
WHERE status_name = 'Вернувшиеся';

-- -----------------------------------------------------------------------------
-- ШАГ 3: ОБНОВИТЬ ФУНКЦИЮ calculate_client_status
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.calculate_client_status(p_client_code character varying)
RETURNS integer
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_year_count INT := 0;     -- текущий (2026)
    v_prev_year_count INT := 0;        -- прошлый (2025)
    v_two_years_ago_count INT := 0;    -- позапрошлый (2024)
    v_status_id INT;
    v_rule RECORD;
    v_current_year INTEGER := EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER;
    v_prev_year INTEGER := v_current_year - 1;
BEGIN
    -- Покупки в текущем году (2026)
    SELECT COUNT(*) INTO v_current_year_count 
    FROM documents WHERE client_code = p_client_code 
      AND EXTRACT(YEAR FROM invoice_date) = v_current_year;

    -- Покупки в прошлом году (2025)
    SELECT COUNT(*) INTO v_prev_year_count 
    FROM documents WHERE client_code = p_client_code 
      AND EXTRACT(YEAR FROM invoice_date) = v_prev_year;

    -- Покупки в позапрошлом году (2024)
    SELECT COUNT(*) INTO v_two_years_ago_count 
    FROM documents WHERE client_code = p_client_code 
      AND EXTRACT(YEAR FROM invoice_date) = v_current_year - 2;

    -- 1. Если есть покупки в текущем году и не было в прошлом (prev = 0):
    IF v_current_year_count >= 1 AND v_prev_year_count = 0 THEN
        -- «Вернувшиеся»: 0 в прошлом, но БЫЛИ в позапрошлом (>= 1)
        IF v_two_years_ago_count >= 1 THEN
            SELECT id INTO v_status_id FROM status_rules WHERE status_name = 'Вернувшиеся';
        -- «Новые»: 0 в прошлом и 0 в позапрошлом (неважно, что было раньше)
        ELSIF v_two_years_ago_count = 0 THEN
            SELECT id INTO v_status_id FROM status_rules WHERE status_name = 'Новые';
        END IF;
    ELSE
        -- 2. Основной цикл для остальных статусов (Ушедшие, Спящие, Разовые, Повторные и т.д.)
        FOR v_rule IN SELECT * FROM status_rules WHERE id NOT IN (1, 10) ORDER BY priority LOOP
            IF (v_rule.min_current_year IS NULL OR v_current_year_count >= v_rule.min_current_year) 
               AND (v_rule.max_current_year IS NULL OR v_current_year_count <= v_rule.max_current_year)
               AND (v_rule.min_prev_year IS NULL OR v_prev_year_count >= v_rule.min_prev_year)
               AND (v_rule.max_prev_year IS NULL OR v_prev_year_count <= v_rule.max_prev_year)
            THEN
                v_status_id := v_rule.id;
                EXIT;
            END IF;
        END LOOP;
    END IF;

    -- 3. Резервный статус (если не определен)
    IF v_status_id IS NULL THEN
        SELECT id INTO v_status_id FROM status_rules WHERE status_name = 'Ушедшие';
    END IF;

    RETURN v_status_id;
END;
$$;

ALTER FUNCTION public.calculate_client_status(p_client_code character varying) OWNER TO postgres;

-- -----------------------------------------------------------------------------
-- ШАГ 4: ФУНКЦИЯ update_client_analytics И ПЕРЕСЧЁТ
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_client_analytics(p_client_code character varying DEFAULT NULL::character varying)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
    WITH client_stats AS (
        SELECT 
            c.code,
            MIN(d.invoice_date) AS first_date,
            MAX(d.invoice_date) AS last_date
        FROM clients c
        LEFT JOIN documents d ON d.client_code = c.code
        WHERE (p_client_code IS NULL OR c.code = p_client_code)
        GROUP BY c.code
    )
    UPDATE clients c
    SET 
        first_purchase_date = cs.first_date,
        last_purchase_date = cs.last_date,
        current_status_id = calculate_client_status(c.code),
        requires_survey = CASE 
            WHEN calculate_client_status(c.code) = (SELECT id FROM status_rules WHERE status_name = 'Новые')
                 AND c.survey_completed_at IS NULL 
            THEN TRUE 
            ELSE FALSE 
        END,
        updated_at = CURRENT_TIMESTAMP
    FROM client_stats cs
    WHERE c.code = cs.code;
END;
$$;

ALTER FUNCTION public.update_client_analytics(p_client_code character varying) OWNER TO postgres;

-- -----------------------------------------------------------------------------
-- ШАГ 5: ОБНОВИТЬ get_statuses_distribution ДЛЯ ОТОБРАЖЕНИЯ ВСЕХ 10 СТАТУСОВ
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_statuses_distribution()
RETURNS TABLE(status_name character varying, count bigint)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    SELECT sr.status_name, COUNT(c.code)::BIGINT as count
    FROM status_rules sr
    LEFT JOIN clients c ON c.current_status_id = sr.id
    GROUP BY sr.id, sr.status_name, sr.priority
    ORDER BY sr.priority;
END;
$$;

-- Пересчет статусов всех клиентов
SELECT update_client_analytics(NULL);

COMMIT;
