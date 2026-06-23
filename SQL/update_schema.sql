-- Скрипт миграции: добавление недостающих колонок, триггеров и представлений

BEGIN;

-- 1. Добавление колонок в таблицу clients
ALTER TABLE clients ADD COLUMN IF NOT EXISTS legacy_unit_id integer;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS okpo_code character varying(20);
ALTER TABLE clients ADD COLUMN IF NOT EXISTS okpo_s1c8 character varying(20);
ALTER TABLE clients ADD COLUMN IF NOT EXISTS ipn character varying(20);
ALTER TABLE clients ADD COLUMN IF NOT EXISTS legal_entity_type character varying(50);
ALTER TABLE clients ADD COLUMN IF NOT EXISTS full_unit_name text;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS group_id integer;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS active_years integer[] DEFAULT '{}'::integer[];
ALTER TABLE clients ADD COLUMN IF NOT EXISTS is_active_current boolean DEFAULT false;
ALTER TABLE clients ADD COLUMN IF NOT EXISTS analysis_updated_at timestamp without time zone;

-- 2. Добавление колонок в таблицу products
ALTER TABLE products ADD COLUMN IF NOT EXISTS is_service boolean DEFAULT false;

-- 3. Удаление старых представлений (каскадно, так как они могут зависеть друг от друга)
DROP VIEW IF EXISTS v_abc_clients_detail CASCADE;
DROP VIEW IF EXISTS v_abc_segmentation CASCADE;
DROP VIEW IF EXISTS v_annual_activity_report CASCADE;
DROP VIEW IF EXISTS v_churn_risk_dashboard CASCADE;
DROP VIEW IF EXISTS v_combined_annual_activity CASCADE;
DROP VIEW IF EXISTS v_direction_profitability CASCADE;
DROP VIEW IF EXISTS v_manager_dashboard CASCADE;
DROP VIEW IF EXISTS v_smart_recommendations CASCADE;
DROP VIEW IF EXISTS v_status_migration_matrix CASCADE;
DROP VIEW IF EXISTS view_client_segmentation_details_2026 CASCADE;
DROP VIEW IF EXISTS view_average_ticket_analytics CASCADE;
DROP VIEW IF EXISTS view_client_profiles_yearly CASCADE;
DROP VIEW IF EXISTS view_cohort_2026_integrity_check CASCADE;

-- 4. Создание представлений из schema_dump.sql

-- 4.1 view_client_segmentation_details_2026
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

-- 4.2 view_average_ticket_analytics
CREATE OR REPLACE VIEW view_average_ticket_analytics AS
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

-- 4.3 view_client_profiles_yearly
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
   FROM ((((public.documents d
     JOIN public.sales_lines sl ON ((sl.document_id = d.id)))
     LEFT JOIN public.products pr ON (((sl.product_code)::text = (pr.code)::text)))
     JOIN public.clients c ON ((((d.client_code)::text = (c.code)::text) AND (c.is_active_current = true))))
     LEFT JOIN public.activity_directions ad ON ((c.activity_direction_id = ad.id)))
  GROUP BY (EXTRACT(year FROM d.invoice_date)), c.code, c.name, ad.name, c.active_years;

-- 4.4 view_cohort_2026_integrity_check
CREATE OR REPLACE VIEW view_cohort_2026_integrity_check AS
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
     FULL JOIN sales_summary_2026 s ON (((c.code)::text = (s.client_code)::text)))
     FULL JOIN cohort_summary_2026 co ON (((c.code)::text = (co.client_code)::text)));

-- 4.5 v_abc_clients_detail
CREATE OR REPLACE VIEW v_abc_clients_detail AS
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

-- 4.6 v_abc_segmentation
CREATE OR REPLACE VIEW v_abc_segmentation AS
 SELECT out_group_name,
    out_total_sales,
    out_total_companies
   FROM public.get_abc_segmentation((EXTRACT(year FROM CURRENT_DATE))::integer, 1.0) get_abc_segmentation(out_group_name, out_total_sales, out_total_companies);

-- 4.7 v_annual_activity_report
CREATE OR REPLACE VIEW v_annual_activity_report AS
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

-- 4.8 v_churn_risk_dashboard
CREATE OR REPLACE VIEW v_churn_risk_dashboard AS
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

-- 4.9 v_combined_annual_activity
CREATE OR REPLACE VIEW v_combined_annual_activity AS
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

-- 4.10 v_direction_profitability
CREATE OR REPLACE VIEW v_direction_profitability AS
 SELECT COALESCE(ad.name, 'Направление не определено'::character varying) AS activity_direction,
    count(DISTINCT c.code) AS total_clients_in_segment,
    sum(sl.amount) AS total_revenue_generated
   FROM (((public.clients c
     LEFT JOIN public.activity_directions ad ON ((c.activity_direction_id = ad.id)))
     JOIN public.documents d ON (((c.code)::text = (d.client_code)::text)))
     JOIN public.sales_lines sl ON ((d.id = sl.document_id)))
  GROUP BY ad.name
  ORDER BY (sum(sl.amount)) DESC;

-- 4.11 v_manager_dashboard
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
           FROM public.documents
          WHERE ((documents.client_code)::text = (c.code)::text)) AS total_docs,
    ( SELECT COALESCE(sum(documents.total_amount), (0)::numeric) AS "coalesce"
           FROM public.documents
          WHERE ((documents.client_code)::text = (c.code)::text)) AS total_revenue
   FROM ((public.clients c
     LEFT JOIN public.status_rules sr ON ((c.current_status_id = sr.id)))
     LEFT JOIN public.activity_directions ad ON ((c.activity_direction_id = ad.id)))
  WHERE (c.is_active_current = true);

-- 4.12 v_smart_recommendations
CREATE OR REPLACE VIEW v_smart_recommendations AS
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

-- 4.13 v_status_migration_matrix
CREATE OR REPLACE VIEW v_status_migration_matrix AS
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


-- 5. Восстановление триггеров
DROP TRIGGER IF EXISTS trg_sales_lines_activity ON public.sales_lines;
CREATE TRIGGER trg_sales_lines_activity AFTER INSERT OR DELETE OR UPDATE ON public.sales_lines
    FOR EACH ROW EXECUTE FUNCTION public.trg_update_client_activity();

COMMIT;
