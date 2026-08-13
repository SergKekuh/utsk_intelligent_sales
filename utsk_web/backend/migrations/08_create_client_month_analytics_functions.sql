-- ====================================================================
-- MIGRATION 08: PostgreSQL Functions for Client Month Deep Analytics
-- Database: bd_intelligent_sales
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. get_client_month_summary(p_code, p_year, p_month)
-- Returns KPI metrics and comparison with previous month & previous year's month
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_client_month_summary(
    p_code VARCHAR,
    p_year INTEGER DEFAULT 2026,
    p_month INTEGER DEFAULT 1
)
RETURNS JSON AS $$
DECLARE
    v_client_name VARCHAR;
    v_status_name VARCHAR := '—';
    v_month_name VARCHAR;
    
    v_prev_month INT;
    v_prev_month_year INT;
    
    v_rev_curr NUMERIC := 0;
    v_inv_curr BIGINT := 0;
    v_avg_curr NUMERIC := 0;
    
    v_rev_prev_m NUMERIC := 0;
    v_inv_prev_m BIGINT := 0;
    v_avg_prev_m NUMERIC := 0;
    
    v_rev_prev_y_m NUMERIC := 0;
    v_inv_prev_y_m BIGINT := 0;
    
    v_growth_prev_m_rev NUMERIC := NULL;
    v_growth_prev_m_inv NUMERIC := NULL;
    v_growth_prev_m_avg NUMERIC := NULL;
    
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

    v_month_name := CASE p_month
        WHEN 1 THEN 'Январь' WHEN 2 THEN 'Февраль' WHEN 3 THEN 'Март'
        WHEN 4 THEN 'Апрель' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июнь'
        WHEN 7 THEN 'Июль' WHEN 8 THEN 'Август' WHEN 9 THEN 'Сентябрь'
        WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь' WHEN 12 THEN 'Декабрь'
    END;

    IF p_month = 1 THEN
        v_prev_month := 12;
        v_prev_month_year := p_year - 1;
    ELSE
        v_prev_month := p_month - 1;
        v_prev_month_year := p_year;
    END IF;

    -- Current month revenue & invoices
    SELECT 
        COALESCE(SUM(sl.amount), 0),
        COALESCE(COUNT(DISTINCT d.id), 0)
    INTO v_rev_curr, v_inv_curr
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code 
      AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month
      AND sl.amount > 0;

    IF v_inv_curr > 0 THEN
        v_avg_curr := ROUND((v_rev_curr / v_inv_curr::numeric), 2);
    END IF;

    -- Previous month revenue & invoices
    SELECT 
        COALESCE(SUM(sl.amount), 0),
        COALESCE(COUNT(DISTINCT d.id), 0)
    INTO v_rev_prev_m, v_inv_prev_m
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code 
      AND EXTRACT(YEAR FROM d.invoice_date) = v_prev_month_year 
      AND EXTRACT(MONTH FROM d.invoice_date) = v_prev_month
      AND sl.amount > 0;

    IF v_inv_prev_m > 0 THEN
        v_avg_prev_m := ROUND((v_rev_prev_m / v_inv_prev_m::numeric), 2);
    END IF;

    -- Previous year's same month revenue & invoices
    SELECT 
        COALESCE(SUM(sl.amount), 0),
        COALESCE(COUNT(DISTINCT d.id), 0)
    INTO v_rev_prev_y_m, v_inv_prev_y_m
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code 
      AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) 
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month
      AND sl.amount > 0;

    -- Changes vs previous month
    IF v_rev_prev_m > 0 THEN
        v_growth_prev_m_rev := ROUND(((v_rev_curr - v_rev_prev_m) / v_rev_prev_m * 100)::numeric, 1);
    END IF;

    IF v_inv_prev_m > 0 THEN
        v_growth_prev_m_inv := ROUND(((v_inv_curr - v_inv_prev_m)::numeric / v_inv_prev_m * 100)::numeric, 1);
    END IF;

    IF v_avg_prev_m > 0 THEN
        v_growth_prev_m_avg := ROUND(((v_avg_curr - v_avg_prev_m) / v_avg_prev_m * 100)::numeric, 1);
    END IF;

    v_result := json_build_object(
        'status', 'ok',
        'client_info', json_build_object(
            'code', p_code,
            'name', v_client_name,
            'status_name', v_status_name
        ),
        'month_info', json_build_object(
            'year', p_year,
            'month', p_month,
            'month_name', v_month_name
        ),
        'kpi', json_build_object(
            'rev_month', v_rev_curr,
            'inv_month', v_inv_curr,
            'avg_check_month', v_avg_curr,
            'growth_to_prev_month_pct', v_growth_prev_m_rev
        ),
        'prev_month_comparison', json_build_object(
            'rev_curr', v_rev_curr,
            'rev_prev_month', v_rev_prev_m,
            'rev_change_pct', v_growth_prev_m_rev,
            'inv_curr', v_inv_curr,
            'inv_prev_month', v_inv_prev_m,
            'inv_change_pct', v_growth_prev_m_inv,
            'avg_curr', v_avg_curr,
            'avg_prev_month', v_avg_prev_m,
            'avg_change_pct', v_growth_prev_m_avg
        ),
        'prev_year_comparison', json_build_object(
            'rev_prev_year_month', v_rev_prev_y_m,
            'inv_prev_year_month', v_inv_prev_y_m
        )
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- --------------------------------------------------------------------
-- 2. get_client_month_invoices(p_code, p_year, p_month)
-- Returns list of invoices for the month
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_client_month_invoices(
    p_code VARCHAR,
    p_year INTEGER DEFAULT 2026,
    p_month INTEGER DEFAULT 1
)
RETURNS JSON AS $$
DECLARE
    v_invoices_data JSON;
    v_result JSON;
BEGIN
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
    SELECT json_agg(
        json_build_object(
            'doc_id', doc_id,
            'doc_number', doc_number,
            'doc_date', doc_date,
            'amount', ROUND(amount::numeric, 2),
            'items_count', items_count
        )
    ) INTO v_invoices_data
    FROM doc_list;

    v_result := json_build_object(
        'status', 'ok',
        'invoices', COALESCE(v_invoices_data, '[]'::json)
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- --------------------------------------------------------------------
-- 3. get_client_month_products(p_code, p_year, p_month)
-- Returns TOP-10 products for the month
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_client_month_products(
    p_code VARCHAR,
    p_year INTEGER DEFAULT 2026,
    p_month INTEGER DEFAULT 1
)
RETURNS JSON AS $$
DECLARE
    v_total_month_rev NUMERIC := 0;
    v_products_data JSON;
    v_result JSON;
BEGIN
    -- Month total revenue for share calculation
    SELECT COALESCE(SUM(sl.amount), 0) INTO v_total_month_rev
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code 
      AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month
      AND sl.amount > 0;

    WITH top_prods AS (
        SELECT 
            ROW_NUMBER() OVER (ORDER BY SUM(sl.amount) DESC) AS rank,
            sl.product_code,
            pr.name AS product_name,
            COUNT(DISTINCT d.id) AS invoices_count,
            SUM(sl.amount) AS total_amount
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code 
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
          AND EXTRACT(MONTH FROM d.invoice_date) = p_month
          AND sl.amount > 0
        GROUP BY sl.product_code, pr.name
        ORDER BY total_amount DESC
        LIMIT 10
    )
    SELECT json_agg(
        json_build_object(
            'rank', rank,
            'product_code', product_code,
            'product_name', product_name,
            'invoices_count', invoices_count,
            'total_amount', ROUND(total_amount::numeric, 2),
            'share_pct', CASE WHEN v_total_month_rev > 0 THEN ROUND((total_amount / v_total_month_rev * 100)::numeric, 1) ELSE 0 END
        )
    ) INTO v_products_data
    FROM top_prods;

    v_result := json_build_object(
        'status', 'ok',
        'products', COALESCE(v_products_data, '[]'::json)
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;

-- --------------------------------------------------------------------
-- 4. get_client_month_daily(p_code, p_year, p_month)
-- Returns daily revenue breakdown for current year & previous year's month
-- --------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.get_client_month_daily(
    p_code VARCHAR,
    p_year INTEGER DEFAULT 2026,
    p_month INTEGER DEFAULT 1
)
RETURNS JSON AS $$
DECLARE
    v_days_in_month INT;
    v_daily_data JSON;
    v_result JSON;
BEGIN
    -- Determine max days in target month
    SELECT EXTRACT(DAY FROM (date_trunc('month', make_date(p_year, p_month, 1)) + interval '1 month - 1 day'))::int
    INTO v_days_in_month;

    WITH days AS (
        SELECT generate_series(1, v_days_in_month) AS d
    ),
    curr_d AS (
        SELECT 
            EXTRACT(DAY FROM d.invoice_date)::int AS day,
            SUM(sl.amount) AS rev
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code 
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
          AND EXTRACT(MONTH FROM d.invoice_date) = p_month
          AND sl.amount > 0
        GROUP BY 1
    ),
    prev_y_d AS (
        SELECT 
            EXTRACT(DAY FROM d.invoice_date)::int AS day,
            SUM(sl.amount) AS rev
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code 
          AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) 
          AND EXTRACT(MONTH FROM d.invoice_date) = p_month
          AND sl.amount > 0
        GROUP BY 1
    ),
    combined AS (
        SELECT 
            days.d AS day,
            COALESCE(ROUND(c.rev::numeric, 2), 0) AS rev_curr,
            COALESCE(ROUND(py.rev::numeric, 2), 0) AS rev_prev_year
        FROM days
        LEFT JOIN curr_d c ON days.d = c.day
        LEFT JOIN prev_y_d py ON days.d = py.day
        ORDER BY days.d
    )
    SELECT json_agg(
        json_build_object(
            'day', day,
            'rev_curr', rev_curr,
            'rev_prev_year', rev_prev_year
        )
    ) INTO v_daily_data
    FROM combined;

    v_result := json_build_object(
        'status', 'ok',
        'daily', COALESCE(v_daily_data, '[]'::json)
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE;
