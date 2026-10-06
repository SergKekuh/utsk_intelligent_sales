-- ============================================================
-- МИГРАЦИЯ 57: Локализация статусов RU → UA
-- Дата: 2026-10-06
-- ЦЕЛЬ:
--   1. Патч 10 функций (привязка к id, UA-значения).
--   2. UPDATE status_rules (RU → UA).
-- РИСК: ВЫСОКИЙ (изменение ядра логики)
-- ОТКАТ: backup таблицы + backup функций
-- ВАЖНО: порядок — СНАЧАЛА функции, ПОТОМ UPDATE
-- ============================================================

-- ═══════════════════════════════════════════════════════════
-- БЭКАПЫ
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS status_rules_backup_20261006 AS
SELECT * FROM status_rules;

CREATE TABLE IF NOT EXISTS backup_functions_20261006_status AS
SELECT proname, pg_get_functiondef(oid) AS definition, now() AS backup_at
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND proname IN (
    'calculate_client_status', 'update_client_analytics',
    'get_funnel_data', 'get_client_status_2025',
    'get_top_clients_80pct', 'get_new_clients_frequency',
    'get_returned_clients_frequency', 'get_returned_clients_compare_new',
    'get_returned_clients_list', 'get_segmentation_special'
);

-- ═══════════════════════════════════════════════════════════
-- ШАГ 1: ПАТЧ 10 ФУНКЦИЙ (привязка к id, UA-значения)
-- ═══════════════════════════════════════════════════════════

-- 1. calculate_client_status
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
        v_status_id := 9;  -- Ушедшие → Вибулі
    END IF;

    RETURN v_status_id;
END;
$function$;

-- 2. update_client_analytics
CREATE OR REPLACE FUNCTION public.update_client_analytics(p_client_code character varying DEFAULT NULL::character varying)
RETURNS void
LANGUAGE plpgsql
AS $function$
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
            WHEN calculate_client_status(c.code) = 1  -- Нові
                 AND c.survey_completed_at IS NULL
            THEN TRUE
            ELSE FALSE
        END,
        updated_at = CURRENT_TIMESTAMP
    FROM client_stats cs
    WHERE c.code = cs.code;
END;
$function$;

-- 3. get_funnel_data
CREATE OR REPLACE FUNCTION public.get_funnel_data(p_year integer DEFAULT 2026)
RETURNS TABLE(stage text, sort_order integer, count bigint, revenue numeric)
LANGUAGE plpgsql
STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH client_invoices AS (
        SELECT
            c.code,
            COUNT(DISTINCT d.id) AS invoice_count,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS total_revenue
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
        GROUP BY c.code
    ),
    classified AS (
        SELECT
            (CASE
                WHEN invoice_count = 1 THEN 'Разові (1)'
                WHEN invoice_count BETWEEN 2 AND 3 THEN 'Повторні (2-3)'
                WHEN invoice_count BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
                WHEN invoice_count BETWEEN 11 AND 40 THEN 'Місяць (11-40)'
                WHEN invoice_count BETWEEN 41 AND 170 THEN 'Тиждень (41-170)'
                ELSE 'День (>170)'
            END)::TEXT AS stage,
            CASE
                WHEN invoice_count = 1 THEN 1
                WHEN invoice_count BETWEEN 2 AND 3 THEN 2
                WHEN invoice_count BETWEEN 4 AND 10 THEN 3
                WHEN invoice_count BETWEEN 11 AND 40 THEN 4
                WHEN invoice_count BETWEEN 41 AND 170 THEN 5
                ELSE 6
            END AS sort_order,
            total_revenue
        FROM client_invoices
    )
    SELECT
        c.stage,
        c.sort_order,
        COUNT(*)::BIGINT AS count,
        ROUND(SUM(c.total_revenue)::numeric, 2) AS revenue
    FROM classified c
    GROUP BY c.stage, c.sort_order
    ORDER BY c.sort_order;
END;
$function$;

-- 4. get_client_status_2025
CREATE OR REPLACE FUNCTION public.get_client_status_2025(p_code text, p_year_prev integer DEFAULT 2025)
RETURNS TABLE(status_2025 text)
LANGUAGE plpgsql
STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT CASE
        WHEN cya.total_docs = 0 THEN 'Сплячі'
        WHEN cya.total_docs = 1 THEN 'Разові'
        WHEN cya.total_docs BETWEEN 2 AND 3 THEN 'Повторні'
        WHEN cya.total_docs BETWEEN 4 AND 10 THEN 'Щоквартальні'
        WHEN cya.total_docs BETWEEN 11 AND 40 THEN 'Щомісячні'
        WHEN cya.total_docs BETWEEN 41 AND 170 THEN 'Щотижневі'
        WHEN cya.total_docs > 170 THEN 'Щоденні'
        ELSE '—'
    END::TEXT AS status_2025
    FROM client_year_activity cya
    WHERE cya.client_code = p_code AND cya.sales_year = p_year_prev;
END;
$function$;

-- 5. get_top_clients_80pct
CREATE OR REPLACE FUNCTION public.get_top_clients_80pct(p_year integer DEFAULT 2026, p_date_from date DEFAULT NULL::date, p_date_to date DEFAULT NULL::date)
 RETURNS TABLE(code character varying, name character varying, status_2025 character varying, status_2026 character varying, goods_revenue numeric, invoice_count bigint, last_purchase_date date, pct_of_total numeric, running_pct numeric, is_included boolean, total_revenue numeric, period_label text)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_year INTEGER := COALESCE(p_year, 2026);
    v_total_revenue NUMERIC;
    v_period_label TEXT;
    v_full_months INTEGER;
BEGIN
    IF p_date_from IS NOT NULL AND p_date_to IS NOT NULL THEN
        v_period_label := TO_CHAR(p_date_from, 'YYYY-MM-DD') || ' — ' || TO_CHAR(p_date_to, 'YYYY-MM-DD');
        
        SELECT COALESCE(ROUND(SUM(sl.amount)::numeric, 0), 0)
        INTO v_total_revenue
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = v_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
          AND d.invoice_date BETWEEN p_date_from AND p_date_to;
    ELSE
        SELECT COUNT(DISTINCT EXTRACT(MONTH FROM d.invoice_date))::INTEGER
        INTO v_full_months
        FROM documents d
        WHERE EXTRACT(YEAR FROM d.invoice_date) = v_year AND d.invoice_date < DATE_TRUNC('month', CURRENT_DATE);

        v_period_label := COALESCE(v_full_months, 0)::TEXT || ' повних міс. ' || v_year::TEXT;

        SELECT COALESCE(ROUND(SUM(sl.amount)::numeric, 0), 0)
        INTO v_total_revenue
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = v_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
          AND EXTRACT(YEAR FROM d.invoice_date) = v_year AND d.invoice_date < DATE_TRUNC('month', CURRENT_DATE);
    END IF;

    RETURN QUERY
    WITH client_sales AS (
        SELECT 
            c.code::VARCHAR AS client_code,
            c.name::VARCHAR AS client_name,
            sr.status_name::VARCHAR AS status_curr,
            ROUND(SUM(sl.amount)::numeric, 0) AS rev,
            COUNT(DISTINCT d.id) AS inv_cnt,
            MAX(d.invoice_date) AS last_dt
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = v_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
          AND (
            (p_date_from IS NOT NULL AND p_date_to IS NOT NULL AND d.invoice_date BETWEEN p_date_from AND p_date_to)
            OR
            (p_date_from IS NULL AND EXTRACT(YEAR FROM d.invoice_date) = v_year AND d.invoice_date < DATE_TRUNC('month', CURRENT_DATE))
          )
        GROUP BY c.code, c.name, sr.status_name
    ),
    ranked AS (
        SELECT 
            cs.*,
            SUM(cs.rev) OVER (ORDER BY cs.rev DESC) AS running_total,
            ROUND((100.0 * cs.rev / NULLIF(v_total_revenue, 0))::numeric, 2) AS pct,
            ROUND((100.0 * SUM(cs.rev) OVER (ORDER BY cs.rev DESC) / NULLIF(v_total_revenue, 0))::numeric, 2) AS run_pct
        FROM client_sales cs
    ),
    top_filtered AS (
        SELECT r.*
        FROM ranked r
        WHERE r.run_pct <= 80 OR (r.run_pct > 80 AND r.run_pct - r.pct < 80)
    )
    SELECT 
        tf.client_code AS code,
        COALESCE(tf.client_name, '—')::VARCHAR AS name,
        COALESCE(
            (
                SELECT 
                    CASE 
                        WHEN cya.total_docs = 0 THEN 'Сплячі'
                        WHEN cya.total_docs = 1 THEN 'Разові'
                        WHEN cya.total_docs BETWEEN 2 AND 3 THEN 'Повторні'
                        WHEN cya.total_docs BETWEEN 4 AND 10 THEN 'Щоквартальні'
                        WHEN cya.total_docs BETWEEN 11 AND 40 THEN 'Щомісячні'
                        WHEN cya.total_docs BETWEEN 41 AND 170 THEN 'Щотижневі'
                        WHEN cya.total_docs > 170 THEN 'Щоденні'
                        ELSE '—'
                    END
                FROM client_year_activity cya
                WHERE cya.client_code = tf.client_code AND cya.sales_year = 2025
                LIMIT 1
            ),
            '—'
        )::VARCHAR AS status_2025,
        COALESCE(tf.status_curr, '—')::VARCHAR AS status_2026,
        tf.rev AS goods_revenue,
        tf.inv_cnt AS invoice_count,
        tf.last_dt AS last_purchase_date,
        tf.pct AS pct_of_total,
        tf.run_pct AS running_pct,
        TRUE AS is_included,
        v_total_revenue AS total_revenue,
        v_period_label AS period_label
    FROM top_filtered tf
    ORDER BY tf.rev DESC;
END;
$function$;

-- 6. get_new_clients_frequency
CREATE OR REPLACE FUNCTION public.get_new_clients_frequency(p_year integer DEFAULT 2026)
 RETURNS TABLE(frequency_group text, sort_order integer, new_count bigint, new_revenue numeric, avg_ticket numeric, new_pct numeric, all_count bigint, share_pct numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH new_clients AS (
        SELECT code FROM clients WHERE current_status_id = 1 AND is_active_current = TRUE AND code NOT IN ('9653', '11230')
    ),
    new_frequency AS (
        SELECT nc.code, COUNT(DISTINCT d.id) AS invoice_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
        FROM new_clients nc
        JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY nc.code
    ),
    all_frequency AS (
        SELECT c.code, COUNT(DISTINCT d.id) AS invoice_count
        FROM clients c
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN client_year_activity cya ON c.code = cya.client_code AND cya.sales_year = p_year AND cya.is_active = TRUE
        WHERE c.is_active_current = TRUE AND c.code NOT IN ('9653', '11230')
        GROUP BY c.code
    ),
    nf_grouped AS (
        SELECT 
            (CASE 
                WHEN invoice_count = 1 THEN 'Разові (1)'
                WHEN invoice_count BETWEEN 2 AND 3 THEN 'Повторні (2-3)'
                WHEN invoice_count BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
                WHEN invoice_count BETWEEN 11 AND 40 THEN 'Місяць (11-40)'
                WHEN invoice_count BETWEEN 41 AND 170 THEN 'Тиждень (41-170)'
                ELSE 'День (>170)'
            END)::TEXT AS frequency_group,
            CASE 
                WHEN invoice_count = 1 THEN 1 
                WHEN invoice_count <= 3 THEN 2 
                WHEN invoice_count <= 10 THEN 3 
                WHEN invoice_count <= 40 THEN 4 
                WHEN invoice_count <= 170 THEN 5 
                ELSE 6 
            END AS sort_order,
            COUNT(code)::BIGINT AS new_count,
            SUM(goods_revenue)::NUMERIC AS new_revenue
        FROM new_frequency
        GROUP BY frequency_group, sort_order
    ),
    af_grouped AS (
        SELECT 
            (CASE 
                WHEN invoice_count = 1 THEN 'Разові (1)'
                WHEN invoice_count BETWEEN 2 AND 3 THEN 'Повторні (2-3)'
                WHEN invoice_count BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
                WHEN invoice_count BETWEEN 11 AND 40 THEN 'Місяць (11-40)'
                WHEN invoice_count BETWEEN 41 AND 170 THEN 'Тиждень (41-170)'
                ELSE 'День (>170)'
            END)::TEXT AS frequency_group,
            COUNT(code)::BIGINT AS all_count
        FROM all_frequency
        GROUP BY frequency_group
    )
    SELECT 
        ng.frequency_group,
        ng.sort_order,
        ng.new_count,
        ng.new_revenue,
        ROUND(ng.new_revenue / NULLIF(ng.new_count, 0), 0)::NUMERIC AS avg_ticket,
        ROUND(ng.new_count * 100.0 / NULLIF(SUM(ng.new_count) OVER(), 0), 1)::NUMERIC AS new_pct,
        COALESCE(ag.all_count, 0)::BIGINT AS all_count,
        ROUND(ng.new_count * 100.0 / NULLIF(ag.all_count, 0), 1)::NUMERIC AS share_pct
    FROM nf_grouped ng
    LEFT JOIN af_grouped ag ON ag.frequency_group = ng.frequency_group
    ORDER BY ng.sort_order;
END;
$function$;

-- 7. get_returned_clients_frequency
CREATE OR REPLACE FUNCTION public.get_returned_clients_frequency(p_year integer DEFAULT 2026)
 RETURNS TABLE(frequency_group text, sort_order integer, returned_count bigint, returned_revenue numeric, avg_ticket numeric, returned_pct numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH returned_clients AS (
        SELECT code FROM clients 
        WHERE current_status_id = 10 AND is_active_current = TRUE 
          AND code NOT IN ('9653', '11230')
    ),
    frequency AS (
        SELECT 
            rc.code,
            COUNT(DISTINCT d.id) AS invoice_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
        FROM returned_clients rc
        JOIN documents d ON d.client_code = rc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY rc.code
    )
    SELECT 
        CASE 
            WHEN invoice_count = 1 THEN 'Разові (1)'
            WHEN invoice_count BETWEEN 2 AND 3 THEN 'Повторні (2-3)'
            WHEN invoice_count BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
            WHEN invoice_count BETWEEN 11 AND 40 THEN 'Місяць (11-40)'
            WHEN invoice_count BETWEEN 41 AND 170 THEN 'Тиждень (41-170)'
            ELSE 'День (>170)'
        END::TEXT AS frequency_group,
        CASE 
            WHEN invoice_count = 1 THEN 1
            WHEN invoice_count <= 3 THEN 2
            WHEN invoice_count <= 10 THEN 3
            WHEN invoice_count <= 40 THEN 4
            WHEN invoice_count <= 170 THEN 5
            ELSE 6
        END AS sort_order,
        COUNT(*)::BIGINT AS returned_count,
        SUM(goods_revenue)::NUMERIC AS returned_revenue,
        ROUND(SUM(goods_revenue) / NULLIF(COUNT(*), 0), 0)::NUMERIC AS avg_ticket,
        ROUND(COUNT(*) * 100.0 / NULLIF(SUM(COUNT(*)) OVER(), 0), 1)::NUMERIC AS returned_pct
    FROM frequency
    GROUP BY frequency_group, sort_order
    ORDER BY sort_order;
END;
$function$;

-- 8. get_returned_clients_compare_new
CREATE OR REPLACE FUNCTION public.get_returned_clients_compare_new(p_year integer DEFAULT 2026)
 RETURNS TABLE(frequency_group text, sort_order integer, returned_count bigint, returned_revenue numeric, returned_avg_ticket numeric, new_count bigint, new_revenue numeric, new_avg_ticket numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH base_stages AS (
        SELECT 'Разові (1)'::TEXT AS frequency_group, 1 AS sort_order
        UNION ALL SELECT 'Повторні (2-3)', 2
        UNION ALL SELECT 'Квартал (4-10)', 3
        UNION ALL SELECT 'Місяць (11-40)', 4
        UNION ALL SELECT 'Тиждень (41-170)', 5
        UNION ALL SELECT 'День (>170)', 6
    ),
    ret AS (
        SELECT * FROM get_returned_clients_frequency(p_year)
    ),
    nw AS (
        SELECT * FROM get_new_clients_frequency(p_year)
    )
    SELECT 
        b.frequency_group,
        b.sort_order,
        COALESCE(r.returned_count, 0)::BIGINT AS returned_count,
        COALESCE(r.returned_revenue, 0)::NUMERIC AS returned_revenue,
        COALESCE(r.avg_ticket, 0)::NUMERIC AS returned_avg_ticket,
        COALESCE(n.new_count, 0)::BIGINT AS new_count,
        COALESCE(n.new_revenue, 0)::NUMERIC AS new_revenue,
        COALESCE(n.avg_ticket, 0)::NUMERIC AS new_avg_ticket
    FROM base_stages b
    LEFT JOIN ret r ON r.frequency_group = b.frequency_group
    LEFT JOIN nw n ON n.frequency_group = b.frequency_group
    WHERE COALESCE(r.returned_count, 0) > 0 OR COALESCE(n.new_count, 0) > 0
    ORDER BY b.sort_order;
END;
$function$;

-- 9. get_returned_clients_list
CREATE OR REPLACE FUNCTION public.get_returned_clients_list(p_year integer DEFAULT 2026, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
 RETURNS TABLE(code character varying, name character varying, docs bigint, revenue numeric, first_date text, last_date text, abc_group text, frequency_group text)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH returned_clients AS (
        SELECT c.code FROM clients c 
        WHERE c.current_status_id = 10 AND c.is_active_current = TRUE AND c.code NOT IN ('9653', '11230')
    ),
    client_rev AS (
        SELECT 
            c.code, c.name, COUNT(DISTINCT d.id)::BIGINT AS docs,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS revenue,
            MIN(d.invoice_date)::TEXT AS first_date, MAX(d.invoice_date)::TEXT AS last_date
        FROM returned_clients rc
        JOIN clients c ON c.code = rc.code
        JOIN documents d ON d.client_code = rc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE (p_search IS NULL OR p_search = '' OR c.name ILIKE '%' || p_search || '%' OR c.code ILIKE '%' || p_search || '%')
        GROUP BY c.code, c.name
    ),
    ranked AS (
        SELECT *,
            SUM(r.revenue) OVER (ORDER BY r.revenue DESC) AS cum_revenue,
            SUM(r.revenue) OVER () AS total_revenue
        FROM client_rev r
    ),
    categorized AS (
        SELECT *,
            (CASE 
                WHEN rk.total_revenue = 0 THEN 'C'
                WHEN rk.cum_revenue <= rk.total_revenue * 0.80 OR (rk.cum_revenue - rk.revenue) < rk.total_revenue * 0.80 THEN 'A'
                WHEN rk.cum_revenue <= rk.total_revenue * 0.95 OR (rk.cum_revenue - rk.revenue) < rk.total_revenue * 0.95 THEN 'B'
                ELSE 'C'
            END)::TEXT AS abc_grp,
            (CASE 
                WHEN rk.docs = 1 THEN 'Разові (1)'
                WHEN rk.docs BETWEEN 2 AND 3 THEN 'Повторні (2-3)'
                WHEN rk.docs BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
                WHEN rk.docs BETWEEN 11 AND 40 THEN 'Місяць (11-40)'
                WHEN rk.docs BETWEEN 41 AND 170 THEN 'Тиждень (41-170)'
                ELSE 'День (>170)'
            END)::TEXT AS freq_grp
        FROM ranked rk
    )
    SELECT cat.code, cat.name, cat.docs, cat.revenue, cat.first_date, cat.last_date, cat.abc_grp AS abc_group, cat.freq_grp AS frequency_group
    FROM categorized cat
    WHERE (p_abc_group IS NULL OR p_abc_group = '' OR cat.abc_grp = p_abc_group)
    ORDER BY cat.revenue DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$;

-- 10. get_segmentation_special
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

    -- 3. Убули (Ушедшие)
    SELECT 
        'churned'::VARCHAR AS segment_code,
        'Вибулі'::VARCHAR AS segment_name,
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

-- ═══════════════════════════════════════════════════════════
-- ШАГ 2: ОБНОВЛЕНИЕ status_rules (RU → UA)
-- ═══════════════════════════════════════════════════════════
UPDATE status_rules SET status_name = 'Нові'          WHERE id = 1;
UPDATE status_rules SET status_name = 'Разові'        WHERE id = 2;
UPDATE status_rules SET status_name = 'Повторні'      WHERE id = 3;
UPDATE status_rules SET status_name = 'Щоквартальні'  WHERE id = 4;
UPDATE status_rules SET status_name = 'Щомісячні'     WHERE id = 5;
UPDATE status_rules SET status_name = 'Щотижневі'     WHERE id = 6;
UPDATE status_rules SET status_name = 'Щоденні'       WHERE id = 7;
UPDATE status_rules SET status_name = 'Сплячі'        WHERE id = 8;
UPDATE status_rules SET status_name = 'Вибулі'        WHERE id = 9;
UPDATE status_rules SET status_name = 'Повернені'     WHERE id = 10;

UPDATE status_rules SET description = '2 роки не купували (минулий і позаминулий), але з''явились у поточному'  WHERE id = 1;
UPDATE status_rules SET description = '1 накладна у поточному, були у минулому. Разові.'                        WHERE id = 2;
UPDATE status_rules SET description = '2-3 накладні у поточному році. Повторні.'                               WHERE id = 3;
UPDATE status_rules SET description = '4-10 накладних у поточному році. Щоквартальні.'                         WHERE id = 4;
UPDATE status_rules SET description = '11-40 накладних у поточному році. Щомісячні.'                           WHERE id = 5;
UPDATE status_rules SET description = '41-170 накладних у поточному році. Щотижневі.'                          WHERE id = 6;
UPDATE status_rules SET description = '171+ накладних у поточному році. Щоденні VIP.'                          WHERE id = 7;
UPDATE status_rules SET description = 'Немає покупок у поточному році, але були у минулому. Сплячі.'            WHERE id = 8;
UPDATE status_rules SET description = 'Немає покупок у поточному та минулому році. Вибулі.'                     WHERE id = 9;
UPDATE status_rules SET description = 'Купували у позаминулому році, пропустили минулий, повернулись у поточному' WHERE id = 10;
