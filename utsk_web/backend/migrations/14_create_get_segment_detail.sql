
DROP FUNCTION IF EXISTS public.get_segment_detail(INT, VARCHAR, VARCHAR, NUMERIC);

CREATE OR REPLACE FUNCTION public.get_segment_detail(
    p_year INT DEFAULT 2026,
    p_segment VARCHAR DEFAULT 'raz',
    p_table VARCHAR DEFAULT 'general',
    p_limit_price NUMERIC DEFAULT 146000
)
RETURNS TABLE(
    code VARCHAR,
    name VARCHAR,
    current_status_id INT,
    status_name VARCHAR,
    invoices_count BIGINT,
    goods_revenue NUMERIC,
    avg_ticket NUMERIC,
    m1 NUMERIC,
    m2 NUMERIC,
    m3 NUMERIC,
    m4 NUMERIC,
    m5 NUMERIC,
    m6 NUMERIC,
    m7 NUMERIC,
    m8 NUMERIC,
    m9 NUMERIC,
    m10 NUMERIC,
    m11 NUMERIC,
    m12 NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
DECLARE
    v_doc_year INT;
    v_is_past BOOLEAN;
BEGIN
    v_is_past := (p_table = 'past' OR p_segment IN ('churn', 'sleep') OR p_segment LIKE 'churn_%' OR p_segment LIKE 'sleep_%');
    
    IF v_is_past THEN
        IF p_segment LIKE 'churn%' THEN
            v_doc_year := p_year - 2;
        ELSE
            v_doc_year := p_year - 1;
        END IF;

        RETURN QUERY
        WITH inactive_clients AS (
            SELECT c.code, c.name, c.current_status_id, COALESCE(sr.status_name, 'Не визначено') AS status_name
            FROM clients c
            LEFT JOIN status_rules sr ON c.current_status_id = sr.id
            WHERE c.code NOT IN ('9653', '11230')
              AND (
                  (p_segment LIKE 'churn%' AND c.current_status_id = 9)
                  OR (p_segment LIKE 'sleep%' AND c.current_status_id = 8)
              )
        ),
        client_stats AS (
            SELECT 
                ic.code,
                ic.name,
                ic.current_status_id,
                ic.status_name,
                COUNT(DISTINCT d.id)::BIGINT AS inv_count,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS total_revenue,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 1 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m1,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 2 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m2,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 3 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m3,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 4 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m4,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 5 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m5,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 6 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m6,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 7 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m7,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 8 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m8,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 9 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m9,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 10 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m10,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 11 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m11,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 12 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m12
            FROM inactive_clients ic
            JOIN documents d ON d.client_code = ic.code AND EXTRACT(YEAR FROM d.invoice_date) = v_doc_year
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            GROUP BY ic.code, ic.name, ic.current_status_id, ic.status_name
        )
        SELECT 
            cs.code::VARCHAR,
            cs.name::VARCHAR,
            cs.current_status_id::INT,
            cs.status_name::VARCHAR,
            cs.inv_count::BIGINT AS invoices_count,
            ROUND(cs.total_revenue, 2)::NUMERIC AS goods_revenue,
            ROUND(cs.total_revenue / GREATEST(cs.inv_count, 1), 2)::NUMERIC AS avg_ticket,
            ROUND(cs.m1, 2)::NUMERIC, ROUND(cs.m2, 2)::NUMERIC, ROUND(cs.m3, 2)::NUMERIC,
            ROUND(cs.m4, 2)::NUMERIC, ROUND(cs.m5, 2)::NUMERIC, ROUND(cs.m6, 2)::NUMERIC,
            ROUND(cs.m7, 2)::NUMERIC, ROUND(cs.m8, 2)::NUMERIC, ROUND(cs.m9, 2)::NUMERIC,
            ROUND(cs.m10, 2)::NUMERIC, ROUND(cs.m11, 2)::NUMERIC, ROUND(cs.m12, 2)::NUMERIC
        FROM client_stats cs
        WHERE 
            CASE 
                WHEN p_segment IN ('churn_raz', 'sleep_raz') THEN cs.inv_count = 1
                WHEN p_segment IN ('churn_povt', 'sleep_povt') THEN cs.inv_count BETWEEN 2 AND 3
                WHEN p_segment IN ('churn_kvart', 'sleep_kvart') THEN cs.inv_count BETWEEN 4 AND 10
                WHEN p_segment IN ('churn_mes', 'sleep_mes') THEN cs.inv_count BETWEEN 11 AND 40
                WHEN p_segment IN ('churn_ned', 'sleep_ned') THEN cs.inv_count BETWEEN 41 AND 170
                WHEN p_segment IN ('churn_den', 'sleep_den') THEN cs.inv_count > 170
                ELSE TRUE
            END
        ORDER BY cs.total_revenue DESC;

    ELSE
        v_doc_year := p_year;

        RETURN QUERY
        WITH active_clients AS (
            SELECT c.code, c.name, c.current_status_id, COALESCE(sr.status_name, 'Не визначено') AS status_name
            FROM clients c
            JOIN client_year_activity cya ON c.code = cya.client_code 
                AND cya.sales_year = v_doc_year AND cya.is_active = TRUE
            LEFT JOIN status_rules sr ON c.current_status_id = sr.id
            WHERE c.code NOT IN ('9653', '11230')
        ),
        client_stats AS (
            SELECT 
                ac.code,
                ac.name,
                ac.current_status_id,
                ac.status_name,
                COUNT(DISTINCT d.id)::BIGINT AS inv_count,
                (MAX(d.invoice_date) - MIN(d.invoice_date)) AS date_span,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS total_revenue,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 1 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m1,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 2 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m2,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 3 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m3,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 4 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m4,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 5 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m5,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 6 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m6,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 7 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m7,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 8 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m8,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 9 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m9,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 10 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m10,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 11 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m11,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE AND EXTRACT(MONTH FROM d.invoice_date) = 12 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS m12
            FROM active_clients ac
            JOIN documents d ON d.client_code = ac.code AND EXTRACT(YEAR FROM d.invoice_date) = v_doc_year
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            GROUP BY ac.code, ac.name, ac.current_status_id, ac.status_name
        )
        SELECT 
            cs.code::VARCHAR,
            cs.name::VARCHAR,
            cs.current_status_id::INT,
            cs.status_name::VARCHAR,
            cs.inv_count::BIGINT AS invoices_count,
            ROUND(cs.total_revenue, 2)::NUMERIC AS goods_revenue,
            ROUND(cs.total_revenue / GREATEST(cs.inv_count, 1), 2)::NUMERIC AS avg_ticket,
            ROUND(cs.m1, 2)::NUMERIC, ROUND(cs.m2, 2)::NUMERIC, ROUND(cs.m3, 2)::NUMERIC,
            ROUND(cs.m4, 2)::NUMERIC, ROUND(cs.m5, 2)::NUMERIC, ROUND(cs.m6, 2)::NUMERIC,
            ROUND(cs.m7, 2)::NUMERIC, ROUND(cs.m8, 2)::NUMERIC, ROUND(cs.m9, 2)::NUMERIC,
            ROUND(cs.m10, 2)::NUMERIC, ROUND(cs.m11, 2)::NUMERIC, ROUND(cs.m12, 2)::NUMERIC
        FROM client_stats cs
        WHERE 
            CASE 
                WHEN p_segment = 'raz' THEN cs.inv_count = 1
                WHEN p_segment = 'povt' THEN cs.inv_count BETWEEN 2 AND 3
                WHEN p_segment = 'kvart' THEN cs.inv_count BETWEEN 4 AND 10
                WHEN p_segment = 'mes' THEN cs.inv_count BETWEEN 11 AND 40
                WHEN p_segment = 'ned' THEN cs.inv_count BETWEEN 41 AND 170
                WHEN p_segment = 'den' THEN cs.inv_count > 170
                WHEN p_segment = 'all' THEN TRUE

                WHEN p_segment = 'povt_quick' THEN (cs.inv_count = 2 AND cs.date_span <= 7)
                WHEN p_segment = 'povt_center' THEN (cs.inv_count BETWEEN 2 AND 3 AND NOT (cs.inv_count = 2 AND cs.date_span <= 7))
                WHEN p_segment = 'povt_3' THEN cs.inv_count = 3

                WHEN p_segment = 'cons_raz' THEN (cs.inv_count = 1 OR (cs.inv_count = 2 AND cs.date_span <= 7))

                WHEN p_segment = 'c2' THEN cs.total_revenue <= p_limit_price
                WHEN p_segment = 'c2_raz' THEN (cs.total_revenue <= p_limit_price AND cs.inv_count = 1)
                WHEN p_segment = 'c2_povt' THEN (cs.total_revenue <= p_limit_price AND cs.inv_count BETWEEN 2 AND 3)
                WHEN p_segment = 'c2_kvart' THEN (cs.total_revenue <= p_limit_price AND cs.inv_count BETWEEN 4 AND 10)
                WHEN p_segment = 'c2_mes' THEN (cs.total_revenue <= p_limit_price AND cs.inv_count BETWEEN 11 AND 40)
                WHEN p_segment = 'c2_ned' THEN (cs.total_revenue <= p_limit_price AND cs.inv_count BETWEEN 41 AND 170)
                WHEN p_segment = 'c2_den' THEN (cs.total_revenue <= p_limit_price AND cs.inv_count > 170)

                WHEN p_segment = 'new' THEN cs.current_status_id = 1
                WHEN p_segment = 'new_raz' THEN (cs.current_status_id = 1 AND cs.inv_count = 1)
                WHEN p_segment = 'new_povt' THEN (cs.current_status_id = 1 AND cs.inv_count BETWEEN 2 AND 3)
                WHEN p_segment = 'new_kvart' THEN (cs.current_status_id = 1 AND cs.inv_count BETWEEN 4 AND 10)
                WHEN p_segment = 'new_mes' THEN (cs.current_status_id = 1 AND cs.inv_count BETWEEN 11 AND 40)
                WHEN p_segment = 'new_ned' THEN (cs.current_status_id = 1 AND cs.inv_count BETWEEN 41 AND 170)
                WHEN p_segment = 'new_den' THEN (cs.current_status_id = 1 AND cs.inv_count > 170)

                ELSE TRUE
            END
        ORDER BY cs.total_revenue DESC;
    END IF;
END;
$function$;
