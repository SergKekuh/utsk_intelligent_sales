-- =============================================================================
-- MIGRATION PART 2: Additional Stored functions for UTSK Intelligent Sales API
-- Date: 2026-08-11
-- Description: Replaces raw SQL queries in app.py Part 2 endpoints with PostgreSQL functions
-- =============================================================================

-- 1a. get_rfm_funnel()
CREATE OR REPLACE FUNCTION public.get_rfm_funnel(
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    rfm_group TEXT,
    companies BIGINT,
    invoices BIGINT,
    sales NUMERIC,
    avg_check NUMERIC
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
    rfm_groups AS (
        SELECT 
            CASE 
                WHEN invoice_count = 1 THEN 'one'
                WHEN invoice_count BETWEEN 2 AND 3 THEN 'repeat'
                WHEN invoice_count BETWEEN 4 AND 10 THEN 'quarter'
                WHEN invoice_count BETWEEN 11 AND 40 THEN 'month'
                WHEN invoice_count BETWEEN 41 AND 170 THEN 'week'
                ELSE 'day'
            END AS rfm_group,
            COUNT(*)::BIGINT AS companies,
            SUM(invoice_count)::BIGINT AS invoices,
            ROUND(SUM(total_revenue)::numeric, 2) AS sales,
            ROUND(AVG(total_revenue / NULLIF(invoice_count, 0))::numeric, 2) AS avg_check
        FROM client_invoices
        GROUP BY rfm_group
    )
    SELECT r.rfm_group::TEXT, r.companies, r.invoices, r.sales, r.avg_check 
    FROM rfm_groups r;
END;
$function$;

-- 1b. get_alt_funnel()
CREATE OR REPLACE FUNCTION public.get_alt_funnel(
    p_year INT DEFAULT 2026,
    p_multiplier NUMERIC DEFAULT 2.9,
    p_limit_price NUMERIC DEFAULT 146000
)
RETURNS TABLE(
    group_key TEXT,
    companies BIGINT,
    sales NUMERIC,
    avg_check NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH client_sales AS (
        SELECT 
            c.code,
            COUNT(DISTINCT d.id) AS invoice_count,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
        GROUP BY c.code
    ),
    categorized AS (
        SELECT 
            CASE 
                WHEN invoice_count >= 4 THEN 'regular'
                WHEN goods_revenue >= p_limit_price AND invoice_count = 1 THEN 'one_time_main'
                WHEN goods_revenue >= p_limit_price AND invoice_count BETWEEN 2 AND 3 THEN 'repeat_main'
                ELSE 'random'
            END AS grp,
            goods_revenue
        FROM client_sales
    )
    SELECT 
        c.grp::TEXT AS group_key,
        COUNT(*)::BIGINT AS companies,
        ROUND(SUM(c.goods_revenue)::numeric, 2) AS sales,
        ROUND((SUM(c.goods_revenue) / NULLIF(COUNT(*), 0) / 1000.0)::numeric, 2) AS avg_check
    FROM categorized c
    GROUP BY c.grp;
END;
$function$;

-- 2. get_abc_structure_data()
DROP FUNCTION IF EXISTS public.get_abc_structure_data(integer,numeric,numeric);
CREATE OR REPLACE FUNCTION public.get_abc_structure_data(
    p_year INT DEFAULT 2026,
    p_multiplier NUMERIC DEFAULT 2.9,
    p_limit_price NUMERIC DEFAULT 146000
)
RETURNS TABLE(
    out_direction TEXT,
    out_group_name VARCHAR,
    out_metric VARCHAR,
    out_1 NUMERIC,
    out_2_3 NUMERIC,
    out_4_10 NUMERIC,
    out_11_40 NUMERIC,
    out_41_170 NUMERIC,
    out_171_plus NUMERIC,
    out_total NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 'below'::TEXT AS out_direction, r.out_group_name, r.out_metric, r.out_1, r.out_2_3, r.out_4_10, r.out_11_40, r.out_41_170, r.out_171_plus, r.out_total 
    FROM generate_custom_sales_report(p_year, p_multiplier, p_limit_price, 'below') r
    UNION ALL
    SELECT 'above'::TEXT AS out_direction, r.out_group_name, r.out_metric, r.out_1, r.out_2_3, r.out_4_10, r.out_11_40, r.out_41_170, r.out_171_plus, r.out_total 
    FROM generate_custom_sales_report(p_year, p_multiplier, p_limit_price, 'above') r;
END;
$function$;

-- 3. get_c2_detail()
CREATE OR REPLACE FUNCTION public.get_c2_detail(
    p_year INT DEFAULT 2026,
    p_multiplier NUMERIC DEFAULT 2.9,
    p_limit_price NUMERIC DEFAULT 146000
)
RETURNS TABLE(
    client_code VARCHAR,
    invoices_count BIGINT,
    goods_revenue NUMERIC,
    freq_group TEXT,
    internal_class TEXT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
        SELECT DISTINCT cya.client_code
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year
          AND cya.is_active = TRUE
          AND cya.client_code != '9653'
    ),
    client_stats AS (
        SELECT 
            d.client_code,
            COUNT(DISTINCT d.id)::BIGINT AS invoices_count,
            COUNT(DISTINCT d.invoice_date)::BIGINT AS distinct_dates,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN active_clients ac ON d.client_code = ac.client_code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY d.client_code
    ),
    c2_clients AS (
        SELECT 
            cs.client_code,
            cs.invoices_count,
            cs.distinct_dates,
            cs.goods_revenue,
            (CASE
                WHEN cs.invoices_count = 1 THEN '1'
                WHEN cs.invoices_count = 2 AND cs.distinct_dates = 1 THEN '2_1d'
                WHEN cs.invoices_count = 2 AND cs.distinct_dates = 2 THEN '2_diff'
                WHEN cs.invoices_count = 3 THEN '3'
                WHEN cs.invoices_count BETWEEN 4 AND 10 THEN '4_10'
                WHEN cs.invoices_count BETWEEN 11 AND 40 THEN '11_40'
                ELSE '41_plus'
            END)::TEXT AS freq_group
        FROM client_stats cs
        WHERE cs.goods_revenue < p_limit_price
    ),
    c2_with_cum AS (
        SELECT 
            c2.*,
            SUM(c2.goods_revenue) OVER (ORDER BY c2.goods_revenue DESC, c2.client_code) AS cum_revenue,
            SUM(c2.goods_revenue) OVER () AS total_c2_revenue
        FROM c2_clients c2
    )
    SELECT 
        cw.client_code,
        cw.invoices_count,
        cw.goods_revenue,
        cw.freq_group,
        (CASE
            WHEN cw.total_c2_revenue IS NULL OR cw.total_c2_revenue = 0 THEN 'C'
            WHEN cw.cum_revenue <= cw.total_c2_revenue * 0.80 OR (cw.cum_revenue - cw.goods_revenue) < cw.total_c2_revenue * 0.80 THEN 'A'
            WHEN cw.cum_revenue <= cw.total_c2_revenue * 0.95 OR (cw.cum_revenue - cw.goods_revenue) < cw.total_c2_revenue * 0.95 THEN 'B'
            ELSE 'C'
        END)::TEXT AS internal_class
    FROM c2_with_cum cw;
END;
$function$;

-- 4. get_segment_detail()
CREATE OR REPLACE FUNCTION public.get_segment_detail(
    p_segment TEXT DEFAULT 'abc',
    p_year INT DEFAULT 2026,
    p_multiplier NUMERIC DEFAULT 2.9,
    p_limit_price NUMERIC DEFAULT 146000
)
RETURNS TABLE(
    client_code VARCHAR,
    invoices_count BIGINT,
    goods_revenue NUMERIC,
    freq_group TEXT,
    internal_class TEXT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
        SELECT DISTINCT cya.client_code
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year
          AND cya.is_active = TRUE
          AND cya.client_code != '9653'
    ),
    client_stats AS (
        SELECT 
            d.client_code,
            COUNT(DISTINCT d.id)::BIGINT AS invoices_count,
            COUNT(DISTINCT d.invoice_date)::BIGINT AS distinct_dates,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN active_clients ac ON d.client_code = ac.client_code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY d.client_code
    ),
    filtered_clients AS (
        SELECT 
            cs.client_code,
            cs.invoices_count,
            cs.distinct_dates,
            cs.goods_revenue,
            (CASE
                WHEN cs.invoices_count = 1 THEN '1'
                WHEN cs.invoices_count = 2 AND cs.distinct_dates = 1 THEN '2_1d'
                WHEN cs.invoices_count = 2 AND cs.distinct_dates = 2 THEN '2_diff'
                WHEN cs.invoices_count = 3 THEN '3'
                WHEN cs.invoices_count BETWEEN 4 AND 10 THEN '4_10'
                WHEN cs.invoices_count BETWEEN 11 AND 40 THEN '11_40'
                WHEN cs.invoices_count BETWEEN 41 AND 170 THEN '41_170'
                ELSE '171_plus'
            END)::TEXT AS freq_group
        FROM client_stats cs
        WHERE 
            (LOWER(p_segment) = 'c2' AND cs.goods_revenue < p_limit_price)
            OR
            (LOWER(p_segment) = 'abc' AND cs.goods_revenue >= p_limit_price)
            OR
            (LOWER(p_segment) = 'total')
            OR
            (LOWER(p_segment) = 'important' AND (cs.goods_revenue >= p_limit_price OR cs.invoices_count >= 4))
    ),
    clients_with_cum AS (
        SELECT 
            fc.*,
            SUM(fc.goods_revenue) OVER (ORDER BY fc.goods_revenue DESC, fc.client_code) AS cum_revenue,
            SUM(fc.goods_revenue) OVER () AS total_segment_revenue
        FROM filtered_clients fc
    )
    SELECT 
        cw.client_code,
        cw.invoices_count,
        cw.goods_revenue,
        cw.freq_group,
        (CASE
            WHEN cw.total_segment_revenue IS NULL OR cw.total_segment_revenue = 0 THEN 'C'
            WHEN cw.cum_revenue <= cw.total_segment_revenue * 0.80 OR (cw.cum_revenue - cw.goods_revenue) < cw.total_segment_revenue * 0.80 THEN 'A'
            WHEN cw.cum_revenue <= cw.total_segment_revenue * 0.95 OR (cw.cum_revenue - cw.goods_revenue) < cw.total_segment_revenue * 0.95 THEN 'B'
            ELSE 'C'
        END)::TEXT AS internal_class
    FROM clients_with_cum cw;
END;
$function$;

-- 5. get_abc_groups_detail()
CREATE OR REPLACE FUNCTION public.get_abc_groups_detail(
    p_year INT DEFAULT 2026,
    p_multiplier NUMERIC DEFAULT 2.9,
    p_limit_price NUMERIC DEFAULT 146000
)
RETURNS TABLE(
    abc_group TEXT,
    companies BIGINT,
    invoices BIGINT,
    sales NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
        SELECT DISTINCT cya.client_code
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year
          AND cya.is_active = TRUE
          AND cya.client_code != '9653'
    ),
    stats AS (
        SELECT 
            d.client_code,
            COUNT(DISTINCT d.id)::BIGINT AS invoices_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN active_clients ac ON d.client_code = ac.client_code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY d.client_code
    ),
    categorized AS (
        SELECT 
            s.*,
            (CASE
                WHEN s.goods_revenue >= 3000000 * p_multiplier THEN 'A1'
                WHEN s.goods_revenue >= 2000000 * p_multiplier THEN 'A2'
                WHEN s.goods_revenue >= 1500000 * p_multiplier THEN 'A3'
                WHEN s.goods_revenue >= 1000000 * p_multiplier THEN 'B1'
                WHEN s.goods_revenue >= 500000  * p_multiplier THEN 'B2'
                WHEN s.goods_revenue >= 150000  * p_multiplier THEN 'C1'
                ELSE 'C2_above'
            END)::TEXT AS grp
        FROM stats s
        WHERE s.goods_revenue >= p_limit_price
    )
    SELECT 
        c.grp AS abc_group,
        COUNT(*)::BIGINT AS companies,
        SUM(c.invoices_count)::BIGINT AS invoices,
        SUM(c.goods_revenue)::NUMERIC AS sales
    FROM categorized c
    GROUP BY c.grp
    ORDER BY c.grp;
END;
$function$;

-- 6. get_important_detail()
CREATE OR REPLACE FUNCTION public.get_important_detail(
    p_year INT DEFAULT 2026,
    p_multiplier NUMERIC DEFAULT 2.9,
    p_limit_price NUMERIC DEFAULT 146000
)
RETURNS TABLE(
    client_code VARCHAR,
    client_name VARCHAR,
    invoices_count BIGINT,
    goods_revenue NUMERIC,
    category TEXT,
    grand_total NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
        SELECT DISTINCT cya.client_code
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year
          AND cya.is_active = TRUE
          AND cya.client_code != '9653'
    ),
    stats AS (
        SELECT 
            d.client_code,
            c.name AS client_name,
            COUNT(DISTINCT d.id)::BIGINT AS invoices_count,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN active_clients ac ON d.client_code = ac.client_code
        JOIN clients c ON d.client_code = c.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY d.client_code, c.name
    ),
    all_sales AS (
        SELECT COALESCE(SUM(s.goods_revenue), 1)::NUMERIC AS grand_total FROM stats s
    )
    SELECT 
        s.client_code,
        s.client_name,
        s.invoices_count,
        s.goods_revenue,
        (CASE 
            WHEN s.goods_revenue >= p_limit_price THEN 'ABC' 
            ELSE 'C2 (4+ накладных)' 
        END)::TEXT AS category,
        a.grand_total
    FROM stats s, all_sales a
    WHERE s.goods_revenue >= p_limit_price OR s.invoices_count >= 4
    ORDER BY s.goods_revenue DESC;
END;
$function$;

-- 7. get_top_clients_monthly()
CREATE OR REPLACE FUNCTION public.get_top_clients_monthly(
    p_year INT DEFAULT 2026,
    p_month INT DEFAULT 7,
    p_limit INT DEFAULT 50,
    p_exclude_client TEXT DEFAULT '9653'
)
RETURNS TABLE(
    client_code VARCHAR,
    client_name VARCHAR,
    invoice_count BIGINT,
    goods_revenue NUMERIC,
    status_2025 TEXT,
    status_2026 TEXT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH month_revenue AS (
        SELECT 
            d.client_code,
            COUNT(DISTINCT d.id)::BIGINT as invoice_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND EXTRACT(MONTH FROM d.invoice_date) = p_month
          AND (p_exclude_client IS NULL OR d.client_code != p_exclude_client)
        GROUP BY d.client_code
    ),
    status_2025 AS (
        SELECT 
            cya.client_code,
            sr.status_name as status_name
        FROM client_year_activity cya
        LEFT JOIN status_rules sr ON sr.id = cya.abc_group::integer
        WHERE cya.sales_year = p_year - 1
          AND cya.is_active = TRUE
    ),
    status_2026 AS (
        SELECT 
            c.code as client_code,
            sr.status_name as status_name
        FROM clients c
        LEFT JOIN status_rules sr ON sr.id = c.current_status_id
        WHERE c.is_active_current = TRUE
    )
    SELECT 
        mr.client_code,
        c.name as client_name,
        mr.invoice_count,
        mr.goods_revenue,
        COALESCE(s25.status_name, '—')::TEXT as status_2025,
        COALESCE(s26.status_name, '—')::TEXT as status_2026
    FROM month_revenue mr
    JOIN clients c ON c.code = mr.client_code
    LEFT JOIN status_2025 s25 ON s25.client_code = mr.client_code
    LEFT JOIN status_2026 s26 ON s26.client_code = mr.client_code
    WHERE mr.goods_revenue > 0
    ORDER BY mr.goods_revenue DESC
    LIMIT p_limit;
END;
$function$;

-- 15. get_inactive_clients_distribution()
CREATE OR REPLACE FUNCTION public.get_inactive_clients_distribution(
    p_status_id INT DEFAULT 8
)
RETURNS TABLE(
    range_label TEXT,
    count BIGINT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    IF p_status_id = 8 THEN
        RETURN QUERY
        WITH client_dates AS (
            SELECT 
                c.code,
                MAX(d.invoice_date) AS last_date
            FROM clients c
            LEFT JOIN documents d ON d.client_code = c.code
            WHERE c.current_status_id = 8 AND c.code NOT IN ('9653', '11230')
            GROUP BY c.code
        ),
        days_calc AS (
            SELECT 
                cd.code,
                CASE WHEN cd.last_date IS NOT NULL THEN CURRENT_DATE - cd.last_date ELSE 9999 END AS days_since
            FROM client_dates cd
        ),
        grouped AS (
            SELECT 
                (CASE 
                    WHEN dc.days_since < 90 THEN '< 90 дней'
                    WHEN dc.days_since BETWEEN 90 AND 180 THEN '90-180 дней'
                    WHEN dc.days_since BETWEEN 181 AND 365 THEN '181-365 дней'
                    ELSE '> 365 дней'
                END)::TEXT AS range_label,
                CASE 
                    WHEN dc.days_since < 90 THEN 1
                    WHEN dc.days_since BETWEEN 90 AND 180 THEN 2
                    WHEN dc.days_since BETWEEN 181 AND 365 THEN 3
                    ELSE 4
                END AS sort_order,
                COUNT(*)::BIGINT AS count
            FROM days_calc dc
            GROUP BY range_label, sort_order
        )
        SELECT g.range_label, g.count
        FROM grouped g
        ORDER BY g.sort_order;
    ELSE
        RETURN QUERY
        WITH client_years AS (
            SELECT 
                c.code,
                EXTRACT(YEAR FROM MAX(d.invoice_date)) AS last_yr
            FROM clients c
            LEFT JOIN documents d ON d.client_code = c.code
            WHERE c.current_status_id = 9 AND c.code NOT IN ('9653', '11230')
            GROUP BY c.code
        )
        SELECT 
            COALESCE(cy.last_yr::text, 'Нет данных')::TEXT AS range_label,
            COUNT(*)::BIGINT AS count
        FROM client_years cy
        GROUP BY range_label
        ORDER BY range_label DESC;
    END IF;
END;
$function$;

-- 16. get_inactive_clients_abc()
CREATE OR REPLACE FUNCTION public.get_inactive_clients_abc(
    p_status_id INT DEFAULT 8,
    p_year_prev INT DEFAULT 2025
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
    WITH inactive AS (
        SELECT c.code FROM clients c WHERE c.current_status_id = p_status_id AND c.code NOT IN ('9653', '11230')
    ),
    client_rev AS (
        SELECT 
            ic.code,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS rev
        FROM inactive ic
        JOIN documents d ON d.client_code = ic.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year_prev
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY ic.code
    ),
    ranked AS (
        SELECT cr.*,
            SUM(cr.rev) OVER (ORDER BY cr.rev DESC) AS cum_rev,
            SUM(cr.rev) OVER () AS total_rev
        FROM client_rev cr WHERE cr.rev > 0
    )
    SELECT 
        (CASE 
            WHEN rk.cum_rev <= rk.total_rev * 0.80 OR (rk.cum_rev - rk.rev) < rk.total_rev * 0.80 THEN 'A'
            WHEN rk.cum_rev <= rk.total_rev * 0.95 OR (rk.cum_rev - rk.rev) < rk.total_rev * 0.95 THEN 'B'
            ELSE 'C'
        END)::TEXT AS abc_group,
        COUNT(*)::BIGINT AS count,
        COALESCE(SUM(rk.rev), 0)::NUMERIC AS revenue,
        ROUND(COALESCE(SUM(rk.rev), 0) * 100.0 / NULLIF(MAX(rk.total_rev), 0), 1)::NUMERIC AS pct
    FROM ranked rk
    GROUP BY abc_group
    ORDER BY abc_group;
END;
$function$;
