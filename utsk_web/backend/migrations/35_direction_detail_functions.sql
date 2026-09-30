-- ============================================================
-- Migration 35: Новые SQL функции для страницы /direction-detail
-- Задача 5 — 7 функций
-- ============================================================

-- ФУНКЦИЯ 1: KPI для детальной страницы направления
CREATE OR REPLACE FUNCTION public.get_direction_detail_kpi(
    p_direction_id integer,
    p_year         integer DEFAULT 2026
)
RETURNS TABLE(
    direction_name   text,
    direction_icon   text,
    direction_color  text,
    clients_count    bigint,
    invoices_count   bigint,
    goods_revenue    numeric,
    avg_ticket       numeric,
    revenue_share_pct numeric,
    prev_year_revenue numeric,
    yoy_pct          numeric
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH dir_info AS (
        SELECT name, COALESCE(icon,'🌐') AS icon, COALESCE(color,'#64748b') AS color
        FROM activity_directions WHERE id = p_direction_id
    ),
    curr AS (
        SELECT 
            COUNT(DISTINCT c.code) AS cnt_clients,
            COUNT(DISTINCT d.id)   AS cnt_inv,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS rev
        FROM clients c
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.activity_direction_id = p_direction_id
          AND c.code NOT IN ('9653', '11230', '8814')
    ),
    prev AS (
        SELECT COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS rev
        FROM clients c
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year - 1
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.activity_direction_id = p_direction_id
          AND c.code NOT IN ('9653', '11230', '8814')
    ),
    total AS (
        SELECT COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS tot_rev
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND d.client_code NOT IN ('9653', '11230', '8814')
    )
    SELECT 
        di.name::text,
        di.icon::text,
        di.color::text,
        c.cnt_clients::bigint,
        c.cnt_inv::bigint,
        ROUND(c.rev, 2)::numeric,
        ROUND(c.rev / NULLIF(c.cnt_inv, 0), 2)::numeric,
        ROUND(c.rev * 100.0 / NULLIF(t.tot_rev, 0), 2)::numeric,
        ROUND(p.rev, 2)::numeric,
        ROUND((c.rev - p.rev) * 100.0 / NULLIF(p.rev, 0), 2)::numeric
    FROM dir_info di, curr c, prev p, total t;
END;
$function$;

COMMENT ON FUNCTION public.get_direction_detail_kpi IS 
    'KPI одного направления: клиенты, накладные, выручка, доля, YoY. Исключены: 9653, 11230, 8814.';

-- ============================================================
-- ФУНКЦИЯ 2: ТОП-10 клиентов направления
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_direction_top_clients(
    p_direction_id integer,
    p_year         integer DEFAULT 2026,
    p_limit        integer DEFAULT 10
)
RETURNS TABLE(
    client_code    varchar,
    client_name    varchar,
    edrpou         varchar,
    status_name    varchar,
    abc_group      text,
    invoices_count bigint,
    goods_revenue  numeric,
    avg_ticket     numeric,
    revenue_share_pct numeric
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH dir_total AS (
        SELECT COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS tot_rev
        FROM clients c
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.activity_direction_id = p_direction_id
          AND c.code NOT IN ('9653', '11230', '8814')
    ),
    client_stats AS (
        SELECT 
            c.code,
            c.name,
            c.edrpou,
            COALESCE(sr.status_name, 'Н/Д')::text AS sname,
            COUNT(DISTINCT d.id)::bigint AS inv_cnt,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS rev
        FROM clients c
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        LEFT JOIN status_rules sr ON sr.id = c.current_status_id
        WHERE c.activity_direction_id = p_direction_id
          AND c.code NOT IN ('9653', '11230', '8814')
        GROUP BY c.code, c.name, c.edrpou, sr.status_name
    ),
    abc_classified AS (
        SELECT 
            cs.*,
            get_abc_group_for_revenue(cs.rev) AS abc_g
        FROM client_stats cs
    )
    SELECT 
        ac.code::varchar,
        ac.name::varchar,
        ac.edrpou::varchar,
        ac.sname::varchar,
        ac.abc_g::text,
        ac.inv_cnt::bigint,
        ROUND(ac.rev, 2)::numeric,
        ROUND(ac.rev / NULLIF(ac.inv_cnt, 0), 2)::numeric,
        ROUND(ac.rev * 100.0 / NULLIF(dt.tot_rev, 0), 2)::numeric
    FROM abc_classified ac, dir_total dt
    ORDER BY ac.rev DESC
    LIMIT p_limit;
END;
$function$;

COMMENT ON FUNCTION public.get_direction_top_clients IS 
    'Топ-N клиентов одного направления по выручке за год. Исключены: 9653, 11230, 8814.';

-- ============================================================
-- ФУНКЦИЯ 3: Полный список клиентов направления (с пагинацией)
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_direction_clients_list(
    p_direction_id integer,
    p_year         integer DEFAULT 2026,
    p_search       varchar DEFAULT NULL,
    p_abc          varchar DEFAULT NULL,
    p_limit        integer DEFAULT 50,
    p_offset       integer DEFAULT 0
)
RETURNS TABLE(
    total_count    bigint,
    client_code    varchar,
    client_name    varchar,
    edrpou         varchar,
    ipn            varchar,
    status_name    varchar,
    abc_group      text,
    invoices_count bigint,
    goods_revenue  numeric,
    avg_ticket     numeric,
    last_purchase_date date
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH client_stats AS (
        SELECT 
            c.code,
            c.name,
            c.edrpou,
            c.ipn,
            COALESCE(sr.status_name, 'Н/Д')::text AS sname,
            COUNT(DISTINCT d.id)::bigint AS inv_cnt,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS rev,
            MAX(d.invoice_date::date) AS last_dt
        FROM clients c
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        LEFT JOIN status_rules sr ON sr.id = c.current_status_id
        WHERE c.activity_direction_id = p_direction_id
          AND c.code NOT IN ('9653', '11230', '8814')
          AND (p_search IS NULL OR p_search = '' OR
               c.name ILIKE '%' || p_search || '%' OR
               c.code ILIKE '%' || p_search || '%' OR
               c.edrpou ILIKE '%' || p_search || '%')
        GROUP BY c.code, c.name, c.edrpou, c.ipn, sr.status_name
    ),
    abc_classified AS (
        SELECT *, get_abc_group_for_revenue(rev) AS abc_g FROM client_stats
    ),
    filtered AS (
        SELECT * FROM abc_classified
        WHERE (p_abc IS NULL OR p_abc = '' OR p_abc = 'ALL' OR abc_g = p_abc)
    ),
    counted AS (SELECT COUNT(*) AS total FROM filtered)
    SELECT 
        ct.total::bigint,
        f.code::varchar,
        f.name::varchar,
        f.edrpou::varchar,
        f.ipn::varchar,
        f.sname::varchar,
        f.abc_g::text,
        f.inv_cnt::bigint,
        ROUND(f.rev, 2)::numeric,
        ROUND(f.rev / NULLIF(f.inv_cnt, 0), 2)::numeric,
        f.last_dt::date
    FROM filtered f, counted ct
    ORDER BY f.rev DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$;

COMMENT ON FUNCTION public.get_direction_clients_list IS 
    'Пагинированный список клиентов направления с фильтрацией. Исключены: 9653, 11230, 8814.';

-- ============================================================
-- ФУНКЦИЯ 4: Продукты по размерам для направления (матрица)
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_direction_products_by_size(
    p_direction_id integer,
    p_year         integer DEFAULT 2026
)
RETURNS TABLE(
    product_code   varchar,
    product_name   varchar,
    diameter       numeric,
    wall           numeric,
    is_prof        boolean,
    total_quantity numeric,
    total_revenue  numeric,
    clients_count  bigint,
    invoices_count bigint,
    avg_price      numeric
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.code::varchar,
        p.name::varchar,
        pa.diameter::numeric,
        pa.wall::numeric,
        pa.is_prof::boolean,
        COALESCE(SUM(sl.quantity), 0)::numeric AS total_qty,
        COALESCE(SUM(sl.amount), 0)::numeric AS total_rev,
        COUNT(DISTINCT d.client_code)::bigint AS cli_cnt,
        COUNT(DISTINCT d.id)::bigint AS inv_cnt,
        ROUND(COALESCE(SUM(sl.amount), 0) / NULLIF(SUM(sl.quantity), 0), 2)::numeric AS avg_price
    FROM clients c
    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    JOIN products p ON p.code = sl.product_code AND p.is_service = FALSE
    CROSS JOIN LATERAL parse_pipe_attributes(p.name) pa
    WHERE c.activity_direction_id = p_direction_id
      AND c.code NOT IN ('9653', '11230', '8814')
      AND pa.diameter IS NOT NULL
    GROUP BY p.code, p.name, pa.diameter, pa.wall, pa.is_prof
    ORDER BY total_rev DESC;
END;
$function$;

COMMENT ON FUNCTION public.get_direction_products_by_size IS 
    'Продукты по размерам для направления — для матрицы. Исключены: 9653, 11230, 8814.';

-- ============================================================
-- ФУНКЦИЯ 5: Детализация по размеру — клиенты для дрилл-дауна
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_direction_size_drilldown(
    p_direction_id integer,
    p_year         integer DEFAULT 2026,
    p_diameter     numeric DEFAULT NULL,
    p_wall         numeric DEFAULT NULL
)
RETURNS TABLE(
    client_code   varchar,
    client_name   varchar,
    product_code  varchar,
    product_name  varchar,
    quantity      numeric,
    revenue       numeric,
    invoice_date  date
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        c.code::varchar,
        c.name::varchar,
        p.code::varchar,
        p.name::varchar,
        sl.quantity::numeric,
        sl.amount::numeric,
        d.invoice_date::date
    FROM clients c
    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    JOIN products p ON p.code = sl.product_code AND p.is_service = FALSE
    CROSS JOIN LATERAL parse_pipe_attributes(p.name) pa
    WHERE c.activity_direction_id = p_direction_id
      AND c.code NOT IN ('9653', '11230', '8814')
      AND (p_diameter IS NULL OR pa.diameter = p_diameter)
      AND (p_wall IS NULL OR pa.wall = p_wall)
    ORDER BY sl.amount DESC
    LIMIT 200;
END;
$function$;

COMMENT ON FUNCTION public.get_direction_size_drilldown IS 
    'Детализация продаж по конкретному диаметру/толщине для направления. Исключены: 9653, 11230, 8814.';

-- ============================================================
-- ФУНКЦИЯ 6: Клиенты — год к году (YoY) для направления
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_direction_clients_yoy(
    p_direction_id integer,
    p_year         integer DEFAULT 2026
)
RETURNS TABLE(
    client_code     varchar,
    client_name     varchar,
    status_name     varchar,
    curr_revenue    numeric,
    prev_revenue    numeric,
    yoy_pct         numeric,
    curr_invoices   bigint,
    prev_invoices   bigint,
    trend           text
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH curr AS (
        SELECT 
            c.code, c.name, COALESCE(sr.status_name, 'Н/Д') AS sname,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS rev,
            COUNT(DISTINCT d.id) AS inv_cnt
        FROM clients c
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        LEFT JOIN status_rules sr ON sr.id = c.current_status_id
        WHERE c.activity_direction_id = p_direction_id
          AND c.code NOT IN ('9653', '11230', '8814')
        GROUP BY c.code, c.name, sr.status_name
    ),
    prev AS (
        SELECT 
            c.code,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS rev,
            COUNT(DISTINCT d.id) AS inv_cnt
        FROM clients c
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year - 1
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.activity_direction_id = p_direction_id
          AND c.code NOT IN ('9653', '11230', '8814')
        GROUP BY c.code
    )
    SELECT 
        c.code::varchar,
        c.name::varchar,
        c.sname::varchar,
        ROUND(c.rev, 2)::numeric,
        ROUND(COALESCE(p.rev, 0), 2)::numeric,
        ROUND((c.rev - COALESCE(p.rev, 0)) * 100.0 / NULLIF(COALESCE(p.rev, 0), 0), 2)::numeric AS yoy,
        c.inv_cnt::bigint,
        COALESCE(p.inv_cnt, 0)::bigint,
        CASE 
            WHEN p.code IS NULL THEN 'new'
            WHEN c.rev > COALESCE(p.rev, 0) * 1.05 THEN 'up'
            WHEN c.rev < COALESCE(p.rev, 0) * 0.95 THEN 'down'
            ELSE 'flat'
        END::text AS trend
    FROM curr c
    LEFT JOIN prev p ON p.code = c.code
    ORDER BY c.rev DESC;
END;
$function$;

COMMENT ON FUNCTION public.get_direction_clients_yoy IS 
    'Год к году по клиентам направления: выручка, накладные, тренд. Исключены: 9653, 11230, 8814.';

-- ============================================================
-- ФУНКЦИЯ 7: Размеры — год к году (YoY) для направления
-- ============================================================
CREATE OR REPLACE FUNCTION public.get_direction_sizes_yoy(
    p_direction_id integer,
    p_year         integer DEFAULT 2026
)
RETURNS TABLE(
    diameter       numeric,
    wall           numeric,
    is_prof        boolean,
    curr_quantity  numeric,
    curr_revenue   numeric,
    prev_quantity  numeric,
    prev_revenue   numeric,
    qty_yoy_pct    numeric,
    rev_yoy_pct    numeric
)
LANGUAGE plpgsql STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH curr AS (
        SELECT pa.diameter, pa.wall, pa.is_prof,
               COALESCE(SUM(sl.quantity), 0) AS qty,
               COALESCE(SUM(sl.amount), 0) AS rev
        FROM clients c
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON p.code = sl.product_code AND p.is_service = FALSE
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) pa
        WHERE c.activity_direction_id = p_direction_id
          AND c.code NOT IN ('9653', '11230', '8814')
          AND pa.diameter IS NOT NULL
        GROUP BY pa.diameter, pa.wall, pa.is_prof
    ),
    prev AS (
        SELECT pa.diameter, pa.wall, pa.is_prof,
               COALESCE(SUM(sl.quantity), 0) AS qty,
               COALESCE(SUM(sl.amount), 0) AS rev
        FROM clients c
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year - 1
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON p.code = sl.product_code AND p.is_service = FALSE
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) pa
        WHERE c.activity_direction_id = p_direction_id
          AND c.code NOT IN ('9653', '11230', '8814')
          AND pa.diameter IS NOT NULL
        GROUP BY pa.diameter, pa.wall, pa.is_prof
    )
    SELECT 
        COALESCE(c.diameter, p.diameter)::numeric,
        COALESCE(c.wall, p.wall)::numeric,
        COALESCE(c.is_prof, p.is_prof)::boolean,
        COALESCE(c.qty, 0)::numeric,
        ROUND(COALESCE(c.rev, 0), 2)::numeric,
        COALESCE(p.qty, 0)::numeric,
        ROUND(COALESCE(p.rev, 0), 2)::numeric,
        ROUND((COALESCE(c.qty, 0) - COALESCE(p.qty, 0)) * 100.0 / NULLIF(COALESCE(p.qty, 0), 0), 2)::numeric,
        ROUND((COALESCE(c.rev, 0) - COALESCE(p.rev, 0)) * 100.0 / NULLIF(COALESCE(p.rev, 0), 0), 2)::numeric
    FROM curr c
    FULL OUTER JOIN prev p 
        ON p.diameter = c.diameter AND p.wall = c.wall AND p.is_prof = c.is_prof
    ORDER BY COALESCE(c.rev, 0) DESC;
END;
$function$;

COMMENT ON FUNCTION public.get_direction_sizes_yoy IS 
    'Год к году по размерам трубы для направления. Исключены: 9653, 11230, 8814.';

-- ============================================================
-- ПРОВЕРКА
-- ============================================================
SELECT proname AS function_name, pg_catalog.pg_get_function_result(oid) AS returns
FROM pg_proc 
WHERE proname IN (
    'get_direction_detail_kpi',
    'get_direction_top_clients',
    'get_direction_clients_list',
    'get_direction_products_by_size',
    'get_direction_size_drilldown',
    'get_direction_clients_yoy',
    'get_direction_sizes_yoy'
)
ORDER BY proname;
