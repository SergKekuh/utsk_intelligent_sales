--
-- PostgreSQL database dump
--

\restrict fk0EK5bzdZWXIo6VCr9whFKOybbP7jBEBhxSeCMfsJTlCXI7T33nc1ndY3yIiEA

-- Dumped from database version 18.4 (Ubuntu 18.4-0ubuntu0.26.04.1)
-- Dumped by pg_dump version 18.4 (Ubuntu 18.4-0ubuntu0.26.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: calculate_client_direction(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_client_direction(p_client_code character varying) RETURNS TABLE(direction_id integer, confidence numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH direction_totals AS (
        SELECT COALESCE(p.anchor_direction_id, 9) AS dir_id, SUM(sl.amount) AS total FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id JOIN products p ON sl.product_code = p.code
        WHERE d.client_code = p_client_code GROUP BY dir_id
    ),
    total_sum AS (SELECT SUM(total) AS grand_total FROM direction_totals)
    SELECT dt.dir_id, ROUND((dt.total / ts.grand_total * 100)::NUMERIC, 2) FROM direction_totals dt, total_sum ts ORDER BY dt.total DESC LIMIT 1;
END;
$$;


--
-- Name: calculate_client_status(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_client_status(p_client_code character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_current_year_count INT;
    v_prev_year_count INT;
    v_days_since_last INT;
    v_status_id INT;
    v_rule RECORD;
BEGIN
    SELECT COUNT(*) INTO v_current_year_count FROM documents WHERE client_code = p_client_code AND EXTRACT(YEAR FROM invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE);
    SELECT COUNT(*) INTO v_prev_year_count FROM documents WHERE client_code = p_client_code AND EXTRACT(YEAR FROM invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1;
    SELECT (CURRENT_DATE - MAX(invoice_date))::INT INTO v_days_since_last FROM documents WHERE client_code = p_client_code;
    
    FOR v_rule IN SELECT * FROM status_rules ORDER BY priority LOOP
        IF (v_rule.min_current_year IS NULL OR v_current_year_count >= v_rule.min_current_year) AND (v_rule.max_current_year IS NULL OR v_current_year_count <= v_rule.max_current_year) AND (v_rule.min_prev_year IS NULL OR v_prev_year_count >= v_rule.min_prev_year) AND (v_rule.max_prev_year IS NULL OR v_prev_year_count <= v_rule.max_prev_year) AND (v_rule.min_days_since_last_purchase IS NULL OR v_days_since_last >= v_rule.min_days_since_last_purchase) THEN
             v_status_id := v_rule.id;
             EXIT;
        END IF;
    END LOOP;
    RETURN v_status_id;
END;
$$;


--
-- Name: calculate_client_year_activity(integer, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.calculate_client_year_activity(p_year integer, p_client_code character varying DEFAULT NULL::character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    WITH year_data AS (
        SELECT 
            d.client_code,
            p_year AS sales_year,
            COALESCE(SUM(sl.amount), 0) AS total_revenue,
            COALESCE(SUM(CASE WHEN p.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
            COUNT(DISTINCT d.id) AS total_docs
        FROM documents d
        LEFT JOIN sales_lines sl ON d.id = sl.document_id
        LEFT JOIN products p ON sl.product_code = p.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND (p_client_code IS NULL OR d.client_code = p_client_code)
        GROUP BY d.client_code
    )
    INSERT INTO client_year_activity (
        client_code, sales_year, total_revenue, goods_revenue, total_docs, 
        is_active, activation_reason, deactivation_reason
    )
    SELECT 
        yd.client_code, yd.sales_year, yd.total_revenue, yd.goods_revenue, yd.total_docs,
        CASE WHEN yd.goods_revenue >= 1000 THEN TRUE ELSE FALSE END,
        CASE WHEN yd.goods_revenue >= 1000 THEN 'Авто: Оборот товаров > 1000' ELSE NULL END,
        CASE 
            WHEN yd.goods_revenue < 1000 AND yd.goods_revenue > 0 THEN 'Авто: Оборот ниже порога'
            WHEN yd.goods_revenue = 0 AND yd.total_revenue > 0 THEN 'Авто: Только услуги'
            WHEN yd.total_revenue = 0 THEN 'Авто: Нет покупок'
            ELSE NULL 
        END
    FROM year_data yd
    ON CONFLICT (client_code, sales_year) DO UPDATE SET 
        total_revenue = EXCLUDED.total_revenue,
        goods_revenue = EXCLUDED.goods_revenue,
        total_docs = EXCLUDED.total_docs,
        is_active = CASE WHEN client_year_activity.is_manual THEN client_year_activity.is_active ELSE EXCLUDED.is_active END,
        activation_reason = CASE WHEN client_year_activity.is_manual THEN client_year_activity.activation_reason ELSE EXCLUDED.activation_reason END,
        deactivation_reason = CASE WHEN client_year_activity.is_manual THEN client_year_activity.deactivation_reason ELSE EXCLUDED.deactivation_reason END,
        updated_at = CURRENT_TIMESTAMP;

    WITH active_agg AS (
        SELECT client_code, ARRAY_AGG(sales_year ORDER BY sales_year) AS arr,
               BOOL_OR(sales_year = EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER AND is_active = TRUE) AS cur
        FROM client_year_activity
        WHERE is_active = TRUE AND (p_client_code IS NULL OR client_code = p_client_code)
        GROUP BY client_code
    )
    UPDATE clients c SET 
        active_years = COALESCE(agg.arr, '{}'),
        is_active_current = COALESCE(agg.cur, FALSE),
        analysis_updated_at = CURRENT_TIMESTAMP
    FROM active_agg agg WHERE c.code = agg.client_code;
END;
$$;


--
-- Name: generate_custom_sales_report(integer, numeric, numeric, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.generate_custom_sales_report(p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer, p_multiplier numeric DEFAULT 1.0, p_limit_price numeric DEFAULT 146000, p_direction character varying DEFAULT 'below'::character varying) RETURNS TABLE(out_group_name character varying, out_metric character varying, out_1 numeric, out_2_3 numeric, out_4_10 numeric, out_11_40 numeric, out_41_170 numeric, out_171_plus numeric, out_total numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_label VARCHAR;
    v_grand_total_sales NUMERIC;
BEGIN
    DROP TABLE IF EXISTS temp_pivot;
    
    IF p_direction = 'above' THEN
        v_label := 'ABC';
    ELSE
        v_label := NULL;
    END IF;
    
    CREATE TEMP TABLE temp_pivot AS
    WITH client_transactional_stats AS (
    SELECT 
        d.client_code,
        COUNT(DISTINCT d.id) AS invoices_count,
        COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE  -- 🔥 ДОБАВИТЬ ЭТУ СТРОКУ
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
    GROUP BY d.client_code
),
    client_categorized AS (
        SELECT 
            goods_revenue,
            invoices_count,
            CASE
                WHEN p_direction = 'above' THEN v_label
                WHEN goods_revenue >= 3000000 * p_multiplier THEN 'A1'
                WHEN goods_revenue >= 2000000 * p_multiplier THEN 'A2'
                WHEN goods_revenue >= 1500000 * p_multiplier THEN 'A3'
                WHEN goods_revenue >= 1000000 * p_multiplier THEN 'B1'
                WHEN goods_revenue >= 500000  * p_multiplier THEN 'B2'
                WHEN goods_revenue >= 150000  * p_multiplier THEN 'C1'
                WHEN goods_revenue >= 1000    * p_multiplier THEN 'C2'
                ELSE 'Other'
            END AS abc_group,
            CASE 
                WHEN invoices_count = 1 THEN '1'
                WHEN invoices_count BETWEEN 2 AND 3 THEN '2-3'
                WHEN invoices_count BETWEEN 4 AND 10 THEN '4-10'
                WHEN invoices_count BETWEEN 11 AND 40 THEN '11-40'
                WHEN invoices_count BETWEEN 41 AND 170 THEN '41-170'
                WHEN invoices_count >= 171 THEN '>170'
                ELSE '0'
            END AS inv_range
        FROM client_transactional_stats
        WHERE 
            (p_direction = 'below' AND goods_revenue < p_limit_price)
            OR
            (p_direction = 'above' AND goods_revenue >= p_limit_price)
    )
    SELECT 
        abc_group AS group_name,
        inv_range AS invoices_range,
        COUNT(*) AS companies,
        SUM(invoices_count) AS total_invoices,
        SUM(goods_revenue) AS total_sales,
        ROUND(SUM(goods_revenue) / NULLIF(SUM(invoices_count), 0), 2) AS avg_sales
    FROM client_categorized
    WHERE abc_group != 'Other'
    GROUP BY abc_group, inv_range;

    -- Общая сумма для percent_share
    SELECT SUM(tp.total_sales) INTO v_grand_total_sales FROM temp_pivot tp;

    RETURN QUERY
    SELECT 
        sub.grp::VARCHAR,
        sub.met::VARCHAR,
        sub.c1, sub.c2, sub.c3, sub.c4, sub.c5, sub.c6, sub.tot
    FROM (
        -- Строка: количество накладных
        SELECT 
            'Всего'::VARCHAR AS grp,
            'Накладных'::VARCHAR AS met,
            COALESCE(SUM(tp.total_invoices) FILTER (WHERE tp.invoices_range = '1'), 0)::NUMERIC AS c1,
            COALESCE(SUM(tp.total_invoices) FILTER (WHERE tp.invoices_range = '2-3'), 0)::NUMERIC AS c2,
            COALESCE(SUM(tp.total_invoices) FILTER (WHERE tp.invoices_range = '4-10'), 0)::NUMERIC AS c3,
            COALESCE(SUM(tp.total_invoices) FILTER (WHERE tp.invoices_range = '11-40'), 0)::NUMERIC AS c4,
            COALESCE(SUM(tp.total_invoices) FILTER (WHERE tp.invoices_range = '41-170'), 0)::NUMERIC AS c5,
            COALESCE(SUM(tp.total_invoices) FILTER (WHERE tp.invoices_range = '>170'), 0)::NUMERIC AS c6,
            COALESCE(SUM(tp.total_invoices), 0)::NUMERIC AS tot,
            0 AS s1, 0 AS s2
        FROM temp_pivot tp
        
        UNION ALL
        
        -- Строки: количество компаний
        SELECT 
            tp.group_name::VARCHAR,
            'Кол-во компаний'::VARCHAR,
            COALESCE(SUM(tp.companies) FILTER (WHERE tp.invoices_range = '1'), 0)::NUMERIC,
            COALESCE(SUM(tp.companies) FILTER (WHERE tp.invoices_range = '2-3'), 0)::NUMERIC,
            COALESCE(SUM(tp.companies) FILTER (WHERE tp.invoices_range = '4-10'), 0)::NUMERIC,
            COALESCE(SUM(tp.companies) FILTER (WHERE tp.invoices_range = '11-40'), 0)::NUMERIC,
            COALESCE(SUM(tp.companies) FILTER (WHERE tp.invoices_range = '41-170'), 0)::NUMERIC,
            COALESCE(SUM(tp.companies) FILTER (WHERE tp.invoices_range = '>170'), 0)::NUMERIC,
            COALESCE(SUM(tp.companies), 0)::NUMERIC,
            CASE WHEN p_direction = 'above' THEN 1 ELSE CASE tp.group_name WHEN 'A1' THEN 1 WHEN 'A2' THEN 2 WHEN 'A3' THEN 3 WHEN 'B1' THEN 4 WHEN 'B2' THEN 5 WHEN 'C1' THEN 6 WHEN 'C2' THEN 7 ELSE 9 END END,
            1
        FROM temp_pivot tp
        GROUP BY tp.group_name
        
        UNION ALL
        
        -- Строки: сумма продаж
        SELECT 
            tp.group_name::VARCHAR,
            'Сумма продаж'::VARCHAR,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '1'), 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '2-3'), 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '4-10'), 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '11-40'), 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '41-170'), 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '>170'), 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales), 0), 2)::NUMERIC,
            CASE WHEN p_direction = 'above' THEN 1 ELSE CASE tp.group_name WHEN 'A1' THEN 1 WHEN 'A2' THEN 2 WHEN 'A3' THEN 3 WHEN 'B1' THEN 4 WHEN 'B2' THEN 5 WHEN 'C1' THEN 6 WHEN 'C2' THEN 7 ELSE 9 END END,
            2
        FROM temp_pivot tp
        GROUP BY tp.group_name
        
        UNION ALL
        
        -- Строки: средний чек
        SELECT 
            tp.group_name::VARCHAR,
            'Средний чек'::VARCHAR,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '1') / NULLIF(SUM(tp.total_invoices) FILTER (WHERE tp.invoices_range = '1'), 0), 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '2-3') / NULLIF(SUM(tp.total_invoices) FILTER (WHERE tp.invoices_range = '2-3'), 0), 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '4-10') / NULLIF(SUM(tp.total_invoices) FILTER (WHERE tp.invoices_range = '4-10'), 0), 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '11-40') / NULLIF(SUM(tp.total_invoices) FILTER (WHERE tp.invoices_range = '11-40'), 0), 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '41-170') / NULLIF(SUM(tp.total_invoices) FILTER (WHERE tp.invoices_range = '41-170'), 0), 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '>170') / NULLIF(SUM(tp.total_invoices) FILTER (WHERE tp.invoices_range = '>170'), 0), 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) / NULLIF(SUM(tp.total_invoices), 0), 0), 2)::NUMERIC,
            CASE WHEN p_direction = 'above' THEN 1 ELSE CASE tp.group_name WHEN 'A1' THEN 1 WHEN 'A2' THEN 2 WHEN 'A3' THEN 3 WHEN 'B1' THEN 4 WHEN 'B2' THEN 5 WHEN 'C1' THEN 6 WHEN 'C2' THEN 7 ELSE 9 END END,
            3
        FROM temp_pivot tp
        GROUP BY tp.group_name
        
        UNION ALL
        
        -- Строки: доля в %
        SELECT 
            tp.group_name::VARCHAR,
            '% от общ'::VARCHAR,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '1') / NULLIF(v_grand_total_sales, 0) * 100, 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '2-3') / NULLIF(v_grand_total_sales, 0) * 100, 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '4-10') / NULLIF(v_grand_total_sales, 0) * 100, 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '11-40') / NULLIF(v_grand_total_sales, 0) * 100, 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '41-170') / NULLIF(v_grand_total_sales, 0) * 100, 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) FILTER (WHERE tp.invoices_range = '>170') / NULLIF(v_grand_total_sales, 0) * 100, 0), 2)::NUMERIC,
            ROUND(COALESCE(SUM(tp.total_sales) / NULLIF(v_grand_total_sales, 0) * 100, 0), 2)::NUMERIC,
            CASE WHEN p_direction = 'above' THEN 1 ELSE CASE tp.group_name WHEN 'A1' THEN 1 WHEN 'A2' THEN 2 WHEN 'A3' THEN 3 WHEN 'B1' THEN 4 WHEN 'B2' THEN 5 WHEN 'C1' THEN 6 WHEN 'C2' THEN 7 ELSE 9 END END,
            4
        FROM temp_pivot tp
        GROUP BY tp.group_name
        
        UNION ALL
        
        -- Итого
        SELECT 
            'Total'::VARCHAR,
            'Итого'::VARCHAR,
            COALESCE(SUM(tp.companies) FILTER (WHERE tp.invoices_range = '1'), 0)::NUMERIC,
            COALESCE(SUM(tp.companies) FILTER (WHERE tp.invoices_range = '2-3'), 0)::NUMERIC,
            COALESCE(SUM(tp.companies) FILTER (WHERE tp.invoices_range = '4-10'), 0)::NUMERIC,
            COALESCE(SUM(tp.companies) FILTER (WHERE tp.invoices_range = '11-40'), 0)::NUMERIC,
            COALESCE(SUM(tp.companies) FILTER (WHERE tp.invoices_range = '41-170'), 0)::NUMERIC,
            COALESCE(SUM(tp.companies) FILTER (WHERE tp.invoices_range = '>170'), 0)::NUMERIC,
            COALESCE(SUM(tp.companies), 0)::NUMERIC,
            8, 0
        FROM temp_pivot tp
    ) sub
    ORDER BY sub.s1, sub.s2;

    DROP TABLE IF EXISTS temp_pivot;
END;
$$;


--
-- Name: get_abc_groups(integer, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_abc_groups(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9) RETURNS TABLE(out_group_name character varying, out_total_sales numeric, out_total_companies bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    DROP TABLE IF EXISTS temp_group_report;

    CREATE TEMP TABLE temp_group_report AS
    SELECT 
        grp AS group_name,
        SUM(goods_revenue) AS total_sales,
        COUNT(*) AS total_companies
    FROM (
        SELECT 
            goods_revenue,
            CASE
                WHEN goods_revenue >= 3000000 * p_multiplier THEN 'A1'
                WHEN goods_revenue >= 2000000 * p_multiplier THEN 'A2'
                WHEN goods_revenue >= 1500000 * p_multiplier THEN 'A3'
                WHEN goods_revenue >= 1000000 * p_multiplier THEN 'B1'
                WHEN goods_revenue >= 500000  * p_multiplier THEN 'B2'
                WHEN goods_revenue >= 150000  * p_multiplier THEN 'C1'
                WHEN goods_revenue >= 1000    * p_multiplier THEN 'C2'
                ELSE 'Other'
            END AS grp
        FROM (
            SELECT 
                d.client_code,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            -- 🔥 ТОЛЬКО АКТИВНЫЕ КЛИЕНТЫ
            JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE
            WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
            GROUP BY d.client_code
        ) client_revenue
        WHERE goods_revenue IS NOT NULL
    ) grouped_data
    WHERE grp != 'Other'
    GROUP BY grp
    ORDER BY 
        CASE grp
            WHEN 'A1' THEN 1 WHEN 'A2' THEN 2 WHEN 'A3' THEN 3
            WHEN 'B1' THEN 4 WHEN 'B2' THEN 5
            WHEN 'C1' THEN 6 WHEN 'C2' THEN 7
            ELSE 8
        END;

    INSERT INTO temp_group_report (group_name, total_sales, total_companies)
    SELECT 'Total', SUM(t.total_sales), SUM(t.total_companies)
    FROM temp_group_report t;

    RETURN QUERY 
    SELECT 
        t.group_name::VARCHAR,
        ROUND(t.total_sales, 2)::NUMERIC,
        t.total_companies::BIGINT
    FROM temp_group_report t
    ORDER BY 
        CASE t.group_name
            WHEN 'A1' THEN 1 WHEN 'A2' THEN 2 WHEN 'A3' THEN 3
            WHEN 'B1' THEN 4 WHEN 'B2' THEN 5
            WHEN 'C1' THEN 6 WHEN 'C2' THEN 7
            WHEN 'Total' THEN 8
            ELSE 9
        END;

    DROP TABLE IF EXISTS temp_group_report;
END;
$$;


--
-- Name: get_abc_segmentation(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_abc_segmentation(p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer) RETURNS TABLE(out_group_name text, out_total_sales numeric, out_total_companies bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH client_revenue AS (
        SELECT 
            c.code,
            COALESCE(SUM(d.total_amount), 0) AS annual_revenue
        FROM clients c
        LEFT JOIN documents d ON c.code = d.client_code 
            AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY c.code
    ),
    grouped AS (
        SELECT 
            CASE
                WHEN annual_revenue >= 3000000 THEN 'A1'
                WHEN annual_revenue >= 2000000 THEN 'A2'
                WHEN annual_revenue >= 1500000 THEN 'A3'
                WHEN annual_revenue >= 1000000 THEN 'B1'
                WHEN annual_revenue >= 500000  THEN 'B2'
                WHEN annual_revenue >= 150000  THEN 'C1'
                WHEN annual_revenue >= 1000    THEN 'C2'
                ELSE 'Other'
            END AS seg_group,
            annual_revenue
        FROM client_revenue
        WHERE annual_revenue > 0
    ),
    result AS (
        SELECT 
            seg_group AS group_name,
            SUM(annual_revenue)::NUMERIC AS total_sales,
            COUNT(*)::BIGINT AS total_companies
        FROM grouped
        WHERE seg_group != 'Other'
        GROUP BY seg_group
        
        UNION ALL
        
        SELECT 
            'Total'::TEXT,
            SUM(annual_revenue)::NUMERIC,
            COUNT(*)::BIGINT
        FROM grouped
        WHERE seg_group != 'Other'
    )
    SELECT 
        r.group_name,
        r.total_sales,
        r.total_companies
    FROM result r
    ORDER BY 
        CASE r.group_name
            WHEN 'A1' THEN 1 WHEN 'A2' THEN 2 WHEN 'A3' THEN 3
            WHEN 'B1' THEN 4 WHEN 'B2' THEN 5
            WHEN 'C1' THEN 6 WHEN 'C2' THEN 7
            ELSE 8
        END;
END;
$$;


--
-- Name: get_abc_segmentation(integer, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_abc_segmentation(p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer, p_multiplier numeric DEFAULT 1.0) RETURNS TABLE(out_group_name text, out_total_sales numeric, out_total_companies bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    WITH client_revenue AS (
        SELECT 
            c.code,
            COALESCE(SUM(d.total_amount), 0) AS annual_revenue
        FROM clients c
        LEFT JOIN documents d ON c.code = d.client_code 
            AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY c.code
    ),
    grouped AS (
        SELECT 
            CASE
                WHEN annual_revenue >= 3000000 * p_multiplier THEN 'A1'
                WHEN annual_revenue >= 2000000 * p_multiplier THEN 'A2'
                WHEN annual_revenue >= 1500000 * p_multiplier THEN 'A3'
                WHEN annual_revenue >= 1000000 * p_multiplier THEN 'B1'
                WHEN annual_revenue >= 500000  * p_multiplier THEN 'B2'
                WHEN annual_revenue >= 150000  * p_multiplier THEN 'C1'
                WHEN annual_revenue >= 1000    * p_multiplier THEN 'C2'
                ELSE 'Other'
            END AS seg_group,
            annual_revenue
        FROM client_revenue
        WHERE annual_revenue > 0
    ),
    result AS (
        SELECT 
            seg_group AS group_name,
            SUM(annual_revenue)::NUMERIC AS total_sales,
            COUNT(*)::BIGINT AS total_companies
        FROM grouped
        WHERE seg_group != 'Other'
        GROUP BY seg_group
        
        UNION ALL
        
        SELECT 
            'Total'::TEXT,
            SUM(annual_revenue)::NUMERIC,
            COUNT(*)::BIGINT
        FROM grouped
        WHERE seg_group != 'Other'
    )
    SELECT 
        r.group_name,
        r.total_sales,
        r.total_companies
    FROM result r
    ORDER BY 
        CASE r.group_name
            WHEN 'A1' THEN 1 WHEN 'A2' THEN 2 WHEN 'A3' THEN 3
            WHEN 'B1' THEN 4 WHEN 'B2' THEN 5
            WHEN 'C1' THEN 6 WHEN 'C2' THEN 7
            ELSE 8
        END;
END;
$$;


--
-- Name: get_abc_segmentation_v2(integer, numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_abc_segmentation_v2(p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer, p_multiplier numeric DEFAULT 1.0) RETURNS TABLE(group_name character varying, total_sales numeric, total_companies bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN
    DROP TABLE IF EXISTS temp_group_report;

    CREATE TEMP TABLE temp_group_report AS
    SELECT 
        group_name,
        SUM(goods_revenue) AS total_sales,
        COUNT(*) AS total_companies
    FROM (
        SELECT 
            cts.goods_revenue,
            CASE
                WHEN cts.goods_revenue >= 3000000 * p_multiplier THEN 'A1'
                WHEN cts.goods_revenue >= 2000000 * p_multiplier THEN 'A2'
                WHEN cts.goods_revenue >= 1500000 * p_multiplier THEN 'A3'
                WHEN cts.goods_revenue >= 1000000 * p_multiplier THEN 'B1'
                WHEN cts.goods_revenue >= 500000  * p_multiplier THEN 'B2'
                WHEN cts.goods_revenue >= 150000  * p_multiplier THEN 'C1'
                WHEN cts.goods_revenue >= 1000                    THEN 'C2'
                ELSE 'Other'
            END AS group_name
        FROM (
            -- Чистая товарная выручка (без услуг) по активным клиентам
            SELECT 
                d.client_code,
                COALESCE(SUM(CASE WHEN p.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products p ON sl.product_code = p.code
            WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
            GROUP BY d.client_code
        ) cts
        WHERE cts.goods_revenue IS NOT NULL
    ) grouped_data
    WHERE group_name != 'Other'
    GROUP BY group_name
    ORDER BY 
        CASE group_name
            WHEN 'A1' THEN 1 WHEN 'A2' THEN 2 WHEN 'A3' THEN 3
            WHEN 'B1' THEN 4 WHEN 'B2' THEN 5
            WHEN 'C1' THEN 6 WHEN 'C2' THEN 7
            ELSE 8
        END;

    -- Итоговая строка
    INSERT INTO temp_group_report (group_name, total_sales, total_companies)
    SELECT 'Total', SUM(total_sales), SUM(total_companies)
    FROM temp_group_report;

    -- Возврат результата
    RETURN QUERY 
    SELECT 
        t.group_name::VARCHAR,
        ROUND(t.total_sales, 2)::NUMERIC,
        t.total_companies::BIGINT
    FROM temp_group_report t
    ORDER BY 
        CASE t.group_name
            WHEN 'A1' THEN 1 WHEN 'A2' THEN 2 WHEN 'A3' THEN 3
            WHEN 'B1' THEN 4 WHEN 'B2' THEN 5
            WHEN 'C1' THEN 6 WHEN 'C2' THEN 7
            WHEN 'Total' THEN 8
            ELSE 9
        END;

    DROP TABLE IF EXISTS temp_group_report;
END;
$$;


--
-- Name: get_companies_by_funnel_stage(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.get_companies_by_funnel_stage(stage_name character varying) RETURNS TABLE(company_code character varying, company_name character varying, invoice_count integer, clean_goods_revenue numeric, services_revenue numeric, overall_revenue numeric, segment_group character varying)
    LANGUAGE sql
    AS $$
    SELECT 
        v.client_code::VARCHAR AS company_code,
        v.client_name::VARCHAR AS company_name,
        v.doc_count::INT AS invoice_count,
        v.goods_revenue::NUMERIC AS clean_goods_revenue,
        v.services_revenue::NUMERIC AS services_revenue,
        v.total_revenue::NUMERIC AS overall_revenue,
        v.detailed_segment::VARCHAR AS segment_group
    FROM view_client_segmentation_details_2026 v
    WHERE 
        v.primary_status = stage_name 
        OR v.detailed_segment = stage_name
        OR (stage_name = 'Все новые' AND v.doc_count > 0)
    ORDER BY v.goods_revenue DESC;
$$;


--
-- Name: log_status_change(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.log_status_change() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (OLD.current_status_id IS DISTINCT FROM NEW.current_status_id) THEN
        INSERT INTO status_change_log (client_code, old_status_id, new_status_id, changed_by, change_reason)
        VALUES (NEW.code, OLD.current_status_id, NEW.current_status_id, 'SYSTEM', 'Автоматический пересчет');
        NEW.status_history = NEW.status_history || jsonb_build_object('date', CURRENT_TIMESTAMP, 'old_status', OLD.current_status_id, 'new_status', NEW.current_status_id);
    END IF;
    RETURN NEW;
END;
$$;


--
-- Name: parse_pipe_attributes(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.parse_pipe_attributes(p_name character varying) RETURNS TABLE(diameter numeric, wall numeric, prof_w numeric, prof_h numeric, is_prof boolean, standard character varying, weight_m numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    dims TEXT[];
BEGIN
    standard := substring(p_name from '(ГОСТ\s*\d+[-\s]*\d*|ДСТУ\s*\d+[:\d]*|GB/T\s*\d+[:\d]*|EN\s*\d+[-\d]*)');
    
    IF p_name ~* 'проф|profile' THEN
        is_prof := TRUE;
        dims := regexp_matches(p_name, '(\d+(?:\.\d+)?)\s*[xх×]\s*(\d+(?:\.\d+)?)\s*[xх×]\s*(\d+(?:\.\d+)?)');
        IF dims IS NOT NULL THEN
            prof_w := dims[1]::NUMERIC;
            prof_h := dims[2]::NUMERIC;
            wall := dims[3]::NUMERIC;
            diameter := GREATEST(prof_w, prof_h);
        END IF;
    ELSE
        is_prof := FALSE;
        dims := regexp_matches(p_name, '(\d+(?:\.\d+)?)\s*[xх×]\s*(\d+(?:\.\d+)?)');
        IF dims IS NOT NULL THEN
            diameter := dims[1]::NUMERIC;
            wall := dims[2]::NUMERIC;
        END IF;
    END IF;
    
    IF diameter IS NOT NULL AND wall IS NOT NULL AND NOT is_prof THEN
        weight_m := ROUND((PI() * (diameter - wall) * wall * 7850 / 1000000)::NUMERIC, 3);
    END IF;
    
    RETURN NEXT;
END;
$$;


--
-- Name: penalize_rejected_product(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.penalize_rejected_product() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO product_scoring (client_code, product_code, negative_reinforcement)
    VALUES (NEW.client_code, NEW.product_code, 3)
    ON CONFLICT (client_code, product_code) 
    DO UPDATE SET 
        negative_reinforcement = product_scoring.negative_reinforcement + 3,
        updated_at = CURRENT_TIMESTAMP;
    
    UPDATE product_scoring 
    SET is_blocked = TRUE, blocked_until = CURRENT_DATE + INTERVAL '30 days'
    WHERE client_code = NEW.client_code AND product_code = NEW.product_code AND current_weight < 0;
    
    RETURN NEW;
END;
$$;


--
-- Name: reward_added_product(character varying, character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.reward_added_product(p_client_code character varying, p_product_code character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
    INSERT INTO product_scoring (client_code, product_code, positive_reinforcement)
    VALUES (p_client_code, p_product_code, 5)
    ON CONFLICT (client_code, product_code) 
    DO UPDATE SET 
        positive_reinforcement = product_scoring.positive_reinforcement + 5,
        is_blocked = FALSE, blocked_until = NULL, updated_at = CURRENT_TIMESTAMP;
END;
$$;


--
-- Name: trg_update_client_activity(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.trg_update_client_activity() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_year INTEGER;
    v_client_code VARCHAR;
    v_doc_id INTEGER;
BEGIN
    -- Определяем ID документа (защита от DELETE)
    IF (TG_OP = 'DELETE') THEN
        v_doc_id := OLD.document_id;
    ELSE
        v_doc_id := NEW.document_id;
    END IF;

    -- Если документа нет, выходим
    IF v_doc_id IS NULL THEN RETURN NULL; END IF;

    -- Находим год и клиента
    SELECT EXTRACT(YEAR FROM invoice_date)::INTEGER, client_code 
    INTO v_year, v_client_code
    FROM documents WHERE id = v_doc_id;
    
    -- Вызываем точечный пересчет
    IF FOUND THEN
        PERFORM calculate_client_year_activity(v_year, v_client_code);
    END IF;
    
    RETURN NULL;
END;
$$;


--
-- Name: update_client_analytics(character varying); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_client_analytics(p_client_code character varying DEFAULT NULL::character varying) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_client RECORD;
    v_dir RECORD;
BEGIN
    FOR v_client IN SELECT code FROM clients WHERE (p_client_code IS NULL OR code = p_client_code) LOOP
        UPDATE clients SET
            first_purchase_date = (SELECT MIN(invoice_date) FROM documents WHERE client_code = v_client.code),
            last_purchase_date = (SELECT MAX(invoice_date) FROM documents WHERE client_code = v_client.code),
            current_status_id = calculate_client_status(v_client.code),
            requires_survey = CASE WHEN calculate_client_status(v_client.code) = (SELECT id FROM status_rules WHERE status_name = 'Новые') THEN TRUE ELSE FALSE END
        WHERE code = v_client.code;
        
        FOR v_dir IN SELECT * FROM calculate_client_direction(v_client.code) LOOP
            UPDATE clients SET activity_direction_id = v_dir.direction_id, direction_confidence = v_dir.confidence WHERE code = v_client.code AND is_direction_manual = FALSE;
        END LOOP;
    END LOOP;
END;
$$;


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: ab_tests; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.ab_tests (
    id integer NOT NULL,
    test_name character varying(100) NOT NULL,
    variant character(1) NOT NULL,
    content jsonb NOT NULL,
    impressions integer DEFAULT 0,
    clicks integer DEFAULT 0,
    add_to_cart integer DEFAULT 0,
    ctr numeric(5,2) GENERATED ALWAYS AS (
CASE
    WHEN (impressions > 0) THEN round((((clicks)::numeric / (impressions)::numeric) * (100)::numeric), 2)
    ELSE (0)::numeric
END) STORED,
    conversion_rate numeric(5,2) GENERATED ALWAYS AS (
CASE
    WHEN (impressions > 0) THEN round((((add_to_cart)::numeric / (impressions)::numeric) * (100)::numeric), 2)
    ELSE (0)::numeric
END) STORED,
    is_active boolean DEFAULT true,
    start_date date DEFAULT CURRENT_DATE,
    end_date date,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT ab_tests_add_to_cart_check CHECK ((add_to_cart >= 0)),
    CONSTRAINT ab_tests_clicks_check CHECK ((clicks >= 0)),
    CONSTRAINT ab_tests_impressions_check CHECK ((impressions >= 0)),
    CONSTRAINT ab_tests_variant_check CHECK ((variant = ANY (ARRAY['A'::bpchar, 'B'::bpchar, 'C'::bpchar])))
);


--
-- Name: TABLE ab_tests; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.ab_tests IS 'Полигон: A/B тестирование баннеров и офферов на сайте';


--
-- Name: ab_tests_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.ab_tests_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: ab_tests_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.ab_tests_id_seq OWNED BY public.ab_tests.id;


--
-- Name: activity_directions; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.activity_directions (
    id integer NOT NULL,
    name character varying(100) NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE activity_directions; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.activity_directions IS 'Справочник: Трубные сегменты рынка (ЖКХ, Нефтегаз, Стройка)';


--
-- Name: activity_directions_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.activity_directions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: activity_directions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.activity_directions_id_seq OWNED BY public.activity_directions.id;


--
-- Name: client_groups; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_groups (
    id integer NOT NULL,
    group_name character varying(100) NOT NULL,
    note text,
    created_at timestamp without time zone DEFAULT now()
);


--
-- Name: client_groups_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_groups_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_groups_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_groups_id_seq OWNED BY public.client_groups.id;


--
-- Name: client_year_activity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.client_year_activity (
    id bigint NOT NULL,
    client_code character varying(50) NOT NULL,
    sales_year integer NOT NULL,
    is_active boolean DEFAULT false,
    is_manual boolean DEFAULT false,
    activation_reason character varying(100),
    deactivation_reason character varying(100),
    total_revenue numeric(15,2) DEFAULT 0,
    goods_revenue numeric(15,2) DEFAULT 0,
    total_docs integer DEFAULT 0,
    abc_group character varying(5),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: client_year_activity_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.client_year_activity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: client_year_activity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.client_year_activity_id_seq OWNED BY public.client_year_activity.id;


--
-- Name: clients; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clients (
    code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    client_type character varying(50),
    current_status_id integer,
    status_history jsonb DEFAULT '[]'::jsonb,
    last_status_push_to_crm timestamp without time zone,
    first_purchase_date date,
    last_purchase_date date,
    activity_direction_id integer,
    direction_confidence numeric(5,2),
    is_direction_manual boolean DEFAULT false,
    requires_survey boolean DEFAULT false,
    survey_completed_at timestamp without time zone,
    survey_completed_by character varying(100),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    legacy_unit_id integer,
    okpo_code character varying(20),
    okpo_s1c8 character varying(20),
    ipn character varying(20),
    legal_entity_type character varying(50),
    full_unit_name text,
    group_id integer,
    active_years integer[] DEFAULT '{}'::integer[],
    is_active_current boolean DEFAULT false,
    analysis_updated_at timestamp without time zone,
    CONSTRAINT clients_direction_confidence_check CHECK (((direction_confidence >= (0)::numeric) AND (direction_confidence <= (100)::numeric)))
);


--
-- Name: TABLE clients; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.clients IS 'Личное дело: Статусы и направления (Тихая аналитика)';


--
-- Name: documents_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.documents_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: documents; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.documents (
    id bigint DEFAULT nextval('public.documents_id_seq'::regclass) NOT NULL,
    client_code character varying(50) NOT NULL,
    invoice_date date NOT NULL,
    total_amount numeric(15,2) DEFAULT 0.00,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    doc_number character varying(50),
    CONSTRAINT documents_total_amount_check CHECK ((total_amount >= (0)::numeric))
);


--
-- Name: historical_client_activity; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historical_client_activity (
    id bigint NOT NULL,
    client_code character varying(50) NOT NULL,
    sales_year integer NOT NULL,
    group_id integer,
    expense_invoices numeric(15,2) DEFAULT 0,
    sales_amount numeric(15,2) DEFAULT 0,
    note text,
    CONSTRAINT historical_client_activity_sales_year_check CHECK (((sales_year >= 2000) AND (sales_year <= 2100)))
);


--
-- Name: historical_client_activity_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.historical_client_activity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: historical_client_activity_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.historical_client_activity_id_seq OWNED BY public.historical_client_activity.id;


--
-- Name: manager_rejections_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.manager_rejections_log (
    id bigint NOT NULL,
    client_code character varying(50) NOT NULL,
    product_code character varying(50) NOT NULL,
    manager_login character varying(100),
    reject_reason text,
    document_id bigint,
    rejected_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE manager_rejections_log; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.manager_rejections_log IS 'Кладбище идей: Товары, удаленные менеджерами из рекомендаций';


--
-- Name: manager_rejections_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.manager_rejections_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: manager_rejections_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.manager_rejections_log_id_seq OWNED BY public.manager_rejections_log.id;


--
-- Name: product_aliases; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_aliases (
    id integer NOT NULL,
    product_code character varying(50) NOT NULL,
    alias_text character varying(255) NOT NULL,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: product_aliases_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_aliases_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_aliases_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_aliases_id_seq OWNED BY public.product_aliases.id;


--
-- Name: product_cross_sells; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_cross_sells (
    id integer NOT NULL,
    main_product_code character varying(50),
    related_product_code character varying(50),
    relation_type character varying(50)
);


--
-- Name: TABLE product_cross_sells; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.product_cross_sells IS 'Шпаргалка: Сопутствующие фитинги (Труба -> Фланец/Отвод)';


--
-- Name: product_cross_sells_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_cross_sells_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_cross_sells_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_cross_sells_id_seq OWNED BY public.product_cross_sells.id;


--
-- Name: product_scoring; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_scoring (
    id bigint NOT NULL,
    client_code character varying(50) NOT NULL,
    product_code character varying(50) NOT NULL,
    base_score integer DEFAULT 10,
    positive_reinforcement integer DEFAULT 0,
    negative_reinforcement integer DEFAULT 0,
    current_weight integer GENERATED ALWAYS AS (((base_score + positive_reinforcement) - negative_reinforcement)) STORED,
    is_blocked boolean DEFAULT false,
    blocked_until date,
    segment_agro_weight integer DEFAULT 0,
    segment_build_weight integer DEFAULT 0,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_current_weight CHECK (((((base_score + positive_reinforcement) - negative_reinforcement) >= '-100'::integer) AND (((base_score + positive_reinforcement) - negative_reinforcement) <= 1000))),
    CONSTRAINT product_scoring_base_score_check CHECK (((base_score >= 0) AND (base_score <= 100)))
);


--
-- Name: product_scoring_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_scoring_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_scoring_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_scoring_id_seq OWNED BY public.product_scoring.id;


--
-- Name: product_similarities; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.product_similarities (
    id bigint NOT NULL,
    source_product_code character varying(50) NOT NULL,
    similar_product_code character varying(50) NOT NULL,
    similarity_score numeric(5,2) DEFAULT 0,
    match_type character varying(50) NOT NULL,
    source_diameter numeric(10,2),
    source_wall numeric(10,2),
    similar_diameter numeric(10,2),
    similar_wall numeric(10,2)
);


--
-- Name: product_similarities_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.product_similarities_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: product_similarities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.product_similarities_id_seq OWNED BY public.product_similarities.id;


--
-- Name: production_lead_times; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.production_lead_times (
    id integer NOT NULL,
    product_code character varying(50) NOT NULL,
    from_blank_days integer,
    from_sheet_days integer,
    transit_days integer,
    alternative_blank_code character varying(50),
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: production_lead_times_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.production_lead_times_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: production_lead_times_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.production_lead_times_id_seq OWNED BY public.production_lead_times.id;


--
-- Name: products; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.products (
    code character varying(50) NOT NULL,
    name character varying(255) NOT NULL,
    anchor_direction_id integer,
    is_auto_tagged boolean DEFAULT false,
    material_grade character varying(50),
    is_new_arrival boolean DEFAULT false,
    in_stock_balance numeric(15,3) DEFAULT 0.00,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    diameter numeric(10,2),
    wall_thickness numeric(10,2),
    profile_width numeric(10,2),
    profile_height numeric(10,2),
    is_profile boolean DEFAULT false,
    standard_name character varying(100),
    weight_per_meter numeric(10,3),
    first_purchase_date date,
    last_purchase_date date,
    unit character varying(20) DEFAULT 'т'::character varying,
    is_service boolean DEFAULT false
);


--
-- Name: sales_lines; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.sales_lines (
    id bigint NOT NULL,
    document_id bigint NOT NULL,
    product_code character varying(50) NOT NULL,
    quantity numeric(15,3) NOT NULL,
    amount numeric(15,2) DEFAULT 0.00 NOT NULL,
    recorded_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT sales_lines_amount_check CHECK ((amount >= (0)::numeric)),
    CONSTRAINT sales_lines_quantity_check CHECK ((quantity > (0)::numeric))
);


--
-- Name: sales_lines_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.sales_lines_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: sales_lines_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.sales_lines_id_seq OWNED BY public.sales_lines.id;


--
-- Name: status_change_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.status_change_log (
    id bigint NOT NULL,
    client_code character varying(50) NOT NULL,
    old_status_id integer,
    new_status_id integer,
    changed_by character varying(50) NOT NULL,
    change_reason text,
    documents_count_current_year integer,
    documents_count_prev_year integer,
    changed_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: status_change_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.status_change_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: status_change_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.status_change_log_id_seq OWNED BY public.status_change_log.id;


--
-- Name: status_rules; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.status_rules (
    id integer NOT NULL,
    status_name character varying(50) NOT NULL,
    min_current_year integer,
    max_current_year integer,
    min_prev_year integer,
    max_prev_year integer,
    min_days_since_last_purchase integer,
    min_days_between_purchases integer,
    priority integer NOT NULL,
    description text,
    created_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE status_rules; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.status_rules IS 'Свод законов: Правила присвоения RFM-статусов (без спам-рассылок)';


--
-- Name: status_rules_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.status_rules_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: status_rules_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.status_rules_id_seq OWNED BY public.status_rules.id;


--
-- Name: v_abc_clients_detail; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_abc_clients_detail AS
 WITH cr AS (
         SELECT c.code,
            c.name,
            COALESCE(sr.status_name, 'Без статуса'::character varying) AS rfm_status,
            COALESCE(ad.name, 'Не определено'::character varying) AS direction,
            COALESCE(sum(sl.amount), (0)::numeric) AS annual_revenue,
            count(DISTINCT d.id) AS total_invoices
           FROM (((((public.clients c
             LEFT JOIN public.documents d ON ((((c.code)::text = (d.client_code)::text) AND (EXTRACT(year FROM d.invoice_date) = EXTRACT(year FROM CURRENT_DATE)))))
             LEFT JOIN public.sales_lines sl ON ((d.id = sl.document_id)))
             LEFT JOIN public.products p ON ((((sl.product_code)::text = (p.code)::text) AND (p.is_service = false))))
             LEFT JOIN public.status_rules sr ON ((c.current_status_id = sr.id)))
             LEFT JOIN public.activity_directions ad ON ((c.activity_direction_id = ad.id)))
          WHERE (c.is_active_current = true)
          GROUP BY c.code, c.name, sr.status_name, ad.name
        )
 SELECT code,
    name,
    rfm_status,
    direction,
    annual_revenue,
    total_invoices,
        CASE
            WHEN (annual_revenue >= (3000000)::numeric) THEN 'A1'::text
            WHEN (annual_revenue >= (2000000)::numeric) THEN 'A2'::text
            WHEN (annual_revenue >= (1500000)::numeric) THEN 'A3'::text
            WHEN (annual_revenue >= (1000000)::numeric) THEN 'B1'::text
            WHEN (annual_revenue >= (500000)::numeric) THEN 'B2'::text
            WHEN (annual_revenue >= (150000)::numeric) THEN 'C1'::text
            WHEN (annual_revenue >= (1000)::numeric) THEN 'C2'::text
            ELSE 'Other'::text
        END AS abc_group
   FROM cr
  ORDER BY annual_revenue DESC;


--
-- Name: VIEW v_abc_clients_detail; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_abc_clients_detail IS 'ABC-сегментация с полной информацией по каждому клиенту';


--
-- Name: v_abc_segmentation; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_abc_segmentation AS
 SELECT out_group_name,
    out_total_sales,
    out_total_companies
   FROM public.get_abc_segmentation((EXTRACT(year FROM CURRENT_DATE))::integer, 1.0) get_abc_segmentation(out_group_name, out_total_sales, out_total_companies);


--
-- Name: v_annual_activity_report; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_annual_activity_report AS
 SELECT c.code AS client_code,
    c.name AS client_name,
    (EXTRACT(year FROM d.invoice_date))::integer AS sales_year,
    COALESCE(sr.status_name, 'Без статуса'::character varying) AS current_rfm_status,
    count(DISTINCT d.id) AS invoices_count,
    sum(sl.amount) AS total_revenue,
    round((sum(sl.amount) / (NULLIF(count(DISTINCT d.id), 0))::numeric), 2) AS average_receipt
   FROM (((public.clients c
     LEFT JOIN public.status_rules sr ON ((c.current_status_id = sr.id)))
     JOIN public.documents d ON (((c.code)::text = (d.client_code)::text)))
     JOIN public.sales_lines sl ON ((d.id = sl.document_id)))
  GROUP BY c.code, c.name, sr.status_name, (EXTRACT(year FROM d.invoice_date))
  ORDER BY ((EXTRACT(year FROM d.invoice_date))::integer) DESC, (sum(sl.amount)) DESC;


--
-- Name: VIEW v_annual_activity_report; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_annual_activity_report IS 'Сводная статистика: Сколько накладных и денег принес каждый клиент по годам';


--
-- Name: v_churn_risk_dashboard; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_churn_risk_dashboard AS
 WITH clp AS (
         SELECT documents.client_code,
            max(documents.invoice_date) AS last_purchase
           FROM public.documents
          GROUP BY documents.client_code
        )
 SELECT c.code AS client_code,
    c.name AS client_name,
    sr.status_name AS status,
    clp.last_purchase,
    (CURRENT_DATE - clp.last_purchase) AS days_since_last_purchase,
    COALESCE(( SELECT sum(sl.amount) AS sum
           FROM (public.sales_lines sl
             JOIN public.documents d ON ((sl.document_id = d.id)))
          WHERE (((d.client_code)::text = (c.code)::text) AND (d.invoice_date >= (CURRENT_DATE - '1 year'::interval)))), (0)::numeric) AS revenue_last_12_months
   FROM ((public.clients c
     JOIN clp ON (((c.code)::text = (clp.client_code)::text)))
     LEFT JOIN public.status_rules sr ON ((c.current_status_id = sr.id)))
  WHERE (((CURRENT_DATE - clp.last_purchase) > 90) AND ((EXTRACT(year FROM CURRENT_DATE))::integer = ANY (c.active_years)))
  ORDER BY (CURRENT_DATE - clp.last_purchase) DESC, COALESCE(( SELECT sum(sl.amount) AS sum
           FROM (public.sales_lines sl
             JOIN public.documents d ON ((sl.document_id = d.id)))
          WHERE (((d.client_code)::text = (c.code)::text) AND (d.invoice_date >= (CURRENT_DATE - '1 year'::interval)))), (0)::numeric) DESC;


--
-- Name: VIEW v_churn_risk_dashboard; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_churn_risk_dashboard IS 'Клиенты в зоне риска (отток): сортировка по давности последней покупки и ценности';


--
-- Name: v_combined_annual_activity; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_combined_annual_activity AS
 SELECT c.code AS client_code,
    c.name AS client_name,
    hca.sales_year AS activity_year,
    hca.expense_invoices AS invoices_count,
    hca.sales_amount AS revenue,
    cg.group_name AS analytical_group,
    sr.status_name AS current_rfm_status,
    'Historical'::text AS data_source
   FROM (((public.historical_client_activity hca
     JOIN public.clients c ON (((hca.client_code)::text = (c.code)::text)))
     LEFT JOIN public.client_groups cg ON ((hca.group_id = cg.id)))
     LEFT JOIN public.status_rules sr ON ((c.current_status_id = sr.id)))
UNION ALL
 SELECT c.code AS client_code,
    c.name AS client_name,
    (EXTRACT(year FROM d.invoice_date))::integer AS activity_year,
    count(DISTINCT d.id) AS invoices_count,
    sum(d.total_amount) AS revenue,
    cg.group_name AS analytical_group,
    sr.status_name AS current_rfm_status,
    'Live'::text AS data_source
   FROM (((public.clients c
     JOIN public.documents d ON (((c.code)::text = (d.client_code)::text)))
     LEFT JOIN public.client_groups cg ON ((c.group_id = cg.id)))
     LEFT JOIN public.status_rules sr ON ((c.current_status_id = sr.id)))
  GROUP BY c.code, c.name, (EXTRACT(year FROM d.invoice_date)), cg.group_name, sr.status_name;


--
-- Name: v_direction_profitability; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_direction_profitability AS
 SELECT COALESCE(ad.name, 'Направление не определено'::character varying) AS activity_direction,
    count(DISTINCT c.code) AS total_clients_in_segment,
    sum(sl.amount) AS total_revenue_generated
   FROM (((public.clients c
     LEFT JOIN public.activity_directions ad ON ((c.activity_direction_id = ad.id)))
     JOIN public.documents d ON (((c.code)::text = (d.client_code)::text)))
     JOIN public.sales_lines sl ON ((d.id = sl.document_id)))
  GROUP BY ad.name
  ORDER BY (sum(sl.amount)) DESC;


--
-- Name: VIEW v_direction_profitability; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_direction_profitability IS 'Рентабельность направлений: какое направление приносит больше денег';


--
-- Name: v_manager_dashboard; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_manager_dashboard AS
 SELECT c.code,
    c.name,
    c.client_type,
    sr.status_name AS current_status,
    c.first_purchase_date,
    c.last_purchase_date,
    (CURRENT_DATE - c.last_purchase_date) AS days_since_last,
    ad.name AS activity_direction,
    c.direction_confidence,
    c.requires_survey,
    c.survey_completed_at,
    ( SELECT count(*) AS count
           FROM public.documents
          WHERE ((documents.client_code)::text = (c.code)::text)) AS total_docs,
    ( SELECT COALESCE(sum(documents.total_amount), (0)::numeric) AS "coalesce"
           FROM public.documents
          WHERE ((documents.client_code)::text = (c.code)::text)) AS total_revenue
   FROM ((public.clients c
     LEFT JOIN public.status_rules sr ON ((c.current_status_id = sr.id)))
     LEFT JOIN public.activity_directions ad ON ((c.activity_direction_id = ad.id)))
  WHERE (c.is_active_current = true);


--
-- Name: website_behavior_log; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.website_behavior_log (
    id bigint NOT NULL,
    client_code character varying(50) NOT NULL,
    product_category character varying(100),
    product_code character varying(50),
    action_type character varying(50),
    "timestamp" timestamp without time zone DEFAULT CURRENT_TIMESTAMP
);


--
-- Name: TABLE website_behavior_log; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON TABLE public.website_behavior_log IS 'Радар интересов: Цифровой след активности клиента';


--
-- Name: COLUMN website_behavior_log.product_code; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.website_behavior_log.product_code IS 'Конкретный товар, который смотрел клиент';


--
-- Name: v_smart_recommendations; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_smart_recommendations AS
 SELECT c.code AS client_code,
    p.code AS product_code,
    p.name AS product_name,
    'Часто покупаете'::text AS recommendation_reason,
    1 AS priority,
    p.in_stock_balance
   FROM (((public.clients c
     JOIN ( SELECT d.client_code,
            sl.product_code,
            count(*) AS buy_count
           FROM (public.sales_lines sl
             JOIN public.documents d ON ((sl.document_id = d.id)))
          GROUP BY d.client_code, sl.product_code) history ON (((c.code)::text = (history.client_code)::text)))
     JOIN public.products p ON (((history.product_code)::text = (p.code)::text)))
     LEFT JOIN public.manager_rejections_log mrl ON ((((c.code)::text = (mrl.client_code)::text) AND ((p.code)::text = (mrl.product_code)::text) AND (mrl.rejected_at > (CURRENT_DATE - '30 days'::interval)))))
  WHERE ((p.in_stock_balance > (0)::numeric) AND (mrl.id IS NULL))
UNION ALL
 SELECT c.code AS client_code,
    p.code AS product_code,
    p.name AS product_name,
    'Новинка в вашем сегменте'::text AS recommendation_reason,
    2 AS priority,
    p.in_stock_balance
   FROM ((public.clients c
     JOIN public.products p ON ((c.activity_direction_id = p.anchor_direction_id)))
     LEFT JOIN public.manager_rejections_log mrl ON ((((c.code)::text = (mrl.client_code)::text) AND ((p.code)::text = (mrl.product_code)::text) AND (mrl.rejected_at > (CURRENT_DATE - '30 days'::interval)))))
  WHERE ((p.is_new_arrival = true) AND (p.in_stock_balance > (0)::numeric) AND (mrl.id IS NULL))
UNION ALL
 SELECT DISTINCT c.code AS client_code,
    p_related.code AS product_code,
    p_related.name AS product_name,
    (('С '::text || (p_main.name)::text) || ' обычно берут'::text) AS recommendation_reason,
    3 AS priority,
    p_related.in_stock_balance
   FROM ((((((public.clients c
     JOIN public.documents d ON (((c.code)::text = (d.client_code)::text)))
     JOIN public.sales_lines sl ON ((d.id = sl.document_id)))
     JOIN public.products p_main ON (((sl.product_code)::text = (p_main.code)::text)))
     JOIN public.product_cross_sells pcs ON (((sl.product_code)::text = (pcs.main_product_code)::text)))
     JOIN public.products p_related ON (((pcs.related_product_code)::text = (p_related.code)::text)))
     LEFT JOIN public.manager_rejections_log mrl ON ((((c.code)::text = (mrl.client_code)::text) AND ((p_related.code)::text = (mrl.product_code)::text) AND (mrl.rejected_at > (CURRENT_DATE - '30 days'::interval)))))
  WHERE ((p_related.in_stock_balance > (0)::numeric) AND (mrl.id IS NULL))
UNION ALL
 SELECT DISTINCT c.code AS client_code,
    p.code AS product_code,
    p.name AS product_name,
    'Вы недавно интересовались'::text AS recommendation_reason,
    4 AS priority,
    p.in_stock_balance
   FROM (((public.clients c
     JOIN public.website_behavior_log wbl ON (((c.code)::text = (wbl.client_code)::text)))
     JOIN public.products p ON ((((wbl.product_code)::text = (p.code)::text) OR (p.anchor_direction_id = ( SELECT activity_directions.id
           FROM public.activity_directions
          WHERE ((activity_directions.name)::text = (wbl.product_category)::text)
         LIMIT 1)))))
     LEFT JOIN public.manager_rejections_log mrl ON ((((c.code)::text = (mrl.client_code)::text) AND ((p.code)::text = (mrl.product_code)::text) AND (mrl.rejected_at > (CURRENT_DATE - '30 days'::interval)))))
  WHERE ((wbl."timestamp" > (CURRENT_DATE - '7 days'::interval)) AND (p.in_stock_balance > (0)::numeric) AND (mrl.id IS NULL))
  ORDER BY 5, 6 DESC;


--
-- Name: v_status_migration_matrix; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_status_migration_matrix AS
 SELECT COALESCE(old_sr.status_name, 'Новый (Регистрация)'::character varying) AS from_status,
    new_sr.status_name AS to_status,
    (EXTRACT(year FROM scl.changed_at))::integer AS migration_year,
    (EXTRACT(month FROM scl.changed_at))::integer AS migration_month,
    count(scl.client_code) AS clients_migrated,
    sum(c.direction_confidence) AS total_confidence_weight
   FROM (((public.status_change_log scl
     JOIN public.clients c ON (((scl.client_code)::text = (c.code)::text)))
     LEFT JOIN public.status_rules old_sr ON ((scl.old_status_id = old_sr.id)))
     JOIN public.status_rules new_sr ON ((scl.new_status_id = new_sr.id)))
  GROUP BY old_sr.status_name, new_sr.status_name, (EXTRACT(year FROM scl.changed_at)), (EXTRACT(month FROM scl.changed_at))
  ORDER BY ((EXTRACT(year FROM scl.changed_at))::integer) DESC, ((EXTRACT(month FROM scl.changed_at))::integer) DESC, (count(scl.client_code)) DESC;


--
-- Name: VIEW v_status_migration_matrix; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON VIEW public.v_status_migration_matrix IS 'Векторы миграции: сколько клиентов и из какого статуса перешли в новый';


--
-- Name: view_client_segmentation_details_2026; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.view_client_segmentation_details_2026 AS
 WITH client_stats_2026 AS (
         SELECT d.client_code,
            count(DISTINCT d.id) AS doc_count,
            min(d.invoice_date) AS first_purchase_date,
            max(d.invoice_date) AS last_purchase_date,
            (max(d.invoice_date) - min(d.invoice_date)) AS days_between_purchases,
            COALESCE(sum(sl.amount), (0)::numeric) AS total_revenue_overall,
            COALESCE(sum(
                CASE
                    WHEN (p.is_service = false) THEN sl.amount
                    ELSE (0)::numeric
                END), (0)::numeric) AS total_goods_revenue,
            COALESCE(sum(
                CASE
                    WHEN (p.is_service = true) THEN sl.amount
                    ELSE (0)::numeric
                END), (0)::numeric) AS total_services_revenue
           FROM ((public.documents d
             LEFT JOIN public.sales_lines sl ON ((sl.document_id = d.id)))
             LEFT JOIN public.products p ON (((sl.product_code)::text = (p.code)::text)))
          WHERE (EXTRACT(year FROM d.invoice_date) = (2026)::numeric)
          GROUP BY d.client_code
        ), all_clients_with_sleeping AS (
         SELECT c.code AS client_code,
            c.name AS client_name,
            COALESCE(s.doc_count, (0)::bigint) AS doc_count,
            s.first_purchase_date,
            s.last_purchase_date,
            COALESCE(s.days_between_purchases, 0) AS days_between_purchases,
            COALESCE(s.total_revenue_overall, (0)::numeric) AS total_revenue,
            COALESCE(s.total_goods_revenue, (0)::numeric) AS goods_revenue,
            COALESCE(s.total_services_revenue, (0)::numeric) AS services_revenue
           FROM ((public.clients c
             LEFT JOIN client_stats_2026 s ON (((c.code)::text = (s.client_code)::text)))
             JOIN public.client_year_activity cya ON (((cya.client_code)::text = (c.code)::text)))
          WHERE ((cya.sales_year = 2026) AND (cya.is_active = true))
        )
 SELECT client_code,
    client_name,
    doc_count,
    goods_revenue,
    services_revenue,
    total_revenue,
        CASE
            WHEN (doc_count >= 4) THEN 'Постоянные (VIP)'::text
            WHEN ((doc_count >= 2) AND (doc_count <= 3)) THEN 'Повторные покупки'::text
            WHEN (doc_count = 1) THEN 'Разовые'::text
            ELSE 'Спящие (Нет отгрузок)'::text
        END AS primary_status,
        CASE
            WHEN (doc_count = 3) THEN 'Повторные: Ближе к постоянным (3 покупки)'::text
            WHEN ((doc_count = 2) AND (days_between_purchases <= 2)) THEN 'Повторные: Ближе к разовым (Быстрый дубль)'::text
            WHEN ((doc_count = 2) AND (days_between_purchases > 2)) THEN 'Повторные: Сбалансированный центр'::text
            WHEN (doc_count >= 4) THEN 'Постоянные (VIP)'::text
            WHEN (doc_count = 1) THEN 'Разовые'::text
            ELSE 'Спящие (Нет отгрузок)'::text
        END AS detailed_segment
   FROM all_clients_with_sleeping;


--
-- Name: view_average_ticket_analytics; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.view_average_ticket_analytics AS
 SELECT client_code,
    client_name,
    doc_count AS total_invoices,
    goods_revenue AS total_goods_sum,
        CASE
            WHEN (doc_count > 0) THEN round((goods_revenue / (doc_count)::numeric), 2)
            ELSE 0.00
        END AS average_goods_ticket,
        CASE
            WHEN (doc_count > 0) THEN round((total_revenue / (doc_count)::numeric), 2)
            ELSE 0.00
        END AS average_gross_ticket,
        CASE
            WHEN (doc_count > 0) THEN round(((total_revenue - goods_revenue) / (doc_count)::numeric), 2)
            ELSE 0.00
        END AS average_services_share
   FROM public.view_client_segmentation_details_2026
  WHERE (doc_count > 0);


--
-- Name: view_client_profiles_yearly; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.view_client_profiles_yearly AS
 SELECT (EXTRACT(year FROM d.invoice_date))::integer AS sales_year,
    c.code AS client_code,
    c.name AS client_name,
    COALESCE(ad.name, 'Не указано'::character varying) AS direction_name,
    COALESCE(sum(
        CASE
            WHEN (COALESCE(pr.is_service, false) = false) THEN sl.amount
            ELSE (0)::numeric
        END), (0)::numeric) AS goods_revenue,
    COALESCE(sum(
        CASE
            WHEN (COALESCE(pr.is_service, false) = true) THEN sl.amount
            ELSE (0)::numeric
        END), (0)::numeric) AS services_revenue,
    COALESCE(sum(sl.amount), (0)::numeric) AS total_revenue,
    count(DISTINCT d.id) AS invoice_count,
    round((COALESCE(sum(
        CASE
            WHEN (COALESCE(pr.is_service, false) = false) THEN sl.amount
            ELSE (0)::numeric
        END), (0)::numeric) / (NULLIF(count(DISTINCT d.id), 0))::numeric), 2) AS avg_goods_ticket,
    COALESCE(array_length(c.active_years, 1), 0) AS active_years_count
   FROM ((((public.documents d
     JOIN public.sales_lines sl ON ((sl.document_id = d.id)))
     LEFT JOIN public.products pr ON (((sl.product_code)::text = (pr.code)::text)))
     JOIN public.clients c ON ((((d.client_code)::text = (c.code)::text) AND (c.is_active_current = true))))
     LEFT JOIN public.activity_directions ad ON ((c.activity_direction_id = ad.id)))
  GROUP BY (EXTRACT(year FROM d.invoice_date)), c.code, c.name, ad.name, c.active_years;


--
-- Name: view_cohort_2026_integrity_check; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.view_cohort_2026_integrity_check AS
 WITH sales_summary_2026 AS (
         SELECT d.client_code,
            count(DISTINCT d.id) AS actual_docs_count,
            COALESCE(sum(sl.amount), (0)::numeric) AS actual_sales_volume
           FROM (public.documents d
             JOIN public.sales_lines sl ON ((sl.document_id = d.id)))
          WHERE (EXTRACT(year FROM d.invoice_date) = (2026)::numeric)
          GROUP BY d.client_code
        ), cohort_summary_2026 AS (
         SELECT client_year_activity.client_code,
            client_year_activity.is_active
           FROM public.client_year_activity
          WHERE (client_year_activity.sales_year = 2026)
        )
 SELECT COALESCE(c.code, co.client_code) AS client_code,
    COALESCE(c.name, 'НЕИЗВЕСТНЫЙ КЛИЕНТ (УДАЛЕН ИЗ СПРАВОЧНИКА)'::character varying) AS client_name,
    COALESCE(co.is_active, false) AS marked_active_in_cohort,
        CASE
            WHEN (s.actual_docs_count > 0) THEN true
            ELSE false
        END AS has_real_sales_2026,
    COALESCE(s.actual_docs_count, (0)::bigint) AS real_documents_count,
    COALESCE(s.actual_sales_volume, 0.00) AS real_sales_volume,
        CASE
            WHEN ((COALESCE(co.is_active, false) = true) AND (COALESCE(s.actual_docs_count, (0)::bigint) > 0)) THEN 'Идеально (В когорте и есть продажи)'::text
            WHEN ((COALESCE(co.is_active, false) = true) AND (COALESCE(s.actual_docs_count, (0)::bigint) = 0)) THEN 'Внимание (В когорте, но нет продаж за 2026 - Спящий)'::text
            WHEN ((COALESCE(co.is_active, false) = false) AND (COALESCE(s.actual_docs_count, (0)::bigint) > 0)) THEN 'КРИТИЧЕСКАЯ ОШИБКА (Есть продажи, но НЕ включен в когорту!)'::text
            ELSE 'Исключен из когорты (Нет активности, всё верно)'::text
        END AS integrity_status
   FROM ((public.clients c
     FULL JOIN cohort_summary_2026 co ON (((c.code)::text = (co.client_code)::text)))
     LEFT JOIN sales_summary_2026 s ON (((c.code)::text = (s.client_code)::text)));


--
-- Name: website_behavior_log_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.website_behavior_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: website_behavior_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.website_behavior_log_id_seq OWNED BY public.website_behavior_log.id;


--
-- Name: ab_tests id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ab_tests ALTER COLUMN id SET DEFAULT nextval('public.ab_tests_id_seq'::regclass);


--
-- Name: activity_directions id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_directions ALTER COLUMN id SET DEFAULT nextval('public.activity_directions_id_seq'::regclass);


--
-- Name: client_groups id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_groups ALTER COLUMN id SET DEFAULT nextval('public.client_groups_id_seq'::regclass);


--
-- Name: client_year_activity id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_year_activity ALTER COLUMN id SET DEFAULT nextval('public.client_year_activity_id_seq'::regclass);


--
-- Name: historical_client_activity id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historical_client_activity ALTER COLUMN id SET DEFAULT nextval('public.historical_client_activity_id_seq'::regclass);


--
-- Name: manager_rejections_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manager_rejections_log ALTER COLUMN id SET DEFAULT nextval('public.manager_rejections_log_id_seq'::regclass);


--
-- Name: product_aliases id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_aliases ALTER COLUMN id SET DEFAULT nextval('public.product_aliases_id_seq'::regclass);


--
-- Name: product_cross_sells id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_cross_sells ALTER COLUMN id SET DEFAULT nextval('public.product_cross_sells_id_seq'::regclass);


--
-- Name: product_scoring id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_scoring ALTER COLUMN id SET DEFAULT nextval('public.product_scoring_id_seq'::regclass);


--
-- Name: product_similarities id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_similarities ALTER COLUMN id SET DEFAULT nextval('public.product_similarities_id_seq'::regclass);


--
-- Name: production_lead_times id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_lead_times ALTER COLUMN id SET DEFAULT nextval('public.production_lead_times_id_seq'::regclass);


--
-- Name: sales_lines id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_lines ALTER COLUMN id SET DEFAULT nextval('public.sales_lines_id_seq'::regclass);


--
-- Name: status_change_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_change_log ALTER COLUMN id SET DEFAULT nextval('public.status_change_log_id_seq'::regclass);


--
-- Name: status_rules id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_rules ALTER COLUMN id SET DEFAULT nextval('public.status_rules_id_seq'::regclass);


--
-- Name: website_behavior_log id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.website_behavior_log ALTER COLUMN id SET DEFAULT nextval('public.website_behavior_log_id_seq'::regclass);


--
-- Name: ab_tests ab_tests_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.ab_tests
    ADD CONSTRAINT ab_tests_pkey PRIMARY KEY (id);


--
-- Name: activity_directions activity_directions_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_directions
    ADD CONSTRAINT activity_directions_name_key UNIQUE (name);


--
-- Name: activity_directions activity_directions_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.activity_directions
    ADD CONSTRAINT activity_directions_pkey PRIMARY KEY (id);


--
-- Name: client_groups client_groups_group_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_groups
    ADD CONSTRAINT client_groups_group_name_key UNIQUE (group_name);


--
-- Name: client_groups client_groups_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_groups
    ADD CONSTRAINT client_groups_pkey PRIMARY KEY (id);


--
-- Name: client_year_activity client_year_activity_client_code_sales_year_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_year_activity
    ADD CONSTRAINT client_year_activity_client_code_sales_year_key UNIQUE (client_code, sales_year);


--
-- Name: client_year_activity client_year_activity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_year_activity
    ADD CONSTRAINT client_year_activity_pkey PRIMARY KEY (id);


--
-- Name: clients clients_legacy_unit_id_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_legacy_unit_id_key UNIQUE (legacy_unit_id);


--
-- Name: clients clients_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_pkey PRIMARY KEY (code);


--
-- Name: documents documents_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_pkey PRIMARY KEY (id);


--
-- Name: historical_client_activity historical_client_activity_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historical_client_activity
    ADD CONSTRAINT historical_client_activity_pkey PRIMARY KEY (id);


--
-- Name: manager_rejections_log manager_rejections_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manager_rejections_log
    ADD CONSTRAINT manager_rejections_log_pkey PRIMARY KEY (id);


--
-- Name: product_aliases product_aliases_alias_text_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_aliases
    ADD CONSTRAINT product_aliases_alias_text_key UNIQUE (alias_text);


--
-- Name: product_aliases product_aliases_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_aliases
    ADD CONSTRAINT product_aliases_pkey PRIMARY KEY (id);


--
-- Name: product_cross_sells product_cross_sells_main_product_code_related_product_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_cross_sells
    ADD CONSTRAINT product_cross_sells_main_product_code_related_product_code_key UNIQUE (main_product_code, related_product_code);


--
-- Name: product_cross_sells product_cross_sells_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_cross_sells
    ADD CONSTRAINT product_cross_sells_pkey PRIMARY KEY (id);


--
-- Name: product_scoring product_scoring_client_code_product_code_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_scoring
    ADD CONSTRAINT product_scoring_client_code_product_code_key UNIQUE (client_code, product_code);


--
-- Name: product_scoring product_scoring_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_scoring
    ADD CONSTRAINT product_scoring_pkey PRIMARY KEY (id);


--
-- Name: product_similarities product_similarities_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_similarities
    ADD CONSTRAINT product_similarities_pkey PRIMARY KEY (id);


--
-- Name: product_similarities product_similarities_source_product_code_similar_product_co_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_similarities
    ADD CONSTRAINT product_similarities_source_product_code_similar_product_co_key UNIQUE (source_product_code, similar_product_code);


--
-- Name: production_lead_times production_lead_times_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_lead_times
    ADD CONSTRAINT production_lead_times_pkey PRIMARY KEY (id);


--
-- Name: products products_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_pkey PRIMARY KEY (code);


--
-- Name: sales_lines sales_lines_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_lines
    ADD CONSTRAINT sales_lines_pkey PRIMARY KEY (id);


--
-- Name: status_change_log status_change_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_change_log
    ADD CONSTRAINT status_change_log_pkey PRIMARY KEY (id);


--
-- Name: status_rules status_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_rules
    ADD CONSTRAINT status_rules_pkey PRIMARY KEY (id);


--
-- Name: status_rules status_rules_status_name_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_rules
    ADD CONSTRAINT status_rules_status_name_key UNIQUE (status_name);


--
-- Name: historical_client_activity uq_historical_activity; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historical_client_activity
    ADD CONSTRAINT uq_historical_activity UNIQUE (client_code, sales_year);


--
-- Name: website_behavior_log website_behavior_log_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.website_behavior_log
    ADD CONSTRAINT website_behavior_log_pkey PRIMARY KEY (id);


--
-- Name: idx_ab_tests_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_ab_tests_active ON public.ab_tests USING btree (is_active) WHERE (is_active = true);


--
-- Name: idx_clients_current_status; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clients_current_status ON public.clients USING btree (current_status_id);


--
-- Name: idx_clients_group; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clients_group ON public.clients USING btree (group_id);


--
-- Name: idx_clients_last_purchase; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clients_last_purchase ON public.clients USING btree (last_purchase_date);


--
-- Name: idx_clients_legacy_id; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clients_legacy_id ON public.clients USING btree (legacy_unit_id);


--
-- Name: idx_clients_okpo; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clients_okpo ON public.clients USING btree (okpo_code);


--
-- Name: idx_clients_status_history; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_clients_status_history ON public.clients USING gin (status_history);


--
-- Name: idx_cya_year_active; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_cya_year_active ON public.client_year_activity USING btree (sales_year, is_active);


--
-- Name: idx_documents_client_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_documents_client_date ON public.documents USING btree (client_code, invoice_date);


--
-- Name: idx_documents_doc_number; Type: INDEX; Schema: public; Owner: -
--

CREATE UNIQUE INDEX idx_documents_doc_number ON public.documents USING btree (doc_number);


--
-- Name: idx_documents_invoice_date; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_documents_invoice_date ON public.documents USING btree (invoice_date);


--
-- Name: idx_historical_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_historical_client ON public.historical_client_activity USING btree (client_code);


--
-- Name: idx_historical_year; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_historical_year ON public.historical_client_activity USING btree (sales_year);


--
-- Name: idx_product_scoring_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_scoring_client ON public.product_scoring USING btree (client_code);


--
-- Name: idx_product_scoring_weight; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_product_scoring_weight ON public.product_scoring USING btree (current_weight) WHERE (current_weight > 0);


--
-- Name: idx_rejections_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rejections_client ON public.manager_rejections_log USING btree (client_code, rejected_at DESC);


--
-- Name: idx_rejections_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_rejections_product ON public.manager_rejections_log USING btree (product_code);


--
-- Name: idx_sales_lines_doc_prod; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_lines_doc_prod ON public.sales_lines USING btree (document_id, product_code);


--
-- Name: idx_sales_lines_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_sales_lines_product ON public.sales_lines USING btree (product_code);


--
-- Name: idx_website_behavior_category; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_website_behavior_category ON public.website_behavior_log USING btree (product_category);


--
-- Name: idx_website_behavior_client; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_website_behavior_client ON public.website_behavior_log USING btree (client_code, "timestamp" DESC);


--
-- Name: idx_website_behavior_product; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_website_behavior_product ON public.website_behavior_log USING btree (product_code);


--
-- Name: ab_tests trg_ab_tests_upd; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_ab_tests_upd BEFORE UPDATE ON public.ab_tests FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: activity_directions trg_activity_directions_upd; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_activity_directions_upd BEFORE UPDATE ON public.activity_directions FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: clients trg_clients_upd; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_clients_upd BEFORE UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: clients trg_log_status_change; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_log_status_change BEFORE UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION public.log_status_change();


--
-- Name: manager_rejections_log trg_penalize_rejection; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_penalize_rejection AFTER INSERT ON public.manager_rejections_log FOR EACH ROW EXECUTE FUNCTION public.penalize_rejected_product();


--
-- Name: product_scoring trg_product_scoring_upd; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_product_scoring_upd BEFORE UPDATE ON public.product_scoring FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: products trg_products_upd; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_products_upd BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: sales_lines trg_sales_lines_activity; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_sales_lines_activity AFTER INSERT OR DELETE OR UPDATE ON public.sales_lines FOR EACH ROW EXECUTE FUNCTION public.trg_update_client_activity();


--
-- Name: status_rules trg_status_rules_upd; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_status_rules_upd BEFORE UPDATE ON public.status_rules FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: client_year_activity client_year_activity_client_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.client_year_activity
    ADD CONSTRAINT client_year_activity_client_code_fkey FOREIGN KEY (client_code) REFERENCES public.clients(code) ON DELETE CASCADE;


--
-- Name: clients clients_activity_direction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_activity_direction_id_fkey FOREIGN KEY (activity_direction_id) REFERENCES public.activity_directions(id) ON DELETE SET NULL;


--
-- Name: clients clients_current_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_current_status_id_fkey FOREIGN KEY (current_status_id) REFERENCES public.status_rules(id) ON DELETE SET NULL;


--
-- Name: clients clients_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clients
    ADD CONSTRAINT clients_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.client_groups(id) ON DELETE SET NULL;


--
-- Name: documents documents_client_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.documents
    ADD CONSTRAINT documents_client_code_fkey FOREIGN KEY (client_code) REFERENCES public.clients(code) ON DELETE CASCADE;


--
-- Name: historical_client_activity historical_client_activity_client_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historical_client_activity
    ADD CONSTRAINT historical_client_activity_client_code_fkey FOREIGN KEY (client_code) REFERENCES public.clients(code) ON DELETE CASCADE;


--
-- Name: historical_client_activity historical_client_activity_group_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historical_client_activity
    ADD CONSTRAINT historical_client_activity_group_id_fkey FOREIGN KEY (group_id) REFERENCES public.client_groups(id) ON DELETE SET NULL;


--
-- Name: manager_rejections_log manager_rejections_log_client_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manager_rejections_log
    ADD CONSTRAINT manager_rejections_log_client_code_fkey FOREIGN KEY (client_code) REFERENCES public.clients(code) ON DELETE CASCADE;


--
-- Name: manager_rejections_log manager_rejections_log_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manager_rejections_log
    ADD CONSTRAINT manager_rejections_log_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.documents(id) ON DELETE SET NULL;


--
-- Name: manager_rejections_log manager_rejections_log_product_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.manager_rejections_log
    ADD CONSTRAINT manager_rejections_log_product_code_fkey FOREIGN KEY (product_code) REFERENCES public.products(code) ON DELETE CASCADE;


--
-- Name: product_aliases product_aliases_product_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_aliases
    ADD CONSTRAINT product_aliases_product_code_fkey FOREIGN KEY (product_code) REFERENCES public.products(code) ON DELETE CASCADE;


--
-- Name: product_cross_sells product_cross_sells_main_product_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_cross_sells
    ADD CONSTRAINT product_cross_sells_main_product_code_fkey FOREIGN KEY (main_product_code) REFERENCES public.products(code) ON DELETE CASCADE;


--
-- Name: product_cross_sells product_cross_sells_related_product_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_cross_sells
    ADD CONSTRAINT product_cross_sells_related_product_code_fkey FOREIGN KEY (related_product_code) REFERENCES public.products(code) ON DELETE CASCADE;


--
-- Name: product_scoring product_scoring_client_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_scoring
    ADD CONSTRAINT product_scoring_client_code_fkey FOREIGN KEY (client_code) REFERENCES public.clients(code) ON DELETE CASCADE;


--
-- Name: product_scoring product_scoring_product_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_scoring
    ADD CONSTRAINT product_scoring_product_code_fkey FOREIGN KEY (product_code) REFERENCES public.products(code) ON DELETE CASCADE;


--
-- Name: product_similarities product_similarities_similar_product_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_similarities
    ADD CONSTRAINT product_similarities_similar_product_code_fkey FOREIGN KEY (similar_product_code) REFERENCES public.products(code) ON DELETE CASCADE;


--
-- Name: product_similarities product_similarities_source_product_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.product_similarities
    ADD CONSTRAINT product_similarities_source_product_code_fkey FOREIGN KEY (source_product_code) REFERENCES public.products(code) ON DELETE CASCADE;


--
-- Name: production_lead_times production_lead_times_alternative_blank_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_lead_times
    ADD CONSTRAINT production_lead_times_alternative_blank_code_fkey FOREIGN KEY (alternative_blank_code) REFERENCES public.products(code);


--
-- Name: production_lead_times production_lead_times_product_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.production_lead_times
    ADD CONSTRAINT production_lead_times_product_code_fkey FOREIGN KEY (product_code) REFERENCES public.products(code) ON DELETE CASCADE;


--
-- Name: products products_anchor_direction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.products
    ADD CONSTRAINT products_anchor_direction_id_fkey FOREIGN KEY (anchor_direction_id) REFERENCES public.activity_directions(id) ON DELETE SET NULL;


--
-- Name: sales_lines sales_lines_document_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_lines
    ADD CONSTRAINT sales_lines_document_id_fkey FOREIGN KEY (document_id) REFERENCES public.documents(id) ON DELETE CASCADE;


--
-- Name: sales_lines sales_lines_product_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.sales_lines
    ADD CONSTRAINT sales_lines_product_code_fkey FOREIGN KEY (product_code) REFERENCES public.products(code) ON DELETE RESTRICT;


--
-- Name: status_change_log status_change_log_client_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_change_log
    ADD CONSTRAINT status_change_log_client_code_fkey FOREIGN KEY (client_code) REFERENCES public.clients(code) ON DELETE CASCADE;


--
-- Name: status_change_log status_change_log_new_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_change_log
    ADD CONSTRAINT status_change_log_new_status_id_fkey FOREIGN KEY (new_status_id) REFERENCES public.status_rules(id);


--
-- Name: status_change_log status_change_log_old_status_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.status_change_log
    ADD CONSTRAINT status_change_log_old_status_id_fkey FOREIGN KEY (old_status_id) REFERENCES public.status_rules(id);


--
-- Name: website_behavior_log website_behavior_log_client_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.website_behavior_log
    ADD CONSTRAINT website_behavior_log_client_code_fkey FOREIGN KEY (client_code) REFERENCES public.clients(code) ON DELETE CASCADE;


--
-- Name: website_behavior_log website_behavior_log_product_code_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.website_behavior_log
    ADD CONSTRAINT website_behavior_log_product_code_fkey FOREIGN KEY (product_code) REFERENCES public.products(code) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict fk0EK5bzdZWXIo6VCr9whFKOybbP7jBEBhxSeCMfsJTlCXI7T33nc1ndY3yIiEA

