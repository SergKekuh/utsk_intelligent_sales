-- =============================================================================
-- MIGRATION: Stored functions for UTSK Intelligent Sales API
-- Date: 2026-08-11
-- Description: Replaces raw SQL queries in app.py with PostgreSQL functions
-- =============================================================================

-- 1. get_dashboard_stats()
CREATE OR REPLACE FUNCTION public.get_dashboard_stats()
RETURNS TABLE(
    total_clients BIGINT,
    active_30d BIGINT,
    active_90d BIGINT,
    total_revenue NUMERIC,
    revenue_30d NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT c.code)::BIGINT as total_clients,
        COUNT(DISTINCT CASE WHEN c.last_purchase_date >= CURRENT_DATE - INTERVAL '30 days' THEN c.code END)::BIGINT as active_30d,
        COUNT(DISTINCT CASE WHEN c.last_purchase_date >= CURRENT_DATE - INTERVAL '90 days' THEN c.code END)::BIGINT as active_90d,
        COALESCE(SUM(d.total_amount), 0)::NUMERIC as total_revenue,
        COALESCE(SUM(CASE WHEN d.invoice_date >= CURRENT_DATE - INTERVAL '30 days' THEN d.total_amount END), 0)::NUMERIC as revenue_30d
    FROM clients c 
    LEFT JOIN documents d ON d.client_code = c.code;
END;
$function$;

-- 2. get_clients_list()
CREATE OR REPLACE FUNCTION public.get_clients_list(
    p_limit INT DEFAULT 50,
    p_search TEXT DEFAULT ''
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    status VARCHAR,
    last_purchase_date DATE
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT c.code, c.name, sr.status_name as status, c.last_purchase_date
    FROM clients c 
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE (p_search IS NULL OR p_search = '' OR c.name ILIKE '%' || p_search || '%' OR c.code ILIKE '%' || p_search || '%')
    ORDER BY c.last_purchase_date DESC NULLS LAST 
    LIMIT p_limit;
END;
$function$;

-- 3. get_active_clients()
CREATE OR REPLACE FUNCTION public.get_active_clients(
    p_limit INT DEFAULT 20
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    status VARCHAR,
    last_purchase_date DATE,
    docs_count BIGINT,
    total_revenue NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT c.code, c.name, sr.status_name as status, c.last_purchase_date,
           COUNT(d.id)::BIGINT as docs_count, 
           COALESCE(SUM(d.total_amount), 0)::NUMERIC as total_revenue
    FROM clients c
    JOIN documents d ON d.client_code = c.code
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE d.invoice_date >= CURRENT_DATE - INTERVAL '30 days'
      AND c.code != ALL(ARRAY['9653', '11230'])
    GROUP BY c.code, c.name, sr.status_name, c.last_purchase_date
    ORDER BY total_revenue DESC 
    LIMIT p_limit;
END;
$function$;

-- 4. get_churn_risk_clients()
CREATE OR REPLACE FUNCTION public.get_churn_risk_clients(
    p_limit INT DEFAULT 20
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    status VARCHAR,
    last_purchase_date DATE,
    days_since_last INT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT c.code, c.name, sr.status_name as status, c.last_purchase_date,
           (CURRENT_DATE - c.last_purchase_date::DATE)::INT as days_since_last
    FROM clients c 
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE c.last_purchase_date IS NOT NULL
      AND c.last_purchase_date < CURRENT_DATE - INTERVAL '90 days'
    ORDER BY days_since_last DESC 
    LIMIT p_limit;
END;
$function$;

-- 5. get_client_detail()
CREATE OR REPLACE FUNCTION public.get_client_detail(
    p_code TEXT,
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    status VARCHAR,
    total_revenue NUMERIC,
    total_invoices BIGINT,
    total_positions BIGINT,
    avg_check NUMERIC,
    last_purchase_date DATE
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        c.code,
        c.name,
        sr.status_name AS status,
        COALESCE(ROUND(SUM(sl.amount)::numeric, 0), 0) AS total_revenue,
        COUNT(DISTINCT d.id)::BIGINT AS total_invoices,
        COUNT(sl.id)::BIGINT AS total_positions,
        COALESCE(ROUND(AVG(sl.amount)::numeric, 0), 0) AS avg_check,
        MAX(d.invoice_date) AS last_purchase_date
    FROM clients c
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    LEFT JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    LEFT JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE c.code = p_code AND COALESCE(pr.is_service, FALSE) = FALSE AND (sl.amount IS NULL OR sl.amount > 0)
    GROUP BY c.code, c.name, sr.status_name;
END;
$function$;

-- 6. get_client_invoices()
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

-- 7. get_invoice_items()
CREATE OR REPLACE FUNCTION public.get_invoice_items(
    p_number TEXT
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    quantity NUMERIC,
    total NUMERIC,
    weight_kg NUMERIC,
    price NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        sl.product_code AS code,
        COALESCE(pr.name, sl.product_code) AS name,
        COALESCE(sl.quantity, 0)::NUMERIC AS quantity,
        COALESCE(sl.amount, 0)::NUMERIC AS total,
        (COALESCE(pr.weight_per_meter, 0) * COALESCE(sl.quantity, 0))::NUMERIC AS weight_kg,
        (CASE WHEN COALESCE(sl.quantity, 0) > 0 THEN sl.amount / sl.quantity ELSE 0 END)::NUMERIC AS price
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.doc_number = p_number
    ORDER BY sl.id;
END;
$function$;

-- 8. get_statuses_distribution()
CREATE OR REPLACE FUNCTION public.get_statuses_distribution()
RETURNS TABLE(
    status_name VARCHAR,
    count BIGINT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT sr.status_name, COUNT(*)::BIGINT as count
    FROM clients c 
    JOIN status_rules sr ON c.current_status_id = sr.id
    GROUP BY sr.status_name, sr.priority 
    ORDER BY sr.priority;
END;
$function$;

-- 9. get_products_list()
CREATE OR REPLACE FUNCTION public.get_products_list(
    p_limit INT DEFAULT 50,
    p_search TEXT DEFAULT ''
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    in_stock_balance NUMERIC,
    direction VARCHAR
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p.code, p.name, p.in_stock_balance, ad.name as direction
    FROM products p 
    LEFT JOIN activity_directions ad ON p.anchor_direction_id = ad.id
    WHERE (p_search IS NULL OR p_search = '' OR p.name ILIKE '%' || p_search || '%' OR p.code ILIKE '%' || p_search || '%')
    ORDER BY p.code 
    LIMIT p_limit;
END;
$function$;

-- 10. get_recommendations_for_client()
CREATE OR REPLACE FUNCTION public.get_recommendations_for_client(
    p_client_code TEXT
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    in_stock NUMERIC,
    purchase_count_total BIGINT,
    purchases_current_year BIGINT,
    revenue_current_year NUMERIC,
    purchases_prev_year BIGINT,
    revenue_prev_year NUMERIC,
    last_purchase_date DATE,
    pct_current_year NUMERIC,
    pct_prev_year NUMERIC,
    trend TEXT,
    days_since_last INT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH client_total_current AS (
        SELECT COALESCE(SUM(sl.amount), 0) AS total_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE)
          AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
    ),
    client_total_prev AS (
        SELECT COALESCE(SUM(sl.amount), 0) AS total_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
          AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
    ),
    product_stats AS (
        SELECT 
            p.code, 
            p.name, 
            COALESCE(p.in_stock_balance, 0)::NUMERIC as in_stock,
            COUNT(sl.id)::BIGINT as purchase_count_total,
            COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) THEN d.id END)::BIGINT as purchases_current_year,
            COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) THEN sl.amount ELSE 0 END), 0)::NUMERIC as revenue_current_year,
            COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1 THEN d.id END)::BIGINT as purchases_prev_year,
            COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1 THEN sl.amount ELSE 0 END), 0)::NUMERIC as revenue_prev_year,
            MAX(d.invoice_date) as last_purchase_date
        FROM clients c
        JOIN documents d ON d.client_code = c.code
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON sl.product_code = p.code
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code = p_client_code 
          AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
        GROUP BY p.code, p.name, p.in_stock_balance
        HAVING COUNT(sl.id) >= 2
    )
    SELECT 
        ps.code,
        ps.name,
        ps.in_stock,
        ps.purchase_count_total,
        ps.purchases_current_year,
        ps.revenue_current_year,
        ps.purchases_prev_year,
        ps.revenue_prev_year,
        ps.last_purchase_date,
        ROUND(ps.revenue_current_year / NULLIF((SELECT total_revenue FROM client_total_current), 0) * 100, 1)::NUMERIC as pct_current_year,
        ROUND(ps.revenue_prev_year / NULLIF((SELECT total_revenue FROM client_total_prev), 0) * 100, 1)::NUMERIC as pct_prev_year,
        (CASE 
            WHEN ps.purchases_current_year > ps.purchases_prev_year THEN '📈 Рост'
            WHEN ps.purchases_current_year < ps.purchases_prev_year THEN '📉 Спад'
            WHEN ps.purchases_current_year = ps.purchases_prev_year AND ps.purchases_current_year > 0 THEN '➡️ Стабильно'
            ELSE '🆕 Новый'
        END)::TEXT as trend,
        (CURRENT_DATE - ps.last_purchase_date::DATE)::INTEGER as days_since_last
    FROM product_stats ps
    ORDER BY ROUND(ps.revenue_current_year / NULLIF((SELECT total_revenue FROM client_total_current), 0) * 100, 1) DESC, ps.purchase_count_total DESC
    LIMIT 5;
END;
$function$;

-- 11. get_funnel_data()
CREATE OR REPLACE FUNCTION public.get_funnel_data(
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    stage TEXT,
    sort_order INT,
    count BIGINT,
    revenue NUMERIC
)
LANGUAGE plpgsql STABLE
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
                WHEN invoice_count = 1 THEN 'Разовые (1)'
                WHEN invoice_count BETWEEN 2 AND 3 THEN 'Повторные (2-3)'
                WHEN invoice_count BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
                WHEN invoice_count BETWEEN 11 AND 40 THEN 'Месяц (11-40)'
                WHEN invoice_count BETWEEN 41 AND 170 THEN 'Неделя (41-170)'
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

-- 12. get_top_recommendations()
CREATE OR REPLACE FUNCTION public.get_top_recommendations(
    p_limit INT DEFAULT 10
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    total_sales BIGINT,
    in_stock_balance NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p.code, p.name, COUNT(sl.id)::BIGINT as total_sales,
           COALESCE(p.in_stock_balance, 0)::NUMERIC as in_stock_balance
    FROM products p
    JOIN sales_lines sl ON sl.product_code = p.code
    WHERE COALESCE(p.in_stock_balance, 0) > 0
    GROUP BY p.code, p.name, p.in_stock_balance
    ORDER BY total_sales DESC 
    LIMIT p_limit;
END;
$function$;

-- 13. get_monthly_revenue()
CREATE OR REPLACE FUNCTION public.get_monthly_revenue(
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    year INT,
    month INT,
    month_name TEXT,
    active_clients BIGINT,
    invoice_count BIGINT,
    goods_revenue NUMERIC,
    services_revenue NUMERIC,
    total_revenue NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        EXTRACT(YEAR FROM d.invoice_date)::INTEGER AS year,
        EXTRACT(MONTH FROM d.invoice_date)::INTEGER AS month,
        TO_CHAR(TO_DATE(EXTRACT(MONTH FROM d.invoice_date)::TEXT, 'MM'), 'Mon')::TEXT AS month_name,
        COUNT(DISTINCT d.client_code)::BIGINT AS active_clients,
        COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
        COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue,
        COALESCE(SUM(CASE WHEN pr.is_service = TRUE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS services_revenue,
        COALESCE(SUM(sl.amount), 0)::NUMERIC AS total_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    JOIN client_year_activity cya ON d.client_code = cya.client_code AND cya.sales_year = p_year AND cya.is_active = TRUE
    JOIN clients c ON d.client_code = c.code
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
    GROUP BY EXTRACT(YEAR FROM d.invoice_date), EXTRACT(MONTH FROM d.invoice_date)
    ORDER BY month;
END;
$function$;

-- 14. get_yoy_comparison()
CREATE OR REPLACE FUNCTION public.get_yoy_comparison(
    p_year1 INT DEFAULT 2026,
    p_year2 INT DEFAULT 2025
)
RETURNS TABLE(
    month INT,
    month_name TEXT,
    goods_revenue_y1 NUMERIC,
    goods_revenue_y2 NUMERIC,
    clients_y1 BIGINT,
    clients_y2 BIGINT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH mutual_clients AS (
        SELECT DISTINCT d1.client_code
        FROM documents d1
        WHERE EXTRACT(YEAR FROM d1.invoice_date) = p_year1
        INTERSECT
        SELECT DISTINCT d2.client_code
        FROM documents d2
        WHERE EXTRACT(YEAR FROM d2.invoice_date) = p_year2
    )
    SELECT 
        EXTRACT(MONTH FROM d.invoice_date)::INTEGER AS month,
        TO_CHAR(TO_DATE(EXTRACT(MONTH FROM d.invoice_date)::TEXT, 'MM'), 'Mon')::TEXT AS month_name,
        COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year1 
            AND pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue_y1,
        COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year2 
            AND pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue_y2,
        COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year1 
            THEN d.client_code END)::BIGINT AS clients_y1,
        COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year2 
            THEN d.client_code END)::BIGINT AS clients_y2
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.client_code IN (SELECT mc.client_code FROM mutual_clients mc)
      AND EXTRACT(YEAR FROM d.invoice_date) IN (p_year1, p_year2)
    GROUP BY EXTRACT(MONTH FROM d.invoice_date)
    ORDER BY month;
END;
$function$;

-- 15. get_abc_migration()
CREATE OR REPLACE FUNCTION public.get_abc_migration(
    p_year INT DEFAULT 2026,
    p_groups TEXT[] DEFAULT ARRAY['A1','A2','B1','B2'],
    p_multiplier NUMERIC DEFAULT 2.9
)
RETURNS TABLE(
    group_prev TEXT,
    companies_count BIGINT,
    goods_revenue NUMERIC,
    invoice_count BIGINT
)
LANGUAGE plpgsql STABLE
AS $function$
DECLARE
    v_year_prev INT := p_year - 1;
BEGIN
    RETURN QUERY
    WITH abc_prev AS (
        SELECT 
            client_code,
            cya.goods_revenue
        FROM client_year_activity cya
        WHERE sales_year = v_year_prev
    ),
    abc_grouped AS (
        SELECT 
            ap.client_code,
            CASE
                WHEN ap.goods_revenue >= 3000000 * p_multiplier THEN 'A1'
                WHEN ap.goods_revenue >= 2000000 * p_multiplier THEN 'A2'
                WHEN ap.goods_revenue >= 1500000 * p_multiplier THEN 'A3'
                WHEN ap.goods_revenue >= 1000000 * p_multiplier THEN 'B1'
                WHEN ap.goods_revenue >= 500000  * p_multiplier THEN 'B2'
                WHEN ap.goods_revenue >= 150000  * p_multiplier THEN 'C1'
                WHEN ap.goods_revenue >= 1000    * p_multiplier THEN 'C2'
                ELSE 'Other'
            END AS abc_group
        FROM abc_prev ap
    )
    SELECT 
        ag.abc_group::TEXT AS group_prev,
        COUNT(DISTINCT ag.client_code)::BIGINT AS companies_count,
        COALESCE(SUM(v.goods_revenue), 0)::NUMERIC AS goods_revenue,
        COALESCE(SUM(v.invoice_count), 0)::BIGINT AS invoice_count
    FROM abc_grouped ag
    LEFT JOIN view_client_profiles_yearly v 
        ON v.client_code = ag.client_code 
        AND v.sales_year = p_year
    WHERE ag.abc_group = ANY(p_groups)
    GROUP BY ag.abc_group
    ORDER BY 
        CASE ag.abc_group
            WHEN 'A1' THEN 1 WHEN 'A2' THEN 2 WHEN 'A3' THEN 3
            WHEN 'B1' THEN 4 WHEN 'B2' THEN 5
            WHEN 'C1' THEN 6 WHEN 'C2' THEN 7
        END;
END;
$function$;

-- 16. get_zaletnye()
CREATE OR REPLACE FUNCTION public.get_zaletnye(
    p_year INT DEFAULT 2026,
    p_multiplier NUMERIC DEFAULT 2.9
)
RETURNS TABLE(
    group_prev TEXT,
    companies_count BIGINT,
    goods_revenue NUMERIC,
    invoice_count BIGINT
)
LANGUAGE plpgsql STABLE
AS $function$
DECLARE
    v_year_prev INT := p_year - 1;
BEGIN
    RETURN QUERY
    WITH abc_prev AS (
        SELECT 
            cya.client_code,
            cya.goods_revenue
        FROM client_year_activity cya
        WHERE sales_year = v_year_prev
    ),
    abc_grouped AS (
        SELECT 
            ap.client_code,
            CASE
                WHEN ap.goods_revenue >= 3000000 * p_multiplier THEN 'A1'
                WHEN ap.goods_revenue >= 2000000 * p_multiplier THEN 'A2'
                WHEN ap.goods_revenue >= 1500000 * p_multiplier THEN 'A3'
                WHEN ap.goods_revenue >= 1000000 * p_multiplier THEN 'B1'
                WHEN ap.goods_revenue >= 500000  * p_multiplier THEN 'B2'
                WHEN ap.goods_revenue >= 150000  * p_multiplier THEN 'C1'
                WHEN ap.goods_revenue >= 1000    * p_multiplier THEN 'C2'
                ELSE 'Other'
            END AS abc_group
        FROM abc_prev ap
    ),
    zalet_prev AS (
        SELECT ag.client_code, ag.abc_group AS group_prev
        FROM abc_grouped ag
        WHERE ag.abc_group IN ('C1', 'C2')
    ),
    new_clients AS (
        SELECT v.client_code, 'Новый' AS group_prev
        FROM view_client_profiles_yearly v
        WHERE v.sales_year = p_year
          AND v.client_code NOT IN (
              SELECT cya.client_code FROM client_year_activity cya WHERE cya.sales_year = v_year_prev AND cya.is_active = TRUE
          )
    ),
    all_zalet AS (
        SELECT * FROM zalet_prev
        UNION ALL
        SELECT * FROM new_clients
    )
    SELECT 
        az.group_prev::TEXT,
        COUNT(DISTINCT az.client_code)::BIGINT AS companies_count,
        COALESCE(SUM(v.goods_revenue), 0)::NUMERIC AS goods_revenue,
        COALESCE(SUM(v.invoice_count), 0)::BIGINT AS invoice_count
    FROM all_zalet az
    LEFT JOIN view_client_profiles_yearly v 
        ON v.client_code = az.client_code 
        AND v.sales_year = p_year
    GROUP BY az.group_prev
    ORDER BY 
        CASE az.group_prev
            WHEN 'C1' THEN 1 WHEN 'C2' THEN 2 WHEN 'Новый' THEN 3
        END;
END;
$function$;

-- 17. get_recurrent_clients()
CREATE OR REPLACE FUNCTION public.get_recurrent_clients(
    p_year INT DEFAULT 2026,
    p_multiplier NUMERIC DEFAULT 2.9
)
RETURNS TABLE(
    client_code VARCHAR,
    name VARCHAR,
    ipn VARCHAR,
    okpo_code VARCHAR,
    invoice_count BIGINT,
    goods_revenue NUMERIC,
    first_date DATE,
    last_date DATE,
    days_between INT,
    abc_group TEXT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH client_invoices AS (
        SELECT
            d.client_code,
            c.name,
            c.ipn,
            c.okpo_code,
            COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue,
            MIN(d.invoice_date) AS first_date,
            MAX(d.invoice_date) AS last_date,
            (MAX(d.invoice_date) - MIN(d.invoice_date))::INT AS days_between
        FROM documents d
        JOIN sales_lines sl ON d.id = sl.document_id
        JOIN client_year_activity cya ON d.client_code = cya.client_code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN clients c ON d.client_code = c.code
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY d.client_code, c.name, c.ipn, c.okpo_code
        HAVING COUNT(DISTINCT d.id) BETWEEN 2 AND 3
    )
    SELECT
        ci.client_code,
        ci.name,
        ci.ipn,
        ci.okpo_code,
        ci.invoice_count,
        ci.goods_revenue,
        ci.first_date,
        ci.last_date,
        ci.days_between,
        (CASE
            WHEN ci.goods_revenue >= 3000000 * p_multiplier THEN 'A1'
            WHEN ci.goods_revenue >= 2000000 * p_multiplier THEN 'A2'
            WHEN ci.goods_revenue >= 1500000 * p_multiplier THEN 'A3'
            WHEN ci.goods_revenue >= 1000000 * p_multiplier THEN 'B1'
            WHEN ci.goods_revenue >= 500000  * p_multiplier THEN 'B2'
            WHEN ci.goods_revenue >= 150000  * p_multiplier THEN 'C1'
            WHEN ci.goods_revenue >= 1000    * p_multiplier THEN 'C2'
            ELSE 'Ниже C2'
        END)::TEXT AS abc_group
    FROM client_invoices ci
    ORDER BY ci.goods_revenue DESC;
END;
$function$;

-- 18. get_clients_yoy()
CREATE OR REPLACE FUNCTION public.get_clients_yoy(
    p_year INT DEFAULT 2026,
    p_multiplier NUMERIC DEFAULT 2.9
)
RETURNS TABLE(
    client_code VARCHAR,
    client_name VARCHAR,
    revenue_curr NUMERIC,
    revenue_prev NUMERIC,
    invoices_curr BIGINT,
    invoices_prev BIGINT,
    abc_curr TEXT,
    abc_prev TEXT
)
LANGUAGE plpgsql STABLE
AS $function$
DECLARE
    v_year_prev INT := p_year - 1;
BEGIN
    RETURN QUERY
    WITH max_month AS (
        SELECT COALESCE(MAX(EXTRACT(MONTH FROM invoice_date)), 12) AS max_m
        FROM documents WHERE EXTRACT(YEAR FROM invoice_date) = p_year
    ),
    curr AS (
        SELECT
            d.client_code,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS revenue,
            COUNT(DISTINCT d.id)::BIGINT AS invoice_count
        FROM documents d
        JOIN sales_lines sl ON d.id = sl.document_id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN client_year_activity cya ON d.client_code = cya.client_code AND cya.sales_year = p_year AND cya.is_active = TRUE
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY d.client_code
    ),
    prev AS (
        SELECT
            d.client_code,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS revenue,
            COUNT(DISTINCT d.id)::BIGINT AS invoice_count
        FROM documents d
        JOIN sales_lines sl ON d.id = sl.document_id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN client_year_activity cya ON d.client_code = cya.client_code AND cya.sales_year = v_year_prev AND cya.is_active = TRUE
        CROSS JOIN max_month m
        WHERE EXTRACT(YEAR FROM d.invoice_date) = v_year_prev
          AND EXTRACT(MONTH FROM d.invoice_date) <= m.max_m
        GROUP BY d.client_code
    ),
    abc_curr AS (
        SELECT c.client_code, c.revenue,
            (CASE
                WHEN c.revenue >= 3000000 * p_multiplier THEN 'A1'
                WHEN c.revenue >= 2000000 * p_multiplier THEN 'A2'
                WHEN c.revenue >= 1500000 * p_multiplier THEN 'A3'
                WHEN c.revenue >= 1000000 * p_multiplier THEN 'B1'
                WHEN c.revenue >= 500000  * p_multiplier THEN 'B2'
                WHEN c.revenue >= 150000  * p_multiplier THEN 'C1'
                WHEN c.revenue >= 1000                    THEN 'C2'
                ELSE 'Ниже C2'
            END)::TEXT AS abc_group,
            c.invoice_count
        FROM curr c
    ),
    abc_prev AS (
        SELECT p.client_code, p.revenue,
            (CASE
                WHEN p.revenue >= 3000000 * p_multiplier THEN 'A1'
                WHEN p.revenue >= 2000000 * p_multiplier THEN 'A2'
                WHEN p.revenue >= 1500000 * p_multiplier THEN 'A3'
                WHEN p.revenue >= 1000000 * p_multiplier THEN 'B1'
                WHEN p.revenue >= 500000  * p_multiplier THEN 'B2'
                WHEN p.revenue >= 150000  * p_multiplier THEN 'C1'
                WHEN p.revenue >= 1000                    THEN 'C2'
                ELSE 'Ниже C2'
            END)::TEXT AS abc_group,
            p.invoice_count
        FROM prev p
    )
    SELECT
        COALESCE(ac.client_code, ap.client_code) AS client_code,
        cl.name AS client_name,
        COALESCE(ac.revenue, 0)::NUMERIC AS revenue_curr,
        COALESCE(ap.revenue, 0)::NUMERIC AS revenue_prev,
        COALESCE(ac.invoice_count, 0)::BIGINT AS invoices_curr,
        COALESCE(ap.invoice_count, 0)::BIGINT AS invoices_prev,
        COALESCE(ac.abc_group, 'Новый')::TEXT AS abc_curr,
        COALESCE(ap.abc_group, 'Новый')::TEXT AS abc_prev
    FROM abc_curr ac
    FULL OUTER JOIN abc_prev ap ON ac.client_code = ap.client_code
    JOIN clients cl ON cl.code = COALESCE(ac.client_code, ap.client_code)
    ORDER BY COALESCE(ac.revenue, 0) DESC;
END;
$function$;

-- 19. get_new_clients_overview()
CREATE OR REPLACE FUNCTION public.get_new_clients_overview(
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    total_new BIGINT,
    total_revenue NUMERIC,
    avg_revenue_per_client NUMERIC,
    avg_ticket NUMERIC,
    pct_of_total_revenue NUMERIC,
    new_in_top80 BIGINT,
    avg_invoices NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH new_clients AS (
        SELECT code FROM clients 
        WHERE current_status_id = 1 AND is_active_current = TRUE AND code NOT IN ('9653', '11230')
    ),
    new_stats AS (
        SELECT 
            COUNT(DISTINCT nc.code)::BIGINT AS total_new,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS total_revenue,
            COUNT(DISTINCT d.id)::BIGINT AS total_invoices
        FROM new_clients nc
        JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
    ),
    total_stats AS (
        SELECT COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS all_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN clients c ON d.client_code = c.code
        WHERE c.is_active_current = TRUE AND c.code NOT IN ('9653', '11230')
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    ),
    new_in_top80 AS (
        SELECT COUNT(*)::BIGINT AS top_count
        FROM (
            SELECT nc.code, COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS rev,
                SUM(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)) OVER (ORDER BY COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) DESC) 
                / NULLIF(SUM(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)) OVER (), 0) * 100 AS running_pct
            FROM new_clients nc
            JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            GROUP BY nc.code
        ) sub WHERE running_pct <= 80
    )
    SELECT 
        s.total_new,
        s.total_revenue,
        ROUND(s.total_revenue / NULLIF(s.total_new, 0), 0)::NUMERIC AS avg_revenue_per_client,
        ROUND(s.total_revenue / NULLIF(s.total_invoices, 0), 0)::NUMERIC AS avg_ticket,
        ROUND(s.total_revenue / NULLIF(ts.all_revenue, 0) * 100, 1)::NUMERIC AS pct_of_total_revenue,
        COALESCE(t80.top_count, 0)::BIGINT AS new_in_top80,
        ROUND(s.total_invoices::NUMERIC / NULLIF(s.total_new, 0), 1)::NUMERIC AS avg_invoices
    FROM new_stats s, total_stats ts, new_in_top80 t80;
END;
$function$;

-- 20. get_new_clients_frequency()
CREATE OR REPLACE FUNCTION public.get_new_clients_frequency(
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    frequency_group TEXT,
    sort_order INT,
    new_count BIGINT,
    new_revenue NUMERIC,
    avg_ticket NUMERIC,
    new_pct NUMERIC,
    all_count BIGINT,
    share_pct NUMERIC
)
LANGUAGE plpgsql STABLE
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
                WHEN invoice_count = 1 THEN 'Разовые (1)'
                WHEN invoice_count BETWEEN 2 AND 3 THEN 'Повторные (2-3)'
                WHEN invoice_count BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
                WHEN invoice_count BETWEEN 11 AND 40 THEN 'Месяц (11-40)'
                WHEN invoice_count BETWEEN 41 AND 170 THEN 'Неделя (41-170)'
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
                WHEN invoice_count = 1 THEN 'Разовые (1)'
                WHEN invoice_count BETWEEN 2 AND 3 THEN 'Повторные (2-3)'
                WHEN invoice_count BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
                WHEN invoice_count BETWEEN 11 AND 40 THEN 'Месяц (11-40)'
                WHEN invoice_count BETWEEN 41 AND 170 THEN 'Неделя (41-170)'
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

-- 21. get_new_clients_abc()
CREATE OR REPLACE FUNCTION public.get_new_clients_abc(
    p_year INT DEFAULT 2026,
    p_multiplier NUMERIC DEFAULT 2.9
)
RETURNS TABLE(
    abc_group TEXT,
    count BIGINT,
    revenue NUMERIC,
    pct NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH new_clients AS (
        SELECT code FROM clients WHERE current_status_id = 1 AND is_active_current = TRUE AND code NOT IN ('9653', '11230')
    ),
    new_revenue AS (
        SELECT nc.code, COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
        FROM new_clients nc
        JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY nc.code
    ),
    ranked AS (
        SELECT *, SUM(goods_revenue) OVER (ORDER BY goods_revenue DESC) AS cum_revenue,
            SUM(goods_revenue) OVER () AS total_revenue
        FROM new_revenue WHERE goods_revenue > 0
    )
    SELECT 
        (CASE 
            WHEN cum_revenue <= total_revenue * 0.80 OR (cum_revenue - goods_revenue) < total_revenue * 0.80 THEN 'A'
            WHEN cum_revenue <= total_revenue * 0.95 OR (cum_revenue - goods_revenue) < total_revenue * 0.95 THEN 'B'
            ELSE 'C'
        END)::TEXT AS abc_group,
        COUNT(*)::BIGINT AS count,
        COALESCE(SUM(goods_revenue), 0)::NUMERIC AS revenue,
        ROUND(COALESCE(SUM(goods_revenue), 0) * 100.0 / NULLIF(MAX(total_revenue), 0), 1)::NUMERIC AS pct
    FROM ranked
    GROUP BY abc_group
    ORDER BY abc_group;
END;
$function$;

-- 22. get_new_clients_abc_compare()
CREATE OR REPLACE FUNCTION public.get_new_clients_abc_compare(
    p_year INT DEFAULT 2026,
    p_multiplier NUMERIC DEFAULT 2.9
)
RETURNS TABLE(
    abc_group TEXT,
    new_count BIGINT,
    new_revenue NUMERIC,
    new_pct NUMERIC,
    all_count BIGINT,
    all_revenue NUMERIC,
    all_pct NUMERIC,
    count_share_pct NUMERIC,
    revenue_share_pct NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH new_clients AS (
        SELECT code FROM clients WHERE current_status_id = 1 AND is_active_current = TRUE AND code NOT IN ('9653', '11230')
    ),
    new_revenue AS (
        SELECT nc.code, COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
        FROM new_clients nc
        JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY nc.code
    ),
    ranked AS (
        SELECT *, SUM(goods_revenue) OVER (ORDER BY goods_revenue DESC) AS cum_revenue,
            SUM(goods_revenue) OVER () AS total_revenue
        FROM new_revenue WHERE goods_revenue > 0
    ),
    new_abc AS (
        SELECT 
            CASE 
                WHEN cum_revenue <= total_revenue * 0.80 OR (cum_revenue - goods_revenue) < total_revenue * 0.80 THEN 'A'
                WHEN cum_revenue <= total_revenue * 0.95 OR (cum_revenue - goods_revenue) < total_revenue * 0.95 THEN 'B'
                ELSE 'C'
            END AS grp,
            COUNT(*)::BIGINT AS count,
            COALESCE(SUM(goods_revenue), 0)::NUMERIC AS revenue,
            ROUND(COALESCE(SUM(goods_revenue), 0) * 100.0 / NULLIF(MAX(total_revenue), 0), 1)::NUMERIC AS pct
        FROM ranked
        GROUP BY grp
    ),
    all_abc AS (
        SELECT 
            LEFT(out_group_name, 1) AS grp,
            SUM(out_total_companies)::BIGINT AS all_count,
            SUM(out_total_sales)::NUMERIC AS all_revenue
        FROM get_abc_groups(p_year, p_multiplier)
        WHERE out_group_name != 'Total'
        GROUP BY LEFT(out_group_name, 1)
    ),
    total_all AS (
        SELECT COALESCE(SUM(a.all_revenue), 0) AS total_all_rev FROM all_abc a
    ),
    all_abc_pct AS (
        SELECT 
            a.grp,
            a.all_count,
            a.all_revenue,
            ROUND(a.all_revenue * 100.0 / NULLIF(t.total_all_rev, 0), 1)::NUMERIC AS all_pct
        FROM all_abc a, total_all t
    ),
    groups_list AS (
        SELECT 'A' AS grp UNION ALL SELECT 'B' UNION ALL SELECT 'C'
    )
    SELECT 
        gl.grp::TEXT AS abc_group,
        COALESCE(n.count, 0)::BIGINT AS new_count,
        COALESCE(n.revenue, 0)::NUMERIC AS new_revenue,
        COALESCE(n.pct, 0)::NUMERIC AS new_pct,
        COALESCE(a.all_count, 0)::BIGINT AS all_count,
        COALESCE(a.all_revenue, 0)::NUMERIC AS all_revenue,
        COALESCE(a.all_pct, 0)::NUMERIC AS all_pct,
        ROUND(COALESCE(n.count, 0) * 100.0 / NULLIF(a.all_count, 0), 1)::NUMERIC AS count_share_pct,
        ROUND(COALESCE(n.revenue, 0) * 100.0 / NULLIF(a.all_revenue, 0), 1)::NUMERIC AS revenue_share_pct
    FROM groups_list gl
    LEFT JOIN new_abc n ON n.grp = gl.grp
    LEFT JOIN all_abc_pct a ON a.grp = gl.grp
    ORDER BY gl.grp;
END;
$function$;

-- 23. get_new_clients_list()
CREATE OR REPLACE FUNCTION public.get_new_clients_list(
    p_year INT DEFAULT 2026,
    p_search TEXT DEFAULT NULL,
    p_abc_group TEXT DEFAULT NULL,
    p_limit INT DEFAULT 50,
    p_offset INT DEFAULT 0
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    docs BIGINT,
    revenue NUMERIC,
    first_date TEXT,
    last_date TEXT,
    abc_group TEXT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH new_clients AS (
        SELECT c.code FROM clients c WHERE c.current_status_id = 1 AND c.is_active_current = TRUE AND c.code NOT IN ('9653', '11230')
    ),
    client_rev AS (
        SELECT 
            c.code, c.name, COUNT(DISTINCT d.id)::BIGINT AS docs,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS revenue,
            MIN(d.invoice_date)::TEXT AS first_date, MAX(d.invoice_date)::TEXT AS last_date
        FROM new_clients nc
        JOIN clients c ON c.code = nc.code
        JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
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
            END)::TEXT AS abc_grp
        FROM ranked rk
    )
    SELECT cat.code, cat.name, cat.docs, cat.revenue, cat.first_date, cat.last_date, cat.abc_grp AS abc_group
    FROM categorized cat
    WHERE (p_abc_group IS NULL OR p_abc_group = '' OR cat.abc_grp = p_abc_group)
    ORDER BY cat.revenue DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$;

-- 24. get_client_products()
CREATE OR REPLACE FUNCTION public.get_client_products(
    p_code TEXT,
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    product_code VARCHAR,
    product_name VARCHAR,
    invoice_count BIGINT,
    total_sales NUMERIC,
    total_quantity NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.code AS product_code,
        p.name AS product_name,
        COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
        COALESCE(SUM(sl.amount), 0)::NUMERIC AS total_sales,
        COALESCE(SUM(sl.quantity), 0)::NUMERIC AS total_quantity
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    JOIN products p ON sl.product_code = p.code
    WHERE d.client_code = p_code
      AND EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND COALESCE(p.is_service, FALSE) = FALSE
    GROUP BY p.code, p.name
    ORDER BY total_sales DESC;
END;
$function$;

-- 25. get_client_products_compare()
CREATE OR REPLACE FUNCTION public.get_client_products_compare(
    p_code TEXT
)
RETURNS TABLE(
    product_code VARCHAR,
    product_name VARCHAR,
    revenue_curr NUMERIC,
    revenue_prev NUMERIC,
    qty_curr NUMERIC,
    qty_prev NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.code AS product_code,
        p.name AS product_name,
        COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = 2026 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS revenue_curr,
        COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = 2025 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS revenue_prev,
        COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = 2026 THEN sl.quantity ELSE 0 END), 0)::NUMERIC AS qty_curr,
        COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = 2025 THEN sl.quantity ELSE 0 END), 0)::NUMERIC AS qty_prev
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    JOIN products p ON sl.product_code = p.code
    WHERE d.client_code = p_code
      AND EXTRACT(YEAR FROM d.invoice_date) IN (2025, 2026)
      AND COALESCE(p.is_service, FALSE) = FALSE
    GROUP BY p.code, p.name
    ORDER BY revenue_curr DESC;
END;
$function$;

-- 26. get_client_products_recommendations()
CREATE OR REPLACE FUNCTION public.get_client_products_recommendations(
    p_code TEXT
)
RETURNS TABLE(
    product_code VARCHAR,
    product_name VARCHAR,
    reason TEXT,
    in_stock NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.code AS product_code,
        p.name AS product_name,
        'Рекомендуемый сопутствующий товар'::TEXT AS reason,
        COALESCE(p.in_stock_balance, 0)::NUMERIC AS in_stock
    FROM products p
    WHERE COALESCE(p.in_stock_balance, 0) > 0
      AND p.code NOT IN (
          SELECT sl2.product_code 
          FROM sales_lines sl2
          JOIN documents d2 ON sl2.document_id = d2.id
          WHERE d2.client_code = p_code
      )
    ORDER BY p.in_stock_balance DESC
    LIMIT 5;
END;
$function$;

-- 27. get_inactive_clients_overview()
CREATE OR REPLACE FUNCTION public.get_inactive_clients_overview(
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    sleeping_count BIGINT,
    churned_count BIGINT,
    total_all BIGINT,
    pct_inactive NUMERIC,
    sleeping_rev_2025 NUMERIC,
    churned_rev_2024 NUMERIC,
    high_risk_count BIGINT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH inactive AS (
        SELECT code, current_status_id FROM clients WHERE current_status_id IN (8, 9) AND code NOT IN ('9653', '11230')
    ),
    all_clients AS (
        SELECT COUNT(*)::BIGINT AS total_all FROM clients WHERE code NOT IN ('9653', '11230')
    ),
    sleeping_stats AS (
        SELECT 
            COUNT(DISTINCT ic.code)::BIGINT AS sleeping_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS sleeping_rev_2025,
            COUNT(DISTINCT CASE WHEN rev_sub.rev > 500000 THEN ic.code END)::BIGINT AS high_risk_count
        FROM inactive ic
        LEFT JOIN documents d ON d.client_code = ic.code AND EXTRACT(YEAR FROM d.invoice_date) = 2025
        LEFT JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        LEFT JOIN (
            SELECT d2.client_code, SUM(CASE WHEN pr2.is_service = FALSE THEN sl2.amount ELSE 0 END) AS rev
            FROM documents d2
            JOIN sales_lines sl2 ON sl2.document_id = d2.id
            LEFT JOIN products pr2 ON sl2.product_code = pr2.code
            WHERE EXTRACT(YEAR FROM d2.invoice_date) = 2025
            GROUP BY d2.client_code
        ) rev_sub ON rev_sub.client_code = ic.code
        WHERE ic.current_status_id = 8
    ),
    churned_stats AS (
        SELECT 
            COUNT(DISTINCT ic.code)::BIGINT AS churned_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS churned_rev_2024
        FROM inactive ic
        LEFT JOIN documents d ON d.client_code = ic.code AND EXTRACT(YEAR FROM d.invoice_date) = 2024
        LEFT JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE ic.current_status_id = 9
    )
    SELECT 
        s.sleeping_count,
        c.churned_count,
        a.total_all,
        ROUND((s.sleeping_count + c.churned_count) * 100.0 / NULLIF(a.total_all, 0), 1)::NUMERIC AS pct_inactive,
        s.sleeping_rev_2025,
        c.churned_rev_2024,
        s.high_risk_count
    FROM sleeping_stats s, churned_stats c, all_clients a;
END;
$function$;

-- 28. get_inactive_clients_list()
CREATE OR REPLACE FUNCTION public.get_inactive_clients_list(
    p_status_id INT DEFAULT 8,
    p_year_prev INT DEFAULT 2025,
    p_search TEXT DEFAULT NULL,
    p_abc_group TEXT DEFAULT NULL,
    p_days_min INT DEFAULT NULL,
    p_days_max INT DEFAULT NULL,
    p_limit INT DEFAULT 50,
    p_offset INT DEFAULT 0
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    docs_prev BIGINT,
    rev_prev NUMERIC,
    abc_group TEXT,
    last_date TEXT,
    days_since INT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH inactive_c AS (
        SELECT c.code, c.name FROM clients c WHERE c.current_status_id = p_status_id AND c.code NOT IN ('9653', '11230')
    ),
    client_sales AS (
        SELECT 
            ic.code,
            ic.name,
            COUNT(DISTINCT d.id)::BIGINT AS docs_prev,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS rev_prev,
            MAX(d.invoice_date) AS last_date
        FROM inactive_c ic
        LEFT JOIN documents d ON d.client_code = ic.code AND EXTRACT(YEAR FROM d.invoice_date) <= p_year_prev
        LEFT JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE (p_search IS NULL OR p_search = '' OR ic.name ILIKE '%' || p_search || '%' OR ic.code ILIKE '%' || p_search || '%')
        GROUP BY ic.code, ic.name
    ),
    ranked AS (
        SELECT cs.*,
            SUM(cs.rev_prev) OVER (ORDER BY cs.rev_prev DESC) AS cum_rev,
            SUM(cs.rev_prev) OVER () AS total_rev
        FROM client_sales cs
    ),
    categorized AS (
        SELECT rk.*,
            (CASE 
                WHEN rk.total_rev = 0 THEN 'C'
                WHEN rk.cum_rev <= rk.total_rev * 0.80 OR (rk.cum_rev - rk.rev_prev) < rk.total_rev * 0.80 THEN 'A'
                WHEN rk.cum_rev <= rk.total_rev * 0.95 OR (rk.cum_rev - rk.rev_prev) < rk.total_rev * 0.95 THEN 'B'
                ELSE 'C'
            END)::TEXT AS abc_grp,
            (CASE WHEN rk.last_date IS NOT NULL THEN CURRENT_DATE - rk.last_date ELSE 9999 END)::INT AS days_since
        FROM ranked rk
    )
    SELECT 
        cat.code, cat.name, cat.docs_prev, cat.rev_prev, cat.abc_grp AS abc_group, cat.last_date::text, cat.days_since
    FROM categorized cat
    WHERE (p_abc_group IS NULL OR p_abc_group = '' OR cat.abc_grp = p_abc_group)
      AND (p_days_min IS NULL OR cat.days_since >= p_days_min)
      AND (p_days_max IS NULL OR cat.days_since <= p_days_max)
    ORDER BY cat.rev_prev DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$;
