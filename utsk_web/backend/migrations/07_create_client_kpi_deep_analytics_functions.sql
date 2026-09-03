-- ====================================================================
-- MIGRATION 07: PostgreSQL Functions for Client Deep Analytics (4 KPI Pages)
-- Database: bd_intelligent_sales
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. get_client_revenue_analytics(p_code, p_year)
-- Returns deep revenue metrics, monthly current vs prev year, cumulative trend, share of total
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_client_revenue_analytics(
    p_code VARCHAR,
    p_year INTEGER DEFAULT 2026
)
RETURNS JSON AS $$
DECLARE
    v_client_name VARCHAR;
    v_status_name VARCHAR := '—';
    v_total_company_rev NUMERIC := 0;
    v_client_rev_curr NUMERIC := 0;
    v_client_rev_prev_total NUMERIC := 0;
    v_client_rev_prev_period NUMERIC := 0;
    v_abc_group VARCHAR := 'C2';
    v_share_pct NUMERIC := 0;
    v_growth_yoy NUMERIC := NULL;
    v_avg_monthly NUMERIC := 0;
    v_max_month INTEGER := 12;
    v_monthly_data JSON;
    v_result JSON;
BEGIN
    -- Client basic info
    SELECT c.name, COALESCE(sr.status_name, '—')
    INTO v_client_name, v_status_name
    FROM clients c
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE c.code = p_code;

    IF v_client_name IS NULL THEN
        RETURN json_build_object('status', 'error', 'message', 'Client not found');
    END IF;

    -- Max month for p_year
    SELECT COALESCE(MAX(EXTRACT(MONTH FROM d.invoice_date))::int, 12)
    INTO v_max_month
    FROM documents d
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year;

    -- Total company revenue (goods only, active clients)
    SELECT COALESCE(SUM(sl.amount), 0) INTO v_total_company_rev
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    JOIN client_year_activity cya ON cya.client_code = d.client_code AND cya.sales_year = p_year AND cya.is_active = TRUE
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND sl.amount > 0
      AND d.client_code NOT IN ('9653', '11230');

    -- Client revenue curr year
    SELECT COALESCE(SUM(sl.amount), 0) INTO v_client_rev_curr
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code
      AND EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND sl.amount > 0;

    -- Client revenue prev year TOTAL (12 months)
    SELECT COALESCE(SUM(sl.amount), 0) INTO v_client_rev_prev_total
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code
      AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
      AND sl.amount > 0;

    -- Client revenue prev year SAME PERIOD (months <= v_max_month)
    SELECT COALESCE(SUM(sl.amount), 0) INTO v_client_rev_prev_period
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code
      AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
      AND EXTRACT(MONTH FROM d.invoice_date) <= v_max_month
      AND sl.amount > 0;

    -- ABC group
    v_abc_group := get_abc_group_for_revenue(v_client_rev_curr);

    -- Share % of total company revenue
    IF v_total_company_rev > 0 THEN
        v_share_pct := ROUND((v_client_rev_curr / v_total_company_rev * 100)::numeric, 2);
    END IF;

    -- YoY Growth % (Ratio to previous year total)
    IF v_client_rev_prev_total > 0 THEN
        v_growth_yoy := ROUND((v_client_rev_curr / v_client_rev_prev_total * 100)::numeric, 1);
    END IF;

    -- Average Monthly Revenue
    v_avg_monthly := ROUND((v_client_rev_curr / 12.0)::numeric, 2);

    -- Monthly breakdown & cumulative calculation
    WITH months AS (
        SELECT generate_series(1, 12) AS m
    ),
    curr_m AS (
        SELECT 
            EXTRACT(MONTH FROM d.invoice_date)::int AS m,
            SUM(sl.amount) AS rev
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND sl.amount > 0
        GROUP BY 1
    ),
    prev_m AS (
        SELECT 
            EXTRACT(MONTH FROM d.invoice_date)::int AS m,
            SUM(sl.amount) AS rev
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) AND sl.amount > 0
        GROUP BY 1
    ),
    combined AS (
        SELECT 
            m.m AS month,
            CASE m.m
                WHEN 1 THEN 'Январь' WHEN 2 THEN 'Февраль' WHEN 3 THEN 'Март'
                WHEN 4 THEN 'Апрель' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июнь'
                WHEN 7 THEN 'Июль' WHEN 8 THEN 'Август' WHEN 9 THEN 'Сентябрь'
                WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь' WHEN 12 THEN 'Декабрь'
            END AS month_name,
            COALESCE(c.rev, 0.0) AS rev_curr,
            COALESCE(p.rev, 0.0) AS rev_prev
        FROM months m
        LEFT JOIN curr_m c ON m.m = c.m
        LEFT JOIN prev_m p ON m.m = p.m
        ORDER BY m.m
    ),
    cumulated AS (
        SELECT 
            month,
            month_name,
            rev_curr,
            rev_prev,
            CASE 
                WHEN rev_prev > 0 THEN ROUND((rev_curr / rev_prev * 100)::numeric, 1)
                ELSE NULL
            END AS growth_pct,
            ROUND(SUM(rev_curr) OVER (ORDER BY month)::numeric, 2) AS cum_curr,
            ROUND(SUM(rev_prev) OVER (ORDER BY month)::numeric, 2) AS cum_prev
        FROM combined
    )
    SELECT json_agg(
        json_build_object(
            'month', month,
            'month_name', month_name,
            'rev_curr', rev_curr,
            'rev_prev', rev_prev,
            'growth_pct', growth_pct,
            'cum_curr', cum_curr,
            'cum_prev', cum_prev
        )
    ) INTO v_monthly_data FROM cumulated;

    v_result := json_build_object(
        'status', 'ok',
        'client_info', json_build_object(
            'code', p_code,
            'name', v_client_name,
            'status_name', v_status_name,
            'abc_group', v_abc_group,
            'total_company_rev', v_total_company_rev,
            'client_share_pct', v_share_pct
        ),
        'kpi', json_build_object(
            'rev_curr', v_client_rev_curr,
            'rev_prev', v_client_rev_prev_total,
            'rev_prev_period', v_client_rev_prev_period,
            'growth_yoy_pct', v_growth_yoy,
            'avg_monthly_rev', v_avg_monthly
        ),
        'monthly', COALESCE(v_monthly_data, '[]'::json)
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- --------------------------------------------------------------------
-- 2. get_client_invoices_analytics(p_code, p_year)
-- Returns total invoices, monthly current vs prev year breakdown, seasonality peak
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_client_invoices_analytics(
    p_code VARCHAR,
    p_year INTEGER DEFAULT 2026
)
RETURNS JSON AS $$
DECLARE
    v_client_name VARCHAR;
    v_status_name VARCHAR := '—';
    v_inv_curr BIGINT := 0;
    v_pos_curr BIGINT := 0;
    v_uniq_curr BIGINT := 0;
    v_inv_prev_total BIGINT := 0;
    v_pos_prev_total BIGINT := 0;
    v_uniq_prev_total BIGINT := 0;
    v_inv_prev_period BIGINT := 0;
    v_growth_yoy NUMERIC := NULL;
    v_avg_monthly NUMERIC := 0;
    v_peak_month VARCHAR := '—';
    v_peak_count INT := 0;
    v_active_months_count INT := 0;
    v_max_month INTEGER := 12;
    v_monthly_data JSON;
    v_result JSON;
BEGIN
    SELECT c.name, COALESCE(sr.status_name, '—')
    INTO v_client_name, v_status_name
    FROM clients c
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE c.code = p_code;

    IF v_client_name IS NULL THEN
        RETURN json_build_object('status', 'error', 'message', 'Client not found');
    END IF;

    -- Max month for p_year
    SELECT COALESCE(MAX(EXTRACT(MONTH FROM d.invoice_date))::int, 12)
    INTO v_max_month
    FROM documents d
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year;

    -- Invoices, positions and unique positions count current year
    SELECT COUNT(DISTINCT d.id), COUNT(sl.id), COUNT(DISTINCT sl.product_code)
    INTO v_inv_curr, v_pos_curr, v_uniq_curr
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND sl.amount > 0;

    -- Invoices, positions and unique positions count prev year TOTAL (12 months)
    SELECT COUNT(DISTINCT d.id), COUNT(sl.id), COUNT(DISTINCT sl.product_code)
    INTO v_inv_prev_total, v_pos_prev_total, v_uniq_prev_total
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code 
      AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) 
      AND sl.amount > 0;

    -- Invoices count prev year SAME PERIOD (months <= v_max_month)
    SELECT COUNT(DISTINCT d.id) INTO v_inv_prev_period
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code 
      AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) 
      AND EXTRACT(MONTH FROM d.invoice_date) <= v_max_month
      AND sl.amount > 0;

    IF v_inv_prev_total > 0 THEN
        v_growth_yoy := ROUND((v_inv_curr::numeric / v_inv_prev_total * 100)::numeric, 1);
    END IF;

    v_avg_monthly := ROUND((v_inv_curr::numeric / 12.0)::numeric, 1);

    -- Monthly breakdown
    WITH months AS (
        SELECT generate_series(1, 12) AS m
    ),
    curr_m AS (
        SELECT 
            EXTRACT(MONTH FROM d.invoice_date)::int AS m,
            COUNT(DISTINCT d.id) AS inv_cnt,
            COUNT(sl.id) AS pos_cnt,
            COUNT(DISTINCT sl.product_code) AS uniq_cnt
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND sl.amount > 0
        GROUP BY 1
    ),
    prev_m AS (
        SELECT 
            EXTRACT(MONTH FROM d.invoice_date)::int AS m,
            COUNT(DISTINCT d.id) AS inv_cnt,
            COUNT(sl.id) AS pos_cnt,
            COUNT(DISTINCT sl.product_code) AS uniq_cnt
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) AND sl.amount > 0
        GROUP BY 1
    ),
    combined AS (
        SELECT 
            m.m AS month,
            CASE m.m
                WHEN 1 THEN 'Январь' WHEN 2 THEN 'Февраль' WHEN 3 THEN 'Март'
                WHEN 4 THEN 'Апрель' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июнь'
                WHEN 7 THEN 'Июль' WHEN 8 THEN 'Август' WHEN 9 THEN 'Сентябрь'
                WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь' WHEN 12 THEN 'Декабрь'
            END AS month_name,
            COALESCE(c.inv_cnt, 0) AS inv_curr,
            COALESCE(c.pos_cnt, 0) AS pos_curr,
            COALESCE(c.pos_cnt, 0) AS positions_2026,
            COALESCE(c.uniq_cnt, 0) AS uniq_curr,
            COALESCE(c.uniq_cnt, 0) AS unique_positions,
            COALESCE(p.inv_cnt, 0) AS inv_prev,
            COALESCE(p.pos_cnt, 0) AS pos_prev,
            COALESCE(p.uniq_cnt, 0) AS uniq_prev,
            CASE 
                WHEN COALESCE(p.inv_cnt, 0) > 0 THEN ROUND((COALESCE(c.inv_cnt, 0)::numeric / p.inv_cnt * 100)::numeric, 1)
                ELSE NULL
            END AS growth_pct
        FROM months m
        LEFT JOIN curr_m c ON m.m = c.m
        LEFT JOIN prev_m p ON m.m = p.m
        ORDER BY m.m
    )
    SELECT json_agg(
        json_build_object(
            'month', month,
            'month_name', month_name,
            'inv_curr', inv_curr,
            'invoices_2026', inv_curr,
            'pos_curr', pos_curr,
            'positions_2026', pos_curr,
            'uniq_curr', uniq_curr,
            'unique_positions', unique_positions,
            'inv_prev', inv_prev,
            'pos_prev', pos_prev,
            'uniq_prev', uniq_prev,
            'growth_pct', growth_pct
        )
    ) INTO v_monthly_data FROM combined;

    -- Peak month
    SELECT month_name, inv_curr INTO v_peak_month, v_peak_count
    FROM (
        SELECT 
            CASE EXTRACT(MONTH FROM d.invoice_date)::int
                WHEN 1 THEN 'Январь' WHEN 2 THEN 'Февраль' WHEN 3 THEN 'Март'
                WHEN 4 THEN 'Апрель' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июнь'
                WHEN 7 THEN 'Июль' WHEN 8 THEN 'Август' WHEN 9 THEN 'Сентябрь'
                WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь' WHEN 12 THEN 'Декабрь'
            END AS month_name,
            COUNT(DISTINCT d.id) AS inv_curr
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND sl.amount > 0
        GROUP BY 1
        ORDER BY inv_curr DESC LIMIT 1
    ) sq;

    SELECT COUNT(DISTINCT EXTRACT(MONTH FROM d.invoice_date)) INTO v_active_months_count
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND sl.amount > 0;

    v_result := json_build_object(
        'status', 'ok',
        'unique_positions', v_uniq_curr,
        'client_info', json_build_object(
            'code', p_code,
            'name', v_client_name,
            'status_name', v_status_name
        ),
        'kpi', json_build_object(
            'invoices_curr', v_inv_curr,
            'positions_curr', v_pos_curr,
            'unique_positions', v_uniq_curr,
            'invoices_prev', v_inv_prev_total,
            'positions_prev', v_pos_prev_total,
            'unique_positions_prev', v_uniq_prev_total,
            'invoices_prev_period', v_inv_prev_period,
            'growth_yoy_pct', v_growth_yoy,
            'avg_monthly_invoices', v_avg_monthly
        ),
        'patterns', json_build_object(
            'peak_month_name', COALESCE(v_peak_month, '—'),
            'peak_inv_count', COALESCE(v_peak_count, 0),
            'active_months_count', COALESCE(v_active_months_count, 0)
        ),
        'monthly', COALESCE(v_monthly_data, '[]'::json)
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- --------------------------------------------------------------------
-- 3. get_client_avg_check_analytics(p_code, p_year)
-- Returns average check, median, max, min, and monthly line graph breakdown
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_client_avg_check_analytics(
    p_code VARCHAR,
    p_year INTEGER DEFAULT 2026
)
RETURNS JSON AS $$
DECLARE
    v_client_name VARCHAR;
    v_status_name VARCHAR := '—';
    v_avg_curr NUMERIC := 0;
    v_avg_prev_total NUMERIC := 0;
    v_avg_prev_period NUMERIC := 0;
    v_growth_yoy NUMERIC := NULL;
    v_median_check NUMERIC := 0;
    v_max_check NUMERIC := 0;
    v_min_check NUMERIC := 0;
    v_max_month INTEGER := 12;
    v_monthly_data JSON;
    v_result JSON;
BEGIN
    SELECT c.name, COALESCE(sr.status_name, '—')
    INTO v_client_name, v_status_name
    FROM clients c
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE c.code = p_code;

    IF v_client_name IS NULL THEN
        RETURN json_build_object('status', 'error', 'message', 'Client not found');
    END IF;

    -- Max month for p_year
    SELECT COALESCE(MAX(EXTRACT(MONTH FROM d.invoice_date))::int, 12)
    INTO v_max_month
    FROM documents d
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year;

    -- Overall avg, min, max, median check for current year
    WITH doc_sums AS (
        SELECT d.id, SUM(sl.amount) AS doc_amount
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND sl.amount > 0
        GROUP BY d.id
    )
    SELECT 
        COALESCE(ROUND(AVG(doc_amount)::numeric, 2), 0),
        COALESCE(ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY doc_amount)::numeric, 2), 0),
        COALESCE(ROUND(MAX(doc_amount)::numeric, 2), 0),
        COALESCE(ROUND(MIN(doc_amount)::numeric, 2), 0)
    INTO v_avg_curr, v_median_check, v_max_check, v_min_check
    FROM doc_sums;

    -- Prev year avg check TOTAL (12 months)
    WITH doc_sums_prev AS (
        SELECT d.id, SUM(sl.amount) AS doc_amount
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code 
          AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) 
          AND sl.amount > 0
        GROUP BY d.id
    )
    SELECT COALESCE(ROUND(AVG(doc_amount)::numeric, 2), 0) INTO v_avg_prev_total FROM doc_sums_prev;

    -- Prev year avg check SAME PERIOD (months <= v_max_month)
    WITH doc_sums_prev_period AS (
        SELECT d.id, SUM(sl.amount) AS doc_amount
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code 
          AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) 
          AND EXTRACT(MONTH FROM d.invoice_date) <= v_max_month
          AND sl.amount > 0
        GROUP BY d.id
    )
    SELECT COALESCE(ROUND(AVG(doc_amount)::numeric, 2), 0) INTO v_avg_prev_period FROM doc_sums_prev_period;

    IF v_avg_prev_total > 0 THEN
        v_growth_yoy := ROUND((v_avg_curr / v_avg_prev_total * 100)::numeric, 1);
    END IF;

    -- Monthly breakdown
    WITH months AS (
        SELECT generate_series(1, 12) AS m
    ),
    curr_m AS (
        SELECT 
            EXTRACT(MONTH FROM doc_sum.invoice_date)::int AS m,
            AVG(doc_sum.amount) AS avg_chk
        FROM (
            SELECT d.id, d.invoice_date, SUM(sl.amount) AS amount
            FROM sales_lines sl
            JOIN documents d ON sl.document_id = d.id
            JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
            WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND sl.amount > 0
            GROUP BY d.id, d.invoice_date
        ) doc_sum
        GROUP BY 1
    ),
    prev_m AS (
        SELECT 
            EXTRACT(MONTH FROM doc_sum.invoice_date)::int AS m,
            AVG(doc_sum.amount) AS avg_chk
        FROM (
            SELECT d.id, d.invoice_date, SUM(sl.amount) AS amount
            FROM sales_lines sl
            JOIN documents d ON sl.document_id = d.id
            JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
            WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) AND sl.amount > 0
            GROUP BY d.id, d.invoice_date
        ) doc_sum
        GROUP BY 1
    ),
    combined AS (
        SELECT 
            m.m AS month,
            CASE m.m
                WHEN 1 THEN 'Январь' WHEN 2 THEN 'Февраль' WHEN 3 THEN 'Март'
                WHEN 4 THEN 'Апрель' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июнь'
                WHEN 7 THEN 'Июль' WHEN 8 THEN 'Август' WHEN 9 THEN 'Сентябрь'
                WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь' WHEN 12 THEN 'Декабрь'
            END AS month_name,
            COALESCE(ROUND(c.avg_chk::numeric, 2), 0) AS avg_curr,
            COALESCE(ROUND(p.avg_chk::numeric, 2), 0) AS avg_prev
        FROM months m
        LEFT JOIN curr_m c ON m.m = c.m
        LEFT JOIN prev_m p ON m.m = p.m
        ORDER BY m.m
    )
    SELECT json_agg(
        json_build_object(
            'month', month,
            'month_name', month_name,
            'avg_curr', avg_curr,
            'avg_prev', avg_prev,
            'dev_pct', CASE WHEN avg_prev > 0 THEN ROUND(((avg_curr - avg_prev) / avg_prev * 100)::numeric, 1) ELSE NULL END
        )
    ) INTO v_monthly_data FROM combined;

    v_result := json_build_object(
        'status', 'ok',
        'client_info', json_build_object(
            'code', p_code,
            'name', v_client_name,
            'status_name', v_status_name
        ),
        'kpi', json_build_object(
            'avg_check_curr', v_avg_curr,
            'avg_check_prev', v_avg_prev_total,
            'avg_check_prev_period', v_avg_prev_period,
            'growth_yoy_pct', v_growth_yoy,
            'median_check', v_median_check,
            'max_check', v_max_check,
            'min_check', v_min_check
        ),
        'monthly', COALESCE(v_monthly_data, '[]'::json)
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- --------------------------------------------------------------------
-- 4. get_client_last_purchase_analytics(p_code)
-- Returns details of last purchase, days since last, comparison with 2025, invoice items, expected next purchase
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_client_last_purchase_analytics(
    p_code VARCHAR
)
RETURNS JSON AS $$
DECLARE
    v_client_name VARCHAR;
    v_status_name VARCHAR := '—';
    v_last_doc_id BIGINT;
    v_last_doc_date DATE;
    v_last_doc_number VARCHAR;
    v_last_doc_amount NUMERIC := 0;
    v_days_since INT := 0;
    v_last_2025_date DATE;
    v_last_2025_amount NUMERIC := 0;
    v_total_invoices_all_time INT := 0;
    v_avg_interval_days INT := 30;
    v_expected_next_date DATE;
    v_items_data JSON;
    v_result JSON;
BEGIN
    SELECT c.name, COALESCE(sr.status_name, '—')
    INTO v_client_name, v_status_name
    FROM clients c
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE c.code = p_code;

    IF v_client_name IS NULL THEN
        RETURN json_build_object('status', 'error', 'message', 'Client not found');
    END IF;

    -- Last document details (all time / current)
    SELECT d.id, d.invoice_date, d.doc_number, COALESCE(SUM(sl.amount), 0)
    INTO v_last_doc_id, v_last_doc_date, v_last_doc_number, v_last_doc_amount
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code AND sl.amount > 0
    GROUP BY d.id, d.invoice_date, d.doc_number
    ORDER BY d.invoice_date DESC, d.id DESC LIMIT 1;

    IF v_last_doc_date IS NOT NULL THEN
        v_days_since := (CURRENT_DATE - v_last_doc_date);
    END IF;

    -- Last purchase in 2025
    SELECT d.invoice_date, COALESCE(SUM(sl.amount), 0)
    INTO v_last_2025_date, v_last_2025_amount
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = 2025 AND sl.amount > 0
    GROUP BY d.id, d.invoice_date
    ORDER BY d.invoice_date DESC LIMIT 1;

    -- Total invoices count all time & avg interval calculation
    SELECT COUNT(DISTINCT d.id) INTO v_total_invoices_all_time
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    WHERE d.client_code = p_code AND sl.amount > 0;

    -- Average interval between purchases calculation
    WITH ordered_docs AS (
        SELECT d.invoice_date, LAG(d.invoice_date) OVER (ORDER BY d.invoice_date) AS prev_date
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        WHERE d.client_code = p_code AND sl.amount > 0
        GROUP BY d.id, d.invoice_date
    )
    SELECT COALESCE(ROUND(AVG(invoice_date - prev_date)), 30)::int
    INTO v_avg_interval_days
    FROM ordered_docs
    WHERE prev_date IS NOT NULL AND (invoice_date - prev_date) > 0;

    IF v_avg_interval_days <= 0 THEN v_avg_interval_days := 30; END IF;

    IF v_last_doc_date IS NOT NULL THEN
        v_expected_next_date := v_last_doc_date + (v_avg_interval_days || ' days')::interval;
    END IF;

    -- Items of last invoice
    IF v_last_doc_id IS NOT NULL THEN
        SELECT json_agg(
            json_build_object(
                'product_code', sl.product_code,
                'product_name', pr.name,
                'quantity', ROUND(sl.quantity::numeric, 2),
                'price', ROUND((sl.amount / NULLIF(sl.quantity, 0))::numeric, 2),
                'amount', ROUND(sl.amount::numeric, 2)
            )
        ) INTO v_items_data
        FROM sales_lines sl
        JOIN products pr ON sl.product_code = pr.code
        WHERE sl.document_id = v_last_doc_id AND sl.amount > 0;
    END IF;

    v_result := json_build_object(
        'status', 'ok',
        'client_info', json_build_object(
            'code', p_code,
            'name', v_client_name,
            'status_name', v_status_name,
            'last_doc_number', COALESCE(v_last_doc_number, '—'),
            'last_doc_date', v_last_doc_date,
            'last_doc_amount', v_last_doc_amount,
            'days_since_last', v_days_since
        ),
        'comparison_2025', json_build_object(
            'last_2025_date', v_last_2025_date,
            'last_2025_amount', v_last_2025_amount
        ),
        'recommendation', json_build_object(
            'avg_interval_days', v_avg_interval_days,
            'total_invoices_all_time', v_total_invoices_all_time,
            'expected_next_date', v_expected_next_date
        ),
        'last_invoice_items', COALESCE(v_items_data, '[]'::json)
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- --------------------------------------------------------------------
-- 5. get_client_invoices_by_month(p_code, p_year, p_month)
-- Returns list of all invoices for a client in a specific month
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_client_invoices_by_month(
    p_code VARCHAR,
    p_year INTEGER DEFAULT 2026,
    p_month INTEGER DEFAULT 1
)
RETURNS JSON AS $$
DECLARE
    v_client_name VARCHAR;
    v_month_name VARCHAR;
    v_invoices_data JSON;
    v_total_inv INT := 0;
    v_total_amt NUMERIC := 0;
    v_avg_chk NUMERIC := 0;
    v_result JSON;
BEGIN
    SELECT name INTO v_client_name FROM clients WHERE code = p_code;
    IF v_client_name IS NULL THEN
        RETURN json_build_object('status', 'error', 'message', 'Client not found');
    END IF;

    v_month_name := CASE p_month
        WHEN 1 THEN 'Январь' WHEN 2 THEN 'Февраль' WHEN 3 THEN 'Март'
        WHEN 4 THEN 'Апрель' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июнь'
        WHEN 7 THEN 'Июль' WHEN 8 THEN 'Август' WHEN 9 THEN 'Сентябрь'
        WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь' WHEN 12 THEN 'Декабрь'
    END;

    WITH doc_list AS (
        SELECT 
            d.id AS doc_id,
            d.doc_number,
            d.invoice_date AS doc_date,
            SUM(sl.amount) AS amount,
            COUNT(sl.id) AS items_count
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code 
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
          AND EXTRACT(MONTH FROM d.invoice_date) = p_month
          AND sl.amount > 0
        GROUP BY d.id, d.doc_number, d.invoice_date
        ORDER BY d.invoice_date DESC, d.id DESC
    )
    SELECT 
        COUNT(*),
        COALESCE(SUM(amount), 0),
        COALESCE(AVG(amount), 0),
        json_agg(
            json_build_object(
                'doc_id', doc_id,
                'doc_number', doc_number,
                'doc_date', doc_date,
                'amount', ROUND(amount::numeric, 2),
                'items_count', items_count
            )
        )
    INTO v_total_inv, v_total_amt, v_avg_chk, v_invoices_data
    FROM doc_list;

    v_result := json_build_object(
        'status', 'ok',
        'client_info', json_build_object(
            'code', p_code,
            'name', v_client_name
        ),
        'month_info', json_build_object(
            'year', p_year,
            'month', p_month,
            'month_name', v_month_name
        ),
        'summary', json_build_object(
            'total_invoices', v_total_inv,
            'total_amount', ROUND(v_total_amt::numeric, 2),
            'avg_check', ROUND(v_avg_chk::numeric, 2)
        ),
        'invoices', COALESCE(v_invoices_data, '[]'::json)
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;
