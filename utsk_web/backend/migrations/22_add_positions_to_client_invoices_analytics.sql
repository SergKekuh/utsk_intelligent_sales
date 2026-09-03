-- Migration 22: Add positions and unique_positions to get_client_invoices_analytics and default limit 500 for get_client_invoices

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

CREATE OR REPLACE FUNCTION public.get_client_invoices(
    p_code TEXT,
    p_year INT DEFAULT 2026,
    p_month_int INT DEFAULT NULL,
    p_date_from DATE DEFAULT NULL,
    p_date_to DATE DEFAULT NULL,
    p_limit INT DEFAULT 500
)
RETURNS TABLE(
    date TEXT,
    number VARCHAR,
    total NUMERIC,
    positions BIGINT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(d.invoice_date, 'DD.MM.YYYY') AS date,
        d.doc_number AS number,
        ROUND(SUM(sl.amount)::numeric, 0) AS total,
        COUNT(sl.id)::BIGINT AS positions
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.client_code = p_code
      AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
      AND (
          (p_date_from IS NOT NULL AND p_date_to IS NOT NULL AND d.invoice_date BETWEEN p_date_from AND p_date_to)
          OR
          (p_date_from IS NULL AND p_month_int IS NOT NULL AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND EXTRACT(MONTH FROM d.invoice_date) = p_month_int)
          OR
          (p_date_from IS NULL AND p_month_int IS NULL AND EXTRACT(YEAR FROM d.invoice_date) = p_year)
      )
    GROUP BY d.id, d.invoice_date, d.doc_number
    ORDER BY d.invoice_date DESC
    LIMIT COALESCE(p_limit, 500);
END;
$function$;
