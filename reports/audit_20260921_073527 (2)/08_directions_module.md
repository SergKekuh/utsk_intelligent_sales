# Модуль отраслей и направлений деятельности (`directions`)

## 📌 Архитектура модуля
Модуль обеспечивает отраслевую сегментацию портфеля клиентов, агрегацию финансовых и количественных метрик по 16 отраслям бизнеса и предоставление сравнительной аналитики.

### Файлы модуля
- **API Роутер:** `utsk_web/backend/app/api/directions.py`
- **Роуты страниц:** `utsk_web/backend/app/api/pages.py`
- **Главная страница:** `utsk_web/frontend/static/directions-analytics.html`
- **Специализированные дашборды:**
  - `directions-revenue-analytics.html` (Аналитика выручки по отраслям)
  - `directions-clients-analytics.html` (Аналитика клиентской базы)
  - `directions-invoices-analytics.html` (Аналитика транзакций и накладных)
  - `directions-avg-check-analytics.html` (Аналитика среднего чека)
  - `directions-leader-analytics.html` (Анализ лидеров отраслей)

---

## ⚙️ SQL-функции модуля (9 функций)

### 1. `get_directions_kpi(p_year INT)`
```sql
CREATE OR REPLACE FUNCTION public.get_directions_kpi(p_year integer DEFAULT 2026)
 RETURNS TABLE(total_revenue numeric, total_clients bigint, total_invoices bigint, avg_ticket numeric, top_direction_id integer, top_direction_name text, top_direction_revenue numeric, top_direction_share_pct numeric, active_directions_count bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
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
$function$
```

### 2. `get_directions_summary(p_year INT)`
```sql
CREATE OR REPLACE FUNCTION public.get_directions_summary(p_year integer DEFAULT 2026)
 RETURNS TABLE(id integer, name character varying, icon character varying, color character varying, clients_count bigint, total_clients_in_base bigint, invoices_count bigint, goods_revenue numeric, avg_ticket numeric, revenue_share_pct numeric, clients_share_pct numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
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
    GROUP BY ad.id, ad.name, ad.icon, ad.color
    ORDER BY goods_revenue DESC, clients_count DESC;
END;
$function$
```

### 3. `get_directions_monthly_dynamics(p_year INT)`
```sql
CREATE OR REPLACE FUNCTION public.get_directions_monthly_dynamics(p_year integer DEFAULT 2026)
 RETURNS TABLE(direction_id integer, direction_name character varying, month_num integer, month_name text, goods_revenue numeric, clients_count bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
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
$function$
```

### 4. `get_direction_companies(p_direction_id INT, p_year INT, p_limit INT, p_offset INT, p_search TEXT, p_sort_by TEXT, p_sort_dir TEXT)`
```sql
CREATE OR REPLACE FUNCTION public.get_direction_companies(p_direction_id integer, p_year integer DEFAULT 2026, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text)
 RETURNS TABLE(code character varying, name character varying, status_name character varying, goods_revenue numeric, invoices_count bigint, avg_ticket numeric, abc_group character varying, edrpou character varying, ipn character varying, last_purchase_date text, total_matching_count bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
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
$function$
```

### 5. `get_directions_revenue_analytics(p_year INT)`
```sql
CREATE OR REPLACE FUNCTION public.get_directions_revenue_analytics(p_year integer DEFAULT 2026)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_result JSON;
BEGIN
    WITH base AS (
        SELECT 
            ad.id AS dir_id,
            ad.name AS dir_name,
            COALESCE(ad.icon, '🌐') AS dir_icon,
            COALESCE(ad.color, '#64748b') AS dir_color,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS revenue,
            COUNT(DISTINCT c.code) AS clients_count,
            COUNT(DISTINCT d.id) AS docs_count,
            COUNT(DISTINCT CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.product_code END) AS products_count
        FROM activity_directions ad
        JOIN clients c ON c.activity_direction_id = ad.id
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY ad.id, ad.name, ad.icon, ad.color
        HAVING COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) > 0
    ),
    totals AS (
        SELECT 
            COALESCE(SUM(revenue), 0) AS grand_total,
            (SELECT COUNT(DISTINCT d2.client_code) FROM documents d2 WHERE EXTRACT(YEAR FROM d2.invoice_date) = p_year) AS total_clients,
            (SELECT COUNT(DISTINCT d2.id) FROM documents d2 WHERE EXTRACT(YEAR FROM d2.invoice_date) = p_year) AS total_docs
        FROM base
    ),
    yoy_data AS (
        SELECT 
            c.activity_direction_id AS dir_id,
            EXTRACT(YEAR FROM d.invoice_date)::INT AS yr,
            ROUND(COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0), 2) AS revenue
        FROM clients c
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) BETWEEN (p_year - 2) AND p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY c.activity_direction_id, yr
    ),
    monthly AS (
        SELECT 
            c.activity_direction_id AS dir_id,
            EXTRACT(MONTH FROM d.invoice_date)::INT AS month,
            ROUND(COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0), 2) AS revenue
        FROM clients c
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY c.activity_direction_id, month
    ),
    top_products AS (
        SELECT 
            sl.product_code,
            COALESCE(p.name, sl.product_code) AS product_name,
            ROUND(SUM(sl.amount), 2) AS revenue,
            ROUND(SUM(sl.quantity), 3) AS qty
        FROM sales_lines sl
        JOIN documents d ON d.id = sl.document_id
        JOIN products p ON p.code = sl.product_code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND COALESCE(p.is_service, FALSE) = FALSE
        GROUP BY sl.product_code, p.name
        ORDER BY revenue DESC
        LIMIT 10
    )
    SELECT json_build_object(
        'year', p_year,
        'total_revenue', (SELECT ROUND(grand_total, 2) FROM totals),
        'total_clients', (SELECT total_clients FROM totals),
        'total_docs', (SELECT total_docs FROM totals),
        'directions', (
            SELECT json_agg(json_build_object(
                'direction_id', b.dir_id,
                'direction_name', b.dir_name,
                'icon', b.dir_icon,
                'color', b.dir_color,
                'revenue', ROUND(b.revenue, 2),
                'pct', ROUND(b.revenue / NULLIF((SELECT grand_total FROM totals), 0) * 100, 2),
                'clients_count', b.clients_count,
                'docs_count', b.docs_count,
                'products_count', b.products_count,
                'avg_check', ROUND(b.revenue / NULLIF(b.docs_count, 0), 2),
                'yoy', (
                    SELECT json_object_agg(
                        y.yr::TEXT,
                        y.revenue
                    )
                    FROM yoy_data y
                    WHERE y.dir_id = b.dir_id
                ),
                'monthly', (
                    SELECT json_agg(json_build_object(
                        'month', m.month,
                        'revenue', m.revenue
                    ) ORDER BY m.month)
                    FROM monthly m
                    WHERE m.dir_id = b.dir_id
                )
            ) ORDER BY b.revenue DESC)
            FROM base b
        ),
        'top_products', (
            SELECT json_agg(json_build_object(
                'product_code', tp.product_code,
                'product_name', tp.product_name,
                'revenue', tp.revenue,
                'qty', tp.qty
            ))
            FROM top_products tp
        )
    ) INTO v_result;

    RETURN v_result;
END;
$function$
```

### 6. `get_directions_clients_analytics(p_year INT)`
```sql
CREATE OR REPLACE FUNCTION public.get_directions_clients_analytics(p_year integer DEFAULT 2026)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_result JSON;
BEGIN
    WITH client_summary AS (
        SELECT 
            c.activity_direction_id AS dir_id,
            c.code AS client_code,
            c.name AS client_name,
            COALESCE(c.edrpou, '—') AS edrpou,
            COALESCE(sr.status_name, 'Активный') AS status_name,
            c.current_status_id,
            COUNT(DISTINCT d.id) AS invoices_count,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS revenue
        FROM clients c
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        LEFT JOIN status_rules sr ON sr.id = c.current_status_id
        GROUP BY c.activity_direction_id, c.code, c.name, c.edrpou, sr.status_name, c.current_status_id
    ),
    dir_metrics AS (
        SELECT 
            ad.id AS dir_id,
            ad.name AS dir_name,
            COALESCE(ad.icon, '🌐') AS dir_icon,
            COALESCE(ad.color, '#64748b') AS dir_color,
            COUNT(cs.client_code) AS clients_count,
            COUNT(cs.client_code) FILTER (WHERE cs.edrpou != '—' AND cs.edrpou != '') AS with_edrpou,
            COUNT(cs.client_code) FILTER (WHERE cs.edrpou = '—' OR cs.edrpou = '') AS without_edrpou,
            COUNT(cs.client_code) FILTER (WHERE cs.current_status_id = 1) AS new_clients,
            COUNT(cs.client_code) FILTER (WHERE cs.current_status_id IN (2, 3)) AS repeat_clients,
            COUNT(cs.client_code) FILTER (WHERE cs.current_status_id IN (4, 5, 6, 7)) AS regular_clients,
            COUNT(cs.client_code) FILTER (WHERE cs.current_status_id = 10) AS returned_clients,
            ROUND(SUM(cs.revenue), 2) AS revenue,
            ROUND(SUM(cs.revenue) / NULLIF(COUNT(cs.client_code), 0), 2) AS avg_revenue_per_client
        FROM activity_directions ad
        LEFT JOIN client_summary cs ON cs.dir_id = ad.id
        GROUP BY ad.id, ad.name, ad.icon, ad.color
        HAVING COUNT(cs.client_code) > 0
    ),
    statuses_by_dir AS (
        SELECT 
            cs.dir_id,
            cs.status_name,
            COUNT(DISTINCT cs.client_code) AS clients_count
        FROM client_summary cs
        GROUP BY cs.dir_id, cs.status_name
    ),
    top_clients_ranked AS (
        SELECT 
            cs.*,
            ROW_NUMBER() OVER (PARTITION BY cs.dir_id ORDER BY cs.revenue DESC) AS rn
        FROM client_summary cs
    ),
    total_stats AS (
        SELECT 
            (SELECT COUNT(DISTINCT d2.client_code) FROM documents d2 WHERE EXTRACT(YEAR FROM d2.invoice_date) = p_year) AS total_clients,
            (SELECT COUNT(DISTINCT c2.code) FROM clients c2) AS total_in_db,
            (SELECT COUNT(DISTINCT d2.client_code) FROM documents d2 JOIN clients c2 ON c2.code = d2.client_code WHERE EXTRACT(YEAR FROM d2.invoice_date) = p_year AND c2.edrpou IS NOT NULL AND c2.edrpou != '') AS total_with_edrpou
    )
    SELECT json_build_object(
        'year', p_year,
        'total_clients', (SELECT total_clients FROM total_stats),
        'total_in_db', (SELECT total_in_db FROM total_stats),
        'total_with_edrpou', (SELECT total_with_edrpou FROM total_stats),
        'directions', (
            SELECT json_agg(json_build_object(
                'direction_id', dm.dir_id,
                'direction_name', dm.dir_name,
                'icon', dm.dir_icon,
                'color', dm.dir_color,
                'clients_count', dm.clients_count,
                'share_pct', ROUND(dm.clients_count * 100.0 / NULLIF((SELECT total_clients FROM total_stats), 0), 2),
                'with_edrpou', dm.with_edrpou,
                'without_edrpou', dm.without_edrpou,
                'new_clients', dm.new_clients,
                'repeat_clients', dm.repeat_clients,
                'regular_clients', dm.regular_clients,
                'returned_clients', dm.returned_clients,
                'revenue', dm.revenue,
                'avg_revenue_per_client', dm.avg_revenue_per_client,
                'statuses', (
                    SELECT json_agg(json_build_object(
                        'status_name', s.status_name,
                        'clients_count', s.clients_count
                    ) ORDER BY s.clients_count DESC)
                    FROM statuses_by_dir s
                    WHERE s.dir_id = dm.dir_id
                ),
                'top_clients', (
                    SELECT json_agg(json_build_object(
                        'code', tc.client_code,
                        'name', tc.client_name,
                        'edrpou', tc.edrpou,
                        'status_name', tc.status_name,
                        'revenue', ROUND(tc.revenue, 2),
                        'invoices_count', tc.invoices_count
                    ) ORDER BY tc.revenue DESC)
                    FROM top_clients_ranked tc
                    WHERE tc.dir_id = dm.dir_id AND tc.rn <= 10
                )
            ) ORDER BY dm.clients_count DESC)
            FROM dir_metrics dm
        ),
        'top_overall_clients', (
            SELECT json_agg(json_build_object(
                'code', t.client_code,
                'name', t.client_name,
                'edrpou', t.edrpou,
                'direction_name', ad.name,
                'status_name', t.status_name,
                'revenue', ROUND(t.revenue, 2),
                'invoices_count', t.invoices_count
            ) ORDER BY t.revenue DESC)
            FROM (
                SELECT * FROM client_summary ORDER BY revenue DESC LIMIT 10
            ) t
            LEFT JOIN activity_directions ad ON ad.id = t.dir_id
        )
    ) INTO v_result;

    RETURN v_result;
END;
$function$
```

### 7. `get_directions_invoices_analytics(p_year INT)`
```sql
CREATE OR REPLACE FUNCTION public.get_directions_invoices_analytics(p_year integer DEFAULT 2026)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_result JSON;
BEGIN
    WITH doc_goods AS (
        SELECT 
            c.activity_direction_id AS dir_id,
            d.id AS doc_id,
            d.doc_number,
            d.invoice_date,
            c.code AS client_code,
            c.name AS client_name,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_amount
        FROM documents d
        JOIN clients c ON c.code = d.client_code
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY c.activity_direction_id, d.id, d.doc_number, d.invoice_date, c.code, c.name
    ),
    dir_metrics AS (
        SELECT 
            ad.id AS dir_id,
            ad.name AS dir_name,
            COALESCE(ad.icon, '🌐') AS dir_icon,
            COALESCE(ad.color, '#64748b') AS dir_color,
            COUNT(dg.doc_id) AS invoices_count,
            COUNT(DISTINCT dg.client_code) AS clients_count,
            ROUND(SUM(dg.goods_amount), 2) AS total_amount,
            ROUND(AVG(dg.goods_amount), 2) AS avg_invoice,
            ROUND(MIN(NULLIF(dg.goods_amount, 0)), 2) AS min_invoice,
            ROUND(MAX(dg.goods_amount), 2) AS max_invoice,
            ROUND(COUNT(dg.doc_id)::NUMERIC / NULLIF(COUNT(DISTINCT dg.client_code), 0), 2) AS invoices_per_client
        FROM activity_directions ad
        LEFT JOIN doc_goods dg ON dg.dir_id = ad.id
        GROUP BY ad.id, ad.name, ad.icon, ad.color
        HAVING COUNT(dg.doc_id) > 0
    ),
    monthly_invoices AS (
        SELECT 
            dg.dir_id,
            EXTRACT(MONTH FROM dg.invoice_date)::INT AS month,
            COUNT(dg.doc_id) AS invoices_count,
            ROUND(SUM(dg.goods_amount), 2) AS amount
        FROM doc_goods dg
        GROUP BY dg.dir_id, month
    ),
    dow_stats AS (
        SELECT 
            EXTRACT(ISODOW FROM dg.invoice_date)::INT AS dow,
            CASE EXTRACT(ISODOW FROM dg.invoice_date)::INT
                WHEN 1 THEN 'Понедельник'
                WHEN 2 THEN 'Вторник'
                WHEN 3 THEN 'Среда'
                WHEN 4 THEN 'Четверг'
                WHEN 5 THEN 'Пятница'
                WHEN 6 THEN 'Суббота'
                WHEN 7 THEN 'Воскресенье'
            END AS dow_name,
            COUNT(dg.doc_id) AS invoices_count,
            ROUND(SUM(dg.goods_amount), 2) AS amount
        FROM doc_goods dg
        GROUP BY dow, dow_name
        ORDER BY dow
    ),
    totals AS (
        SELECT 
            COUNT(dg.doc_id) AS total_invoices,
            COUNT(DISTINCT dg.client_code) AS total_clients,
            ROUND(SUM(dg.goods_amount), 2) AS total_amount,
            ROUND(AVG(dg.goods_amount), 2) AS avg_invoice,
            ROUND(MIN(NULLIF(dg.goods_amount, 0)), 2) AS min_invoice,
            ROUND(MAX(dg.goods_amount), 2) AS max_invoice
        FROM doc_goods dg
    ),
    top_invoices AS (
        SELECT 
            dg.doc_id,
            COALESCE(dg.doc_number, '—') AS doc_number,
            TO_CHAR(dg.invoice_date, 'YYYY-MM-DD') AS invoice_date,
            dg.client_code,
            dg.client_name,
            COALESCE(ad.name, '—') AS direction_name,
            ROUND(dg.goods_amount, 2) AS amount
        FROM doc_goods dg
        LEFT JOIN activity_directions ad ON ad.id = dg.dir_id
        ORDER BY dg.goods_amount DESC
        LIMIT 10
    )
    SELECT json_build_object(
        'year', p_year,
        'total_invoices', (SELECT total_invoices FROM totals),
        'total_clients', (SELECT total_clients FROM totals),
        'total_amount', (SELECT total_amount FROM totals),
        'avg_invoice', (SELECT avg_invoice FROM totals),
        'min_invoice', (SELECT min_invoice FROM totals),
        'max_invoice', (SELECT max_invoice FROM totals),
        'directions', (
            SELECT json_agg(json_build_object(
                'direction_id', dm.dir_id,
                'direction_name', dm.dir_name,
                'icon', dm.dir_icon,
                'color', dm.dir_color,
                'invoices_count', dm.invoices_count,
                'clients_count', dm.clients_count,
                'share_pct', ROUND(dm.invoices_count * 100.0 / NULLIF((SELECT total_invoices FROM totals), 0), 2),
                'total_amount', dm.total_amount,
                'avg_invoice', dm.avg_invoice,
                'min_invoice', dm.min_invoice,
                'max_invoice', dm.max_invoice,
                'invoices_per_client', dm.invoices_per_client,
                'monthly', (
                    SELECT json_agg(json_build_object(
                        'month', mi.month,
                        'invoices_count', mi.invoices_count,
                        'amount', mi.amount
                    ) ORDER BY mi.month)
                    FROM monthly_invoices mi
                    WHERE mi.dir_id = dm.dir_id
                )
            ) ORDER BY dm.invoices_count DESC)
            FROM dir_metrics dm
        ),
        'day_of_week', (
            SELECT json_agg(json_build_object(
                'dow', ds.dow,
                'dow_name', ds.dow_name,
                'invoices_count', ds.invoices_count,
                'amount', ds.amount
            ))
            FROM dow_stats ds
        ),
        'top_invoices', (
            SELECT json_agg(json_build_object(
                'doc_id', ti.doc_id,
                'doc_number', ti.doc_number,
                'invoice_date', ti.invoice_date,
                'client_code', ti.client_code,
                'client_name', ti.client_name,
                'direction_name', ti.direction_name,
                'amount', ti.amount
            ))
            FROM top_invoices ti
        )
    ) INTO v_result;

    RETURN v_result;
END;
$function$
```

### 8. `get_directions_avg_check_analytics(p_year INT)`
```sql
CREATE OR REPLACE FUNCTION public.get_directions_avg_check_analytics(p_year integer DEFAULT 2026)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_result JSON;
BEGIN
    WITH doc_goods AS (
        SELECT 
            c.activity_direction_id AS dir_id,
            d.id AS doc_id,
            d.doc_number,
            d.invoice_date,
            c.code AS client_code,
            c.name AS client_name,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_amount
        FROM documents d
        JOIN clients c ON c.code = d.client_code
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY c.activity_direction_id, d.id, d.doc_number, d.invoice_date, c.code, c.name
    ),
    dir_metrics AS (
        SELECT 
            ad.id AS dir_id,
            ad.name AS dir_name,
            COALESCE(ad.icon, '🌐') AS dir_icon,
            COALESCE(ad.color, '#64748b') AS dir_color,
            COUNT(dg.doc_id) AS checks_count,
            COUNT(DISTINCT dg.client_code) AS clients_count,
            ROUND(AVG(dg.goods_amount), 2) AS avg_check,
            ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dg.goods_amount)::NUMERIC, 2) AS median_check,
            ROUND(MIN(NULLIF(dg.goods_amount, 0)), 2) AS min_check,
            ROUND(MAX(dg.goods_amount), 2) AS max_check,
            ROUND(COALESCE(STDDEV(dg.goods_amount), 0), 2) AS stddev_check
        FROM activity_directions ad
        LEFT JOIN doc_goods dg ON dg.dir_id = ad.id
        GROUP BY ad.id, ad.name, ad.icon, ad.color
        HAVING COUNT(dg.doc_id) > 0
    ),
    yoy_data AS (
        SELECT 
            c.activity_direction_id AS dir_id,
            EXTRACT(YEAR FROM d.invoice_date)::INT AS yr,
            ROUND(COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) / NULLIF(COUNT(DISTINCT d.id), 0), 2) AS avg_check
        FROM clients c
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) BETWEEN (p_year - 2) AND p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY c.activity_direction_id, yr
    ),
    top_checks_ranked AS (
        SELECT 
            dg.*,
            ROW_NUMBER() OVER (PARTITION BY dg.dir_id ORDER BY dg.goods_amount DESC) AS rn
        FROM doc_goods dg
    ),
    totals AS (
        SELECT 
            ROUND(AVG(dg.goods_amount), 2) AS total_avg_check,
            ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dg.goods_amount)::NUMERIC, 2) AS total_median_check,
            COUNT(dg.doc_id) AS total_checks
        FROM doc_goods dg
    )
    SELECT json_build_object(
        'year', p_year,
        'total_avg_check', (SELECT total_avg_check FROM totals),
        'total_median_check', (SELECT total_median_check FROM totals),
        'total_checks', (SELECT total_checks FROM totals),
        'directions', (
            SELECT json_agg(json_build_object(
                'direction_id', dm.dir_id,
                'direction_name', dm.dir_name,
                'icon', dm.dir_icon,
                'color', dm.dir_color,
                'checks_count', dm.checks_count,
                'clients_count', dm.clients_count,
                'avg_check', dm.avg_check,
                'median_check', dm.median_check,
                'min_check', dm.min_check,
                'max_check', dm.max_check,
                'stddev_check', dm.stddev_check,
                'yoy', (
                    SELECT json_object_agg(y.yr::TEXT, y.avg_check)
                    FROM yoy_data y
                    WHERE y.dir_id = dm.dir_id
                ),
                'top_checks', (
                    SELECT json_agg(json_build_object(
                        'client_code', tc.client_code,
                        'client_name', tc.client_name,
                        'doc_id', tc.doc_id,
                        'doc_number', tc.doc_number,
                        'invoice_date', TO_CHAR(tc.invoice_date, 'YYYY-MM-DD'),
                        'check_amount', ROUND(tc.goods_amount, 2)
                    ) ORDER BY tc.goods_amount DESC)
                    FROM top_checks_ranked tc
                    WHERE tc.dir_id = dm.dir_id AND tc.rn <= 5
                )
            ) ORDER BY dm.avg_check DESC)
            FROM dir_metrics dm
        ),
        'top_company_checks', (
            SELECT json_agg(json_build_object(
                'client_code', dg.client_code,
                'client_name', dg.client_name,
                'direction_name', ad.name,
                'doc_id', dg.doc_id,
                'doc_number', dg.doc_number,
                'invoice_date', TO_CHAR(dg.invoice_date, 'YYYY-MM-DD'),
                'check_amount', ROUND(dg.goods_amount, 2)
            ) ORDER BY dg.goods_amount DESC)
            FROM (
                SELECT * FROM doc_goods ORDER BY goods_amount DESC LIMIT 10
            ) dg
            LEFT JOIN activity_directions ad ON ad.id = dg.dir_id
        )
    ) INTO v_result;

    RETURN v_result;
END;
$function$
```

### 9. `get_directions_leader_analytics(p_year INT)`
```sql
CREATE OR REPLACE FUNCTION public.get_directions_leader_analytics(p_year integer DEFAULT 2026)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_result JSON;
BEGIN
    WITH base_metrics AS (
        SELECT 
            ad.id AS dir_id,
            ad.name AS dir_name,
            COALESCE(ad.icon, '🌐') AS dir_icon,
            COALESCE(ad.color, '#64748b') AS dir_color,
            ROUND(COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0), 2) AS revenue,
            COUNT(DISTINCT c.code) AS clients_count,
            COUNT(DISTINCT d.id) AS invoices_count,
            ROUND(COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) / NULLIF(COUNT(DISTINCT d.id), 0), 2) AS avg_check,
            ROUND(COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) / NULLIF(COUNT(DISTINCT c.code), 0), 2) AS avg_rev_per_client
        FROM activity_directions ad
        JOIN clients c ON c.activity_direction_id = ad.id
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY ad.id, ad.name, ad.icon, ad.color
        HAVING COUNT(DISTINCT d.id) > 0
    ),
    totals AS (
        SELECT 
            SUM(revenue) AS t_revenue,
            (SELECT COUNT(DISTINCT d2.client_code) FROM documents d2 WHERE EXTRACT(YEAR FROM d2.invoice_date) = p_year) AS t_clients,
            SUM(invoices_count) AS t_invoices,
            COUNT(*) AS t_directions
        FROM base_metrics
    ),
    ranked AS (
        SELECT 
            bm.*,
            ROW_NUMBER() OVER (ORDER BY bm.revenue DESC) AS rank_rev,
            ROW_NUMBER() OVER (ORDER BY bm.clients_count DESC) AS rank_cli,
            ROW_NUMBER() OVER (ORDER BY bm.invoices_count DESC) AS rank_inv,
            ROUND(bm.revenue * 100.0 / NULLIF((SELECT t_revenue FROM totals), 0), 2) AS revenue_pct,
            ROUND(bm.clients_count * 100.0 / NULLIF((SELECT t_clients FROM totals), 0), 2) AS clients_pct,
            ROUND(bm.invoices_count * 100.0 / NULLIF((SELECT t_invoices FROM totals), 0), 2) AS invoices_pct
        FROM base_metrics bm
    ),
    leaders_rev AS (
        SELECT 'revenue' AS metric, 'Выручка' AS metric_title, dir_id, dir_name, dir_icon, dir_color, revenue AS value, revenue_pct AS pct
        FROM ranked ORDER BY revenue DESC LIMIT 1
    ),
    leaders_cli AS (
        SELECT 'clients' AS metric, 'Клиенты' AS metric_title, dir_id, dir_name, dir_icon, dir_color, clients_count AS value, clients_pct AS pct
        FROM ranked ORDER BY clients_count DESC LIMIT 1
    ),
    leaders_inv AS (
        SELECT 'invoices' AS metric, 'Накладные' AS metric_title, dir_id, dir_name, dir_icon, dir_color, invoices_count AS value, invoices_pct AS pct
        FROM ranked ORDER BY invoices_count DESC LIMIT 1
    ),
    leaders_avg AS (
        SELECT 'avg_check' AS metric, 'Средний чек' AS metric_title, dir_id, dir_name, dir_icon, dir_color, avg_check AS value, NULL::numeric AS pct
        FROM ranked ORDER BY avg_check DESC LIMIT 1
    ),
    concentration AS (
        SELECT 
            ROUND(SUM(revenue) FILTER (WHERE rank_rev <= 3) * 100.0 / NULLIF((SELECT t_revenue FROM totals), 0), 2) AS rev_top3_pct,
            ROUND(SUM(revenue) FILTER (WHERE rank_rev <= 5) * 100.0 / NULLIF((SELECT t_revenue FROM totals), 0), 2) AS rev_top5_pct,
            ROUND(SUM(clients_count) FILTER (WHERE rank_cli <= 3) * 100.0 / NULLIF((SELECT t_clients FROM totals), 0), 2) AS cli_top3_pct,
            ROUND(SUM(clients_count) FILTER (WHERE rank_cli <= 5) * 100.0 / NULLIF((SELECT t_clients FROM totals), 0), 2) AS cli_top5_pct,
            ROUND(SUM(invoices_count) FILTER (WHERE rank_inv <= 3) * 100.0 / NULLIF((SELECT t_invoices FROM totals), 0), 2) AS inv_top3_pct,
            ROUND(SUM(invoices_count) FILTER (WHERE rank_inv <= 5) * 100.0 / NULLIF((SELECT t_invoices FROM totals), 0), 2) AS inv_top5_pct,
            ROUND(SUM(POWER(revenue_pct, 2)), 0) AS hhi_index
        FROM ranked
    )
    SELECT json_build_object(
        'year', p_year,
        'totals', json_build_object(
            'total_revenue', (SELECT ROUND(t_revenue, 2) FROM totals),
            'total_clients', (SELECT t_clients FROM totals),
            'total_invoices', (SELECT t_invoices FROM totals),
            'active_directions', (SELECT t_directions FROM totals)
        ),
        'leaders', (
            SELECT json_agg(json_build_object(
                'metric', metric,
                'metric_title', metric_title,
                'direction_id', dir_id,
                'direction_name', dir_name,
                'icon', dir_icon,
                'color', dir_color,
                'value', value,
                'pct', pct
            ))
            FROM (
                SELECT * FROM leaders_rev
                UNION ALL SELECT * FROM leaders_cli
                UNION ALL SELECT * FROM leaders_inv
                UNION ALL SELECT * FROM leaders_avg
            ) x
        ),
        'concentration', (
            SELECT json_agg(json_build_object(
                'direction_id', r.dir_id,
                'direction_name', r.dir_name,
                'icon', r.dir_icon,
                'color', r.dir_color,
                'revenue', r.revenue,
                'revenue_pct', r.revenue_pct,
                'clients_count', r.clients_count,
                'clients_pct', r.clients_pct,
                'invoices_count', r.invoices_count,
                'invoices_pct', r.invoices_pct,
                'avg_check', r.avg_check,
                'avg_rev_per_client', r.avg_rev_per_client,
                'rank_revenue', r.rank_rev,
                'rank_clients', r.rank_cli,
                'rank_invoices', r.rank_inv
            ) ORDER BY r.revenue DESC)
            FROM ranked r
        ),
        'top_concentration', (SELECT row_to_json(c.*) FROM concentration c)
    ) INTO v_result;

    RETURN v_result;
END;
$function$
```

---

## 🌐 Эндпоинты API
- `GET /api/analytics/directions/kpi?year=2026` -> `get_directions_kpi`
- `GET /api/analytics/directions/summary?year=2026` -> `get_directions_summary`
- `GET /api/analytics/directions/monthly?year=2026` -> `get_directions_monthly_dynamics`
- `GET /api/analytics/directions/companies?direction_id=...&year=2026` -> `get_direction_companies`
- `GET /api/analytics/directions/revenue-analytics?year=2026` -> `get_directions_revenue_analytics`
- `GET /api/analytics/directions/clients-analytics?year=2026` -> `get_directions_clients_analytics`
- `GET /api/analytics/directions/invoices-analytics?year=2026` -> `get_directions_invoices_analytics`
- `GET /api/analytics/directions/avg-check-analytics?year=2026` -> `get_directions_avg_check_analytics`
- `GET /api/analytics/directions/leader-analytics?year=2026` -> `get_directions_leader_analytics`

---

## 📊 Распределение клиентов и выручки по 16 отраслям (2026 год)
| ID | Иконка | Отрасль | Клиентов в базе | Активных клиентов (2026) | Накладных 2026 | Выручка 2026 (товары) | Доля выручки |
|:---:|:---:|:---|:---:|:---:|:---:|:---:|:---:|
| 9 | 🌐 | **Универсальный/Смешанное** | 956 | 297 | 2,050 | 153,191,493.75 ₴ | 27.2% |
| 2 | 🏗️ | **Строительство** | 74 | 38 | 391 | 151,329,647.92 ₴ | 26.9% |
| 6 | 💼 | **Трейдер** | 205 | 132 | 1,623 | 109,706,502.37 ₴ | 19.5% |
| 3 | 🏭 | **Промышленность / Нефтегаз** | 168 | 91 | 567 | 62,543,447.55 ₴ | 11.1% |
| 1 | 🌾 | **Сельское хозяйство** | 61 | 47 | 375 | 42,207,065.20 ₴ | 7.5% |
| 15 | 🏛️ | **Госструктуры / Ритейл** | 6 | 4 | 235 | 12,048,418.20 ₴ | 2.1% |
| 11 | ⚙️ | **Машиностроение** | 54 | 28 | 150 | 8,147,471.70 ₴ | 1.4% |
| 8 | ⚙️ | **Трейдер с производством** | 24 | 15 | 96 | 6,898,077.90 ₴ | 1.2% |
| 7 | 👤 | **Конечный потребитель** | 161 | 50 | 150 | 6,405,213.80 ₴ | 1.1% |
| 13 | 🚗 | **Автомобильная отрасль / Спецтехника** | 17 | 11 | 67 | 5,161,365.20 ₴ | 0.9% |
| 12 | ⚡ | **Энергетика** | 8 | 5 | 21 | 2,228,479.70 ₴ | 0.4% |
| 14 | 🚚 | **Логистика / Транспорт** | 8 | 6 | 18 | 1,802,290.00 ₴ | 0.3% |
| 10 | 🔩 | **Металлоконструкции** | 4 | 3 | 22 | 1,465,170.80 ₴ | 0.3% |
| 4 | 🚰 | **ЖКХ и Водоканалы** | 7 | 2 | 8 | 281,989.00 ₴ | 0.1% |
| 16 | ❓ | **Не определено** | 0 | 0 | 0 | 0.00 ₴ | 0.0% |
| 5 | 🛣️ | **Дорожное строительство** | 1 | 0 | 0 | 0.00 ₴ | 0.0% |

**ИТОГО:** Клиентов в базе: 1754 | Активных клиентов: 729 | Выручка 2026: 563,416,633.09 ₴

---

## 🚨 Выявленные проблемы и план исправлений

1. **Несоответствие счетчика клиентов в KPI (748 вместо 729):**
   - В функции `get_directions_kpi` переменная `tot_clients` считается как:
     `SELECT COUNT(DISTINCT d2.client_code) FROM documents d2 WHERE EXTRACT(YEAR FROM d2.invoice_date) = p_year;`
   - Это возвращает всех 748 покупателей, включая 19 исключенных/неактивных клиентов (`deactivation_reason = 'Не в списке аналитики'`: аренда, долги, внутренние компании).
   - **Решение:** связать с `clients c` и условием `c.is_active_current = TRUE` (или проверкой `client_year_activity.is_active = TRUE`), что вернет ровно **729**.

2. **Клиент 8814 («Форпост-М ООО С-1»):**
   - Должен быть исключен наравне с 9653 и 11230. В функциях модуля направлений пока не исключен.

3. **Лишняя таблица «Компании отрасли» на главной странице `directions-analytics.html`:**
   - Таблица в нижней части страницы создает визуальный шум и не решает аналитических задач верхнего уровня.
   - **Решение:** удалить секцию и связанный скрипт загрузки `loadCompaniesTable()` из `directions-analytics.html`.

4. **Отсутствие кликабельности строк в сводной матрице:**
   - Строки таблицы отраслей должны вести на новую страницу drill-down по отрасли: `/direction-detail?direction_id=$<built-in function id>`.

5. **Необходимость новой страницы `/direction-detail`:**
   - Страница глубокой аналитики конкретной отрасли с вкладками:
     1. Сводные KPI и динамика отрасли.
     2. Все компании отрасли с фильтрами и пагинацией.
     3. Продуктовый профиль отрасли (топ-размеры труб).
     4. Новые и ушедшие клиенты отрасли.
