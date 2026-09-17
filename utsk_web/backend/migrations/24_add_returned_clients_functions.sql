-- ====================================================================
-- Миграция 24: Функции для аналитики Вернувшихся клиентов (статус ID=10)
-- ====================================================================

-- 1. Частотный анализ вернувшихся клиентов
CREATE OR REPLACE FUNCTION public.get_returned_clients_frequency(p_year INT DEFAULT 2026)
RETURNS TABLE(
    frequency_group TEXT,
    sort_order INT,
    returned_count BIGINT,
    returned_revenue NUMERIC,
    avg_ticket NUMERIC,
    returned_pct NUMERIC
)
LANGUAGE plpgsql STABLE AS $$
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
            WHEN invoice_count = 1 THEN 'Разовые (1)'
            WHEN invoice_count BETWEEN 2 AND 3 THEN 'Повторные (2-3)'
            WHEN invoice_count BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
            WHEN invoice_count BETWEEN 11 AND 40 THEN 'Месяц (11-40)'
            WHEN invoice_count BETWEEN 41 AND 170 THEN 'Неделя (41-170)'
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
$$;

-- 2. Обзор KPI вернувшихся клиентов
CREATE OR REPLACE FUNCTION public.get_returned_clients_overview(p_year INT DEFAULT 2026)
RETURNS TABLE(
    total_returned BIGINT,
    total_revenue NUMERIC,
    total_invoices BIGINT,
    avg_revenue_per_client NUMERIC,
    avg_ticket NUMERIC,
    pct_of_active_clients NUMERIC,
    avg_break_period TEXT
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN QUERY
    WITH returned_clients AS (
        SELECT code FROM clients 
        WHERE current_status_id = 10 AND is_active_current = TRUE 
          AND code NOT IN ('9653', '11230')
    ),
    returned_stats AS (
        SELECT 
            COUNT(DISTINCT rc.code)::BIGINT AS total_ret,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS total_rev,
            COUNT(DISTINCT d.id)::BIGINT AS total_inv
        FROM returned_clients rc
        JOIN documents d ON d.client_code = rc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
    ),
    total_active AS (
        SELECT COUNT(DISTINCT cya.client_code)::BIGINT as total_act
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year AND cya.is_active = TRUE AND cya.client_code NOT IN ('9653', '11230')
    )
    SELECT 
        rs.total_ret AS total_returned,
        rs.total_rev AS total_revenue,
        rs.total_inv AS total_invoices,
        ROUND(rs.total_rev / NULLIF(rs.total_ret, 0), 0)::NUMERIC AS avg_revenue_per_client,
        ROUND(rs.total_rev / NULLIF(rs.total_inv, 0), 0)::NUMERIC AS avg_ticket,
        ROUND(rs.total_ret * 100.0 / NULLIF(ta.total_act, 0), 1)::NUMERIC AS pct_of_active_clients,
        '1 год'::TEXT AS avg_break_period
    FROM returned_stats rs, total_active ta;
END;
$$;

-- 3. ABC-анализ вернувшихся клиентов
CREATE OR REPLACE FUNCTION public.get_returned_clients_abc(p_year INT DEFAULT 2026)
RETURNS TABLE(
    abc_group TEXT,
    count BIGINT,
    revenue NUMERIC,
    pct NUMERIC
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN QUERY
    WITH returned_clients AS (
        SELECT code FROM clients WHERE current_status_id = 10 AND is_active_current = TRUE AND code NOT IN ('9653', '11230')
    ),
    returned_revenue AS (
        SELECT rc.code, COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
        FROM returned_clients rc
        JOIN documents d ON d.client_code = rc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY rc.code
    ),
    ranked AS (
        SELECT *, 
            SUM(goods_revenue) OVER (ORDER BY goods_revenue DESC) AS cum_revenue,
            SUM(goods_revenue) OVER () AS total_revenue
        FROM returned_revenue WHERE goods_revenue > 0
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
$$;

-- 4. Сравнение Вернувшихся с Новыми
CREATE OR REPLACE FUNCTION public.get_returned_clients_compare_new(p_year INT DEFAULT 2026)
RETURNS TABLE(
    frequency_group TEXT,
    sort_order INT,
    returned_count BIGINT,
    returned_revenue NUMERIC,
    returned_avg_ticket NUMERIC,
    new_count BIGINT,
    new_revenue NUMERIC,
    new_avg_ticket NUMERIC
)
LANGUAGE plpgsql STABLE AS $$
BEGIN
    RETURN QUERY
    WITH base_stages AS (
        SELECT 'Разовые (1)'::TEXT AS frequency_group, 1 AS sort_order
        UNION ALL SELECT 'Повторные (2-3)', 2
        UNION ALL SELECT 'Квартал (4-10)', 3
        UNION ALL SELECT 'Месяц (11-40)', 4
        UNION ALL SELECT 'Неделя (41-170)', 5
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
$$;

-- 5. Список вернувшихся клиентов
CREATE OR REPLACE FUNCTION public.get_returned_clients_list(
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
    abc_group TEXT,
    frequency_group TEXT
)
LANGUAGE plpgsql STABLE AS $$
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
                WHEN rk.docs = 1 THEN 'Разовые (1)'
                WHEN rk.docs BETWEEN 2 AND 3 THEN 'Повторные (2-3)'
                WHEN rk.docs BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
                WHEN rk.docs BETWEEN 11 AND 40 THEN 'Месяц (11-40)'
                WHEN rk.docs BETWEEN 41 AND 170 THEN 'Неделя (41-170)'
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
$$;
