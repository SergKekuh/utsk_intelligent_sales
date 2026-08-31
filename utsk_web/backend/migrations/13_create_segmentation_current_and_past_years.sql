-- =============================================================================
-- MIGRATION 13: Stored functions get_segmentation_current_year and get_segmentation_past_years
-- Date: 2026-08-28
-- Description: Creates PostgreSQL functions for current year frequency distribution
--              (total, new, C2, retained) and past years inactive clients (sleeping status 8, churned status 9)
-- =============================================================================

-- 1. get_segmentation_current_year(p_year INT, p_limit_price NUMERIC)
DROP FUNCTION IF EXISTS public.get_segmentation_current_year(INT, NUMERIC);
DROP FUNCTION IF EXISTS public.get_segmentation_current_year(INT);

CREATE OR REPLACE FUNCTION public.get_segmentation_current_year(
    p_year INT DEFAULT 2026,
    p_limit_price NUMERIC DEFAULT 146000
)
RETURNS TABLE(
    sort_order INT,
    freq_group VARCHAR,
    freq_name VARCHAR,
    freq_range VARCHAR,
    total_count BIGINT,
    total_revenue NUMERIC,
    new_count BIGINT,
    c2_count BIGINT,
    c2_revenue NUMERIC,
    retained_count BIGINT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH freq_defs(sort_order, freq_group, freq_name, freq_range) AS (
        VALUES 
            (1, 'raz'::VARCHAR, 'РАЗОВІ'::VARCHAR, '1'::VARCHAR),
            (2, 'povt'::VARCHAR, 'ПОВТОРНІ'::VARCHAR, '2-3'::VARCHAR),
            (3, 'kvart'::VARCHAR, 'КВАРТАЛЬНІ'::VARCHAR, '4-10'::VARCHAR),
            (4, 'mes'::VARCHAR, 'МІСЯЧНІ'::VARCHAR, '11-40'::VARCHAR),
            (5, 'ned'::VARCHAR, 'ТИЖНЕВІ'::VARCHAR, '41-170'::VARCHAR),
            (6, 'den'::VARCHAR, 'ЩОДЕННІ'::VARCHAR, '>170'::VARCHAR)
    ),
    active_clients AS (
        SELECT c.code
        FROM clients c
        JOIN client_year_activity cya ON c.code = cya.client_code 
            AND cya.sales_year = p_year AND cya.is_active = TRUE
        WHERE c.code NOT IN ('9653', '11230')
    ),
    frequency AS (
        SELECT 
            ac.code,
            COUNT(DISTINCT d.id) AS inv_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
            EXISTS(SELECT 1 FROM clients WHERE code = ac.code AND current_status_id = 1) AS is_new,
            EXISTS(SELECT 1 FROM documents d_prev WHERE d_prev.client_code = ac.code AND EXTRACT(YEAR FROM d_prev.invoice_date) = p_year - 1) AS is_retained
        FROM active_clients ac
        JOIN documents d ON d.client_code = ac.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY ac.code
    ),
    agg AS (
        SELECT 
            CASE 
                WHEN f.inv_count = 1 THEN 'raz'
                WHEN f.inv_count BETWEEN 2 AND 3 THEN 'povt'
                WHEN f.inv_count BETWEEN 4 AND 10 THEN 'kvart'
                WHEN f.inv_count BETWEEN 11 AND 40 THEN 'mes'
                WHEN f.inv_count BETWEEN 41 AND 170 THEN 'ned'
                ELSE 'den'
            END AS freq_group,
            COUNT(*)::BIGINT AS total_count,
            ROUND(SUM(f.goods_revenue), 2)::NUMERIC AS total_revenue,
            SUM(CASE WHEN f.is_new THEN 1 ELSE 0 END)::BIGINT AS new_count,
            SUM(CASE WHEN f.goods_revenue <= p_limit_price THEN 1 ELSE 0 END)::BIGINT AS c2_count,
            ROUND(SUM(CASE WHEN f.goods_revenue <= p_limit_price THEN f.goods_revenue ELSE 0 END), 2)::NUMERIC AS c2_revenue,
            SUM(CASE WHEN f.is_retained THEN 1 ELSE 0 END)::BIGINT AS retained_count
        FROM frequency f
        GROUP BY 
            CASE 
                WHEN f.inv_count = 1 THEN 'raz'
                WHEN f.inv_count BETWEEN 2 AND 3 THEN 'povt'
                WHEN f.inv_count BETWEEN 4 AND 10 THEN 'kvart'
                WHEN f.inv_count BETWEEN 11 AND 40 THEN 'mes'
                WHEN f.inv_count BETWEEN 41 AND 170 THEN 'ned'
                ELSE 'den'
            END
    )
    SELECT 
        fd.sort_order,
        fd.freq_group,
        fd.freq_name,
        fd.freq_range,
        COALESCE(a.total_count, 0)::BIGINT AS total_count,
        COALESCE(a.total_revenue, 0.00)::NUMERIC AS total_revenue,
        COALESCE(a.new_count, 0)::BIGINT AS new_count,
        COALESCE(a.c2_count, 0)::BIGINT AS c2_count,
        COALESCE(a.c2_revenue, 0.00)::NUMERIC AS c2_revenue,
        COALESCE(a.retained_count, 0)::BIGINT AS retained_count
    FROM freq_defs fd
    LEFT JOIN agg a ON fd.freq_group = a.freq_group
    ORDER BY fd.sort_order;
END;
$function$;


-- 2. get_segmentation_past_years(p_year INT)
DROP FUNCTION IF EXISTS public.get_segmentation_past_years(INT);

CREATE OR REPLACE FUNCTION public.get_segmentation_past_years(
    p_year INT DEFAULT 2026
)
RETURNS TABLE(
    sort_order INT,
    freq_group VARCHAR,
    freq_name VARCHAR,
    freq_range VARCHAR,
    current_status_id INT,
    status_name VARCHAR,
    total_count BIGINT,
    total_revenue NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH freq_defs(sort_order, freq_group, freq_name, freq_range) AS (
        VALUES 
            (1, 'raz'::VARCHAR, 'РАЗОВІ'::VARCHAR, '1'::VARCHAR),
            (2, 'povt'::VARCHAR, 'ПОВТОРНІ'::VARCHAR, '2-3'::VARCHAR),
            (3, 'kvart'::VARCHAR, 'КВАРТАЛЬНІ'::VARCHAR, '4-10'::VARCHAR),
            (4, 'mes'::VARCHAR, 'МІСЯЧНІ'::VARCHAR, '11-40'::VARCHAR),
            (5, 'ned'::VARCHAR, 'ТИЖНЕВІ'::VARCHAR, '41-170'::VARCHAR),
            (6, 'den'::VARCHAR, 'ЩОДЕННІ'::VARCHAR, '>170'::VARCHAR)
    ),
    inactive_clients AS (
        SELECT c.code, c.current_status_id
        FROM clients c
        WHERE c.current_status_id IN (8, 9)
          AND c.code NOT IN ('9653', '11230')
    ),
    frequency AS (
        SELECT 
            ic.code,
            ic.current_status_id,
            COUNT(DISTINCT d.id) AS inv_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
        FROM inactive_clients ic
        JOIN documents d ON d.client_code = ic.code 
            AND EXTRACT(YEAR FROM d.invoice_date) = (
                CASE WHEN ic.current_status_id = 8 THEN p_year - 1 ELSE p_year - 2 END
            )
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY ic.code, ic.current_status_id
    ),
    agg AS (
        SELECT 
            f.current_status_id,
            CASE 
                WHEN f.inv_count = 1 THEN 'raz'
                WHEN f.inv_count BETWEEN 2 AND 3 THEN 'povt'
                WHEN f.inv_count BETWEEN 4 AND 10 THEN 'kvart'
                WHEN f.inv_count BETWEEN 11 AND 40 THEN 'mes'
                WHEN f.inv_count BETWEEN 41 AND 170 THEN 'ned'
                ELSE 'den'
            END AS freq_group,
            COUNT(*)::BIGINT AS total_count,
            ROUND(SUM(f.goods_revenue), 2)::NUMERIC AS total_revenue
        FROM frequency f
        GROUP BY 
            f.current_status_id,
            CASE 
                WHEN f.inv_count = 1 THEN 'raz'
                WHEN f.inv_count BETWEEN 2 AND 3 THEN 'povt'
                WHEN f.inv_count BETWEEN 4 AND 10 THEN 'kvart'
                WHEN f.inv_count BETWEEN 11 AND 40 THEN 'mes'
                WHEN f.inv_count BETWEEN 41 AND 170 THEN 'ned'
                ELSE 'den'
            END
    )
    SELECT 
        fd.sort_order,
        fd.freq_group,
        fd.freq_name,
        fd.freq_range,
        st.status_id AS current_status_id,
        st.status_name,
        COALESCE(a.total_count, 0)::BIGINT AS total_count,
        COALESCE(a.total_revenue, 0.00)::NUMERIC AS total_revenue
    FROM (VALUES (8, 'sleeping'::VARCHAR), (9, 'churned'::VARCHAR)) AS st(status_id, status_name)
    CROSS JOIN freq_defs fd
    LEFT JOIN agg a ON a.current_status_id = st.status_id AND a.freq_group = fd.freq_group
    ORDER BY st.status_id, fd.sort_order;
END;
$function$;
