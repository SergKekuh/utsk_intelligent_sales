-- ============================================================
-- МИГРАЦИЯ 58: Правка грамматики 'Вибулі' → 'Вибули'
-- Дата: 2026-10-06
-- ЦЕЛЬ: Исправить форму прошедшего времени мн. ч. ('Вибули')
-- РИСК: низкий (UPDATE текста в status_rules + патч get_segmentation_special)
-- ============================================================

-- ═══════════════════════════════════════════════════════════
-- БЭКАП
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS status_rules_backup_20261006_v2 AS
SELECT * FROM status_rules;

CREATE TABLE IF NOT EXISTS backup_functions_20261006_vybuli AS
SELECT proname, pg_get_functiondef(oid) AS definition, now() AS backup_at
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND proname IN ('get_segmentation_special', 'calculate_client_status');

-- ═══════════════════════════════════════════════════════════
-- ШАГ 1: ПАТЧ get_segmentation_special
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_segmentation_special(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(segment_code character varying, segment_name character varying, badge_label character varying, icon character varying, color character varying, clients_count bigint, sales_revenue numeric, invoices_count bigint, avg_ticket numeric, share_clients_pct numeric, share_revenue_pct numeric, description text, sort_order integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_total_active BIGINT;
    v_total_revenue NUMERIC;
    v_total_all BIGINT;
BEGIN
    -- Общее число активных клиентов и выручка за выбранный год
    SELECT 
        COUNT(DISTINCT cya.client_code),
        COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)
    INTO v_total_active, v_total_revenue
    FROM client_year_activity cya
    JOIN documents d ON d.client_code = cya.client_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE cya.sales_year = p_year AND cya.is_active = TRUE AND cya.client_code NOT IN ('9653', '11230');

    -- Всего клиентов в базе
    SELECT COUNT(*) INTO v_total_all
    FROM clients
    WHERE code NOT IN ('9653', '11230');

    RETURN QUERY
    WITH active_clients AS (
        SELECT DISTINCT cya.client_code
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year AND cya.is_active = TRUE AND cya.client_code NOT IN ('9653', '11230')
    ),
    client_stats AS (
        SELECT 
            c.code,
            c.current_status_id,
            COUNT(DISTINCT d.id) AS invoices_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
            CASE 
                WHEN p_year = 2026 AND c.current_status_id IS NOT NULL THEN (c.current_status_id = 1)
                ELSE NOT EXISTS (
                    SELECT 1 FROM documents d_prev 
                    WHERE d_prev.client_code = c.code AND EXTRACT(YEAR FROM d_prev.invoice_date) = p_year - 1
                )
            END AS is_new_client
        FROM clients c
        JOIN active_clients ac ON c.code = ac.client_code
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY c.code, c.current_status_id
    ),
    sleeping_stats AS (
        SELECT 
            COUNT(DISTINCT c.code)::BIGINT AS sleeping_cnt,
            ROUND(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC, 2) AS sleeping_rev,
            COUNT(DISTINCT d.id)::BIGINT AS sleeping_inv
        FROM clients c
        LEFT JOIN active_clients ac ON c.code = ac.client_code
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year - 1
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE ac.client_code IS NULL AND c.code NOT IN ('9653', '11230')
    ),
    churned_stats AS (
        SELECT 
            COUNT(DISTINCT c.code)::BIGINT AS churned_cnt,
            ROUND(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC, 2) AS churned_rev,
            COUNT(DISTINCT d.id)::BIGINT AS churned_inv
        FROM clients c
        LEFT JOIN active_clients ac ON c.code = ac.client_code
        LEFT JOIN documents d_prev ON d_prev.client_code = c.code AND EXTRACT(YEAR FROM d_prev.invoice_date) = p_year - 1
        LEFT JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year - 2
        LEFT JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE ac.client_code IS NULL AND d_prev.id IS NULL AND c.code NOT IN ('9653', '11230')
    )
    -- 1. C2 (Дрібні)
    SELECT 
        'c2'::VARCHAR AS segment_code,
        'C2 (Дрібні)'::VARCHAR AS segment_name,
        ('≤ ' || TO_CHAR(p_limit_price, 'FM999G999G999') || ' ₴')::VARCHAR AS badge_label,
        'fa-coins'::VARCHAR AS icon,
        '#f59e0b'::VARCHAR AS color,
        COUNT(CASE WHEN cs.goods_revenue <= p_limit_price THEN 1 END)::BIGINT AS clients_count,
        ROUND(COALESCE(SUM(CASE WHEN cs.goods_revenue <= p_limit_price THEN cs.goods_revenue END), 0)::NUMERIC, 2) AS sales_revenue,
        COALESCE(SUM(CASE WHEN cs.goods_revenue <= p_limit_price THEN cs.invoices_count END), 0)::BIGINT AS invoices_count,
        ROUND((COALESCE(SUM(CASE WHEN cs.goods_revenue <= p_limit_price THEN cs.goods_revenue END), 0) / 
               NULLIF(SUM(CASE WHEN cs.goods_revenue <= p_limit_price THEN cs.invoices_count END), 0))::NUMERIC, 2) AS avg_ticket,
        ROUND(COUNT(CASE WHEN cs.goods_revenue <= p_limit_price THEN 1 END) * 100.0 / NULLIF(v_total_active, 0), 1)::NUMERIC AS share_clients_pct,
        ROUND(COALESCE(SUM(CASE WHEN cs.goods_revenue <= p_limit_price THEN cs.goods_revenue END), 0) * 100.0 / NULLIF(v_total_revenue, 0), 1)::NUMERIC AS share_revenue_pct,
        'Клієнти з виручкою не більше границі C2'::TEXT AS description,
        1 AS sort_order
    FROM client_stats cs

    UNION ALL

    -- 2. Нові клієнти
    SELECT 
        'new_clients'::VARCHAR AS segment_code,
        'Нові клієнти'::VARCHAR AS segment_name,
        'Status ID = 1'::VARCHAR AS badge_label,
        'fa-user-plus'::VARCHAR AS icon,
        '#10b981'::VARCHAR AS color,
        COUNT(CASE WHEN cs.is_new_client THEN 1 END)::BIGINT AS clients_count,
        ROUND(COALESCE(SUM(CASE WHEN cs.is_new_client THEN cs.goods_revenue END), 0)::NUMERIC, 2) AS sales_revenue,
        COALESCE(SUM(CASE WHEN cs.is_new_client THEN cs.invoices_count END), 0)::BIGINT AS invoices_count,
        ROUND((COALESCE(SUM(CASE WHEN cs.is_new_client THEN cs.goods_revenue END), 0) / 
               NULLIF(SUM(CASE WHEN cs.is_new_client THEN cs.invoices_count END), 0))::NUMERIC, 2) AS avg_ticket,
        ROUND(COUNT(CASE WHEN cs.is_new_client THEN 1 END) * 100.0 / NULLIF(v_total_active, 0), 1)::NUMERIC AS share_clients_pct,
        ROUND(COALESCE(SUM(CASE WHEN cs.is_new_client THEN cs.goods_revenue END), 0) * 100.0 / NULLIF(v_total_revenue, 0), 1)::NUMERIC AS share_revenue_pct,
        'Вперше здійснили покупку у вибраному році'::TEXT AS description,
        2 AS sort_order
    FROM client_stats cs

    UNION ALL

    -- 3. Вибули
    SELECT 
        'churned'::VARCHAR AS segment_code,
        'Вибули'::VARCHAR AS segment_name,
        'Status ID = 9'::VARCHAR AS badge_label,
        'fa-user-xmark'::VARCHAR AS icon,
        '#ef4444'::VARCHAR AS color,
        cs.churned_cnt AS clients_count,
        cs.churned_rev AS sales_revenue,
        cs.churned_inv AS invoices_count,
        ROUND((cs.churned_rev / NULLIF(cs.churned_inv, 0))::NUMERIC, 2) AS avg_ticket,
        ROUND(cs.churned_cnt * 100.0 / NULLIF(v_total_all, 0), 1)::NUMERIC AS share_clients_pct,
        ROUND(cs.churned_rev * 100.0 / NULLIF(v_total_revenue + cs.churned_rev, 0), 1)::NUMERIC AS share_revenue_pct,
        'Не купували 2+ роки (втрачена клієнтська база)'::TEXT AS description,
        3 AS sort_order
    FROM churned_stats cs

    UNION ALL

    -- 4. Сплячі
    SELECT 
        'sleeping'::VARCHAR AS segment_code,
        'Сплячі'::VARCHAR AS segment_name,
        'Status ID = 8'::VARCHAR AS badge_label,
        'fa-moon'::VARCHAR AS icon,
        '#8b5cf6'::VARCHAR AS color,
        ss.sleeping_cnt AS clients_count,
        ss.sleeping_rev AS sales_revenue,
        ss.sleeping_inv AS invoices_count,
        ROUND((ss.sleeping_rev / NULLIF(ss.sleeping_inv, 0))::NUMERIC, 2) AS avg_ticket,
        ROUND(ss.sleeping_cnt * 100.0 / NULLIF(v_total_all, 0), 1)::NUMERIC AS share_clients_pct,
        ROUND(ss.sleeping_rev * 100.0 / NULLIF(v_total_revenue + ss.sleeping_rev, 0), 1)::NUMERIC AS share_revenue_pct,
        'Купували минулого року, але 0 покупок у поточному'::TEXT AS description,
        4 AS sort_order
    FROM sleeping_stats ss

    ORDER BY sort_order;
END;
$function$;

-- ─── calculate_client_status ───
CREATE OR REPLACE FUNCTION public.calculate_client_status(p_client_code character varying)
RETURNS integer
LANGUAGE plpgsql
AS $function$
DECLARE
    v_current_year_count INT := 0;
    v_prev_year_count INT := 0;
    v_two_years_ago_count INT := 0;
    v_status_id INT;
    v_rule RECORD;
    v_current_year INTEGER := EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER;
    v_prev_year INTEGER := v_current_year - 1;
BEGIN
    SELECT COUNT(*) INTO v_current_year_count
    FROM documents WHERE client_code = p_client_code
      AND EXTRACT(YEAR FROM invoice_date) = v_current_year;

    SELECT COUNT(*) INTO v_prev_year_count
    FROM documents WHERE client_code = p_client_code
      AND EXTRACT(YEAR FROM invoice_date) = v_prev_year;

    SELECT COUNT(*) INTO v_two_years_ago_count
    FROM documents WHERE client_code = p_client_code
      AND EXTRACT(YEAR FROM invoice_date) = v_current_year - 2;

    IF v_current_year_count >= 1 AND v_prev_year_count = 0 THEN
        IF v_two_years_ago_count >= 1 THEN
            v_status_id := 10;  -- Вернувшиеся → Повернені
        ELSIF v_two_years_ago_count = 0 THEN
            v_status_id := 1;   -- Новые → Нові
        END IF;
    ELSE
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

    IF v_status_id IS NULL THEN
        v_status_id := 9;  -- Ушедшие → Вибули
    END IF;

    RETURN v_status_id;
END;
$function$;

-- ═══════════════════════════════════════════════════════════
-- ШАГ 2: UPDATE status_rules
-- ═══════════════════════════════════════════════════════════
UPDATE status_rules
SET status_name = 'Вибули'
WHERE id = 9;

UPDATE status_rules
SET description = 'Немає покупок у поточному та минулому році. Вибули.'
WHERE id = 9;

-- ═══════════════════════════════════════════════════════════
-- ШАГ 3: ПРОВЕРКА
-- ═══════════════════════════════════════════════════════════
SELECT id, status_name, description FROM status_rules WHERE id = 9;
