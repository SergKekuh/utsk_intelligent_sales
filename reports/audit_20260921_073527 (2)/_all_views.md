### v_manager_dashboard

```sql
CREATE OR REPLACE VIEW v_manager_dashboard AS
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
           FROM documents
          WHERE ((documents.client_code)::text = (c.code)::text)) AS total_docs,
    ( SELECT COALESCE(sum(documents.total_amount), (0)::numeric) AS "coalesce"
           FROM documents
          WHERE ((documents.client_code)::text = (c.code)::text)) AS total_revenue
   FROM ((clients c
     LEFT JOIN status_rules sr ON ((c.current_status_id = sr.id)))
     LEFT JOIN activity_directions ad ON ((c.activity_direction_id = ad.id)))
  WHERE (c.is_active_current = true);
```

---

### v_smart_recommendations

```sql
CREATE OR REPLACE VIEW v_smart_recommendations AS
SELECT c.code AS client_code,
    p.code AS product_code,
    p.name AS product_name,
    'Часто покупаете'::text AS recommendation_reason,
    1 AS priority,
    p.in_stock_balance
   FROM (((clients c
     JOIN ( SELECT d.client_code,
            sl.product_code,
            count(*) AS buy_count
           FROM (sales_lines sl
             JOIN documents d ON ((sl.document_id = d.id)))
          GROUP BY d.client_code, sl.product_code) history ON (((c.code)::text = (history.client_code)::text)))
     JOIN products p ON (((history.product_code)::text = (p.code)::text)))
     LEFT JOIN manager_rejections_log mrl ON ((((c.code)::text = (mrl.client_code)::text) AND ((p.code)::text = (mrl.product_code)::text) AND (mrl.rejected_at > (CURRENT_DATE - '30 days'::interval)))))
  WHERE ((p.in_stock_balance > (0)::numeric) AND (mrl.id IS NULL))
UNION ALL
 SELECT c.code AS client_code,
    p.code AS product_code,
    p.name AS product_name,
    'Новинка в вашем сегменте'::text AS recommendation_reason,
    2 AS priority,
    p.in_stock_balance
   FROM ((clients c
     JOIN products p ON ((c.activity_direction_id = p.anchor_direction_id)))
     LEFT JOIN manager_rejections_log mrl ON ((((c.code)::text = (mrl.client_code)::text) AND ((p.code)::text = (mrl.product_code)::text) AND (mrl.rejected_at > (CURRENT_DATE - '30 days'::interval)))))
  WHERE ((p.is_new_arrival = true) AND (p.in_stock_balance > (0)::numeric) AND (mrl.id IS NULL))
UNION ALL
 SELECT DISTINCT c.code AS client_code,
    p_related.code AS product_code,
    p_related.name AS product_name,
    (('С '::text || (p_main.name)::text) || ' обычно берут'::text) AS recommendation_reason,
    3 AS priority,
    p_related.in_stock_balance
   FROM ((((((clients c
     JOIN documents d ON (((c.code)::text = (d.client_code)::text)))
     JOIN sales_lines sl ON ((d.id = sl.document_id)))
     JOIN products p_main ON (((sl.product_code)::text = (p_main.code)::text)))
     JOIN product_cross_sells pcs ON (((sl.product_code)::text = (pcs.main_product_code)::text)))
     JOIN products p_related ON (((pcs.related_product_code)::text = (p_related.code)::text)))
     LEFT JOIN manager_rejections_log mrl ON ((((c.code)::text = (mrl.client_code)::text) AND ((p_related.code)::text = (mrl.product_code)::text) AND (mrl.rejected_at > (CURRENT_DATE - '30 days'::interval)))))
  WHERE ((p_related.in_stock_balance > (0)::numeric) AND (mrl.id IS NULL))
UNION ALL
 SELECT DISTINCT c.code AS client_code,
    p.code AS product_code,
    p.name AS product_name,
    'Вы недавно интересовались'::text AS recommendation_reason,
    4 AS priority,
    p.in_stock_balance
   FROM (((clients c
     JOIN website_behavior_log wbl ON (((c.code)::text = (wbl.client_code)::text)))
     JOIN products p ON ((((wbl.product_code)::text = (p.code)::text) OR (p.anchor_direction_id = ( SELECT activity_directions.id
           FROM activity_directions
          WHERE ((activity_directions.name)::text = (wbl.product_category)::text)
         LIMIT 1)))))
     LEFT JOIN manager_rejections_log mrl ON ((((c.code)::text = (mrl.client_code)::text) AND ((p.code)::text = (mrl.product_code)::text) AND (mrl.rejected_at > (CURRENT_DATE - '30 days'::interval)))))
  WHERE ((wbl."timestamp" > (CURRENT_DATE - '7 days'::interval)) AND (p.in_stock_balance > (0)::numeric) AND (mrl.id IS NULL))
  ORDER BY 5, 6 DESC;
```

---

### view_client_profiles_yearly

```sql
CREATE OR REPLACE VIEW view_client_profiles_yearly AS
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
   FROM ((((documents d
     JOIN sales_lines sl ON ((sl.document_id = d.id)))
     LEFT JOIN products pr ON (((sl.product_code)::text = (pr.code)::text)))
     JOIN clients c ON ((((d.client_code)::text = (c.code)::text) AND (c.is_active_current = true))))
     LEFT JOIN activity_directions ad ON ((c.activity_direction_id = ad.id)))
  GROUP BY (EXTRACT(year FROM d.invoice_date)), c.code, c.name, ad.name, c.active_years;
```

---

### view_client_segmentation_details_2026

```sql
CREATE OR REPLACE VIEW view_client_segmentation_details_2026 AS
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
           FROM ((documents d
             LEFT JOIN sales_lines sl ON ((sl.document_id = d.id)))
             LEFT JOIN products p ON (((sl.product_code)::text = (p.code)::text)))
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
           FROM ((clients c
             LEFT JOIN client_stats_2026 s ON (((c.code)::text = (s.client_code)::text)))
             JOIN client_year_activity cya ON (((cya.client_code)::text = (c.code)::text)))
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
```

---

