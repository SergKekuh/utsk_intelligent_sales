-- ============================================================
-- МИГРАЦИЯ 56: Функции для страницы «Деталізація рекомендації»
-- Дата: 2026-10-06
-- ЦЕЛЬ: 5 новых SQL-функций для 5 вкладок новой страницы
-- РИСК: низкий (только новые функции, данные не трогаем)
-- ============================================================

-- БЭКАП (для страховки)
CREATE TABLE IF NOT EXISTS backup_functions_20261006_rec_detail AS
SELECT proname, pg_get_functiondef(oid) AS definition, now() AS backup_at
FROM pg_proc
WHERE proname IN ('get_profile_pipes_products_by_size', 'get_recommendations_by_size');

-- ═══════════════════════════════════════════════════════════
-- ФУНКЦИЯ 1: get_recommendation_detail_kpi
-- Сводка по одному размеру у клиента
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_recommendation_detail_kpi(
    p_client_code text,
    p_size_key text,
    p_year integer DEFAULT 2026
)
RETURNS TABLE(
    client_name varchar,
    size_display varchar,
    shape varchar,
    pipe_type_ua varchar,
    purchase_count bigint,
    total_revenue numeric,
    total_quantity numeric,
    share_pct numeric,
    avg_price numeric,
    last_purchase_date date,
    stock_tonnage numeric,
    segment_share_pct numeric,
    segment_clients_count bigint
)
LANGUAGE sql
STABLE
AS $function$
    WITH client_total AS (
        SELECT COALESCE(SUM(sl.amount), 0) AS total_client_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
    ),
    target AS (
        SELECT
            sl.amount,
            sl.quantity,
            d.id AS document_id,
            d.invoice_date
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON p.code = sl.product_code
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND COALESCE(p.is_service, FALSE) = FALSE
          AND sl.amount > 0
          AND (
                CASE
                    WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                        THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                    WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                        THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                    WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                        THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                    ELSE NULL
                END
              ) = p_size_key
    ),
    target_summary AS (
        SELECT
            COALESCE(SUM(amount), 0) AS revenue,
            COALESCE(SUM(quantity), 0) AS quantity,
            COUNT(DISTINCT document_id) AS purchase_count,
            MAX(invoice_date) AS last_purchase,
            ROUND(COALESCE(SUM(amount) / NULLIF(SUM(quantity), 0), 0)::numeric, 2) AS avg_price
        FROM target
    ),
    stock AS (
        SELECT COALESCE(SUM(p.in_stock_balance), 0) AS stock_tonnage
        FROM products p
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE COALESCE(p.is_service, FALSE) = FALSE
          AND (
                CASE
                    WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                        THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                    WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                        THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                    WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                        THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                    ELSE NULL
                END
              ) = p_size_key
    ),
    segment AS (
        SELECT
            COUNT(DISTINCT d.client_code) AS clients_count,
            COALESCE(SUM(sl.amount), 0) AS segment_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON p.code = sl.product_code
        JOIN clients c ON c.code = d.client_code
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE c.activity_direction_id = (
                SELECT activity_direction_id FROM clients WHERE code = p_client_code
              )
          AND c.code NOT IN ('9653', '11230', '8814')
          AND c.is_active_current = TRUE
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND COALESCE(p.is_service, FALSE) = FALSE
          AND sl.amount > 0
          AND (
                CASE
                    WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                        THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                    WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                        THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                    WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                        THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                    ELSE NULL
                END
              ) = p_size_key
    )
    SELECT
        c.name::varchar AS client_name,
        COALESCE(
            CASE
                WHEN ppa_sample.is_prof AND ppa_sample.prof_w = ppa_sample.prof_h AND ppa_sample.wall IS NOT NULL
                    THEN 'Квадрат ' || ppa_sample.prof_w::TEXT || '×' || ppa_sample.prof_h::TEXT || '×' || ppa_sample.wall::TEXT
                WHEN ppa_sample.is_prof AND ppa_sample.prof_w = ppa_sample.prof_h
                    THEN 'Квадрат ' || ppa_sample.prof_w::TEXT || '×' || ppa_sample.prof_h::TEXT
                WHEN ppa_sample.is_prof AND ppa_sample.prof_w <> ppa_sample.prof_h AND ppa_sample.wall IS NOT NULL
                    THEN 'Профіль ' || ppa_sample.prof_w::TEXT || '×' || ppa_sample.prof_h::TEXT || '×' || ppa_sample.wall::TEXT
                WHEN ppa_sample.is_prof AND ppa_sample.prof_w <> ppa_sample.prof_h
                    THEN 'Профіль ' || ppa_sample.prof_w::TEXT || '×' || ppa_sample.prof_h::TEXT
                WHEN NOT ppa_sample.is_prof AND ppa_sample.diameter IS NOT NULL AND ppa_sample.wall IS NOT NULL
                    THEN 'Кругла ' || ppa_sample.diameter::TEXT || '×' || ppa_sample.wall::TEXT
                ELSE p_size_key
            END,
            p_size_key
        )::varchar AS size_display,
        CASE
            WHEN ppa_sample.is_prof = FALSE THEN 'round'
            WHEN ppa_sample.prof_w = ppa_sample.prof_h THEN 'square'
            ELSE 'rect'
        END::varchar AS shape,
        CASE
            WHEN ppa_sample.is_prof = FALSE THEN 'Кругла труба'
            WHEN ppa_sample.prof_w = ppa_sample.prof_h THEN 'Квадратна труба'
            ELSE 'Прямокутна труба'
        END::varchar AS pipe_type_ua,
        COALESCE(ts.purchase_count, 0)::bigint AS purchase_count,
        ROUND(COALESCE(ts.revenue, 0), 2)::numeric AS total_revenue,
        ROUND(COALESCE(ts.quantity, 0), 3)::numeric AS total_quantity,
        ROUND(
            COALESCE(ts.revenue, 0) / NULLIF(ct.total_client_revenue, 0) * 100,
            2
        )::numeric AS share_pct,
        ROUND(COALESCE(ts.avg_price, 0), 2)::numeric AS avg_price,
        ts.last_purchase::date AS last_purchase_date,
        ROUND(COALESCE(st.stock_tonnage, 0), 3)::numeric AS stock_tonnage,
        ROUND(
            COALESCE(ts.revenue, 0) / NULLIF(seg.segment_revenue, 0) * 100,
            2
        )::numeric AS segment_share_pct,
        COALESCE(seg.clients_count, 0)::bigint AS segment_clients_count
    FROM clients c
    CROSS JOIN client_total ct
    CROSS JOIN target_summary ts
    CROSS JOIN stock st
    CROSS JOIN segment seg
    LEFT JOIN LATERAL (
        SELECT ppa2.*
        FROM products p2
        CROSS JOIN LATERAL parse_pipe_attributes(p2.name) ppa2
        WHERE COALESCE(p2.is_service, FALSE) = FALSE
          AND (
                CASE
                    WHEN ppa2.is_prof AND ppa2.prof_w IS NOT NULL AND ppa2.prof_h IS NOT NULL AND ppa2.wall IS NOT NULL
                        THEN 'prof_' || ppa2.prof_w::TEXT || 'x' || ppa2.prof_h::TEXT || 'x' || ppa2.wall::TEXT
                    WHEN ppa2.is_prof AND ppa2.prof_w IS NOT NULL AND ppa2.prof_h IS NOT NULL
                        THEN 'prof_' || ppa2.prof_w::TEXT || 'x' || ppa2.prof_h::TEXT
                    WHEN NOT ppa2.is_prof AND ppa2.diameter IS NOT NULL AND ppa2.wall IS NOT NULL
                        THEN 'round_' || ppa2.diameter::TEXT || 'x' || ppa2.wall::TEXT
                    ELSE NULL
                  END
              ) = p_size_key
        LIMIT 1
    ) ppa_sample ON TRUE
    WHERE c.code = p_client_code;
$function$;

-- ═══════════════════════════════════════════════════════════
-- ФУНКЦИЯ 2: get_recommendation_detail_monthly
-- Помесячная динамика (2026 vs 2025) для одного размера
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_recommendation_detail_monthly(
    p_client_code text,
    p_size_key text,
    p_year integer DEFAULT 2026
)
RETURNS TABLE(
    month_num int,
    month_name varchar,
    revenue_cur numeric,
    revenue_prev numeric,
    delta_abs numeric,
    delta_pct numeric
)
LANGUAGE sql
STABLE
AS $function$
    WITH month_series AS (
        SELECT generate_series(1, 12) AS m
    ),
    base AS (
        SELECT
            EXTRACT(MONTH FROM d.invoice_date)::int AS month_num,
            EXTRACT(YEAR FROM d.invoice_date)::int AS year_num,
            sl.amount
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON p.code = sl.product_code
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) IN (p_year, p_year - 1)
          AND COALESCE(p.is_service, FALSE) = FALSE
          AND sl.amount > 0
          AND CASE
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                ELSE NULL
              END = p_size_key
    ),
    cur AS (
        SELECT month_num, SUM(amount)::numeric AS revenue
        FROM base
        WHERE year_num = p_year
        GROUP BY month_num
    ),
    prev AS (
        SELECT month_num, SUM(amount)::numeric AS revenue
        FROM base
        WHERE year_num = p_year - 1
        GROUP BY month_num
    )
    SELECT
        ms.m AS month_num,
        (ARRAY['Січ','Лют','Бер','Кві','Тра','Чер','Лип','Сер','Вер','Жов','Лис','Гру'])[ms.m]::varchar AS month_name,
        ROUND(COALESCE(cur.revenue, 0), 2)::numeric AS revenue_cur,
        ROUND(COALESCE(prev.revenue, 0), 2)::numeric AS revenue_prev,
        ROUND(COALESCE(cur.revenue, 0) - COALESCE(prev.revenue, 0), 2)::numeric AS delta_abs,
        ROUND(
            (COALESCE(cur.revenue, 0) - COALESCE(prev.revenue, 0))
            / NULLIF(prev.revenue, 0) * 100, 2
        )::numeric AS delta_pct
    FROM month_series ms
    LEFT JOIN cur ON cur.month_num = ms.m
    LEFT JOIN prev ON prev.month_num = ms.m
    ORDER BY ms.m;
$function$;

-- ═══════════════════════════════════════════════════════════
-- ФУНКЦИЯ 3: get_recommendation_detail_segment
-- Сравнение клиента с сегментом (отраслью)
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_recommendation_detail_segment(
    p_client_code text,
    p_size_key text,
    p_year integer DEFAULT 2026
)
RETURNS TABLE(
    scope varchar,
    revenue numeric,
    quantity numeric,
    avg_price numeric,
    clients_count bigint,
    invoices_count bigint
)
LANGUAGE sql
STABLE
AS $function$
    WITH direction AS (
        SELECT activity_direction_id
        FROM clients
        WHERE code = p_client_code
    ),
    base AS (
        SELECT
            d.client_code,
            d.id AS document_id,
            sl.amount,
            sl.quantity,
            CASE
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                ELSE NULL
            END AS size_key
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON p.code = sl.product_code
        JOIN clients c ON c.code = d.client_code
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND COALESCE(p.is_service, FALSE) = FALSE
          AND sl.amount > 0
          AND c.code NOT IN ('9653', '11230', '8814')
          AND c.is_active_current = TRUE
          AND c.activity_direction_id = (SELECT activity_direction_id FROM direction)
    ),
    client_stats AS (
        SELECT
            'client'::varchar AS scope,
            ROUND(SUM(amount), 2)::numeric AS revenue,
            ROUND(SUM(quantity), 3)::numeric AS quantity,
            ROUND(SUM(amount) / NULLIF(SUM(quantity), 0), 2)::numeric AS avg_price,
            COUNT(DISTINCT client_code)::bigint AS clients_count,
            COUNT(DISTINCT document_id)::bigint AS invoices_count
        FROM base
        WHERE client_code = p_client_code
          AND size_key = p_size_key
    ),
    segment_stats AS (
        SELECT
            'segment'::varchar AS scope,
            ROUND(SUM(amount), 2)::numeric AS revenue,
            ROUND(SUM(quantity), 3)::numeric AS quantity,
            ROUND(SUM(amount) / NULLIF(SUM(quantity), 0), 2)::numeric AS avg_price,
            COUNT(DISTINCT client_code)::bigint AS clients_count,
            COUNT(DISTINCT document_id)::bigint AS invoices_count
        FROM base
        WHERE size_key = p_size_key
    )
    SELECT * FROM client_stats
    UNION ALL
    SELECT * FROM segment_stats;
$function$;

-- ═══════════════════════════════════════════════════════════
-- ФУНКЦИЯ 4: get_recommendation_detail_products
-- Универсальная — работает и с круглыми, и с профильными
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_recommendation_detail_products(
    p_client_code text,
    p_size_key text,
    p_year integer DEFAULT 2026
)
RETURNS TABLE(
    product_code varchar,
    product_name varchar,
    quantity numeric,
    revenue numeric,
    avg_price numeric,
    invoices bigint,
    stock_tonnage numeric,
    last_purchase date
)
LANGUAGE sql
STABLE
AS $function$
    SELECT
        p.code::varchar AS product_code,
        p.name::varchar AS product_name,
        ROUND(SUM(sl.quantity), 3)::numeric AS quantity,
        ROUND(SUM(sl.amount), 2)::numeric AS revenue,
        ROUND(SUM(sl.amount) / NULLIF(SUM(sl.quantity), 0), 2)::numeric AS avg_price,
        COUNT(DISTINCT sl.document_id)::bigint AS invoices,
        ROUND(COALESCE(p.in_stock_balance, 0)::numeric, 3) AS stock_tonnage,
        MAX(d.invoice_date)::date AS last_purchase
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    JOIN products p ON p.code = sl.product_code
    CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
    WHERE d.client_code = p_client_code
      AND EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND COALESCE(p.is_service, FALSE) = FALSE
      AND sl.amount > 0
      AND CASE
            WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
            WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
            WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
            ELSE NULL
          END = p_size_key
    GROUP BY p.code, p.name, p.in_stock_balance
    ORDER BY revenue DESC;
$function$;

-- ═══════════════════════════════════════════════════════════
-- ФУНКЦИЯ 5: get_recommendation_detail_similar
-- Похожие размеры (близкие по диаметру/сечению)
-- ═══════════════════════════════════════════════════════════
CREATE OR REPLACE FUNCTION public.get_recommendation_detail_similar(
    p_client_code text,
    p_size_key text,
    p_year integer DEFAULT 2026
)
RETURNS TABLE(
    similar_size_key varchar,
    size_display varchar,
    pipe_type_ua varchar,
    similarity_reason varchar,
    client_bought boolean,
    segment_revenue numeric,
    stock_tonnage numeric
)
LANGUAGE sql
STABLE
AS $function$
    WITH target AS (
        SELECT
            ppa.is_prof, ppa.prof_w, ppa.prof_h, ppa.diameter, ppa.wall
        FROM products p
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE COALESCE(p.is_service, FALSE) = FALSE
          AND (
                CASE
                    WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                        THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                    WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                        THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                    WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                        THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                    ELSE NULL
                  END
              ) = p_size_key
        LIMIT 1
    ),
    client_dir AS (
        SELECT activity_direction_id FROM clients WHERE code = p_client_code
    ),
    stock_by_size AS (
        SELECT
            CASE
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                ELSE NULL
            END AS size_key,
            SUM(COALESCE(p.in_stock_balance, 0)) AS stock_total
        FROM products p
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE COALESCE(p.is_service, FALSE) = FALSE
        GROUP BY 1
    )
    SELECT
        ppa_sim.size_key::varchar AS similar_size_key,
        CASE
            WHEN ppa_sim.is_prof AND ppa_sim.prof_w = ppa_sim.prof_h AND ppa_sim.wall IS NOT NULL
                THEN 'Квадрат ' || ppa_sim.prof_w::TEXT || '×' || ppa_sim.prof_h::TEXT || '×' || ppa_sim.wall::TEXT
            WHEN ppa_sim.is_prof AND ppa_sim.prof_w = ppa_sim.prof_h
                THEN 'Квадрат ' || ppa_sim.prof_w::TEXT || '×' || ppa_sim.prof_h::TEXT
            WHEN ppa_sim.is_prof AND ppa_sim.prof_w <> ppa_sim.prof_h AND ppa_sim.wall IS NOT NULL
                THEN 'Профіль ' || ppa_sim.prof_w::TEXT || '×' || ppa_sim.prof_h::TEXT || '×' || ppa_sim.wall::TEXT
            WHEN ppa_sim.is_prof AND ppa_sim.prof_w <> ppa_sim.prof_h
                THEN 'Профіль ' || ppa_sim.prof_w::TEXT || '×' || ppa_sim.prof_h::TEXT
            WHEN NOT ppa_sim.is_prof AND ppa_sim.diameter IS NOT NULL AND ppa_sim.wall IS NOT NULL
                THEN 'Кругла ' || ppa_sim.diameter::TEXT || '×' || ppa_sim.wall::TEXT
            ELSE ppa_sim.size_key
        END::varchar AS size_display,
        CASE
            WHEN ppa_sim.is_prof = FALSE THEN 'Кругла труба'
            WHEN ppa_sim.prof_w = ppa_sim.prof_h THEN 'Квадратна труба'
            ELSE 'Прямокутна труба'
        END::varchar AS pipe_type_ua,
        CASE
            WHEN NOT ppa_sim.is_prof THEN '±5мм діаметр'
            WHEN ppa_sim.prof_w = (SELECT prof_w FROM target) AND ppa_sim.prof_h = (SELECT prof_h FROM target)
                THEN 'Інша стінка'
            ELSE 'Близький перетин'
        END::varchar AS similarity_reason,
        EXISTS (
            SELECT 1 FROM documents d2
            JOIN sales_lines sl2 ON sl2.document_id = d2.id
            JOIN products p2 ON p2.code = sl2.product_code
            CROSS JOIN LATERAL parse_pipe_attributes(p2.name) ppa2
            WHERE d2.client_code = p_client_code
              AND EXTRACT(YEAR FROM d2.invoice_date) = p_year
              AND COALESCE(p2.is_service, FALSE) = FALSE
              AND (
                    CASE
                        WHEN ppa2.is_prof AND ppa2.prof_w IS NOT NULL AND ppa2.prof_h IS NOT NULL AND ppa2.wall IS NOT NULL
                            THEN 'prof_' || ppa2.prof_w::TEXT || 'x' || ppa2.prof_h::TEXT || 'x' || ppa2.wall::TEXT
                        WHEN ppa2.is_prof AND ppa2.prof_w IS NOT NULL AND ppa2.prof_h IS NOT NULL
                            THEN 'prof_' || ppa2.prof_w::TEXT || 'x' || ppa2.prof_h::TEXT
                        WHEN NOT ppa2.is_prof AND ppa2.diameter IS NOT NULL AND ppa2.wall IS NOT NULL
                            THEN 'round_' || ppa2.diameter::TEXT || 'x' || ppa2.wall::TEXT
                        ELSE NULL
                      END
                  ) = ppa_sim.size_key
        )::boolean AS client_bought,
        ROUND(COALESCE(SUM(sl_sim.amount), 0), 2)::numeric AS segment_revenue,
        ROUND(COALESCE(MAX(sbs.stock_total), 0), 3)::numeric AS stock_tonnage
    FROM documents d_sim
    JOIN sales_lines sl_sim ON sl_sim.document_id = d_sim.id
    JOIN products p_sim ON p_sim.code = sl_sim.product_code
    JOIN clients c_sim ON c_sim.code = d_sim.client_code
    CROSS JOIN LATERAL parse_pipe_attributes(p_sim.name) ppa_sim_raw
    CROSS JOIN LATERAL (
        SELECT
            ppa_sim_raw.diameter,
            ppa_sim_raw.wall,
            ppa_sim_raw.prof_w,
            ppa_sim_raw.prof_h,
            ppa_sim_raw.is_prof,
            CASE
                WHEN ppa_sim_raw.is_prof AND ppa_sim_raw.prof_w IS NOT NULL AND ppa_sim_raw.prof_h IS NOT NULL AND ppa_sim_raw.wall IS NOT NULL
                    THEN 'prof_' || ppa_sim_raw.prof_w::TEXT || 'x' || ppa_sim_raw.prof_h::TEXT || 'x' || ppa_sim_raw.wall::TEXT
                WHEN ppa_sim_raw.is_prof AND ppa_sim_raw.prof_w IS NOT NULL AND ppa_sim_raw.prof_h IS NOT NULL
                    THEN 'prof_' || ppa_sim_raw.prof_w::TEXT || 'x' || ppa_sim_raw.prof_h::TEXT
                WHEN NOT ppa_sim_raw.is_prof AND ppa_sim_raw.diameter IS NOT NULL AND ppa_sim_raw.wall IS NOT NULL
                    THEN 'round_' || ppa_sim_raw.diameter::TEXT || 'x' || ppa_sim_raw.wall::TEXT
                ELSE NULL
            END AS size_key
    ) ppa_sim
    LEFT JOIN stock_by_size sbs ON sbs.size_key = ppa_sim.size_key
    WHERE EXTRACT(YEAR FROM d_sim.invoice_date) = p_year
      AND COALESCE(p_sim.is_service, FALSE) = FALSE
      AND sl_sim.amount > 0
      AND c_sim.activity_direction_id = (SELECT activity_direction_id FROM client_dir)
      AND c_sim.code NOT IN ('9653', '11230', '8814')
      AND c_sim.is_active_current = TRUE
      AND ppa_sim.size_key <> p_size_key
      AND (
          ( (SELECT is_prof FROM target) = FALSE
            AND NOT ppa_sim.is_prof
            AND ABS(ppa_sim.diameter - (SELECT diameter FROM target)) <= 5
          )
          OR
          ( (SELECT is_prof FROM target) = TRUE
            AND ppa_sim.is_prof
            AND (
                (ppa_sim.prof_w = (SELECT prof_w FROM target) AND ppa_sim.prof_h = (SELECT prof_h FROM target))
                OR (ABS(ppa_sim.prof_w - (SELECT prof_w FROM target)) <= 10 AND ABS(ppa_sim.prof_h - (SELECT prof_h FROM target)) <= 10)
            )
          )
      )
    GROUP BY ppa_sim.size_key, ppa_sim.is_prof, ppa_sim.prof_w, ppa_sim.prof_h, ppa_sim.diameter, ppa_sim.wall
    ORDER BY segment_revenue DESC NULLS LAST
    LIMIT 10;
$function$;

-- ПРОВЕРКА
SELECT 'Migration 56 applied' AS status;
SELECT routine_name FROM information_schema.routines
WHERE routine_name LIKE 'get_recommendation_detail%';
