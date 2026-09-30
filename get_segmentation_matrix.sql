CREATE OR REPLACE FUNCTION public.get_segmentation_matrix(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(section character varying, row_key character varying, row_label character varying, val_1 numeric, val_2_3 numeric, val_4_10 numeric, val_11_40 numeric, val_41_plus numeric, val_total numeric, sort_order integer)
 LANGUAGE plpgsql
 STABLE
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
$function$
