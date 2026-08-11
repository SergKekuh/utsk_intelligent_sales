-- ============================================================================
-- UTSK Intelligent Sales — Миграция 03: Оставшиеся 15 функций PostgreSQL
-- ============================================================================

-- 1. get_client_status_2025()
CREATE OR REPLACE FUNCTION public.get_client_status_2025(
    p_code TEXT,
    p_year_prev INT DEFAULT 2025
)
RETURNS TABLE(status_2025 TEXT)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT CASE 
        WHEN cya.total_docs = 0 THEN 'Спящие'
        WHEN cya.total_docs = 1 THEN 'Разовые'
        WHEN cya.total_docs BETWEEN 2 AND 3 THEN 'Повторные'
        WHEN cya.total_docs BETWEEN 4 AND 10 THEN 'Ежеквартальные'
        WHEN cya.total_docs BETWEEN 11 AND 40 THEN 'Ежемесячные'
        WHEN cya.total_docs BETWEEN 41 AND 170 THEN 'Еженедельные'
        WHEN cya.total_docs > 170 THEN 'Ежедневные'
        ELSE '—'
    END::TEXT AS status_2025
    FROM client_year_activity cya
    WHERE cya.client_code = p_code AND cya.sales_year = p_year_prev;
END;
$function$;


-- 2. get_client_monthly_dynamics()
CREATE OR REPLACE FUNCTION public.get_client_monthly_dynamics(
    p_code TEXT,
    p_year INT DEFAULT 2026,
    p_year_prev INT DEFAULT 2025
)
RETURNS TABLE(
    month INT,
    revenue_current NUMERIC,
    revenue_previous NUMERIC,
    invoices_current BIGINT,
    invoices_previous BIGINT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        EXTRACT(MONTH FROM d.invoice_date)::INTEGER AS month,
        ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year THEN sl.amount ELSE 0 END)::NUMERIC, 0) AS revenue_current,
        ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year_prev THEN sl.amount ELSE 0 END)::NUMERIC, 0) AS revenue_previous,
        COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year THEN d.id END)::BIGINT AS invoices_current,
        COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year_prev THEN d.id END)::BIGINT AS invoices_previous
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.client_code = p_code
      AND EXTRACT(YEAR FROM d.invoice_date) IN (p_year, p_year_prev)
      AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
    GROUP BY EXTRACT(MONTH FROM d.invoice_date)
    ORDER BY month;
END;
$function$;


-- 3. get_recommendations_block2()
CREATE OR REPLACE FUNCTION public.get_recommendations_block2(
    p_direction_id INT,
    p_client_code TEXT
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    reason TEXT,
    priority INT,
    in_stock NUMERIC,
    purchase_count INT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p.code, p.name, 'Новинка в вашем сегменте'::TEXT AS reason, 2 AS priority,
           COALESCE(p.in_stock_balance, 0)::NUMERIC AS in_stock, 0::INT AS purchase_count
    FROM products p
    WHERE p.anchor_direction_id = p_direction_id
      AND p.is_new_arrival = TRUE
      AND COALESCE(p.in_stock_balance, 0) > 0
      AND p.code NOT IN (
          SELECT sl2.product_code FROM sales_lines sl2
          JOIN documents d2 ON sl2.document_id = d2.id
          WHERE d2.client_code = p_client_code
      )
    ORDER BY p.in_stock_balance DESC
    LIMIT 5;
END;
$function$;


-- 4. get_recommendations_block3()
CREATE OR REPLACE FUNCTION public.get_recommendations_block3(
    p_client_code TEXT
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    reason TEXT,
    priority INT,
    in_stock NUMERIC,
    purchase_count INT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p_related.code, p_related.name, 'С этим обычно берут'::TEXT AS reason, 3 AS priority,
           COALESCE(p_related.in_stock_balance, 0)::NUMERIC AS in_stock, 0::INT AS purchase_count
    FROM clients c
    JOIN documents d ON d.client_code = c.code
    JOIN sales_lines sl ON sl.document_id = d.id
    JOIN product_cross_sells pcs ON sl.product_code = pcs.main_product_code
    JOIN products p_related ON pcs.related_product_code = p_related.code
    WHERE c.code = p_client_code
      AND COALESCE(p_related.in_stock_balance, 0) > 0
      AND p_related.code NOT IN (
          SELECT sl2.product_code FROM sales_lines sl2
          JOIN documents d2 ON sl2.document_id = d2.id
          WHERE d2.client_code = p_client_code
      )
    GROUP BY p_related.code, p_related.name, p_related.in_stock_balance
    LIMIT 5;
END;
$function$;


-- 5. get_recommendations_block4()
CREATE OR REPLACE FUNCTION public.get_recommendations_block4(
    p_client_code TEXT
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    reason TEXT,
    priority INT,
    in_stock NUMERIC,
    purchase_count INT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p.code, p.name, 'Вы недавно интересовались'::TEXT AS reason, 4 AS priority,
           COALESCE(p.in_stock_balance, 0)::NUMERIC AS in_stock, 0::INT AS purchase_count
    FROM website_behavior_log wbl
    JOIN products p ON wbl.product_code = p.code
    WHERE wbl.client_code = p_client_code
      AND wbl.timestamp >= CURRENT_TIMESTAMP - INTERVAL '7 days'
      AND COALESCE(p.in_stock_balance, 0) > 0
      AND p.code NOT IN (
          SELECT sl2.product_code FROM sales_lines sl2
          JOIN documents d2 ON sl2.document_id = d2.id
          WHERE d2.client_code = p_client_code
      )
    GROUP BY p.code, p.name, p.in_stock_balance
    ORDER BY MAX(wbl.timestamp) DESC
    LIMIT 5;
END;
$function$;


-- 6. get_recommendations_fallback()
CREATE OR REPLACE FUNCTION public.get_recommendations_fallback()
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    reason TEXT,
    priority INT,
    in_stock NUMERIC,
    purchase_count INT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p.code, p.name, 'Популярный товар'::TEXT AS reason, 99::INT AS priority,
           COALESCE(p.in_stock_balance, 0)::NUMERIC AS in_stock, 0::INT AS purchase_count
    FROM products p
    WHERE COALESCE(p.in_stock_balance, 0) > 0
    ORDER BY p.code
    LIMIT 5;
END;
$function$;


-- 7. get_top_recommendations()
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
    SELECT p.code, p.name, COUNT(sl.id)::BIGINT AS total_sales,
           COALESCE(p.in_stock_balance, 0)::NUMERIC AS in_stock_balance
    FROM products p
    JOIN sales_lines sl ON sl.product_code = p.code
    WHERE COALESCE(p.in_stock_balance, 0) > 0
    GROUP BY p.code, p.name, p.in_stock_balance
    ORDER BY total_sales DESC
    LIMIT p_limit;
END;
$function$;


-- 8. get_daily_revenue()
CREATE OR REPLACE FUNCTION public.get_daily_revenue(
    p_year INT,
    p_month INT
)
RETURNS TABLE(
    day INT,
    active_clients BIGINT,
    invoice_count BIGINT,
    goods_revenue NUMERIC,
    total_revenue NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        EXTRACT(DAY FROM d.invoice_date)::INTEGER AS day,
        COUNT(DISTINCT d.client_code)::BIGINT AS active_clients,
        COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
        COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue,
        COALESCE(SUM(sl.amount), 0)::NUMERIC AS total_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month
    GROUP BY day
    ORDER BY day;
END;
$function$;


-- 9. get_monthly_detail_metrics()
CREATE OR REPLACE FUNCTION public.get_monthly_detail_metrics(
    p_year INT,
    p_month INT
)
RETURNS TABLE(
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
        COUNT(DISTINCT d.client_code)::BIGINT AS active_clients,
        COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
        COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue,
        COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = TRUE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS services_revenue,
        COALESCE(SUM(sl.amount), 0)::NUMERIC AS total_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month;
END;
$function$;


-- 10. get_monthly_directions()
CREATE OR REPLACE FUNCTION public.get_monthly_directions(
    p_year INT,
    p_month INT
)
RETURNS TABLE(
    direction_name TEXT,
    companies_count BIGINT,
    invoice_count BIGINT,
    goods_revenue NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(ad.name, 'Не указано')::TEXT AS direction_name,
        COUNT(DISTINCT d.client_code)::BIGINT AS companies_count,
        COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
        COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE
    LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month
    GROUP BY ad.name
    ORDER BY goods_revenue DESC
    LIMIT 10;
END;
$function$;


-- 11. get_monthly_products()
CREATE OR REPLACE FUNCTION public.get_monthly_products(
    p_year INT,
    p_month INT,
    p_limit INT DEFAULT 10
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
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month
      AND COALESCE(p.is_service, FALSE) = FALSE
    GROUP BY p.code, p.name
    ORDER BY total_sales DESC
    LIMIT p_limit;
END;
$function$;


-- 12. get_monthly_top_clients()
CREATE OR REPLACE FUNCTION public.get_monthly_top_clients(
    p_year INT,
    p_month INT,
    p_year_prev INT DEFAULT 2025,
    p_mult NUMERIC DEFAULT 2.9,
    p_limit INT DEFAULT 10
)
RETURNS TABLE(
    client_name VARCHAR,
    group_prev TEXT,
    invoice_count BIGINT,
    goods_revenue NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH month_data AS (
        SELECT 
            d.client_code,
            COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND EXTRACT(MONTH FROM d.invoice_date) = p_month
        GROUP BY d.client_code
    ),
    abc_prev AS (
        SELECT 
            d.client_code,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue_prev
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year_prev
        GROUP BY d.client_code
    ),
    abc_grouped AS (
        SELECT 
            ap.client_code,
            CASE
                WHEN ap.goods_revenue_prev >= 3000000 * p_mult THEN 'A1'
                WHEN ap.goods_revenue_prev >= 2000000 * p_mult THEN 'A2'
                WHEN ap.goods_revenue_prev >= 1500000 * p_mult THEN 'A3'
                WHEN ap.goods_revenue_prev >= 1000000 * p_mult THEN 'B1'
                WHEN ap.goods_revenue_prev >= 500000  * p_mult THEN 'B2'
                WHEN ap.goods_revenue_prev >= 150000  * p_mult THEN 'C1'
                WHEN ap.goods_revenue_prev >= 1000    * p_mult THEN 'C2'
                ELSE 'Новый'
            END::TEXT AS abc_group_prev
        FROM abc_prev ap
    )
    SELECT 
        c.name AS client_name,
        COALESCE(ag.abc_group_prev, 'Новый')::TEXT AS group_prev,
        md.invoice_count,
        md.goods_revenue
    FROM month_data md
    JOIN clients c ON c.code = md.client_code
    LEFT JOIN abc_grouped ag ON ag.client_code = md.client_code
    WHERE c.is_active_current = TRUE
    ORDER BY md.goods_revenue DESC
    LIMIT p_limit;
END;
$function$;


-- 13. get_yearly_clients_count()
CREATE OR REPLACE FUNCTION public.get_yearly_clients_count(
    p_year INT DEFAULT 2026
)
RETURNS BIGINT
LANGUAGE plpgsql STABLE
AS $function$
DECLARE
    cnt BIGINT;
BEGIN
    SELECT COUNT(*)::BIGINT INTO cnt
    FROM client_year_activity 
    WHERE sales_year = p_year AND is_active = TRUE;
    
    RETURN cnt;
END;
$function$;


-- 14. get_excluded_client_info()
CREATE OR REPLACE FUNCTION public.get_excluded_client_info(
    p_year INT,
    p_month INT,
    p_exclude_client TEXT
)
RETURNS TABLE(
    client_code VARCHAR,
    client_name VARCHAR,
    invoice_count BIGINT,
    goods_revenue NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        d.client_code,
        c.name AS client_name,
        COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
        COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    JOIN clients c ON c.code = d.client_code
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month
      AND d.client_code = p_exclude_client
    GROUP BY d.client_code, c.name;
END;
$function$;
