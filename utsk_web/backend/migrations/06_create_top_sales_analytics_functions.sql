-- ====================================================================
-- MIGRATION 06: PostgreSQL Functions for TOP Sales Analytics (7 Tabs)
-- FILTERED STRICTLY BY client_year_activity (is_active = TRUE)
-- Database: bd_intelligent_sales
-- ====================================================================

-- --------------------------------------------------------------------
-- Helper Function to calculate ABC group based on annual revenue
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_abc_group_for_revenue(p_revenue NUMERIC)
RETURNS VARCHAR AS $$
BEGIN
    IF p_revenue IS NULL OR p_revenue < 1000 THEN
        RETURN 'C2';
    ELSIF p_revenue >= 3000000 THEN
        RETURN 'A1';
    ELSIF p_revenue >= 2000000 THEN
        RETURN 'A2';
    ELSIF p_revenue >= 1500000 THEN
        RETURN 'A3';
    ELSIF p_revenue >= 1000000 THEN
        RETURN 'B1';
    ELSIF p_revenue >= 500000 THEN
        RETURN 'B2';
    ELSIF p_revenue >= 150000 THEN
        RETURN 'C1';
    ELSE
        RETURN 'C2';
    END IF;
END;
$$ LANGUAGE plpgsql STABLE;

-- --------------------------------------------------------------------
-- 1. get_top_sales_kpi(p_year)
-- Returns overall KPI metrics for TOP Sales Analytics page
-- Filtered strictly by active clients (client_year_activity is_active = TRUE)
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_top_sales_kpi(p_year INTEGER DEFAULT 2026)
RETURNS TABLE(
    total_revenue NUMERIC,
    active_clients_count BIGINT,
    top1_share_pct NUMERIC,
    top10_share_pct NUMERIC,
    clients_for_80pct BIGINT,
    avg_check NUMERIC
) AS $$
DECLARE
    v_total_revenue NUMERIC := 0;
    v_total_invoices BIGINT := 0;
    v_top1_rev NUMERIC := 0;
    v_top10_rev NUMERIC := 0;
    v_clients_80 BIGINT := 0;
BEGIN
    -- Total goods revenue and total invoices for active clients in p_year
    SELECT 
        COALESCE(ROUND(SUM(sl.amount)::numeric, 2), 0),
        COALESCE(COUNT(DISTINCT d.id), 0)
    INTO v_total_revenue, v_total_invoices
    FROM clients c
    JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE c.code NOT IN ('9653', '11230')
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    IF v_total_revenue = 0 THEN
        RETURN QUERY SELECT 0::NUMERIC, 0::BIGINT, 0::NUMERIC, 0::NUMERIC, 0::BIGINT, 0::NUMERIC;
        RETURN;
    END IF;

    -- Active clients count from client_year_activity
    SELECT COUNT(DISTINCT cya.client_code)
    INTO active_clients_count
    FROM client_year_activity cya
    WHERE cya.sales_year = p_year AND cya.is_active = TRUE
      AND cya.client_code NOT IN ('9653', '11230');

    -- Top 1 client revenue
    WITH top1 AS (
        SELECT SUM(sl.amount) as rev
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code
        ORDER BY rev DESC
        LIMIT 1
    )
    SELECT COALESCE(SUM(rev), 0) INTO v_top1_rev FROM top1;

    -- Top 10 clients revenue
    WITH top10 AS (
        SELECT SUM(sl.amount) as rev
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code
        ORDER BY rev DESC
        LIMIT 10
    )
    SELECT COALESCE(SUM(rev), 0) INTO v_top10_rev FROM top10;

    -- Clients for 80% revenue
    WITH client_revs AS (
        SELECT 
            SUM(sl.amount) as rev,
            SUM(SUM(sl.amount)) OVER (ORDER BY SUM(sl.amount) DESC) as running_total
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code
    ),
    filtered AS (
        SELECT rev, running_total, (100.0 * running_total / v_total_revenue) as run_pct, (100.0 * rev / v_total_revenue) as pct
        FROM client_revs
    )
    SELECT COUNT(*) INTO v_clients_80
    FROM filtered
    WHERE run_pct <= 80 OR (run_pct > 80 AND run_pct - pct < 80);

    total_revenue := v_total_revenue;
    top1_share_pct := ROUND((100.0 * v_top1_rev / v_total_revenue)::numeric, 2);
    top10_share_pct := ROUND((100.0 * v_top10_rev / v_total_revenue)::numeric, 2);
    clients_for_80pct := v_clients_80;
    avg_check := CASE WHEN v_total_invoices > 0 THEN ROUND((v_total_revenue / v_total_invoices)::numeric, 2) ELSE 0 END;

    RETURN NEXT;
END;
$$ LANGUAGE plpgsql STABLE;


-- --------------------------------------------------------------------
-- 2. get_top_companies(p_year, p_limit)
-- Filtered strictly by active clients (client_year_activity is_active = TRUE)
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_top_companies(INTEGER, INTEGER) CASCADE;
CREATE OR REPLACE FUNCTION public.get_top_companies(p_year INTEGER DEFAULT 2026, p_limit INTEGER DEFAULT 5)
RETURNS TABLE(
    rank BIGINT,
    code VARCHAR,
    name VARCHAR,
    goods_revenue NUMERIC,
    pct_of_total NUMERIC,
    running_pct NUMERIC,
    status_name VARCHAR,
    invoice_count BIGINT,
    avg_check NUMERIC,
    prev_year_revenue NUMERIC,
    growth_yoy_pct NUMERIC,
    abc_group VARCHAR,
    prev_period_revenue NUMERIC
) AS $$
DECLARE
    v_total_revenue NUMERIC := 0;
    v_max_month INTEGER := 12;
BEGIN
    SELECT COALESCE(MAX(EXTRACT(MONTH FROM d.invoice_date))::int, 12)
    INTO v_max_month
    FROM documents d
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year;

    SELECT COALESCE(SUM(sl.amount)::numeric, 0)
    INTO v_total_revenue
    FROM clients c
    JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE c.code NOT IN ('9653', '11230')
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    RETURN QUERY
    WITH curr_sales AS (
        SELECT 
            c.code as client_code,
            c.name as client_name,
            sr.status_name as curr_status,
            ROUND(SUM(sl.amount)::numeric, 2) as rev,
            COUNT(DISTINCT d.id) as inv_cnt
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code, c.name, sr.status_name
    ),
    prev_sales_total AS (
        SELECT 
            c.code as client_code,
            ROUND(SUM(sl.amount)::numeric, 2) as rev
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code
    ),
    prev_sales_period AS (
        SELECT 
            c.code as client_code,
            ROUND(SUM(sl.amount)::numeric, 2) as rev
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
          AND EXTRACT(MONTH FROM d.invoice_date) <= v_max_month
        GROUP BY c.code
    ),
    ranked AS (
        SELECT 
            cs.client_code,
            cs.client_name,
            cs.curr_status,
            cs.rev,
            cs.inv_cnt,
            COALESCE(pst.rev, 0.0) as prev_total_rev,
            COALESCE(psp.rev, 0.0) as prev_period_rev,
            SUM(cs.rev) OVER (ORDER BY cs.rev DESC) as run_tot,
            ROW_NUMBER() OVER (ORDER BY cs.rev DESC) as rk
        FROM curr_sales cs
        LEFT JOIN prev_sales_total pst ON pst.client_code = cs.client_code
        LEFT JOIN prev_sales_period psp ON psp.client_code = cs.client_code
    )
    SELECT 
        r.rk::BIGINT as rank,
        r.client_code::VARCHAR as code,
        COALESCE(r.client_name, '—')::VARCHAR as name,
        r.rev::NUMERIC as goods_revenue,
        ROUND((100.0 * r.rev / NULLIF(v_total_revenue, 0))::numeric, 2)::NUMERIC as pct_of_total,
        ROUND((100.0 * r.run_tot / NULLIF(v_total_revenue, 0))::numeric, 2)::NUMERIC as running_pct,
        COALESCE(r.curr_status, '—')::VARCHAR as status_name,
        r.inv_cnt::BIGINT as invoice_count,
        ROUND((r.rev / NULLIF(r.inv_cnt, 0))::numeric, 2)::NUMERIC as avg_check,
        r.prev_total_rev::NUMERIC as prev_year_revenue,
        CASE 
            WHEN r.prev_total_rev > 0 THEN ROUND((100.0 * r.rev / r.prev_total_rev)::numeric, 2)
            ELSE NULL
        END::NUMERIC as growth_yoy_pct,
        get_abc_group_for_revenue(r.rev)::VARCHAR as abc_group,
        r.prev_period_rev::NUMERIC as prev_period_revenue
    FROM ranked r
    ORDER BY r.rk ASC
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql STABLE;


-- --------------------------------------------------------------------
-- 3. get_top_company_detail(p_code, p_year)
-- Returns full details for TOP-1 (or any selected) company
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_top_company_detail(p_code VARCHAR, p_year INTEGER DEFAULT 2026)
RETURNS JSON AS $$
DECLARE
    v_total_revenue NUMERIC := 0;
    v_curr_rev NUMERIC := 0;
    v_prev_total_rev NUMERIC := 0;
    v_prev_period_rev NUMERIC := 0;
    v_inv_cnt BIGINT := 0;
    v_client_name VARCHAR := '—';
    v_status_name VARCHAR := '—';
    v_abc_group VARCHAR := '—';
    v_max_month INTEGER := 12;
    v_monthly_curr JSON;
    v_monthly_prev JSON;
    v_top_products JSON;
    v_result JSON;
BEGIN
    -- Max month for p_year
    SELECT COALESCE(MAX(EXTRACT(MONTH FROM d.invoice_date))::int, 12)
    INTO v_max_month
    FROM documents d
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year;

    -- Total year revenue in active companies
    SELECT COALESCE(SUM(sl.amount)::numeric, 0)
    INTO v_total_revenue
    FROM clients c
    JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE c.code NOT IN ('9653', '11230')
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    -- Current client basic info & current year sales
    SELECT 
        COALESCE(c.name, '—'),
        COALESCE(sr.status_name, '—'),
        COALESCE(ROUND(SUM(sl.amount)::numeric, 2), 0),
        COALESCE(COUNT(DISTINCT d.id), 0)
    INTO v_client_name, v_status_name, v_curr_rev, v_inv_cnt
    FROM clients c
    JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    LEFT JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    LEFT JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
    WHERE c.code = p_code
    GROUP BY c.name, sr.status_name;

    -- Previous year sales TOTAL (12 months)
    SELECT COALESCE(ROUND(SUM(sl.amount)::numeric, 2), 0)
    INTO v_prev_total_rev
    FROM clients c
    JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE c.code = p_code
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    -- Previous year sales SAME PERIOD (months <= v_max_month)
    SELECT COALESCE(ROUND(SUM(sl.amount)::numeric, 2), 0)
    INTO v_prev_period_rev
    FROM clients c
    JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE c.code = p_code
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0
      AND EXTRACT(MONTH FROM d.invoice_date) <= v_max_month;

    v_abc_group := get_abc_group_for_revenue(v_curr_rev);

    -- Monthly dynamics for current year (1..12)
    SELECT json_agg(months_data ORDER BY m)
    INTO v_monthly_curr
    FROM (
        SELECT 
            m,
            COALESCE(ROUND(SUM(sl.amount)::numeric, 2), 0) as rev
        FROM generate_series(1, 12) m
        LEFT JOIN documents d ON EXTRACT(MONTH FROM d.invoice_date) = m 
            AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
            AND d.client_code = p_code
        LEFT JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
        GROUP BY m
    ) months_data;

    -- Monthly dynamics for previous year (1..12)
    SELECT json_agg(months_data ORDER BY m)
    INTO v_monthly_prev
    FROM (
        SELECT 
            m,
            COALESCE(ROUND(SUM(sl.amount)::numeric, 2), 0) as rev
        FROM generate_series(1, 12) m
        LEFT JOIN documents d ON EXTRACT(MONTH FROM d.invoice_date) = m 
            AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) 
            AND d.client_code = p_code
        LEFT JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
        GROUP BY m
    ) months_data;

    -- TOP 5 products for this client in p_year
    SELECT json_agg(prod_data)
    INTO v_top_products
    FROM (
        SELECT 
            sl.product_code,
            COALESCE(pr.name, 'Товар ' || sl.product_code) as product_name,
            ROUND(SUM(sl.quantity)::numeric, 2) as quantity,
            ROUND(SUM(sl.amount)::numeric, 2) as amount,
            CASE WHEN v_curr_rev > 0 THEN ROUND((100.0 * SUM(sl.amount) / v_curr_rev)::numeric, 2) ELSE 0 END as share_pct
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE d.client_code = p_code
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY sl.product_code, pr.name
        ORDER BY amount DESC
        LIMIT 5
    ) prod_data;

    v_result := json_build_object(
        'code', p_code,
        'name', v_client_name,
        'status_name', v_status_name,
        'abc_group', v_abc_group,
        'year', p_year,
        'goods_revenue', v_curr_rev,
        'prev_year_revenue', v_prev_total_rev,
        'prev_period_revenue', v_prev_period_rev,
        'growth_yoy_pct', CASE WHEN v_prev_total_rev > 0 THEN ROUND((100.0 * v_curr_rev / v_prev_total_rev)::numeric, 2) ELSE NULL END,
        'invoice_count', v_inv_cnt,
        'avg_check', CASE WHEN v_inv_cnt > 0 THEN ROUND((v_curr_rev / v_inv_cnt)::numeric, 2) ELSE 0 END,
        'pct_of_total', CASE WHEN v_total_revenue > 0 THEN ROUND((100.0 * v_curr_rev / v_total_revenue)::numeric, 2) ELSE 0 END,
        'monthly_curr', COALESCE(v_monthly_curr, '[]'::json),
        'monthly_prev', COALESCE(v_monthly_prev, '[]'::json),
        'top_products', COALESCE(v_top_products, '[]'::json)
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;


-- --------------------------------------------------------------------
-- 4. get_top_revenue_core(p_year, p_pct)
-- Filtered strictly by active clients (client_year_activity is_active = TRUE)
-- --------------------------------------------------------------------
DROP FUNCTION IF EXISTS public.get_top_revenue_core(INTEGER, NUMERIC) CASCADE;
CREATE OR REPLACE FUNCTION public.get_top_revenue_core(p_year INTEGER DEFAULT 2026, p_pct NUMERIC DEFAULT 80)
RETURNS TABLE(
    rank BIGINT,
    code VARCHAR,
    name VARCHAR,
    goods_revenue NUMERIC,
    pct_of_total NUMERIC,
    running_pct NUMERIC,
    status_name VARCHAR,
    invoice_count BIGINT,
    avg_check NUMERIC,
    abc_group VARCHAR,
    prev_year_revenue NUMERIC,
    growth_yoy_pct NUMERIC,
    prev_period_revenue NUMERIC
) AS $$
DECLARE
    v_total_revenue NUMERIC := 0;
    v_max_month INTEGER := 12;
BEGIN
    SELECT COALESCE(MAX(EXTRACT(MONTH FROM d.invoice_date))::int, 12)
    INTO v_max_month
    FROM documents d
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year;

    SELECT COALESCE(SUM(sl.amount)::numeric, 0)
    INTO v_total_revenue
    FROM clients c
    JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE c.code NOT IN ('9653', '11230')
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    RETURN QUERY
    WITH curr_sales AS (
        SELECT 
            c.code as client_code,
            c.name as client_name,
            sr.status_name as curr_status,
            ROUND(SUM(sl.amount)::numeric, 2) as rev,
            COUNT(DISTINCT d.id) as inv_cnt
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code, c.name, sr.status_name
    ),
    prev_sales_total AS (
        SELECT 
            c.code as client_code,
            ROUND(SUM(sl.amount)::numeric, 2) as rev
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code
    ),
    prev_sales_period AS (
        SELECT 
            c.code as client_code,
            ROUND(SUM(sl.amount)::numeric, 2) as rev
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
          AND EXTRACT(MONTH FROM d.invoice_date) <= v_max_month
        GROUP BY c.code
    ),
    ranked AS (
        SELECT 
            cs.client_code,
            cs.client_name,
            cs.curr_status,
            cs.rev,
            cs.inv_cnt,
            COALESCE(pst.rev, 0.0) as prev_total_rev,
            COALESCE(psp.rev, 0.0) as prev_period_rev,
            SUM(cs.rev) OVER (ORDER BY cs.rev DESC) as run_tot,
            ROUND((100.0 * cs.rev / NULLIF(v_total_revenue, 0))::numeric, 2) as pct,
            ROUND((100.0 * SUM(cs.rev) OVER (ORDER BY cs.rev DESC) / NULLIF(v_total_revenue, 0))::numeric, 2) as run_pct,
            ROW_NUMBER() OVER (ORDER BY cs.rev DESC) as rk
        FROM curr_sales cs
        LEFT JOIN prev_sales_total pst ON pst.client_code = cs.client_code
        LEFT JOIN prev_sales_period psp ON psp.client_code = cs.client_code
    )
    SELECT 
        r.rk::BIGINT as rank,
        r.client_code::VARCHAR as code,
        COALESCE(r.client_name, '—')::VARCHAR as name,
        r.rev::NUMERIC as goods_revenue,
        r.pct::NUMERIC as pct_of_total,
        r.run_pct::NUMERIC as running_pct,
        COALESCE(r.curr_status, '—')::VARCHAR as status_name,
        r.inv_cnt::BIGINT as invoice_count,
        ROUND((r.rev / NULLIF(r.inv_cnt, 0))::numeric, 2)::NUMERIC as avg_check,
        get_abc_group_for_revenue(r.rev)::VARCHAR as abc_group,
        r.prev_total_rev::NUMERIC as prev_year_revenue,
        CASE 
            WHEN r.prev_total_rev > 0 THEN ROUND((100.0 * r.rev / r.prev_total_rev)::numeric, 2)
            ELSE NULL
        END::NUMERIC as growth_yoy_pct,
        r.prev_period_rev::NUMERIC as prev_period_revenue
    FROM ranked r
    WHERE r.run_pct <= p_pct OR (r.run_pct > p_pct AND r.run_pct - r.pct < p_pct)
    ORDER BY r.rk ASC;
END;
$$ LANGUAGE plpgsql STABLE;


-- --------------------------------------------------------------------
-- 5. get_top_compare_yoy(p_year, p_limit)
-- Filtered strictly by active clients (client_year_activity is_active = TRUE)
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_top_compare_yoy(p_year INTEGER DEFAULT 2026, p_limit INTEGER DEFAULT 10)
RETURNS JSON AS $$
DECLARE
    v_curr_top JSON;
    v_prev_top JSON;
    v_retained_cnt INTEGER := 0;
    v_new_cnt INTEGER := 0;
    v_left_cnt INTEGER := 0;
    v_result JSON;
BEGIN
    -- TOP N current year
    WITH curr_top AS (
        SELECT 
            c.code as client_code,
            c.name as client_name,
            ROUND(SUM(sl.amount)::numeric, 2) as rev,
            ROW_NUMBER() OVER (ORDER BY SUM(sl.amount) DESC) as rk
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code, c.name
        ORDER BY rev DESC
        LIMIT p_limit
    ),
    prev_top AS (
        SELECT 
            c.code as client_code,
            c.name as client_name,
            ROUND(SUM(sl.amount)::numeric, 2) as rev,
            ROW_NUMBER() OVER (ORDER BY SUM(sl.amount) DESC) as rk
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code, c.name
        ORDER BY rev DESC
        LIMIT p_limit
    )
    SELECT 
        (SELECT COUNT(*) FROM curr_top ct JOIN prev_top pt ON ct.client_code = pt.client_code),
        (SELECT COUNT(*) FROM curr_top ct WHERE ct.client_code NOT IN (SELECT client_code FROM prev_top)),
        (SELECT COUNT(*) FROM prev_top pt WHERE pt.client_code NOT IN (SELECT client_code FROM curr_top))
    INTO v_retained_cnt, v_new_cnt, v_left_cnt;

    -- Detailed JSON list comparing ranks
    WITH curr_top AS (
        SELECT 
            c.code as client_code,
            c.name as client_name,
            ROUND(SUM(sl.amount)::numeric, 2) as rev,
            ROW_NUMBER() OVER (ORDER BY SUM(sl.amount) DESC) as rk
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code, c.name
        ORDER BY rev DESC
        LIMIT p_limit
    ),
    prev_top AS (
        SELECT 
            c.code as client_code,
            c.name as client_name,
            ROUND(SUM(sl.amount)::numeric, 2) as rev,
            ROW_NUMBER() OVER (ORDER BY SUM(sl.amount) DESC) as rk
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code, c.name
        ORDER BY rev DESC
        LIMIT p_limit
    ),
    combined AS (
        SELECT 
            ct.rk as curr_rank,
            ct.client_code,
            ct.client_name,
            ct.rev as curr_revenue,
            pt.rk as prev_rank,
            COALESCE(pt.rev, 0.0) as prev_revenue,
            CASE 
                WHEN pt.client_code IS NOT NULL THEN 'retained'
                ELSE 'new'
            END as category
        FROM curr_top ct
        LEFT JOIN prev_top pt ON pt.client_code = ct.client_code
    )
    SELECT json_agg(combined ORDER BY curr_rank)
    INTO v_curr_top
    FROM combined;

    -- Dropped out list
    WITH curr_top AS (
        SELECT c.code as client_code 
        FROM clients c 
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
        JOIN sales_lines sl ON sl.document_id = d.id 
        LEFT JOIN products pr ON sl.product_code = pr.code 
        WHERE c.code NOT IN ('9653', '11230') AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0 
        GROUP BY c.code 
        ORDER BY SUM(sl.amount) DESC 
        LIMIT p_limit
    ),
    prev_top AS (
        SELECT 
            c.code as client_code,
            c.name as client_name,
            ROUND(SUM(sl.amount)::numeric, 2) as rev,
            ROW_NUMBER() OVER (ORDER BY SUM(sl.amount) DESC) as rk
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code, c.name
        ORDER BY rev DESC
        LIMIT p_limit
    )
    SELECT json_agg(dropped ORDER BY dropped.prev_rank)
    INTO v_prev_top
    FROM (
        SELECT pt.rk as prev_rank, pt.client_code, pt.client_name, pt.rev as prev_revenue
        FROM prev_top pt
        WHERE pt.client_code NOT IN (SELECT client_code FROM curr_top)
    ) dropped;

    v_result := json_build_object(
        'year', p_year,
        'limit', p_limit,
        'retained_count', v_retained_cnt,
        'new_entries_count', v_new_cnt,
        'left_top_count', v_left_cnt,
        'current_top', COALESCE(v_curr_top, '[]'::json),
        'dropped_out', COALESCE(v_prev_top, '[]'::json)
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;
