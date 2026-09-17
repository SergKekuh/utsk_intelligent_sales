-- ============================================================
-- Migration 27: Create Directions Analytics Functions
-- UTSK Intelligent Sales
-- ============================================================

-- 1. KPI Overview for Directions
CREATE OR REPLACE FUNCTION public.get_directions_kpi(p_year integer DEFAULT 2026)
RETURNS TABLE(
    total_revenue numeric,
    total_clients bigint,
    total_invoices bigint,
    avg_ticket numeric,
    top_direction_id integer,
    top_direction_name text,
    top_direction_revenue numeric,
    top_direction_share_pct numeric,
    active_directions_count bigint
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    WITH dir_sales AS (
        SELECT 
            ad.id AS dir_id,
            ad.name AS dir_name,
            COUNT(DISTINCT c.code) AS dir_clients,
            COUNT(DISTINCT d.id) AS dir_invoices,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS dir_revenue
        FROM activity_directions ad
        JOIN clients c ON c.activity_direction_id = ad.id
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY ad.id, ad.name
    ),
    totals AS (
        SELECT 
            COALESCE(SUM(dir_revenue), 0) AS tot_rev,
            COALESCE(SUM(dir_invoices), 0) AS tot_inv,
            (SELECT COUNT(DISTINCT d2.client_code) 
             FROM documents d2 
             WHERE EXTRACT(YEAR FROM d2.invoice_date) = p_year) AS tot_clients,
            COUNT(*) FILTER (WHERE dir_revenue > 0) AS active_dirs
        FROM dir_sales
    ),
    top_dir AS (
        SELECT dir_id, dir_name, dir_revenue
        FROM dir_sales
        ORDER BY dir_revenue DESC
        LIMIT 1
    )
    SELECT 
        ROUND(t.tot_rev, 2)::NUMERIC AS total_revenue,
        t.tot_clients::BIGINT AS total_clients,
        t.tot_inv::BIGINT AS total_invoices,
        ROUND(t.tot_rev / NULLIF(t.tot_inv, 0), 2)::NUMERIC AS avg_ticket,
        td.dir_id::INTEGER AS top_direction_id,
        td.dir_name::TEXT AS top_direction_name,
        ROUND(td.dir_revenue, 2)::NUMERIC AS top_direction_revenue,
        ROUND(td.dir_revenue * 100.0 / NULLIF(t.tot_rev, 0), 2)::NUMERIC AS top_direction_share_pct,
        t.active_dirs::BIGINT AS active_directions_count
    FROM totals t
    CROSS JOIN top_dir td;
END;
$$;


-- 2. Summary Table of Directions with Visual Metadata
DROP FUNCTION IF EXISTS public.get_directions_summary(integer);

CREATE OR REPLACE FUNCTION public.get_directions_summary(p_year integer DEFAULT 2026)
RETURNS TABLE(
    id integer,
    name character varying,
    icon character varying,
    color character varying,
    clients_count bigint,
    total_clients_in_base bigint,
    invoices_count bigint,
    goods_revenue numeric,
    avg_ticket numeric,
    revenue_share_pct numeric,
    clients_share_pct numeric
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    WITH overall AS (
        SELECT 
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS tot_rev,
            COUNT(DISTINCT d.client_code) AS tot_clients
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
    )
    SELECT 
        ad.id::INTEGER,
        ad.name::VARCHAR,
        COALESCE(ad.icon, '🌐')::VARCHAR AS icon,
        COALESCE(ad.color, '#64748b')::VARCHAR AS color,
        COUNT(DISTINCT CASE WHEN d.id IS NOT NULL THEN c.code END)::BIGINT AS clients_count,
        COUNT(DISTINCT c.code)::BIGINT AS total_clients_in_base,
        COUNT(DISTINCT d.id)::BIGINT AS invoices_count,
        ROUND(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0), 2)::NUMERIC AS goods_revenue,
        ROUND(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) / NULLIF(COUNT(DISTINCT d.id), 0), 2)::NUMERIC AS avg_ticket,
        ROUND(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) * 100.0 / NULLIF(MAX(ov.tot_rev), 0), 2)::NUMERIC AS revenue_share_pct,
        ROUND(COUNT(DISTINCT CASE WHEN d.id IS NOT NULL THEN c.code END) * 100.0 / NULLIF(MAX(ov.tot_clients), 0), 2)::NUMERIC AS clients_share_pct
    FROM activity_directions ad
    CROSS JOIN overall ov
    LEFT JOIN clients c ON c.activity_direction_id = ad.id
    LEFT JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    LEFT JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    GROUP BY ad.id, ad.name
    ORDER BY goods_revenue DESC, clients_count DESC;
END;
$$;


-- 3. Monthly Dynamics by Direction
CREATE OR REPLACE FUNCTION public.get_directions_monthly_dynamics(p_year integer DEFAULT 2026)
RETURNS TABLE(
    direction_id integer,
    direction_name character varying,
    month_num integer,
    month_name text,
    goods_revenue numeric,
    clients_count bigint
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ad.id::INTEGER AS direction_id,
        ad.name::VARCHAR AS direction_name,
        m.m_num::INTEGER AS month_num,
        CASE m.m_num
            WHEN 1 THEN 'Янв' WHEN 2 THEN 'Фев' WHEN 3 THEN 'Мар'
            WHEN 4 THEN 'Апр' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июн'
            WHEN 7 THEN 'Июл' WHEN 8 THEN 'Авг' WHEN 9 THEN 'Сен'
            WHEN 10 THEN 'Окт' WHEN 11 THEN 'Ноя' WHEN 12 THEN 'Дек'
        END::TEXT AS month_name,
        ROUND(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0), 2)::NUMERIC AS goods_revenue,
        COUNT(DISTINCT d.client_code)::BIGINT AS clients_count
    FROM generate_series(1, 12) AS m(m_num)
    CROSS JOIN activity_directions ad
    LEFT JOIN clients c ON c.activity_direction_id = ad.id
    LEFT JOIN documents d ON d.client_code = c.code 
        AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
        AND EXTRACT(MONTH FROM d.invoice_date) = m.m_num
    LEFT JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    GROUP BY ad.id, ad.name, m.m_num
    ORDER BY m.m_num, ad.id;
END;
$$;


-- 4. Clients / Companies for Selected Direction (Drill-down)
CREATE OR REPLACE FUNCTION public.get_direction_companies(
    p_direction_id integer,
    p_year integer DEFAULT 2026,
    p_limit integer DEFAULT 50,
    p_offset integer DEFAULT 0,
    p_search text DEFAULT NULL,
    p_abc_group text DEFAULT NULL
)
RETURNS TABLE(
    code character varying,
    name character varying,
    status_name character varying,
    goods_revenue numeric,
    invoices_count bigint,
    avg_ticket numeric,
    abc_group character varying,
    edrpou character varying,
    ipn character varying,
    last_purchase_date text,
    total_matching_count bigint
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    WITH client_rev AS (
        SELECT 
            c.code AS cl_code,
            c.name AS cl_name,
            c.edrpou AS cl_edrpou,
            c.ipn AS cl_ipn,
            sr.status_name AS cl_status,
            c.last_purchase_date AS cl_last_date,
            COUNT(DISTINCT d.id) AS inv_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS g_rev
        FROM clients c
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        LEFT JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        LEFT JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE (p_direction_id = 0 OR c.activity_direction_id = p_direction_id)
        GROUP BY c.code, c.name, c.edrpou, c.ipn, sr.status_name, c.last_purchase_date
    ),
    client_abc AS (
        SELECT 
            cr.cl_code,
            cr.cl_name,
            cr.cl_status,
            cr.g_rev,
            cr.inv_count,
            ROUND(cr.g_rev / NULLIF(cr.inv_count, 0), 2) AS a_ticket,
            CASE 
                WHEN cr.g_rev >= (SELECT limit_a1 FROM (
                    SELECT 50000000.0 * 2.9 AS limit_a1
                ) s) THEN 'A1'
                WHEN cr.g_rev >= 15000000.0 * 2.9 THEN 'A2'
                WHEN cr.g_rev >= 5000000.0 * 2.9 THEN 'B1'
                WHEN cr.g_rev >= 1500000.0 * 2.9 THEN 'B2'
                WHEN cr.g_rev >= 500000.0 * 2.9 THEN 'C1'
                ELSE 'C2'
            END AS abc_grp,
            cr.cl_edrpou,
            cr.cl_ipn,
            TO_CHAR(cr.cl_last_date, 'YYYY-MM-DD') AS last_date_str
        FROM client_rev cr
        WHERE cr.g_rev > 0 OR cr.inv_count > 0
    ),
    filtered AS (
        SELECT ca.*
        FROM client_abc ca
        WHERE (p_search IS NULL OR p_search = '' 
               OR ca.cl_code ILIKE '%' || p_search || '%'
               OR ca.cl_name ILIKE '%' || p_search || '%'
               OR ca.cl_edrpou ILIKE '%' || p_search || '%')
          AND (p_abc_group IS NULL OR p_abc_group = '' OR p_abc_group = 'ALL' OR ca.abc_grp = p_abc_group)
    ),
    cnt AS (
        SELECT COUNT(*) AS total_cnt FROM filtered
    )
    SELECT 
        f.cl_code::VARCHAR AS code,
        f.cl_name::VARCHAR AS name,
        COALESCE(f.cl_status, 'Активный')::VARCHAR AS status_name,
        ROUND(f.g_rev, 2)::NUMERIC AS goods_revenue,
        f.inv_count::BIGINT AS invoices_count,
        COALESCE(f.a_ticket, 0)::NUMERIC AS avg_ticket,
        f.abc_grp::VARCHAR AS abc_group,
        COALESCE(f.cl_edrpou, '—')::VARCHAR AS edrpou,
        COALESCE(f.cl_ipn, '—')::VARCHAR AS ipn,
        COALESCE(f.last_date_str, '—')::TEXT AS last_purchase_date,
        cnt.total_cnt::BIGINT AS total_matching_count
    FROM filtered f
    CROSS JOIN cnt
    ORDER BY f.g_rev DESC
    LIMIT p_limit OFFSET p_offset;
END;
$$;
