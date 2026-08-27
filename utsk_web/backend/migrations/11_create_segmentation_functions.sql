-- =============================================================================
-- MIGRATION 11: Stored functions for UTSK General Client Segmentation (5th Tab)
-- Date: 2026-08-25
-- Description: Creates get_segmentation_kpi, get_segmentation_special, get_segmentation_matrix
-- =============================================================================

-- 1. get_segmentation_kpi(p_year INT, p_limit_price NUMERIC)
DROP FUNCTION IF EXISTS public.get_segmentation_kpi(INT, NUMERIC);
CREATE OR REPLACE FUNCTION public.get_segmentation_kpi(
    p_year INT DEFAULT 2026,
    p_limit_price NUMERIC DEFAULT 146000
)
RETURNS TABLE(
    total_clients BIGINT,
    repeat_loyal_clients BIGINT,
    repeat_loyal_pct NUMERIC,
    c2_clients BIGINT,
    c2_pct NUMERIC,
    new_clients BIGINT,
    new_pct NUMERIC,
    total_revenue NUMERIC,
    total_invoices BIGINT,
    avg_check NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
        SELECT DISTINCT cya.client_code
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year AND cya.is_active = TRUE AND cya.client_code NOT IN ('9653', '11230')
    ),
    client_stats AS (
        SELECT 
            c.code,
            c.current_status_id,
            COUNT(DISTINCT d.id) AS invoices_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
            CASE 
                WHEN p_year = 2026 AND c.current_status_id IS NOT NULL THEN (c.current_status_id = 1)
                ELSE NOT EXISTS (
                    SELECT 1 FROM documents d_prev 
                    WHERE d_prev.client_code = c.code AND EXTRACT(YEAR FROM d_prev.invoice_date) = p_year - 1
                )
            END AS is_new_client
        FROM clients c
        JOIN active_clients ac ON c.code = ac.client_code
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY c.code, c.current_status_id
    )
    SELECT 
        COUNT(*)::BIGINT AS total_clients,
        COUNT(CASE WHEN cs.invoices_count >= 2 THEN 1 END)::BIGINT AS repeat_loyal_clients,
        ROUND(COUNT(CASE WHEN cs.invoices_count >= 2 THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 1)::NUMERIC AS repeat_loyal_pct,
        COUNT(CASE WHEN cs.goods_revenue <= p_limit_price THEN 1 END)::BIGINT AS c2_clients,
        ROUND(COUNT(CASE WHEN cs.goods_revenue <= p_limit_price THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 1)::NUMERIC AS c2_pct,
        COUNT(CASE WHEN cs.is_new_client THEN 1 END)::BIGINT AS new_clients,
        ROUND(COUNT(CASE WHEN cs.is_new_client THEN 1 END) * 100.0 / NULLIF(COUNT(*), 0), 1)::NUMERIC AS new_pct,
        ROUND(SUM(cs.goods_revenue)::NUMERIC, 2) AS total_revenue,
        SUM(cs.invoices_count)::BIGINT AS total_invoices,
        ROUND((SUM(cs.goods_revenue) / NULLIF(SUM(cs.invoices_count), 0))::NUMERIC, 2) AS avg_check
    FROM client_stats cs;
END;
$function$;


-- 2. get_segmentation_special(p_year INT, p_limit_price NUMERIC)
DROP FUNCTION IF EXISTS public.get_segmentation_special(INT, NUMERIC);
CREATE OR REPLACE FUNCTION public.get_segmentation_special(
    p_year INT DEFAULT 2026,
    p_limit_price NUMERIC DEFAULT 146000
)
RETURNS TABLE(
    segment_code VARCHAR,
    segment_name VARCHAR,
    badge_label VARCHAR,
    icon VARCHAR,
    color VARCHAR,
    clients_count BIGINT,
    sales_revenue NUMERIC,
    invoices_count BIGINT,
    avg_ticket NUMERIC,
    share_clients_pct NUMERIC,
    share_revenue_pct NUMERIC,
    description TEXT,
    sort_order INT
)
LANGUAGE plpgsql STABLE
AS $function$
DECLARE
    v_total_active BIGINT;
    v_total_revenue NUMERIC;
    v_total_all BIGINT;
BEGIN
    -- Общее число активных клиентов и выручка за выбранный год
    SELECT 
        COUNT(DISTINCT cya.client_code),
        COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)
    INTO v_total_active, v_total_revenue
    FROM client_year_activity cya
    JOIN documents d ON d.client_code = cya.client_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE cya.sales_year = p_year AND cya.is_active = TRUE AND cya.client_code NOT IN ('9653', '11230');

    -- Всего клиентов в базе
    SELECT COUNT(*) INTO v_total_all
    FROM clients
    WHERE code NOT IN ('9653', '11230');

    RETURN QUERY
    WITH active_clients AS (
        SELECT DISTINCT cya.client_code
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year AND cya.is_active = TRUE AND cya.client_code NOT IN ('9653', '11230')
    ),
    client_stats AS (
        SELECT 
            c.code,
            c.current_status_id,
            COUNT(DISTINCT d.id) AS invoices_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
            CASE 
                WHEN p_year = 2026 AND c.current_status_id IS NOT NULL THEN (c.current_status_id = 1)
                ELSE NOT EXISTS (
                    SELECT 1 FROM documents d_prev 
                    WHERE d_prev.client_code = c.code AND EXTRACT(YEAR FROM d_prev.invoice_date) = p_year - 1
                )
            END AS is_new_client
        FROM clients c
        JOIN active_clients ac ON c.code = ac.client_code
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY c.code, c.current_status_id
    ),
    sleeping_stats AS (
        SELECT 
            COUNT(DISTINCT c.code)::BIGINT AS sleeping_cnt,
            ROUND(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC, 2) AS sleeping_rev,
            COUNT(DISTINCT d.id)::BIGINT AS sleeping_inv
        FROM clients c
        LEFT JOIN active_clients ac ON c.code = ac.client_code
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year - 1
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE ac.client_code IS NULL AND c.code NOT IN ('9653', '11230')
    ),
    churned_stats AS (
        SELECT 
            COUNT(DISTINCT c.code)::BIGINT AS churned_cnt,
            ROUND(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC, 2) AS churned_rev,
            COUNT(DISTINCT d.id)::BIGINT AS churned_inv
        FROM clients c
        LEFT JOIN active_clients ac ON c.code = ac.client_code
        LEFT JOIN documents d_prev ON d_prev.client_code = c.code AND EXTRACT(YEAR FROM d_prev.invoice_date) = p_year - 1
        LEFT JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year - 2
        LEFT JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE ac.client_code IS NULL AND d_prev.id IS NULL AND c.code NOT IN ('9653', '11230')
    )
    -- 1. C2 (Дрібні)
    SELECT 
        'c2'::VARCHAR AS segment_code,
        'C2 (Дрібні)'::VARCHAR AS segment_name,
        ('≤ ' || TO_CHAR(p_limit_price, 'FM999G999G999') || ' ₴')::VARCHAR AS badge_label,
        'fa-coins'::VARCHAR AS icon,
        '#f59e0b'::VARCHAR AS color,
        COUNT(CASE WHEN cs.goods_revenue <= p_limit_price THEN 1 END)::BIGINT AS clients_count,
        ROUND(COALESCE(SUM(CASE WHEN cs.goods_revenue <= p_limit_price THEN cs.goods_revenue END), 0)::NUMERIC, 2) AS sales_revenue,
        COALESCE(SUM(CASE WHEN cs.goods_revenue <= p_limit_price THEN cs.invoices_count END), 0)::BIGINT AS invoices_count,
        ROUND((COALESCE(SUM(CASE WHEN cs.goods_revenue <= p_limit_price THEN cs.goods_revenue END), 0) / 
               NULLIF(SUM(CASE WHEN cs.goods_revenue <= p_limit_price THEN cs.invoices_count END), 0))::NUMERIC, 2) AS avg_ticket,
        ROUND(COUNT(CASE WHEN cs.goods_revenue <= p_limit_price THEN 1 END) * 100.0 / NULLIF(v_total_active, 0), 1)::NUMERIC AS share_clients_pct,
        ROUND(COALESCE(SUM(CASE WHEN cs.goods_revenue <= p_limit_price THEN cs.goods_revenue END), 0) * 100.0 / NULLIF(v_total_revenue, 0), 1)::NUMERIC AS share_revenue_pct,
        'Клієнти з виручкою не більше границі C2'::TEXT AS description,
        1 AS sort_order
    FROM client_stats cs

    UNION ALL

    -- 2. Нові клієнти
    SELECT 
        'new_clients'::VARCHAR AS segment_code,
        'Нові клієнти'::VARCHAR AS segment_name,
        'Status ID = 1'::VARCHAR AS badge_label,
        'fa-user-plus'::VARCHAR AS icon,
        '#10b981'::VARCHAR AS color,
        COUNT(CASE WHEN cs.is_new_client THEN 1 END)::BIGINT AS clients_count,
        ROUND(COALESCE(SUM(CASE WHEN cs.is_new_client THEN cs.goods_revenue END), 0)::NUMERIC, 2) AS sales_revenue,
        COALESCE(SUM(CASE WHEN cs.is_new_client THEN cs.invoices_count END), 0)::BIGINT AS invoices_count,
        ROUND((COALESCE(SUM(CASE WHEN cs.is_new_client THEN cs.goods_revenue END), 0) / 
               NULLIF(SUM(CASE WHEN cs.is_new_client THEN cs.invoices_count END), 0))::NUMERIC, 2) AS avg_ticket,
        ROUND(COUNT(CASE WHEN cs.is_new_client THEN 1 END) * 100.0 / NULLIF(v_total_active, 0), 1)::NUMERIC AS share_clients_pct,
        ROUND(COALESCE(SUM(CASE WHEN cs.is_new_client THEN cs.goods_revenue END), 0) * 100.0 / NULLIF(v_total_revenue, 0), 1)::NUMERIC AS share_revenue_pct,
        'Вперше здійснили покупку у вибраному році'::TEXT AS description,
        2 AS sort_order
    FROM client_stats cs

    UNION ALL

    -- 3. Убули (Ушедшие)
    SELECT 
        'churned'::VARCHAR AS segment_code,
        'Убули (Ушедшие)'::VARCHAR AS segment_name,
        'Status ID = 9'::VARCHAR AS badge_label,
        'fa-user-xmark'::VARCHAR AS icon,
        '#ef4444'::VARCHAR AS color,
        cs.churned_cnt AS clients_count,
        cs.churned_rev AS sales_revenue,
        cs.churned_inv AS invoices_count,
        ROUND((cs.churned_rev / NULLIF(cs.churned_inv, 0))::NUMERIC, 2) AS avg_ticket,
        ROUND(cs.churned_cnt * 100.0 / NULLIF(v_total_all, 0), 1)::NUMERIC AS share_clients_pct,
        ROUND(cs.churned_rev * 100.0 / NULLIF(v_total_revenue + cs.churned_rev, 0), 1)::NUMERIC AS share_revenue_pct,
        'Не купували 2+ роки (втрачена клієнтська база)'::TEXT AS description,
        3 AS sort_order
    FROM churned_stats cs

    UNION ALL

    -- 4. Сплячі
    SELECT 
        'sleeping'::VARCHAR AS segment_code,
        'Сплячі'::VARCHAR AS segment_name,
        'Status ID = 8'::VARCHAR AS badge_label,
        'fa-moon'::VARCHAR AS icon,
        '#8b5cf6'::VARCHAR AS color,
        ss.sleeping_cnt AS clients_count,
        ss.sleeping_rev AS sales_revenue,
        ss.sleeping_inv AS invoices_count,
        ROUND((ss.sleeping_rev / NULLIF(ss.sleeping_inv, 0))::NUMERIC, 2) AS avg_ticket,
        ROUND(ss.sleeping_cnt * 100.0 / NULLIF(v_total_all, 0), 1)::NUMERIC AS share_clients_pct,
        ROUND(ss.sleeping_rev * 100.0 / NULLIF(v_total_revenue + ss.sleeping_rev, 0), 1)::NUMERIC AS share_revenue_pct,
        'Купували минулого року, але 0 покупок у поточному'::TEXT AS description,
        4 AS sort_order
    FROM sleeping_stats ss

    ORDER BY sort_order;
END;
$function$;


-- 3. get_segmentation_matrix(p_year INT, p_limit_price NUMERIC)
DROP FUNCTION IF EXISTS public.get_segmentation_matrix(INT, NUMERIC);
CREATE OR REPLACE FUNCTION public.get_segmentation_matrix(
    p_year INT DEFAULT 2026,
    p_limit_price NUMERIC DEFAULT 146000
)
RETURNS TABLE(
    section VARCHAR,
    row_key VARCHAR,
    row_label VARCHAR,
    val_1 NUMERIC,
    val_2_3 NUMERIC,
    val_4_10 NUMERIC,
    val_11_40 NUMERIC,
    val_41_plus NUMERIC,
    val_total NUMERIC,
    sort_order INT
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
        SELECT DISTINCT cya.client_code
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year AND cya.is_active = TRUE AND cya.client_code NOT IN ('9653', '11230')
    ),
    client_stats AS (
        SELECT 
            c.code,
            c.current_status_id,
            COUNT(DISTINCT d.id) AS invoices_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
            CASE 
                WHEN COUNT(DISTINCT d.id) = 1 THEN '1'
                WHEN COUNT(DISTINCT d.id) BETWEEN 2 AND 3 THEN '2_3'
                WHEN COUNT(DISTINCT d.id) BETWEEN 4 AND 10 THEN '4_10'
                WHEN COUNT(DISTINCT d.id) BETWEEN 11 AND 40 THEN '11_40'
                ELSE '41_plus'
            END AS freq_group,
            CASE 
                WHEN p_year = 2026 AND c.current_status_id IS NOT NULL THEN (c.current_status_id = 1)
                ELSE NOT EXISTS (
                    SELECT 1 FROM documents d_prev 
                    WHERE d_prev.client_code = c.code AND EXTRACT(YEAR FROM d_prev.invoice_date) = p_year - 1
                )
            END AS is_new_client,
            EXISTS (
                SELECT 1 FROM documents d_prev 
                WHERE d_prev.client_code = c.code AND EXTRACT(YEAR FROM d_prev.invoice_date) = p_year - 1
            ) AS is_retained
        FROM clients c
        JOIN active_clients ac ON c.code = ac.client_code
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY c.code, c.current_status_id
    ),
    prev_active_clients AS (
        SELECT DISTINCT cya.client_code
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year - 1 AND cya.is_active = TRUE AND cya.client_code NOT IN ('9653', '11230')
    ),
    prev_stats AS (
        SELECT 
            c.code,
            CASE 
                WHEN COUNT(DISTINCT d.id) = 1 THEN '1'
                WHEN COUNT(DISTINCT d.id) BETWEEN 2 AND 3 THEN '2_3'
                WHEN COUNT(DISTINCT d.id) BETWEEN 4 AND 10 THEN '4_10'
                WHEN COUNT(DISTINCT d.id) BETWEEN 11 AND 40 THEN '11_40'
                ELSE '41_plus'
            END AS freq_group
        FROM clients c
        JOIN prev_active_clients pac ON c.code = pac.client_code
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year - 1
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY c.code
    ),
    agg AS (
        SELECT 
            -- 1
            COUNT(CASE WHEN cs.freq_group = '1' THEN 1 END)::NUMERIC AS comp_1,
            SUM(CASE WHEN cs.freq_group = '1' THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS sales_1,
            SUM(CASE WHEN cs.freq_group = '1' THEN cs.invoices_count ELSE 0 END)::NUMERIC AS inv_1,
            COUNT(CASE WHEN cs.freq_group = '1' AND cs.goods_revenue <= p_limit_price THEN 1 END)::NUMERIC AS c2_comp_1,
            SUM(CASE WHEN cs.freq_group = '1' AND cs.goods_revenue <= p_limit_price THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS c2_sales_1,
            SUM(CASE WHEN cs.freq_group = '1' AND cs.goods_revenue <= p_limit_price THEN cs.invoices_count ELSE 0 END)::NUMERIC AS c2_inv_1,
            COUNT(CASE WHEN cs.freq_group = '1' AND cs.goods_revenue > p_limit_price THEN 1 END)::NUMERIC AS abc_comp_1,
            SUM(CASE WHEN cs.freq_group = '1' AND cs.goods_revenue > p_limit_price THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS abc_sales_1,
            SUM(CASE WHEN cs.freq_group = '1' AND cs.goods_revenue > p_limit_price THEN cs.invoices_count ELSE 0 END)::NUMERIC AS abc_inv_1,
            COUNT(CASE WHEN cs.freq_group = '1' AND cs.is_new_client THEN 1 END)::NUMERIC AS new_comp_1,
            COUNT(CASE WHEN cs.freq_group = '1' AND cs.is_retained THEN 1 END)::NUMERIC AS ret_comp_1,

            -- 2-3
            COUNT(CASE WHEN cs.freq_group = '2_3' THEN 1 END)::NUMERIC AS comp_2_3,
            SUM(CASE WHEN cs.freq_group = '2_3' THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS sales_2_3,
            SUM(CASE WHEN cs.freq_group = '2_3' THEN cs.invoices_count ELSE 0 END)::NUMERIC AS inv_2_3,
            COUNT(CASE WHEN cs.freq_group = '2_3' AND cs.goods_revenue <= p_limit_price THEN 1 END)::NUMERIC AS c2_comp_2_3,
            SUM(CASE WHEN cs.freq_group = '2_3' AND cs.goods_revenue <= p_limit_price THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS c2_sales_2_3,
            SUM(CASE WHEN cs.freq_group = '2_3' AND cs.goods_revenue <= p_limit_price THEN cs.invoices_count ELSE 0 END)::NUMERIC AS c2_inv_2_3,
            COUNT(CASE WHEN cs.freq_group = '2_3' AND cs.goods_revenue > p_limit_price THEN 1 END)::NUMERIC AS abc_comp_2_3,
            SUM(CASE WHEN cs.freq_group = '2_3' AND cs.goods_revenue > p_limit_price THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS abc_sales_2_3,
            SUM(CASE WHEN cs.freq_group = '2_3' AND cs.goods_revenue > p_limit_price THEN cs.invoices_count ELSE 0 END)::NUMERIC AS abc_inv_2_3,
            COUNT(CASE WHEN cs.freq_group = '2_3' AND cs.is_new_client THEN 1 END)::NUMERIC AS new_comp_2_3,
            COUNT(CASE WHEN cs.freq_group = '2_3' AND cs.is_retained THEN 1 END)::NUMERIC AS ret_comp_2_3,

            -- 4-10
            COUNT(CASE WHEN cs.freq_group = '4_10' THEN 1 END)::NUMERIC AS comp_4_10,
            SUM(CASE WHEN cs.freq_group = '4_10' THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS sales_4_10,
            SUM(CASE WHEN cs.freq_group = '4_10' THEN cs.invoices_count ELSE 0 END)::NUMERIC AS inv_4_10,
            COUNT(CASE WHEN cs.freq_group = '4_10' AND cs.goods_revenue <= p_limit_price THEN 1 END)::NUMERIC AS c2_comp_4_10,
            SUM(CASE WHEN cs.freq_group = '4_10' AND cs.goods_revenue <= p_limit_price THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS c2_sales_4_10,
            SUM(CASE WHEN cs.freq_group = '4_10' AND cs.goods_revenue <= p_limit_price THEN cs.invoices_count ELSE 0 END)::NUMERIC AS c2_inv_4_10,
            COUNT(CASE WHEN cs.freq_group = '4_10' AND cs.goods_revenue > p_limit_price THEN 1 END)::NUMERIC AS abc_comp_4_10,
            SUM(CASE WHEN cs.freq_group = '4_10' AND cs.goods_revenue > p_limit_price THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS abc_sales_4_10,
            SUM(CASE WHEN cs.freq_group = '4_10' AND cs.goods_revenue > p_limit_price THEN cs.invoices_count ELSE 0 END)::NUMERIC AS abc_inv_4_10,
            COUNT(CASE WHEN cs.freq_group = '4_10' AND cs.is_new_client THEN 1 END)::NUMERIC AS new_comp_4_10,
            COUNT(CASE WHEN cs.freq_group = '4_10' AND cs.is_retained THEN 1 END)::NUMERIC AS ret_comp_4_10,

            -- 11-40
            COUNT(CASE WHEN cs.freq_group = '11_40' THEN 1 END)::NUMERIC AS comp_11_40,
            SUM(CASE WHEN cs.freq_group = '11_40' THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS sales_11_40,
            SUM(CASE WHEN cs.freq_group = '11_40' THEN cs.invoices_count ELSE 0 END)::NUMERIC AS inv_11_40,
            COUNT(CASE WHEN cs.freq_group = '11_40' AND cs.goods_revenue <= p_limit_price THEN 1 END)::NUMERIC AS c2_comp_11_40,
            SUM(CASE WHEN cs.freq_group = '11_40' AND cs.goods_revenue <= p_limit_price THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS c2_sales_11_40,
            SUM(CASE WHEN cs.freq_group = '11_40' AND cs.goods_revenue <= p_limit_price THEN cs.invoices_count ELSE 0 END)::NUMERIC AS c2_inv_11_40,
            COUNT(CASE WHEN cs.freq_group = '11_40' AND cs.goods_revenue > p_limit_price THEN 1 END)::NUMERIC AS abc_comp_11_40,
            SUM(CASE WHEN cs.freq_group = '11_40' AND cs.goods_revenue > p_limit_price THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS abc_sales_11_40,
            SUM(CASE WHEN cs.freq_group = '11_40' AND cs.goods_revenue > p_limit_price THEN cs.invoices_count ELSE 0 END)::NUMERIC AS abc_inv_11_40,
            COUNT(CASE WHEN cs.freq_group = '11_40' AND cs.is_new_client THEN 1 END)::NUMERIC AS new_comp_11_40,
            COUNT(CASE WHEN cs.freq_group = '11_40' AND cs.is_retained THEN 1 END)::NUMERIC AS ret_comp_11_40,

            -- 41+
            COUNT(CASE WHEN cs.freq_group = '41_plus' THEN 1 END)::NUMERIC AS comp_41_plus,
            SUM(CASE WHEN cs.freq_group = '41_plus' THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS sales_41_plus,
            SUM(CASE WHEN cs.freq_group = '41_plus' THEN cs.invoices_count ELSE 0 END)::NUMERIC AS inv_41_plus,
            COUNT(CASE WHEN cs.freq_group = '41_plus' AND cs.goods_revenue <= p_limit_price THEN 1 END)::NUMERIC AS c2_comp_41_plus,
            SUM(CASE WHEN cs.freq_group = '41_plus' AND cs.goods_revenue <= p_limit_price THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS c2_sales_41_plus,
            SUM(CASE WHEN cs.freq_group = '41_plus' AND cs.goods_revenue <= p_limit_price THEN cs.invoices_count ELSE 0 END)::NUMERIC AS c2_inv_41_plus,
            COUNT(CASE WHEN cs.freq_group = '41_plus' AND cs.goods_revenue > p_limit_price THEN 1 END)::NUMERIC AS abc_comp_41_plus,
            SUM(CASE WHEN cs.freq_group = '41_plus' AND cs.goods_revenue > p_limit_price THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS abc_sales_41_plus,
            SUM(CASE WHEN cs.freq_group = '41_plus' AND cs.goods_revenue > p_limit_price THEN cs.invoices_count ELSE 0 END)::NUMERIC AS abc_inv_41_plus,
            COUNT(CASE WHEN cs.freq_group = '41_plus' AND cs.is_new_client THEN 1 END)::NUMERIC AS new_comp_41_plus,
            COUNT(CASE WHEN cs.freq_group = '41_plus' AND cs.is_retained THEN 1 END)::NUMERIC AS ret_comp_41_plus,

            -- Totals
            COUNT(*)::NUMERIC AS tot_comp,
            SUM(cs.goods_revenue)::NUMERIC AS tot_sales,
            SUM(cs.invoices_count)::NUMERIC AS tot_inv,
            COUNT(CASE WHEN cs.goods_revenue <= p_limit_price THEN 1 END)::NUMERIC AS tot_c2_comp,
            SUM(CASE WHEN cs.goods_revenue <= p_limit_price THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS tot_c2_sales,
            SUM(CASE WHEN cs.goods_revenue <= p_limit_price THEN cs.invoices_count ELSE 0 END)::NUMERIC AS tot_c2_inv,
            COUNT(CASE WHEN cs.goods_revenue > p_limit_price THEN 1 END)::NUMERIC AS tot_abc_comp,
            SUM(CASE WHEN cs.goods_revenue > p_limit_price THEN cs.goods_revenue ELSE 0 END)::NUMERIC AS tot_abc_sales,
            SUM(CASE WHEN cs.goods_revenue > p_limit_price THEN cs.invoices_count ELSE 0 END)::NUMERIC AS tot_abc_inv,
            COUNT(CASE WHEN cs.is_new_client THEN 1 END)::NUMERIC AS tot_new_comp,
            COUNT(CASE WHEN cs.is_retained THEN 1 END)::NUMERIC AS tot_ret_comp
        FROM client_stats cs
    ),
    prev_agg AS (
        SELECT 
            COUNT(CASE WHEN ps.freq_group = '1' THEN 1 END)::NUMERIC AS prev_comp_1,
            COUNT(CASE WHEN ps.freq_group = '2_3' THEN 1 END)::NUMERIC AS prev_comp_2_3,
            COUNT(CASE WHEN ps.freq_group = '4_10' THEN 1 END)::NUMERIC AS prev_comp_4_10,
            COUNT(CASE WHEN ps.freq_group = '11_40' THEN 1 END)::NUMERIC AS prev_comp_11_40,
            COUNT(CASE WHEN ps.freq_group = '41_plus' THEN 1 END)::NUMERIC AS prev_comp_41_plus,
            COUNT(*)::NUMERIC AS prev_tot_comp
        FROM prev_stats ps
    )
    SELECT * FROM (
        -- ==================== 1. ЗАГАЛЬНА КІЛЬКІСТЬ ====================
        SELECT 
            'total'::VARCHAR AS section,
            'companies'::VARCHAR AS row_key,
            'Кількість клієнтів (фірм)'::VARCHAR AS row_label,
            a.comp_1, a.comp_2_3, a.comp_4_10, a.comp_11_40, a.comp_41_plus, a.tot_comp AS val_total,
            1 AS sort_order
        FROM agg a

        UNION ALL

        SELECT 
            'total'::VARCHAR,
            'companies_pct'::VARCHAR,
            '% від загальної кількості клієнтів'::VARCHAR,
            ROUND(a.comp_1 * 100.0 / NULLIF(a.tot_comp, 0), 1),
            ROUND(a.comp_2_3 * 100.0 / NULLIF(a.tot_comp, 0), 1),
            ROUND(a.comp_4_10 * 100.0 / NULLIF(a.tot_comp, 0), 1),
            ROUND(a.comp_11_40 * 100.0 / NULLIF(a.tot_comp, 0), 1),
            ROUND(a.comp_41_plus * 100.0 / NULLIF(a.tot_comp, 0), 1),
            100.0,
            2
        FROM agg a

        UNION ALL

        SELECT 
            'total'::VARCHAR,
            'sales'::VARCHAR,
            'Сума товарних продажів (₴)'::VARCHAR,
            ROUND(a.sales_1, 2), ROUND(a.sales_2_3, 2), ROUND(a.sales_4_10, 2), ROUND(a.sales_11_40, 2), ROUND(a.sales_41_plus, 2), ROUND(a.tot_sales, 2),
            3
        FROM agg a

        UNION ALL

        SELECT 
            'total'::VARCHAR,
            'sales_pct'::VARCHAR,
            '% від загальної виручки'::VARCHAR,
            ROUND(a.sales_1 * 100.0 / NULLIF(a.tot_sales, 0), 1),
            ROUND(a.sales_2_3 * 100.0 / NULLIF(a.tot_sales, 0), 1),
            ROUND(a.sales_4_10 * 100.0 / NULLIF(a.tot_sales, 0), 1),
            ROUND(a.sales_11_40 * 100.0 / NULLIF(a.tot_sales, 0), 1),
            ROUND(a.sales_41_plus * 100.0 / NULLIF(a.tot_sales, 0), 1),
            100.0,
            4
        FROM agg a

        UNION ALL

        SELECT 
            'total'::VARCHAR,
            'invoices'::VARCHAR,
            'Кількість накладних'::VARCHAR,
            a.inv_1, a.inv_2_3, a.inv_4_10, a.inv_11_40, a.inv_41_plus, a.tot_inv,
            5
        FROM agg a

        UNION ALL

        SELECT 
            'total'::VARCHAR,
            'avg_ticket'::VARCHAR,
            'Середній чек (₴ / накладну)'::VARCHAR,
            ROUND(a.sales_1 / NULLIF(a.inv_1, 0), 2),
            ROUND(a.sales_2_3 / NULLIF(a.inv_2_3, 0), 2),
            ROUND(a.sales_4_10 / NULLIF(a.inv_4_10, 0), 2),
            ROUND(a.sales_11_40 / NULLIF(a.inv_11_40, 0), 2),
            ROUND(a.sales_41_plus / NULLIF(a.inv_41_plus, 0), 2),
            ROUND(a.tot_sales / NULLIF(a.tot_inv, 0), 2),
            6
        FROM agg a

        -- ==================== 2. РОЗБИВКА C2 / ABC ====================
        UNION ALL

        SELECT 
            'c2_abc'::VARCHAR,
            'c2_companies'::VARCHAR,
            '🟡 C2 (≤ границі): Клієнти'::VARCHAR,
            a.c2_comp_1, a.c2_comp_2_3, a.c2_comp_4_10, a.c2_comp_11_40, a.c2_comp_41_plus, a.tot_c2_comp,
            7
        FROM agg a

        UNION ALL

        SELECT 
            'c2_abc'::VARCHAR,
            'c2_companies_pct'::VARCHAR,
            '🟡 C2: % від клієнтів C2'::VARCHAR,
            ROUND(a.c2_comp_1 * 100.0 / NULLIF(a.tot_c2_comp, 0), 1),
            ROUND(a.c2_comp_2_3 * 100.0 / NULLIF(a.tot_c2_comp, 0), 1),
            ROUND(a.c2_comp_4_10 * 100.0 / NULLIF(a.tot_c2_comp, 0), 1),
            ROUND(a.c2_comp_11_40 * 100.0 / NULLIF(a.tot_c2_comp, 0), 1),
            ROUND(a.c2_comp_41_plus * 100.0 / NULLIF(a.tot_c2_comp, 0), 1),
            100.0,
            8
        FROM agg a

        UNION ALL

        SELECT 
            'c2_abc'::VARCHAR,
            'c2_sales'::VARCHAR,
            '🟡 C2: Сума продажів (₴)'::VARCHAR,
            ROUND(a.c2_sales_1, 2), ROUND(a.c2_sales_2_3, 2), ROUND(a.c2_sales_4_10, 2), ROUND(a.c2_sales_11_40, 2), ROUND(a.c2_sales_41_plus, 2), ROUND(a.tot_c2_sales, 2),
            9
        FROM agg a

        UNION ALL

        SELECT 
            'c2_abc'::VARCHAR,
            'c2_avg_ticket'::VARCHAR,
            '🟡 C2: Середній чек (₴)'::VARCHAR,
            ROUND(a.c2_sales_1 / NULLIF(a.c2_inv_1, 0), 2),
            ROUND(a.c2_sales_2_3 / NULLIF(a.c2_inv_2_3, 0), 2),
            ROUND(a.c2_sales_4_10 / NULLIF(a.c2_inv_4_10, 0), 2),
            ROUND(a.c2_sales_11_40 / NULLIF(a.c2_inv_11_40, 0), 2),
            ROUND(a.c2_sales_41_plus / NULLIF(a.c2_inv_41_plus, 0), 2),
            ROUND(a.tot_c2_sales / NULLIF(a.tot_c2_inv, 0), 2),
            10
        FROM agg a

        UNION ALL

        SELECT 
            'c2_abc'::VARCHAR,
            'abc_companies'::VARCHAR,
            '🟢 ABC (> границі): Клієнти'::VARCHAR,
            a.abc_comp_1, a.abc_comp_2_3, a.abc_comp_4_10, a.abc_comp_11_40, a.abc_comp_41_plus, a.tot_abc_comp,
            11
        FROM agg a

        UNION ALL

        SELECT 
            'c2_abc'::VARCHAR,
            'abc_companies_pct'::VARCHAR,
            '🟢 ABC: % від клієнтів ABC'::VARCHAR,
            ROUND(a.abc_comp_1 * 100.0 / NULLIF(a.tot_abc_comp, 0), 1),
            ROUND(a.abc_comp_2_3 * 100.0 / NULLIF(a.tot_abc_comp, 0), 1),
            ROUND(a.abc_comp_4_10 * 100.0 / NULLIF(a.tot_abc_comp, 0), 1),
            ROUND(a.abc_comp_11_40 * 100.0 / NULLIF(a.tot_abc_comp, 0), 1),
            ROUND(a.abc_comp_41_plus * 100.0 / NULLIF(a.tot_abc_comp, 0), 1),
            100.0,
            12
        FROM agg a

        UNION ALL

        SELECT 
            'c2_abc'::VARCHAR,
            'abc_sales'::VARCHAR,
            '🟢 ABC: Сума продажів (₴)'::VARCHAR,
            ROUND(a.abc_sales_1, 2), ROUND(a.abc_sales_2_3, 2), ROUND(a.abc_sales_4_10, 2), ROUND(a.abc_sales_11_40, 2), ROUND(a.abc_sales_41_plus, 2), ROUND(a.tot_abc_sales, 2),
            13
        FROM agg a

        UNION ALL

        SELECT 
            'c2_abc'::VARCHAR,
            'abc_avg_ticket'::VARCHAR,
            '🟢 ABC: Середній чек (₴)'::VARCHAR,
            ROUND(a.abc_sales_1 / NULLIF(a.abc_inv_1, 0), 2),
            ROUND(a.abc_sales_2_3 / NULLIF(a.abc_inv_2_3, 0), 2),
            ROUND(a.abc_sales_4_10 / NULLIF(a.abc_inv_4_10, 0), 2),
            ROUND(a.abc_sales_11_40 / NULLIF(a.abc_inv_11_40, 0), 2),
            ROUND(a.abc_sales_41_plus / NULLIF(a.abc_inv_41_plus, 0), 2),
            ROUND(a.tot_abc_sales / NULLIF(a.tot_abc_inv, 0), 2),
            14
        FROM agg a

        -- ==================== 3. ДИНАМІЧНИЙ СЛОЙ ====================
        UNION ALL

        SELECT 
            'dynamic'::VARCHAR,
            'new_companies'::VARCHAR,
            '🆕 Нові клієнти (Status ID = 1)'::VARCHAR,
            a.new_comp_1, a.new_comp_2_3, a.new_comp_4_10, a.new_comp_11_40, a.new_comp_41_plus, a.tot_new_comp,
            15
        FROM agg a

        UNION ALL

        SELECT 
            'dynamic'::VARCHAR,
            'new_companies_pct'::VARCHAR,
            '🆕 Нові: частка в групі (%)'::VARCHAR,
            ROUND(a.new_comp_1 * 100.0 / NULLIF(a.comp_1, 0), 1),
            ROUND(a.new_comp_2_3 * 100.0 / NULLIF(a.comp_2_3, 0), 1),
            ROUND(a.new_comp_4_10 * 100.0 / NULLIF(a.comp_4_10, 0), 1),
            ROUND(a.new_comp_11_40 * 100.0 / NULLIF(a.comp_11_40, 0), 1),
            ROUND(a.new_comp_41_plus * 100.0 / NULLIF(a.comp_41_plus, 0), 1),
            ROUND(a.tot_new_comp * 100.0 / NULLIF(a.tot_comp, 0), 1),
            16
        FROM agg a

        UNION ALL

        SELECT 
            'dynamic'::VARCHAR,
            'retained_companies'::VARCHAR,
            '🔄 Постійні / Утримані клієнти'::VARCHAR,
            a.ret_comp_1, a.ret_comp_2_3, a.ret_comp_4_10, a.ret_comp_11_40, a.ret_comp_41_plus, a.tot_ret_comp,
            17
        FROM agg a

        UNION ALL

        SELECT 
            'dynamic'::VARCHAR,
            'prev_companies'::VARCHAR,
            '📅 Клієнтів минулого року'::VARCHAR,
            pa.prev_comp_1, pa.prev_comp_2_3, pa.prev_comp_4_10, pa.prev_comp_11_40, pa.prev_comp_41_plus, pa.prev_tot_comp,
            18
        FROM prev_agg pa

        UNION ALL

        SELECT 
            'dynamic'::VARCHAR,
            'yoy_growth_pct'::VARCHAR,
            '📈 YoY приріст кількості клієнтів (%)'::VARCHAR,
            ROUND((a.comp_1 - pa.prev_comp_1) * 100.0 / NULLIF(pa.prev_comp_1, 0), 1),
            ROUND((a.comp_2_3 - pa.prev_comp_2_3) * 100.0 / NULLIF(pa.prev_comp_2_3, 0), 1),
            ROUND((a.comp_4_10 - pa.prev_comp_4_10) * 100.0 / NULLIF(pa.prev_comp_4_10, 0), 1),
            ROUND((a.comp_11_40 - pa.prev_comp_11_40) * 100.0 / NULLIF(pa.prev_comp_11_40, 0), 1),
            ROUND((a.comp_41_plus - pa.prev_comp_41_plus) * 100.0 / NULLIF(pa.prev_comp_41_plus, 0), 1),
            ROUND((a.tot_comp - pa.prev_tot_comp) * 100.0 / NULLIF(pa.prev_tot_comp, 0), 1),
            19
        FROM agg a, prev_agg pa
    ) sub
    ORDER BY sub.sort_order;
END;
$function$;
