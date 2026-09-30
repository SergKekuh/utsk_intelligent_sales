# SQL-функции базы данных PostgreSQL (`public`)

Всего функций: 120. Язык: PL/pgSQL.

## 📑 Полный алфавитный список функций

| Функция | Аргументы | Возвращаемый тип |
|:---|:---|:---|
| `calculate_client_status` | `p_client_code character varying` | `integer` |
| `calculate_client_year_activity` | `p_year integer, p_client_code character varying DEFAULT NULL::character varying` | `void` |
| `classify_clients_directions` | `p_overwrite_manual boolean DEFAULT false` | `TABLE(updated_count bigint)` |
| `generate_custom_sales_report` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000, p_direction character varying DEFAULT 'below'::character varying` | `TABLE(out_group_name character varying, out_metric character varying, out_1 numeric, out_2_3 numeric, out_4_10 numeric, out_11_40 numeric, out_41_170 numeric, out_171_plus numeric, out_total numeric)` |
| `get_abc_group_for_revenue` | `p_revenue numeric` | `character varying` |
| `get_abc_groups` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9` | `TABLE(out_group_name character varying, out_total_sales numeric, out_total_companies bigint)` |
| `get_abc_groups_detail` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000` | `TABLE(abc_group text, companies bigint, invoices bigint, sales numeric)` |
| `get_abc_migration` | `p_year integer DEFAULT 2026, p_groups text[] DEFAULT ARRAY['A1'::text, 'A2'::text, 'B1'::text, 'B2'::text], p_multiplier numeric DEFAULT 2.9` | `TABLE(group_prev text, companies_count bigint, goods_revenue numeric, invoice_count bigint)` |
| `get_abc_segmentation` | `p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer, p_multiplier numeric DEFAULT 1.0` | `TABLE(out_group_name text, out_total_sales numeric, out_total_companies bigint)` |
| `get_abc_segmentation` | `p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer` | `TABLE(out_group_name text, out_total_sales numeric, out_total_companies bigint)` |
| `get_abc_structure_data` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000` | `TABLE(out_direction text, out_group_name character varying, out_metric character varying, out_1 numeric, out_2_3 numeric, out_4_10 numeric, out_11_40 numeric, out_41_170 numeric, out_171_plus numeric, out_total numeric)` |
| `get_active_clients` | `p_limit integer DEFAULT 20` | `TABLE(code character varying, name character varying, status character varying, last_purchase_date date, docs_count bigint, total_revenue numeric)` |
| `get_all_sizes_for_client` | `p_client_code text, p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer` | `TABLE(size_key text, size_display text, pipe_type text, pipe_type_ua text, display_name text, purchase_count bigint, revenue numeric, pct_of_client_total numeric, stock_balance_total numeric, products_count integer, has_stock boolean)` |
| `get_alt_funnel` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000` | `TABLE(group_key text, companies bigint, sales numeric, avg_check numeric)` |
| `get_c2_detail` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000` | `TABLE(client_code character varying, invoices_count bigint, goods_revenue numeric, freq_group text, internal_class text)` |
| `get_c2_segmentation_companies` | `p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000, p_limit_tonnage numeric DEFAULT 2.0` | `TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, total_tonnage numeric, avg_ticket numeric, abc_group character varying, industry character varying, status_name character varying, current_status_id integer, cohort character varying)` |
| `get_c2_top_products` | `p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000` | `TABLE(product_code character varying, product_name character varying, total_amount numeric, total_qty numeric, orders_count bigint)` |
| `get_churn_risk_clients` | `p_limit integer DEFAULT 20` | `TABLE(code character varying, name character varying, status character varying, last_purchase_date date, days_since_last integer)` |
| `get_churned_segmentation` | `p_year integer DEFAULT 2026` | `TABLE(code character varying, name character varying, inv_prev bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, last_purchase date, days_since integer, last_year integer, abc_group character varying, recommendation character varying, industry character varying, cohort character varying)` |
| `get_client_avg_check_analytics` | `p_code character varying, p_year integer DEFAULT 2026` | `json` |
| `get_client_cross_sell_pipes` | `p_client_code character varying` | `TABLE(product_code character varying, product_name character varying, reason text, in_stock numeric)` |
| `get_client_detail` | `p_code text, p_year integer DEFAULT 2026` | `TABLE(code character varying, name character varying, status character varying, total_revenue numeric, total_invoices bigint, total_positions bigint, avg_check numeric, last_purchase_date date)` |
| `get_client_direction_variety` | `p_client_code character varying` | `TABLE(product_code character varying, product_name character varying, popularity bigint, reason text, in_stock numeric)` |
| `get_client_invoices` | `p_code text, p_year integer DEFAULT 2026, p_month_int integer DEFAULT NULL::integer, p_date_from date DEFAULT NULL::date, p_date_to date DEFAULT NULL::date, p_limit integer DEFAULT 500` | `TABLE(date text, number character varying, total numeric, positions bigint)` |
| `get_client_invoices_analytics` | `p_code character varying, p_year integer DEFAULT 2026` | `json` |
| `get_client_invoices_by_month` | `p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1` | `json` |
| `get_client_last_purchase_analytics` | `p_code character varying` | `json` |
| `get_client_month_daily` | `p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1` | `json` |
| `get_client_month_invoices` | `p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1` | `json` |
| `get_client_month_products` | `p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1` | `json` |
| `get_client_month_summary` | `p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1` | `json` |
| `get_client_monthly_dynamics` | `p_code text, p_year integer DEFAULT 2026, p_year_prev integer DEFAULT 2025` | `TABLE(month integer, revenue_current numeric, revenue_previous numeric, invoices_current bigint, invoices_previous bigint)` |
| `get_client_products` | `p_code text, p_year integer DEFAULT 2026` | `TABLE(product_code character varying, product_name character varying, invoice_count bigint, total_sales numeric, total_quantity numeric)` |
| `get_client_products_compare` | `p_code text` | `TABLE(product_code character varying, product_name character varying, revenue_curr numeric, revenue_prev numeric, qty_curr numeric, qty_prev numeric)` |
| `get_client_revenue_analytics` | `p_code character varying, p_year integer DEFAULT 2026` | `json` |
| `get_client_revenue_deep_analytics` | `p_code character varying, p_year integer DEFAULT 2026` | `json` |
| `get_client_similar_fallback` | `p_client_code character varying` | `TABLE(product_code character varying, product_name character varying, diameter numeric, wall_thickness numeric, reason text, in_stock numeric)` |
| `get_client_similar_sizes` | `p_client_code character varying` | `TABLE(product_code character varying, product_name character varying, diameter numeric, wall_thickness numeric, reason text, in_stock numeric)` |
| `get_client_status_2025` | `p_code text, p_year_prev integer DEFAULT 2025` | `TABLE(status_2025 text)` |
| `get_clients_list` | `p_limit integer DEFAULT 50, p_search text DEFAULT ''::text` | `TABLE(code character varying, name character varying, status character varying, last_purchase_date date)` |
| `get_clients_yoy` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9` | `TABLE(client_code character varying, client_name character varying, revenue_curr numeric, revenue_prev numeric, invoices_curr bigint, invoices_prev bigint, abc_curr text, abc_prev text)` |
| `get_consolidated_segmentation_companies` | `p_year integer DEFAULT 2026` | `TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, days_between integer, consolidated_group character varying, consolidated_key character varying, detailed_segment character varying, abc_group character varying, industry character varying, status_name character varying, current_status_id integer)` |
| `get_daily_revenue` | `p_year integer, p_month integer` | `TABLE(day integer, active_clients bigint, invoice_count bigint, goods_revenue numeric, total_revenue numeric)` |
| `get_dashboard_stats` | `—` | `TABLE(total_clients bigint, active_30d bigint, active_90d bigint, total_revenue numeric, revenue_30d numeric)` |
| `get_direction_companies` | `p_direction_id integer, p_year integer DEFAULT 2026, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text` | `TABLE(code character varying, name character varying, status_name character varying, goods_revenue numeric, invoices_count bigint, avg_ticket numeric, abc_group character varying, edrpou character varying, ipn character varying, last_purchase_date text, total_matching_count bigint)` |
| `get_directions_avg_check_analytics` | `p_year integer DEFAULT 2026` | `json` |
| `get_directions_clients_analytics` | `p_year integer DEFAULT 2026` | `json` |
| `get_directions_invoices_analytics` | `p_year integer DEFAULT 2026` | `json` |
| `get_directions_kpi` | `p_year integer DEFAULT 2026` | `TABLE(total_revenue numeric, total_clients bigint, total_invoices bigint, avg_ticket numeric, top_direction_id integer, top_direction_name text, top_direction_revenue numeric, top_direction_share_pct numeric, active_directions_count bigint)` |
| `get_directions_leader_analytics` | `p_year integer DEFAULT 2026` | `json` |
| `get_directions_monthly_dynamics` | `p_year integer DEFAULT 2026` | `TABLE(direction_id integer, direction_name character varying, month_num integer, month_name text, goods_revenue numeric, clients_count bigint)` |
| `get_directions_revenue_analytics` | `p_year integer DEFAULT 2026` | `json` |
| `get_directions_summary` | `p_year integer DEFAULT 2026` | `TABLE(id integer, name character varying, icon character varying, color character varying, clients_count bigint, total_clients_in_base bigint, invoices_count bigint, goods_revenue numeric, avg_ticket numeric, revenue_share_pct numeric, clients_share_pct numeric)` |
| `get_excluded_client_info` | `p_year integer, p_month integer, p_exclude_client text` | `TABLE(client_code character varying, client_name character varying, invoice_count bigint, goods_revenue numeric)` |
| `get_funnel_data` | `p_year integer DEFAULT 2026` | `TABLE(stage text, sort_order integer, count bigint, revenue numeric)` |
| `get_general_segmentation_companies` | `p_year integer DEFAULT 2026` | `TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, abc_group character varying, cohort character varying, detailed_segment character varying, industry character varying, status_name character varying, current_status_id integer)` |
| `get_important_detail` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000` | `TABLE(client_code character varying, client_name character varying, invoices_count bigint, goods_revenue numeric, category text, grand_total numeric)` |
| `get_inactive_clients_abc` | `p_status_id integer DEFAULT 8, p_year_prev integer DEFAULT 2025` | `TABLE(abc_group text, count bigint, revenue numeric, pct numeric)` |
| `get_inactive_clients_distribution` | `p_status_id integer DEFAULT 8` | `TABLE(range_label text, count bigint)` |
| `get_inactive_clients_list` | `p_status_id integer DEFAULT 8, p_year_prev integer DEFAULT 2025, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text, p_days_min integer DEFAULT NULL::integer, p_days_max integer DEFAULT NULL::integer, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0` | `TABLE(code character varying, name character varying, docs_prev bigint, rev_prev numeric, abc_group text, last_date text, days_since integer)` |
| `get_inactive_clients_overview` | `p_year integer DEFAULT 2026` | `TABLE(sleeping_count bigint, churned_count bigint, total_all bigint, pct_inactive numeric, sleeping_rev_2025 numeric, churned_rev_2024 numeric, high_risk_count bigint)` |
| `get_invoice_header` | `p_number character varying` | `TABLE(date text, number character varying, total numeric)` |
| `get_invoice_items` | `p_number text` | `TABLE(code character varying, name character varying, quantity numeric, total numeric, weight_kg numeric, price numeric)` |
| `get_monthly_detail_metrics` | `p_year integer, p_month integer` | `TABLE(active_clients bigint, invoice_count bigint, goods_revenue numeric, services_revenue numeric, total_revenue numeric)` |
| `get_monthly_directions` | `p_year integer, p_month integer` | `TABLE(direction_name text, companies_count bigint, invoice_count bigint, goods_revenue numeric)` |
| `get_monthly_products` | `p_year integer, p_month integer, p_limit integer DEFAULT 10` | `TABLE(product_code character varying, product_name character varying, invoice_count bigint, total_sales numeric, total_quantity numeric)` |
| `get_monthly_revenue` | `p_year integer DEFAULT 2026` | `TABLE(year integer, month integer, month_name text, active_clients bigint, invoice_count bigint, goods_revenue numeric, services_revenue numeric, total_revenue numeric)` |
| `get_monthly_top_clients` | `p_year integer, p_month integer, p_year_prev integer DEFAULT 2025, p_mult numeric DEFAULT 2.9, p_limit integer DEFAULT 10` | `TABLE(client_name character varying, group_prev text, invoice_count bigint, goods_revenue numeric)` |
| `get_new_clients_abc` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9` | `TABLE(abc_group text, count bigint, revenue numeric, pct numeric)` |
| `get_new_clients_abc_compare` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9` | `TABLE(abc_group text, new_count bigint, new_revenue numeric, new_pct numeric, all_count bigint, all_revenue numeric, all_pct numeric, count_share_pct numeric, revenue_share_pct numeric)` |
| `get_new_clients_frequency` | `p_year integer DEFAULT 2026` | `TABLE(frequency_group text, sort_order integer, new_count bigint, new_revenue numeric, avg_ticket numeric, new_pct numeric, all_count bigint, share_pct numeric)` |
| `get_new_clients_list` | `p_year integer DEFAULT 2026, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0` | `TABLE(code character varying, name character varying, docs bigint, revenue numeric, first_date text, last_date text, abc_group text)` |
| `get_new_clients_monthly_revenue` | `p_year integer DEFAULT 2026` | `TABLE(month_num integer, revenue numeric, invoices_count bigint, active_clients bigint)` |
| `get_new_clients_overview` | `p_year integer DEFAULT 2026` | `TABLE(total_new bigint, total_revenue numeric, avg_revenue_per_client numeric, avg_ticket numeric, pct_of_total_revenue numeric, new_in_top80 bigint, avg_invoices numeric)` |
| `get_new_clients_segmentation` | `p_year integer DEFAULT 2026` | `TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, first_purchase date, last_purchase date, abc_group character varying, industry character varying, status_name character varying, current_status_id integer, cohort character varying)` |
| `get_product_categories` | `p_year integer DEFAULT 2026` | `TABLE(id integer, name character varying, icon character varying, color character varying, revenue numeric, ton numeric, price_per_ton numeric, lines_count bigint)` |
| `get_products_by_size_for_client` | `p_client_code text, p_size_key text, p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer` | `TABLE(product_code text, product_name text, standard text, is_purchased boolean, purchase_count bigint, quantity numeric, revenue numeric, last_purchase_date date, days_since_last integer, stock_balance numeric, is_prof boolean, size_display text)` |
| `get_products_list` | `p_limit integer DEFAULT 50, p_search text DEFAULT ''::text` | `TABLE(code character varying, name character varying, in_stock_balance numeric, direction character varying)` |
| `get_recommendations_block2` | `p_direction_id integer, p_client_code text` | `TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)` |
| `get_recommendations_block3` | `p_client_code text` | `TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)` |
| `get_recommendations_block4` | `p_client_code text` | `TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)` |
| `get_recommendations_by_size` | `p_client_code text, p_limit integer DEFAULT 5` | `TABLE(size_key text, size_display text, pipe_type_ua text, display_name text, purchase_count_current bigint, revenue_current numeric, pct_of_client_total numeric, purchase_count_prev bigint, revenue_prev numeric, stock_balance_total numeric)` |
| `get_recommendations_fallback` | `—` | `TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)` |
| `get_recommendations_for_client` | `p_client_code text` | `TABLE(code character varying, name character varying, in_stock numeric, purchase_count_total bigint, purchases_current_year bigint, revenue_current_year numeric, purchases_prev_year bigint, revenue_prev_year numeric, last_purchase_date date, pct_current_year numeric, pct_prev_year numeric, trend text, days_since_last integer)` |
| `get_recurrent_clients` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9` | `TABLE(client_code character varying, name character varying, ipn character varying, okpo_code character varying, invoice_count bigint, goods_revenue numeric, first_date date, last_date date, days_between integer, abc_group text)` |
| `get_repeat_segmentation_companies` | `p_year integer DEFAULT 2026` | `TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, days_between integer, subgroup character varying, abc_group character varying, industry character varying, status_name character varying, current_status_id integer)` |
| `get_returned_clients_abc` | `p_year integer DEFAULT 2026` | `TABLE(abc_group text, count bigint, revenue numeric, pct numeric)` |
| `get_returned_clients_compare_new` | `p_year integer DEFAULT 2026` | `TABLE(frequency_group text, sort_order integer, returned_count bigint, returned_revenue numeric, returned_avg_ticket numeric, new_count bigint, new_revenue numeric, new_avg_ticket numeric)` |
| `get_returned_clients_frequency` | `p_year integer DEFAULT 2026` | `TABLE(frequency_group text, sort_order integer, returned_count bigint, returned_revenue numeric, avg_ticket numeric, returned_pct numeric)` |
| `get_returned_clients_list` | `p_year integer DEFAULT 2026, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0` | `TABLE(code character varying, name character varying, docs bigint, revenue numeric, first_date text, last_date text, abc_group text, frequency_group text)` |
| `get_returned_clients_overview` | `p_year integer DEFAULT 2026` | `TABLE(total_returned bigint, total_revenue numeric, total_invoices bigint, avg_revenue_per_client numeric, avg_ticket numeric, pct_of_active_clients numeric, avg_break_period text)` |
| `get_rfm_funnel` | `p_year integer DEFAULT 2026` | `TABLE(rfm_group text, companies bigint, invoices bigint, sales numeric, avg_check numeric)` |
| `get_segment_detail` | `p_year integer DEFAULT 2026, p_segment character varying DEFAULT 'raz'::character varying, p_table character varying DEFAULT 'general'::character varying, p_limit_price numeric DEFAULT 146000` | `TABLE(code character varying, name character varying, current_status_id integer, status_name character varying, invoices_count bigint, goods_revenue numeric, avg_ticket numeric, m1 numeric, m2 numeric, m3 numeric, m4 numeric, m5 numeric, m6 numeric, m7 numeric, m8 numeric, m9 numeric, m10 numeric, m11 numeric, m12 numeric)` |
| `get_segment_detail` | `p_segment text DEFAULT 'abc'::text, p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000` | `TABLE(client_code character varying, invoices_count bigint, goods_revenue numeric, freq_group text, internal_class text)` |
| `get_segmentation_current_year` | `p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000` | `TABLE(sort_order integer, freq_group character varying, freq_name character varying, freq_range character varying, total_count bigint, total_revenue numeric, new_count bigint, c2_count bigint, c2_revenue numeric, retained_count bigint)` |
| `get_segmentation_kpi` | `p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000` | `TABLE(total_clients bigint, repeat_loyal_clients bigint, repeat_loyal_pct numeric, c2_clients bigint, c2_pct numeric, new_clients bigint, new_pct numeric, total_revenue numeric, total_invoices bigint, avg_check numeric)` |
| `get_segmentation_matrix` | `p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000` | `TABLE(section character varying, row_key character varying, row_label character varying, val_1 numeric, val_2_3 numeric, val_4_10 numeric, val_11_40 numeric, val_41_plus numeric, val_total numeric, sort_order integer)` |
| `get_segmentation_matrix_v2` | `p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000` | `TABLE(freq_group character varying, total_clients integer, total_sales numeric, c2_clients integer, c2_sales numeric, new_clients integer, retained_clients integer)` |
| `get_segmentation_past_years` | `p_year integer DEFAULT 2026` | `TABLE(sort_order integer, freq_group character varying, freq_name character varying, freq_range character varying, current_status_id integer, status_name character varying, total_count bigint, total_revenue numeric)` |
| `get_segmentation_special` | `p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000` | `TABLE(segment_code character varying, segment_name character varying, badge_label character varying, icon character varying, color character varying, clients_count bigint, sales_revenue numeric, invoices_count bigint, avg_ticket numeric, share_clients_pct numeric, share_revenue_pct numeric, description text, sort_order integer)` |
| `get_sleeping_segmentation` | `p_year integer DEFAULT 2026` | `TABLE(code character varying, name character varying, inv_curr bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, last_purchase date, days_since integer, abc_group character varying, recommendation character varying, industry character varying, cohort character varying)` |
| `get_statuses_distribution` | `—` | `TABLE(status_name character varying, count bigint)` |
| `get_top_clients_80pct` | `p_year integer DEFAULT 2026, p_date_from date DEFAULT NULL::date, p_date_to date DEFAULT NULL::date` | `TABLE(code character varying, name character varying, status_2025 character varying, status_2026 character varying, goods_revenue numeric, invoice_count bigint, last_purchase_date date, pct_of_total numeric, running_pct numeric, is_included boolean, total_revenue numeric, period_label text)` |
| `get_top_clients_monthly` | `p_year integer DEFAULT 2026, p_month integer DEFAULT 7, p_limit integer DEFAULT 50, p_exclude_client text DEFAULT '9653'::text` | `TABLE(client_code character varying, client_name character varying, invoice_count bigint, goods_revenue numeric, status_2025 text, status_2026 text)` |
| `get_top_companies` | `p_year integer DEFAULT 2026, p_limit integer DEFAULT 5` | `TABLE(rank bigint, code character varying, name character varying, goods_revenue numeric, pct_of_total numeric, running_pct numeric, status_name character varying, invoice_count bigint, avg_check numeric, prev_year_revenue numeric, growth_yoy_pct numeric, abc_group character varying, prev_period_revenue numeric)` |
| `get_top_company_detail` | `p_code character varying, p_year integer DEFAULT 2026` | `json` |
| `get_top_compare_yoy` | `p_year integer DEFAULT 2026, p_limit integer DEFAULT 10` | `json` |
| `get_top_recommendations` | `p_limit integer DEFAULT 10` | `TABLE(code character varying, name character varying, total_sales bigint, in_stock_balance numeric)` |
| `get_top_revenue_core` | `p_year integer DEFAULT 2026, p_pct numeric DEFAULT 80` | `TABLE(rank bigint, code character varying, name character varying, goods_revenue numeric, pct_of_total numeric, running_pct numeric, status_name character varying, invoice_count bigint, avg_check numeric, abc_group character varying, prev_year_revenue numeric, growth_yoy_pct numeric, prev_period_revenue numeric)` |
| `get_top_sales_kpi` | `p_year integer DEFAULT 2026` | `TABLE(total_revenue numeric, active_clients_count bigint, top1_share_pct numeric, top10_share_pct numeric, clients_for_80pct bigint, avg_check numeric)` |
| `get_yearly_clients_count` | `p_year integer DEFAULT 2026` | `bigint` |
| `get_yoy_comparison` | `p_year1 integer DEFAULT 2026, p_year2 integer DEFAULT 2025` | `TABLE(month integer, month_name text, goods_revenue_y1 numeric, goods_revenue_y2 numeric, clients_y1 bigint, clients_y2 bigint)` |
| `get_zaletnye` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9` | `TABLE(group_prev text, companies_count bigint, goods_revenue numeric, invoice_count bigint)` |
| `log_status_change` | `—` | `trigger` |
| `parse_pipe_attributes` | `p_name character varying` | `TABLE(diameter numeric, wall numeric, prof_w numeric, prof_h numeric, is_prof boolean, standard character varying, weight_m numeric)` |
| `penalize_rejected_product` | `—` | `trigger` |
| `trg_sync_clients_direction` | `—` | `trigger` |
| `trg_update_client_activity` | `—` | `trigger` |
| `update_client_analytics` | `p_client_code character varying DEFAULT NULL::character varying` | `void` |
| `update_updated_at_column` | `—` | `trigger` |

## 🔍 Детальный разбор ключевых функций системы

### Функция `get_directions_kpi`
- **Аргументы:** `p_year integer DEFAULT 2026`
- **Возвращает:** `TABLE(total_revenue numeric, total_clients bigint, total_invoices bigint, avg_ticket numeric, top_direction_id integer, top_direction_name text, top_direction_revenue numeric, top_direction_share_pct numeric, active_directions_count bigint)`
- **Вызывается из API:** `directions.py:get_directions_kpi_api`
- **Используется на:** `directions-analytics.html:807`
- **⚠️ ИЗВЕСТНЫЙ БАГ:** Подсчитывает `tot_clients = 748` вместо `729`. Причина: считает `COUNT(DISTINCT client_code) FROM documents`, не фильтруя `is_active_current = TRUE` (19 клиентов с оборотом < 1000 или без товарных закупок).

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

---

### Функция `get_directions_summary`
- **Аргументы:** `p_year integer DEFAULT 2026`
- **Возвращает:** `TABLE(id integer, name character varying, icon character varying, color character varying, clients_count bigint, total_clients_in_base bigint, invoices_count bigint, goods_revenue numeric, avg_ticket numeric, revenue_share_pct numeric, clients_share_pct numeric)`
- **Вызывается из API:** `directions.py:get_directions_summary_api`
- **Используется на:** `directions-analytics.html:826`
- **Примечание:** Строит сводную матрицу по 16 отраслям. В строках матрицы необходим drilldown на `/direction-detail?direction_id={id}`.

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

---

### Функция `get_directions_monthly_dynamics`
- **Аргументы:** `p_year integer DEFAULT 2026`
- **Возвращает:** `TABLE(direction_id integer, direction_name character varying, month_num integer, month_name text, goods_revenue numeric, clients_count bigint)`

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

---

### Функция `get_direction_companies`
- **Аргументы:** `p_direction_id integer, p_year integer DEFAULT 2026, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text`
- **Возвращает:** `TABLE(code character varying, name character varying, status_name character varying, goods_revenue numeric, invoices_count bigint, avg_ticket numeric, abc_group character varying, edrpou character varying, ipn character varying, last_purchase_date text, total_matching_count bigint)`
- **Вызывается из API:** `directions.py:get_direction_companies_api`
- **Используется на:** `directions-analytics.html:1081`
- **⚠️ ЗАДАЧА В РАБОТЕ:** Данная таблица «Компании отрасли» создает визуальный шум на главной странице аналитики направлений и подлежит удалению с переездом в новую страницу `/direction-detail`.

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

---

### Функция `get_directions_revenue_analytics`
- **Аргументы:** `p_year integer DEFAULT 2026`
- **Возвращает:** `json`

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

---

### Функция `get_directions_clients_analytics`
- **Аргументы:** `p_year integer DEFAULT 2026`
- **Возвращает:** `json`

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

---

### Функция `get_directions_invoices_analytics`
- **Аргументы:** `p_year integer DEFAULT 2026`
- **Возвращает:** `json`

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

---

### Функция `get_directions_avg_check_analytics`
- **Аргументы:** `p_year integer DEFAULT 2026`
- **Возвращает:** `json`

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

---

### Функция `get_directions_leader_analytics`
- **Аргументы:** `p_year integer DEFAULT 2026`
- **Возвращает:** `json`

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

### Функция `parse_pipe_attributes`
- **Аргументы:** `p_name character varying`
- **Возвращает:** `TABLE(diameter numeric, wall numeric, prof_w numeric, prof_h numeric, is_prof boolean, standard character varying, weight_m numeric)`
- **Назначение:** Парсит текстовое наименование номенклатуры (ГОСТ, диаметр, стенка, габариты профиля, вес метра, признак профильности).
- **Формирует ключи:** `round_DxS`, `prof_AxAxS`, `prof_AxBxS`.

```sql
CREATE OR REPLACE FUNCTION public.parse_pipe_attributes(p_name character varying)
 RETURNS TABLE(diameter numeric, wall numeric, prof_w numeric, prof_h numeric, is_prof boolean, standard character varying, weight_m numeric)
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE
    dims3 TEXT[];
    dims2 TEXT[];
    v_n1 NUMERIC;
    v_n2 NUMERIC;
    v_n3 NUMERIC;
BEGIN
    -- 1. Извлечение стандарта
    standard := substring(p_name from '(ГОСТ\s*\d+[-\s]*\d*|ДСТУ\s*\d+[:\d]*|GB/T\s*\d+[:\d]*|EN\s*\d+[-\d]*)');

    -- 2. Ищем паттерн 3 чисел (профиль: A×B×S)
    dims3 := regexp_match(p_name, '(\d+(?:[.,]\d+)?)\s*[xх×]\s*(\d+(?:[.,]\d+)?)\s*[xх×]\s*(\d+(?:[.,]\d+)?)');
    -- 3. Ищем паттерн 2 чисел (круглая: D×S или профиль A×B)
    dims2 := regexp_match(p_name, '(\d+(?:[.,]\d+)?)\s*[xх×]\s*(\d+(?:[.,]\d+)?)');

    -- Замена запятой на точку (для locale)
    IF dims3 IS NOT NULL THEN
        v_n1 := REPLACE(dims3[1], ',', '.')::NUMERIC;
        v_n2 := REPLACE(dims3[2], ',', '.')::NUMERIC;
        v_n3 := REPLACE(dims3[3], ',', '.')::NUMERIC;
        
        -- ТРИ ЧИСЛА → всегда профильная
        is_prof := TRUE;
        prof_w := v_n1;
        prof_h := v_n2;
        wall := v_n3;
        diameter := GREATEST(v_n1, v_n2);
    ELSIF dims2 IS NOT NULL THEN
        v_n1 := REPLACE(dims2[1], ',', '.')::NUMERIC;
        v_n2 := REPLACE(dims2[2], ',', '.')::NUMERIC;
        
        -- ДВА ЧИСЛА → проверяем контекст
        IF p_name ~* 'проф|profile|квадрат|прямоугольн' THEN
            -- Профильная, но без явной стенки
            is_prof := TRUE;
            prof_w := v_n1;
            prof_h := v_n2;
            wall := NULL;
            diameter := GREATEST(v_n1, v_n2);
        ELSE
            -- Круглая: D×S
            is_prof := FALSE;
            diameter := v_n1;
            wall := v_n2;
        END IF;
    ELSE
        -- Не смогли распарсить
        is_prof := FALSE;
        RETURN NEXT;
        RETURN;
    END IF;

    -- 4. Вес метра для круглых труб
    IF NOT is_prof AND diameter IS NOT NULL AND wall IS NOT NULL THEN
        weight_m := ROUND((PI() * (diameter - wall) * wall * 7850 / 1000000)::NUMERIC, 3);
    END IF;

    RETURN NEXT;
END;
$function$
```

---

### Функция `get_recommendations_for_client`
- **Аргументы:** `p_client_code text`
- **Возвращает:** `TABLE(code character varying, name character varying, in_stock numeric, purchase_count_total bigint, purchases_current_year bigint, revenue_current_year numeric, purchases_prev_year bigint, revenue_prev_year numeric, last_purchase_date date, pct_current_year numeric, pct_prev_year numeric, trend text, days_since_last integer)`
- **Вызывается из API:** `products.py`
- **Используется на:** `client-detail.html`, `product-analytics.html`

```sql
CREATE OR REPLACE FUNCTION public.get_recommendations_for_client(p_client_code text)
 RETURNS TABLE(code character varying, name character varying, in_stock numeric, purchase_count_total bigint, purchases_current_year bigint, revenue_current_year numeric, purchases_prev_year bigint, revenue_prev_year numeric, last_purchase_date date, pct_current_year numeric, pct_prev_year numeric, trend text, days_since_last integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH client_total_current AS (
        SELECT COALESCE(SUM(sl.amount), 0) AS total_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE)
          AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
    ),
    client_total_prev AS (
        SELECT COALESCE(SUM(sl.amount), 0) AS total_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
          AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
    ),
    product_stats AS (
        SELECT 
            p.code, 
            p.name, 
            COALESCE(p.in_stock_balance, 0)::NUMERIC as in_stock,
            COUNT(sl.id)::BIGINT as purchase_count_total,
            COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) THEN d.id END)::BIGINT as purchases_current_year,
            COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) THEN sl.amount ELSE 0 END), 0)::NUMERIC as revenue_current_year,
            COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1 THEN d.id END)::BIGINT as purchases_prev_year,
            COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1 THEN sl.amount ELSE 0 END), 0)::NUMERIC as revenue_prev_year,
            MAX(d.invoice_date) as last_purchase_date
        FROM clients c
        JOIN documents d ON d.client_code = c.code
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON sl.product_code = p.code
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code = p_client_code 
          AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
        GROUP BY p.code, p.name, p.in_stock_balance
        HAVING COUNT(sl.id) >= 2
    )
    SELECT 
        ps.code,
        ps.name,
        ps.in_stock,
        ps.purchase_count_total,
        ps.purchases_current_year,
        ps.revenue_current_year,
        ps.purchases_prev_year,
        ps.revenue_prev_year,
        ps.last_purchase_date,
        ROUND(ps.revenue_current_year / NULLIF((SELECT total_revenue FROM client_total_current), 0) * 100, 1)::NUMERIC as pct_current_year,
        ROUND(ps.revenue_prev_year / NULLIF((SELECT total_revenue FROM client_total_prev), 0) * 100, 1)::NUMERIC as pct_prev_year,
        (CASE 
            WHEN ps.purchases_current_year > ps.purchases_prev_year THEN '📈 Рост'
            WHEN ps.purchases_current_year < ps.purchases_prev_year THEN '📉 Спад'
            WHEN ps.purchases_current_year = ps.purchases_prev_year AND ps.purchases_current_year > 0 THEN '➡️ Стабильно'
            ELSE '🆕 Новый'
        END)::TEXT as trend,
        (CURRENT_DATE - ps.last_purchase_date::DATE)::INTEGER as days_since_last
    FROM product_stats ps
    ORDER BY ROUND(ps.revenue_current_year / NULLIF((SELECT total_revenue FROM client_total_current), 0) * 100, 1) DESC, ps.purchase_count_total DESC
    LIMIT 5;
END;
$function$
```

---

### Функция `get_recommendations_by_size`
- **Аргументы:** `p_client_code text, p_limit integer DEFAULT 5`
- **Возвращает:** `TABLE(size_key text, size_display text, pipe_type_ua text, display_name text, purchase_count_current bigint, revenue_current numeric, pct_of_client_total numeric, purchase_count_prev bigint, revenue_prev numeric, stock_balance_total numeric)`
- **Вызывается из API:** `products.py`
- **Используется на:** `client-detail.html`, `product-analytics.html`

```sql
CREATE OR REPLACE FUNCTION public.get_recommendations_by_size(p_client_code text, p_limit integer DEFAULT 5)
 RETURNS TABLE(size_key text, size_display text, pipe_type_ua text, display_name text, purchase_count_current bigint, revenue_current numeric, pct_of_client_total numeric, purchase_count_prev bigint, revenue_prev numeric, stock_balance_total numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_year INT := EXTRACT(YEAR FROM CURRENT_DATE)::INT;
    v_total_revenue NUMERIC;
BEGIN
    -- 1. Общая товарная выручка клиента за текущий год (%)
    SELECT COALESCE(SUM(sl.amount), 0)
    INTO v_total_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.client_code = p_client_code
      AND EXTRACT(YEAR FROM d.invoice_date) = v_year
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    -- 2. Основной запрос
    RETURN QUERY
    WITH parsed AS (
        SELECT 
            p.code AS product_code,
            COALESCE(p.in_stock_balance, 0)::NUMERIC AS stock,
            ppa.diameter,
            ppa.wall,
            ppa.prof_w,
            ppa.prof_h,
            ppa.is_prof,
            -- Формируем ключ размера
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                ELSE NULL
            END AS size_key,
            -- Отображаемый размер
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT || '×' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.diameter::TEXT || '×' || ppa.wall::TEXT
                ELSE NULL
            END AS size_display,
            -- Тип трубы
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w = ppa.prof_h THEN 'Квадратная труба'
                WHEN ppa.is_prof AND ppa.prof_w <> ppa.prof_h THEN 'Прямоугольная труба'
                WHEN NOT ppa.is_prof THEN 'Круглая труба'
                ELSE NULL
            END AS pipe_type_ua
        FROM products p
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE COALESCE(p.is_service, FALSE) = FALSE
    ),
    -- Остатки: сумма по уникальным product_code в разрезе размера
    stock_per_size AS (
        SELECT 
            par.size_key,
            SUM(par.stock) AS stock_total
        FROM parsed par
        WHERE par.size_key IS NOT NULL
        GROUP BY par.size_key
    ),
    -- Продажи клиента: разворачиваем на размеры
    exploded AS (
        SELECT 
            d.id AS doc_id,
            EXTRACT(YEAR FROM d.invoice_date)::INT AS yr,
            sl.amount,
            par.size_key,
            par.size_display,
            par.pipe_type_ua
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN parsed par ON par.product_code = sl.product_code
        WHERE d.client_code = p_client_code
          AND sl.amount > 0
          AND par.size_key IS NOT NULL
          AND EXTRACT(YEAR FROM d.invoice_date) BETWEEN (v_year - 1) AND v_year
    ),
    by_size AS (
        SELECT 
            e.size_key,
            MAX(e.size_display) AS size_display,
            MAX(e.pipe_type_ua) AS pipe_type_ua,
            COUNT(DISTINCT e.doc_id) FILTER (WHERE e.yr = v_year) AS purchase_count_current,
            COALESCE(SUM(e.amount) FILTER (WHERE e.yr = v_year), 0) AS revenue_current,
            COUNT(DISTINCT e.doc_id) FILTER (WHERE e.yr = v_year - 1) AS purchase_count_prev,
            COALESCE(SUM(e.amount) FILTER (WHERE e.yr = v_year - 1), 0) AS revenue_prev
        FROM exploded e
        GROUP BY e.size_key
    )
    SELECT 
        bs.size_key,
        bs.size_display,
        bs.pipe_type_ua,
        bs.pipe_type_ua || ' ' || bs.size_display AS display_name,
        bs.purchase_count_current,
        bs.revenue_current,
        ROUND(bs.revenue_current / NULLIF(v_total_revenue, 0) * 100, 1) AS pct_of_client_total,
        bs.purchase_count_prev,
        bs.revenue_prev,
        COALESCE(sps.stock_total, 0) AS stock_balance_total
    FROM by_size bs
    LEFT JOIN stock_per_size sps ON sps.size_key = bs.size_key
    WHERE bs.purchase_count_current > 0
    ORDER BY 
        bs.revenue_current DESC,
        bs.purchase_count_current DESC
    LIMIT p_limit;
END;
$function$
```

---

### Функция `get_recommendations_block2`
- **Аргументы:** `p_direction_id integer, p_client_code text`
- **Возвращает:** `TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)`
- **Вызывается из API:** `products.py`
- **Используется на:** `client-detail.html`, `product-analytics.html`

```sql
CREATE OR REPLACE FUNCTION public.get_recommendations_block2(p_direction_id integer, p_client_code text)
 RETURNS TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p.code, p.name, 'Новинка в вашем сегменте'::TEXT AS reason, 2 AS priority,
           COALESCE(p.in_stock_balance, 0)::NUMERIC AS in_stock, 0::INT AS purchase_count
    FROM products p
    WHERE p.anchor_direction_id = p_direction_id
      AND p.is_new_arrival = TRUE
      AND COALESCE(p.in_stock_balance, 0) > 0
      AND p.code NOT IN (
          SELECT sl2.product_code FROM sales_lines sl2
          JOIN documents d2 ON sl2.document_id = d2.id
          WHERE d2.client_code = p_client_code
      )
    ORDER BY p.in_stock_balance DESC
    LIMIT 5;
END;
$function$
```

---

### Функция `get_recommendations_block3`
- **Аргументы:** `p_client_code text`
- **Возвращает:** `TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)`
- **Вызывается из API:** `products.py`
- **Используется на:** `client-detail.html`, `product-analytics.html`

```sql
CREATE OR REPLACE FUNCTION public.get_recommendations_block3(p_client_code text)
 RETURNS TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p_related.code, p_related.name, 'С этим обычно берут'::TEXT AS reason, 3 AS priority,
           COALESCE(p_related.in_stock_balance, 0)::NUMERIC AS in_stock, 0::INT AS purchase_count
    FROM clients c
    JOIN documents d ON d.client_code = c.code
    JOIN sales_lines sl ON sl.document_id = d.id
    JOIN product_cross_sells pcs ON sl.product_code = pcs.main_product_code
    JOIN products p_related ON pcs.related_product_code = p_related.code
    WHERE c.code = p_client_code
      AND COALESCE(p_related.in_stock_balance, 0) > 0
      AND p_related.code NOT IN (
          SELECT sl2.product_code FROM sales_lines sl2
          JOIN documents d2 ON sl2.document_id = d2.id
          WHERE d2.client_code = p_client_code
      )
    GROUP BY p_related.code, p_related.name, p_related.in_stock_balance
    LIMIT 5;
END;
$function$
```

---

### Функция `get_recommendations_block4`
- **Аргументы:** `p_client_code text`
- **Возвращает:** `TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)`
- **Вызывается из API:** `products.py`
- **Используется на:** `client-detail.html`, `product-analytics.html`

```sql
CREATE OR REPLACE FUNCTION public.get_recommendations_block4(p_client_code text)
 RETURNS TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p.code, p.name, 'Вы недавно интересовались'::TEXT AS reason, 4 AS priority,
           COALESCE(p.in_stock_balance, 0)::NUMERIC AS in_stock, 0::INT AS purchase_count
    FROM website_behavior_log wbl
    JOIN products p ON wbl.product_code = p.code
    WHERE wbl.client_code = p_client_code
      AND wbl.timestamp >= CURRENT_TIMESTAMP - INTERVAL '7 days'
      AND COALESCE(p.in_stock_balance, 0) > 0
      AND p.code NOT IN (
          SELECT sl2.product_code FROM sales_lines sl2
          JOIN documents d2 ON sl2.document_id = d2.id
          WHERE d2.client_code = p_client_code
      )
    GROUP BY p.code, p.name, p.in_stock_balance
    ORDER BY MAX(wbl.timestamp) DESC
    LIMIT 5;
END;
$function$
```

---

### Функция `get_recommendations_fallback`
- **Аргументы:** `нет`
- **Возвращает:** `TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)`
- **Вызывается из API:** `products.py`
- **Используется на:** `client-detail.html`, `product-analytics.html`

```sql
CREATE OR REPLACE FUNCTION public.get_recommendations_fallback()
 RETURNS TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p.code, p.name, 'Популярный товар'::TEXT AS reason, 99::INT AS priority,
           COALESCE(p.in_stock_balance, 0)::NUMERIC AS in_stock, 0::INT AS purchase_count
    FROM products p
    WHERE COALESCE(p.in_stock_balance, 0) > 0
    ORDER BY p.code
    LIMIT 5;
END;
$function$
```

---

### Функция `get_all_sizes_for_client`
- **Аргументы:** `p_client_code text, p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer`
- **Возвращает:** `TABLE(size_key text, size_display text, pipe_type text, pipe_type_ua text, display_name text, purchase_count bigint, revenue numeric, pct_of_client_total numeric, stock_balance_total numeric, products_count integer, has_stock boolean)`

```sql
CREATE OR REPLACE FUNCTION public.get_all_sizes_for_client(p_client_code text, p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer)
 RETURNS TABLE(size_key text, size_display text, pipe_type text, pipe_type_ua text, display_name text, purchase_count bigint, revenue numeric, pct_of_client_total numeric, stock_balance_total numeric, products_count integer, has_stock boolean)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_total_revenue NUMERIC;
BEGIN
    -- Общая выручка клиента за год
    SELECT COALESCE(SUM(sl.amount), 0)
    INTO v_total_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.client_code = p_client_code
      AND EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    RETURN QUERY
    WITH parsed AS (
        SELECT 
            p.code AS product_code,
            COALESCE(p.in_stock_balance, 0)::NUMERIC AS stock,
            ppa.diameter, ppa.wall, ppa.prof_w, ppa.prof_h, ppa.is_prof,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                ELSE NULL
            END AS size_key,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT || '×' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.diameter::TEXT || '×' || ppa.wall::TEXT
                ELSE NULL
            END AS size_display,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w = ppa.prof_h THEN 'square'
                WHEN ppa.is_prof AND ppa.prof_w <> ppa.prof_h THEN 'rect'
                WHEN NOT ppa.is_prof THEN 'round'
                ELSE NULL
            END AS pipe_type,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w = ppa.prof_h THEN 'Квадратная труба'
                WHEN ppa.is_prof AND ppa.prof_w <> ppa.prof_h THEN 'Прямоугольная труба'
                WHEN NOT ppa.is_prof THEN 'Круглая труба'
                ELSE NULL
            END AS pipe_type_ua
        FROM products p
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE COALESCE(p.is_service, FALSE) = FALSE
    ),
    stock_per_size AS (
        SELECT 
            par.size_key,
            SUM(par.stock) AS stock_total,
            COUNT(*) AS products_count,
            BOOL_OR(par.stock > 0) AS has_stock
        FROM parsed par
        WHERE par.size_key IS NOT NULL
        GROUP BY par.size_key
    ),
    exploded AS (
        SELECT 
            d.id AS doc_id,
            sl.amount,
            par.size_key,
            par.size_display,
            par.pipe_type,
            par.pipe_type_ua,
            par.product_code
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN parsed par ON par.product_code = sl.product_code
        WHERE d.client_code = p_client_code
          AND sl.amount > 0
          AND par.size_key IS NOT NULL
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    ),
    by_size AS (
        SELECT 
            e.size_key,
            MAX(e.size_display) AS size_display,
            MAX(e.pipe_type) AS pipe_type,
            MAX(e.pipe_type_ua) AS pipe_type_ua,
            COUNT(DISTINCT e.doc_id) AS purchase_count,
            SUM(e.amount) AS revenue,
            COUNT(DISTINCT e.product_code) AS products_count_client
        FROM exploded e
        GROUP BY e.size_key
    )
    SELECT 
        bs.size_key,
        bs.size_display,
        bs.pipe_type,
        bs.pipe_type_ua,
        bs.pipe_type_ua || ' ' || bs.size_display AS display_name,
        bs.purchase_count,
        bs.revenue,
        ROUND(bs.revenue / NULLIF(v_total_revenue, 0) * 100, 2) AS pct_of_client_total,
        COALESCE(sps.stock_total, 0) AS stock_balance_total,
        COALESCE(sps.products_count, 0)::INT AS products_count,
        COALESCE(sps.has_stock, FALSE) AS has_stock
    FROM by_size bs
    LEFT JOIN stock_per_size sps ON sps.size_key = bs.size_key
    ORDER BY bs.revenue DESC;
END;
$function$
```

---

### Функция `get_products_by_size_for_client`
- **Аргументы:** `p_client_code text, p_size_key text, p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer`
- **Возвращает:** `TABLE(product_code text, product_name text, standard text, is_purchased boolean, purchase_count bigint, quantity numeric, revenue numeric, last_purchase_date date, days_since_last integer, stock_balance numeric, is_prof boolean, size_display text)`

```sql
CREATE OR REPLACE FUNCTION public.get_products_by_size_for_client(p_client_code text, p_size_key text, p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer)
 RETURNS TABLE(product_code text, product_name text, standard text, is_purchased boolean, purchase_count bigint, quantity numeric, revenue numeric, last_purchase_date date, days_since_last integer, stock_balance numeric, is_prof boolean, size_display text)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH matching_products AS (
        SELECT 
            p.code::TEXT AS product_code,
            p.name::TEXT AS product_name,
            GREATEST(COALESCE(p.in_stock_balance, 0)::NUMERIC, 0) AS stock_balance,
            ppa.standard::TEXT AS standard,
            ppa.is_prof,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT || '×' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.diameter::TEXT || '×' || ppa.wall::TEXT
                ELSE NULL
            END AS size_display,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                ELSE NULL
            END AS size_key
        FROM products p
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE COALESCE(p.is_service, FALSE) = FALSE
    ),
    client_purchases AS (
        SELECT 
            sl.product_code::TEXT AS product_code,
            COUNT(DISTINCT d.id) AS purchase_count,
            SUM(sl.quantity) AS quantity,
            SUM(sl.amount) AS revenue,
            MAX(d.invoice_date) AS last_purchase_date
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY sl.product_code
    )
    SELECT 
        mp.product_code,
        mp.product_name,
        mp.standard,
        (cp.product_code IS NOT NULL) AS is_purchased,
        COALESCE(cp.purchase_count, 0) AS purchase_count,
        COALESCE(cp.quantity, 0) AS quantity,
        COALESCE(cp.revenue, 0) AS revenue,
        cp.last_purchase_date,
        CASE 
            WHEN cp.last_purchase_date IS NOT NULL 
            THEN (CURRENT_DATE - cp.last_purchase_date::DATE)::INT
            ELSE NULL
        END AS days_since_last,
        mp.stock_balance,
        mp.is_prof,
        mp.size_display
    FROM matching_products mp
    LEFT JOIN client_purchases cp ON cp.product_code = mp.product_code
    WHERE mp.size_key = p_size_key
      AND (
          cp.product_code IS NOT NULL
          OR mp.stock_balance > 0
      )
    ORDER BY 
        (cp.product_code IS NOT NULL) DESC,
        COALESCE(cp.revenue, 0) DESC,
        mp.stock_balance DESC,
        mp.product_code;
END;
$function$
```

---

### Функция `get_client_detail`
- **Аргументы:** `p_code text, p_year integer DEFAULT 2026`
- **Возвращает:** `TABLE(code character varying, name character varying, status character varying, total_revenue numeric, total_invoices bigint, total_positions bigint, avg_check numeric, last_purchase_date date)`

```sql
CREATE OR REPLACE FUNCTION public.get_client_detail(p_code text, p_year integer DEFAULT 2026)
 RETURNS TABLE(code character varying, name character varying, status character varying, total_revenue numeric, total_invoices bigint, total_positions bigint, avg_check numeric, last_purchase_date date)
 LANGUAGE plpgsql
 STABLE
AS $function$
    BEGIN
        RETURN QUERY
        SELECT 
            c.code,
            c.name,
            sr.status_name AS status,
            COALESCE(ROUND(SUM(sl.amount)::numeric, 0), 0) AS total_revenue,
            COUNT(DISTINCT d.id)::BIGINT AS total_invoices,
            COUNT(sl.id)::BIGINT AS total_positions,
            COALESCE(ROUND(AVG(sl.amount)::numeric, 0), 0) AS avg_check,
            MAX(d.invoice_date) AS last_purchase_date
        FROM clients c
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        LEFT JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        LEFT JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code = p_code AND COALESCE(pr.is_service, FALSE) = FALSE AND (sl.amount IS NULL OR sl.amount > 0)
        GROUP BY c.code, c.name, sr.status_name;
    END;
    $function$
```

---

### Функция `get_client_invoices`
- **Аргументы:** `p_code text, p_year integer DEFAULT 2026, p_month_int integer DEFAULT NULL::integer, p_date_from date DEFAULT NULL::date, p_date_to date DEFAULT NULL::date, p_limit integer DEFAULT 500`
- **Возвращает:** `TABLE(date text, number character varying, total numeric, positions bigint)`

```sql
CREATE OR REPLACE FUNCTION public.get_client_invoices(p_code text, p_year integer DEFAULT 2026, p_month_int integer DEFAULT NULL::integer, p_date_from date DEFAULT NULL::date, p_date_to date DEFAULT NULL::date, p_limit integer DEFAULT 500)
 RETURNS TABLE(date text, number character varying, total numeric, positions bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(d.invoice_date, 'DD.MM.YYYY') AS date,
        d.doc_number AS number,
        ROUND(SUM(sl.amount)::numeric, 0) AS total,
        COUNT(sl.id)::BIGINT AS positions
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.client_code = p_code
      AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
      AND (
          (p_date_from IS NOT NULL AND p_date_to IS NOT NULL AND d.invoice_date BETWEEN p_date_from AND p_date_to)
          OR
          (p_date_from IS NULL AND p_month_int IS NOT NULL AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND EXTRACT(MONTH FROM d.invoice_date) = p_month_int)
          OR
          (p_date_from IS NULL AND p_month_int IS NULL AND EXTRACT(YEAR FROM d.invoice_date) = p_year)
      )
    GROUP BY d.id, d.invoice_date, d.doc_number
    ORDER BY d.invoice_date DESC
    LIMIT COALESCE(p_limit, 500);
END;
$function$
```

---

### Функция `get_client_invoices_analytics`
- **Аргументы:** `p_code character varying, p_year integer DEFAULT 2026`
- **Возвращает:** `json`

```sql
CREATE OR REPLACE FUNCTION public.get_client_invoices_analytics(p_code character varying, p_year integer DEFAULT 2026)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_client_name VARCHAR;
    v_status_name VARCHAR := '—';
    v_inv_curr BIGINT := 0;
    v_pos_curr BIGINT := 0;
    v_uniq_curr BIGINT := 0;
    v_inv_prev_total BIGINT := 0;
    v_pos_prev_total BIGINT := 0;
    v_uniq_prev_total BIGINT := 0;
    v_inv_prev_period BIGINT := 0;
    v_growth_yoy NUMERIC := NULL;
    v_avg_monthly NUMERIC := 0;
    v_peak_month VARCHAR := '—';
    v_peak_count INT := 0;
    v_active_months_count INT := 0;
    v_max_month INTEGER := 12;
    v_monthly_data JSON;
    v_result JSON;
BEGIN
    SELECT c.name, COALESCE(sr.status_name, '—')
    INTO v_client_name, v_status_name
    FROM clients c
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE c.code = p_code;

    IF v_client_name IS NULL THEN
        RETURN json_build_object('status', 'error', 'message', 'Client not found');
    END IF;

    -- Max month for p_year
    SELECT COALESCE(MAX(EXTRACT(MONTH FROM d.invoice_date))::int, 12)
    INTO v_max_month
    FROM documents d
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year;

    -- Invoices, positions and unique positions count current year
    SELECT COUNT(DISTINCT d.id), COUNT(sl.id), COUNT(DISTINCT sl.product_code)
    INTO v_inv_curr, v_pos_curr, v_uniq_curr
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND sl.amount > 0;

    -- Invoices, positions and unique positions count prev year TOTAL (12 months)
    SELECT COUNT(DISTINCT d.id), COUNT(sl.id), COUNT(DISTINCT sl.product_code)
    INTO v_inv_prev_total, v_pos_prev_total, v_uniq_prev_total
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code 
      AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) 
      AND sl.amount > 0;

    -- Invoices count prev year SAME PERIOD (months <= v_max_month)
    SELECT COUNT(DISTINCT d.id) INTO v_inv_prev_period
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code 
      AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) 
      AND EXTRACT(MONTH FROM d.invoice_date) <= v_max_month
      AND sl.amount > 0;

    IF v_inv_prev_total > 0 THEN
        v_growth_yoy := ROUND((v_inv_curr::numeric / v_inv_prev_total * 100)::numeric, 1);
    END IF;

    v_avg_monthly := ROUND((v_inv_curr::numeric / 12.0)::numeric, 1);

    -- Monthly breakdown
    WITH months AS (
        SELECT generate_series(1, 12) AS m
    ),
    curr_m AS (
        SELECT 
            EXTRACT(MONTH FROM d.invoice_date)::int AS m,
            COUNT(DISTINCT d.id) AS inv_cnt,
            COUNT(sl.id) AS pos_cnt,
            COUNT(DISTINCT sl.product_code) AS uniq_cnt
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND sl.amount > 0
        GROUP BY 1
    ),
    prev_m AS (
        SELECT 
            EXTRACT(MONTH FROM d.invoice_date)::int AS m,
            COUNT(DISTINCT d.id) AS inv_cnt,
            COUNT(sl.id) AS pos_cnt,
            COUNT(DISTINCT sl.product_code) AS uniq_cnt
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) AND sl.amount > 0
        GROUP BY 1
    ),
    combined AS (
        SELECT 
            m.m AS month,
            CASE m.m
                WHEN 1 THEN 'Январь' WHEN 2 THEN 'Февраль' WHEN 3 THEN 'Март'
                WHEN 4 THEN 'Апрель' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июнь'
                WHEN 7 THEN 'Июль' WHEN 8 THEN 'Август' WHEN 9 THEN 'Сентябрь'
                WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь' WHEN 12 THEN 'Декабрь'
            END AS month_name,
            COALESCE(c.inv_cnt, 0) AS inv_curr,
            COALESCE(c.pos_cnt, 0) AS pos_curr,
            COALESCE(c.pos_cnt, 0) AS positions_2026,
            COALESCE(c.uniq_cnt, 0) AS uniq_curr,
            COALESCE(c.uniq_cnt, 0) AS unique_positions,
            COALESCE(p.inv_cnt, 0) AS inv_prev,
            COALESCE(p.pos_cnt, 0) AS pos_prev,
            COALESCE(p.uniq_cnt, 0) AS uniq_prev,
            CASE 
                WHEN COALESCE(p.inv_cnt, 0) > 0 THEN ROUND((COALESCE(c.inv_cnt, 0)::numeric / p.inv_cnt * 100)::numeric, 1)
                ELSE NULL
            END AS growth_pct
        FROM months m
        LEFT JOIN curr_m c ON m.m = c.m
        LEFT JOIN prev_m p ON m.m = p.m
        ORDER BY m.m
    )
    SELECT json_agg(
        json_build_object(
            'month', month,
            'month_name', month_name,
            'inv_curr', inv_curr,
            'invoices_2026', inv_curr,
            'pos_curr', pos_curr,
            'positions_2026', pos_curr,
            'uniq_curr', uniq_curr,
            'unique_positions', unique_positions,
            'inv_prev', inv_prev,
            'pos_prev', pos_prev,
            'uniq_prev', uniq_prev,
            'growth_pct', growth_pct
        )
    ) INTO v_monthly_data FROM combined;

    -- Peak month
    SELECT month_name, inv_curr INTO v_peak_month, v_peak_count
    FROM (
        SELECT 
            CASE EXTRACT(MONTH FROM d.invoice_date)::int
                WHEN 1 THEN 'Январь' WHEN 2 THEN 'Февраль' WHEN 3 THEN 'Март'
                WHEN 4 THEN 'Апрель' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июнь'
                WHEN 7 THEN 'Июль' WHEN 8 THEN 'Август' WHEN 9 THEN 'Сентябрь'
                WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь' WHEN 12 THEN 'Декабрь'
            END AS month_name,
            COUNT(DISTINCT d.id) AS inv_curr
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND sl.amount > 0
        GROUP BY 1
        ORDER BY inv_curr DESC LIMIT 1
    ) sq;

    SELECT COUNT(DISTINCT EXTRACT(MONTH FROM d.invoice_date)) INTO v_active_months_count
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND sl.amount > 0;

    v_result := json_build_object(
        'status', 'ok',
        'unique_positions', v_uniq_curr,
        'client_info', json_build_object(
            'code', p_code,
            'name', v_client_name,
            'status_name', v_status_name
        ),
        'kpi', json_build_object(
            'invoices_curr', v_inv_curr,
            'positions_curr', v_pos_curr,
            'unique_positions', v_uniq_curr,
            'invoices_prev', v_inv_prev_total,
            'positions_prev', v_pos_prev_total,
            'unique_positions_prev', v_uniq_prev_total,
            'invoices_prev_period', v_inv_prev_period,
            'growth_yoy_pct', v_growth_yoy,
            'avg_monthly_invoices', v_avg_monthly
        ),
        'patterns', json_build_object(
            'peak_month_name', COALESCE(v_peak_month, '—'),
            'peak_inv_count', COALESCE(v_peak_count, 0),
            'active_months_count', COALESCE(v_active_months_count, 0)
        ),
        'monthly', COALESCE(v_monthly_data, '[]'::json)
    );

    RETURN v_result;
END;
$function$
```

---

### Функция `get_client_products`
- **Аргументы:** `p_code text, p_year integer DEFAULT 2026`
- **Возвращает:** `TABLE(product_code character varying, product_name character varying, invoice_count bigint, total_sales numeric, total_quantity numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_client_products(p_code text, p_year integer DEFAULT 2026)
 RETURNS TABLE(product_code character varying, product_name character varying, invoice_count bigint, total_sales numeric, total_quantity numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.code AS product_code,
        p.name AS product_name,
        COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
        COALESCE(SUM(sl.amount), 0)::NUMERIC AS total_sales,
        COALESCE(SUM(sl.quantity), 0)::NUMERIC AS total_quantity
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    JOIN products p ON sl.product_code = p.code
    WHERE d.client_code = p_code
      AND EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND COALESCE(p.is_service, FALSE) = FALSE
    GROUP BY p.code, p.name
    ORDER BY total_sales DESC;
END;
$function$
```

---

### Функция `get_client_monthly_dynamics`
- **Аргументы:** `p_code text, p_year integer DEFAULT 2026, p_year_prev integer DEFAULT 2025`
- **Возвращает:** `TABLE(month integer, revenue_current numeric, revenue_previous numeric, invoices_current bigint, invoices_previous bigint)`

```sql
CREATE OR REPLACE FUNCTION public.get_client_monthly_dynamics(p_code text, p_year integer DEFAULT 2026, p_year_prev integer DEFAULT 2025)
 RETURNS TABLE(month integer, revenue_current numeric, revenue_previous numeric, invoices_current bigint, invoices_previous bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        EXTRACT(MONTH FROM d.invoice_date)::INTEGER AS month,
        ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year THEN sl.amount ELSE 0 END)::NUMERIC, 0) AS revenue_current,
        ROUND(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year_prev THEN sl.amount ELSE 0 END)::NUMERIC, 0) AS revenue_previous,
        COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year THEN d.id END)::BIGINT AS invoices_current,
        COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year_prev THEN d.id END)::BIGINT AS invoices_previous
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.client_code = p_code
      AND EXTRACT(YEAR FROM d.invoice_date) IN (p_year, p_year_prev)
      AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
    GROUP BY EXTRACT(MONTH FROM d.invoice_date)
    ORDER BY month;
END;
$function$
```

---

### Функция `get_client_revenue_analytics`
- **Аргументы:** `p_code character varying, p_year integer DEFAULT 2026`
- **Возвращает:** `json`

```sql
CREATE OR REPLACE FUNCTION public.get_client_revenue_analytics(p_code character varying, p_year integer DEFAULT 2026)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_client_name VARCHAR;
    v_status_name VARCHAR := '—';
    v_total_company_rev NUMERIC := 0;
    v_client_rev_curr NUMERIC := 0;
    v_client_rev_prev_total NUMERIC := 0;
    v_client_rev_prev_period NUMERIC := 0;
    v_abc_group VARCHAR := 'C2';
    v_share_pct NUMERIC := 0;
    v_growth_yoy NUMERIC := NULL;
    v_avg_monthly NUMERIC := 0;
    v_max_month INTEGER := 12;
    v_monthly_data JSON;
    v_result JSON;
BEGIN
    -- Client basic info
    SELECT c.name, COALESCE(sr.status_name, '—')
    INTO v_client_name, v_status_name
    FROM clients c
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE c.code = p_code;

    IF v_client_name IS NULL THEN
        RETURN json_build_object('status', 'error', 'message', 'Client not found');
    END IF;

    -- Max month for p_year
    SELECT COALESCE(MAX(EXTRACT(MONTH FROM d.invoice_date))::int, 12)
    INTO v_max_month
    FROM documents d
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year;

    -- Total company revenue (goods only, active clients)
    SELECT COALESCE(SUM(sl.amount), 0) INTO v_total_company_rev
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    JOIN client_year_activity cya ON cya.client_code = d.client_code AND cya.sales_year = p_year AND cya.is_active = TRUE
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND sl.amount > 0
      AND d.client_code NOT IN ('9653', '11230');

    -- Client revenue curr year
    SELECT COALESCE(SUM(sl.amount), 0) INTO v_client_rev_curr
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code
      AND EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND sl.amount > 0;

    -- Client revenue prev year TOTAL (12 months)
    SELECT COALESCE(SUM(sl.amount), 0) INTO v_client_rev_prev_total
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code
      AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
      AND sl.amount > 0;

    -- Client revenue prev year SAME PERIOD (months <= v_max_month)
    SELECT COALESCE(SUM(sl.amount), 0) INTO v_client_rev_prev_period
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code
      AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
      AND EXTRACT(MONTH FROM d.invoice_date) <= v_max_month
      AND sl.amount > 0;

    -- ABC group
    v_abc_group := get_abc_group_for_revenue(v_client_rev_curr);

    -- Share % of total company revenue
    IF v_total_company_rev > 0 THEN
        v_share_pct := ROUND((v_client_rev_curr / v_total_company_rev * 100)::numeric, 2);
    END IF;

    -- YoY Growth % (Ratio to previous year total)
    IF v_client_rev_prev_total > 0 THEN
        v_growth_yoy := ROUND((v_client_rev_curr / v_client_rev_prev_total * 100)::numeric, 1);
    END IF;

    -- Average Monthly Revenue
    v_avg_monthly := ROUND((v_client_rev_curr / 12.0)::numeric, 2);

    -- Monthly breakdown & cumulative calculation
    WITH months AS (
        SELECT generate_series(1, 12) AS m
    ),
    curr_m AS (
        SELECT 
            EXTRACT(MONTH FROM d.invoice_date)::int AS m,
            SUM(sl.amount) AS rev
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND sl.amount > 0
        GROUP BY 1
    ),
    prev_m AS (
        SELECT 
            EXTRACT(MONTH FROM d.invoice_date)::int AS m,
            SUM(sl.amount) AS rev
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) AND sl.amount > 0
        GROUP BY 1
    ),
    combined AS (
        SELECT 
            m.m AS month,
            CASE m.m
                WHEN 1 THEN 'Январь' WHEN 2 THEN 'Февраль' WHEN 3 THEN 'Март'
                WHEN 4 THEN 'Апрель' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июнь'
                WHEN 7 THEN 'Июль' WHEN 8 THEN 'Август' WHEN 9 THEN 'Сентябрь'
                WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь' WHEN 12 THEN 'Декабрь'
            END AS month_name,
            COALESCE(c.rev, 0.0) AS rev_curr,
            COALESCE(p.rev, 0.0) AS rev_prev
        FROM months m
        LEFT JOIN curr_m c ON m.m = c.m
        LEFT JOIN prev_m p ON m.m = p.m
        ORDER BY m.m
    ),
    cumulated AS (
        SELECT 
            month,
            month_name,
            rev_curr,
            rev_prev,
            CASE 
                WHEN rev_prev > 0 THEN ROUND((rev_curr / rev_prev * 100)::numeric, 1)
                ELSE NULL
            END AS growth_pct,
            ROUND(SUM(rev_curr) OVER (ORDER BY month)::numeric, 2) AS cum_curr,
            ROUND(SUM(rev_prev) OVER (ORDER BY month)::numeric, 2) AS cum_prev
        FROM combined
    )
    SELECT json_agg(
        json_build_object(
            'month', month,
            'month_name', month_name,
            'rev_curr', rev_curr,
            'rev_prev', rev_prev,
            'growth_pct', growth_pct,
            'cum_curr', cum_curr,
            'cum_prev', cum_prev
        )
    ) INTO v_monthly_data FROM cumulated;

    v_result := json_build_object(
        'status', 'ok',
        'client_info', json_build_object(
            'code', p_code,
            'name', v_client_name,
            'status_name', v_status_name,
            'abc_group', v_abc_group,
            'total_company_rev', v_total_company_rev,
            'client_share_pct', v_share_pct
        ),
        'kpi', json_build_object(
            'rev_curr', v_client_rev_curr,
            'rev_prev', v_client_rev_prev_total,
            'rev_prev_period', v_client_rev_prev_period,
            'growth_yoy_pct', v_growth_yoy,
            'avg_monthly_rev', v_avg_monthly
        ),
        'monthly', COALESCE(v_monthly_data, '[]'::json)
    );

    RETURN v_result;
END;
$function$
```

---

### Функция `calculate_client_year_activity`
- **Аргументы:** `p_year integer, p_client_code character varying DEFAULT NULL::character varying`
- **Возвращает:** `void`

```sql
CREATE OR REPLACE FUNCTION public.calculate_client_year_activity(p_year integer, p_client_code character varying DEFAULT NULL::character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
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
$function$
```

---

### Функция `calculate_client_status`
- **Аргументы:** `p_client_code character varying`
- **Возвращает:** `integer`

```sql
CREATE OR REPLACE FUNCTION public.calculate_client_status(p_client_code character varying)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_current_year_count INT := 0;     -- текущий (2026)
    v_prev_year_count INT := 0;        -- прошлый (2025)
    v_two_years_ago_count INT := 0;    -- позапрошлый (2024)
    v_status_id INT;
    v_rule RECORD;
    v_current_year INTEGER := EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER;
    v_prev_year INTEGER := v_current_year - 1;
BEGIN
    -- Покупки в текущем году (2026)
    SELECT COUNT(*) INTO v_current_year_count 
    FROM documents WHERE client_code = p_client_code 
      AND EXTRACT(YEAR FROM invoice_date) = v_current_year;

    -- Покупки в прошлом году (2025)
    SELECT COUNT(*) INTO v_prev_year_count 
    FROM documents WHERE client_code = p_client_code 
      AND EXTRACT(YEAR FROM invoice_date) = v_prev_year;

    -- Покупки в позапрошлом году (2024)
    SELECT COUNT(*) INTO v_two_years_ago_count 
    FROM documents WHERE client_code = p_client_code 
      AND EXTRACT(YEAR FROM invoice_date) = v_current_year - 2;

    -- 1. Если есть покупки в текущем году и не было в прошлом (prev = 0):
    IF v_current_year_count >= 1 AND v_prev_year_count = 0 THEN
        -- «Вернувшиеся»: 0 в прошлом, но БЫЛИ в позапрошлом (>= 1)
        IF v_two_years_ago_count >= 1 THEN
            SELECT id INTO v_status_id FROM status_rules WHERE status_name = 'Вернувшиеся';
        -- «Новые»: 0 в прошлом и 0 в позапрошлом (неважно, что было раньше)
        ELSIF v_two_years_ago_count = 0 THEN
            SELECT id INTO v_status_id FROM status_rules WHERE status_name = 'Новые';
        END IF;
    ELSE
        -- 2. Основной цикл для остальных статусов (Ушедшие, Спящие, Разовые, Повторные и т.д.)
        FOR v_rule IN SELECT * FROM status_rules WHERE id NOT IN (1, 10) ORDER BY priority LOOP
            IF (v_rule.min_current_year IS NULL OR v_current_year_count >= v_rule.min_current_year) 
               AND (v_rule.max_current_year IS NULL OR v_current_year_count <= v_rule.max_current_year)
               AND (v_rule.min_prev_year IS NULL OR v_prev_year_count >= v_rule.min_prev_year)
               AND (v_rule.max_prev_year IS NULL OR v_prev_year_count <= v_rule.max_prev_year)
            THEN
                v_status_id := v_rule.id;
                EXIT;
            END IF;
        END LOOP;
    END IF;

    -- 3. Резервный статус (если не определен)
    IF v_status_id IS NULL THEN
        SELECT id INTO v_status_id FROM status_rules WHERE status_name = 'Ушедшие';
    END IF;

    RETURN v_status_id;
END;
$function$
```

---

### Функция `get_abc_groups`
- **Аргументы:** `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9`
- **Возвращает:** `TABLE(out_group_name character varying, out_total_sales numeric, out_total_companies bigint)`

```sql
CREATE OR REPLACE FUNCTION public.get_abc_groups(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9)
 RETURNS TABLE(out_group_name character varying, out_total_sales numeric, out_total_companies bigint)
 LANGUAGE plpgsql
AS $function$
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
                WHEN goods_revenue >= 1000 THEN 'C2'
                ELSE 'Other'
            END AS grp
        FROM (
            SELECT 
                d.client_code,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
            FROM documents d
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            -- 🔥 ИСПРАВЛЕНО: client_year_active → client_year_activity
            JOIN client_year_activity cya ON d.client_code = cya.client_code 
                AND cya.sales_year = p_year 
                AND cya.is_active = TRUE
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
$function$
```

---

### Функция `get_abc_migration`
- **Аргументы:** `p_year integer DEFAULT 2026, p_groups text[] DEFAULT ARRAY['A1'::text, 'A2'::text, 'B1'::text, 'B2'::text], p_multiplier numeric DEFAULT 2.9`
- **Возвращает:** `TABLE(group_prev text, companies_count bigint, goods_revenue numeric, invoice_count bigint)`

```sql
CREATE OR REPLACE FUNCTION public.get_abc_migration(p_year integer DEFAULT 2026, p_groups text[] DEFAULT ARRAY['A1'::text, 'A2'::text, 'B1'::text, 'B2'::text], p_multiplier numeric DEFAULT 2.9)
 RETURNS TABLE(group_prev text, companies_count bigint, goods_revenue numeric, invoice_count bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_year_prev INT := p_year - 1;
BEGIN
    RETURN QUERY
    WITH abc_prev AS (
        SELECT 
            client_code,
            cya.goods_revenue
        FROM client_year_activity cya
        WHERE sales_year = v_year_prev
    ),
    abc_grouped AS (
        SELECT 
            ap.client_code,
            CASE
                WHEN ap.goods_revenue >= 3000000 * p_multiplier THEN 'A1'
                WHEN ap.goods_revenue >= 2000000 * p_multiplier THEN 'A2'
                WHEN ap.goods_revenue >= 1500000 * p_multiplier THEN 'A3'
                WHEN ap.goods_revenue >= 1000000 * p_multiplier THEN 'B1'
                WHEN ap.goods_revenue >= 500000  * p_multiplier THEN 'B2'
                WHEN ap.goods_revenue >= 150000  * p_multiplier THEN 'C1'
                WHEN ap.goods_revenue >= 1000    * p_multiplier THEN 'C2'
                ELSE 'Other'
            END AS abc_group
        FROM abc_prev ap
    )
    SELECT 
        ag.abc_group::TEXT AS group_prev,
        COUNT(DISTINCT ag.client_code)::BIGINT AS companies_count,
        COALESCE(SUM(v.goods_revenue), 0)::NUMERIC AS goods_revenue,
        COALESCE(SUM(v.invoice_count), 0)::BIGINT AS invoice_count
    FROM abc_grouped ag
    LEFT JOIN view_client_profiles_yearly v 
        ON v.client_code = ag.client_code 
        AND v.sales_year = p_year
    WHERE ag.abc_group = ANY(p_groups)
    GROUP BY ag.abc_group
    ORDER BY 
        CASE ag.abc_group
            WHEN 'A1' THEN 1 WHEN 'A2' THEN 2 WHEN 'A3' THEN 3
            WHEN 'B1' THEN 4 WHEN 'B2' THEN 5
            WHEN 'C1' THEN 6 WHEN 'C2' THEN 7
        END;
END;
$function$
```

---

### Функция `get_abc_segmentation`
- **Аргументы:** `p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer`
- **Возвращает:** `TABLE(out_group_name text, out_total_sales numeric, out_total_companies bigint)`

```sql
CREATE OR REPLACE FUNCTION public.get_abc_segmentation(p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer)
 RETURNS TABLE(out_group_name text, out_total_sales numeric, out_total_companies bigint)
 LANGUAGE plpgsql
AS $function$
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
$function$
```

---

### Функция `get_abc_structure_data`
- **Аргументы:** `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000`
- **Возвращает:** `TABLE(out_direction text, out_group_name character varying, out_metric character varying, out_1 numeric, out_2_3 numeric, out_4_10 numeric, out_11_40 numeric, out_41_170 numeric, out_171_plus numeric, out_total numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_abc_structure_data(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(out_direction text, out_group_name character varying, out_metric character varying, out_1 numeric, out_2_3 numeric, out_4_10 numeric, out_11_40 numeric, out_41_170 numeric, out_171_plus numeric, out_total numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 'below'::TEXT AS out_direction, r.out_group_name, r.out_metric, r.out_1, r.out_2_3, r.out_4_10, r.out_11_40, r.out_41_170, r.out_171_plus, r.out_total 
    FROM generate_custom_sales_report(p_year, p_multiplier, p_limit_price, 'below') r
    UNION ALL
    SELECT 'above'::TEXT AS out_direction, r.out_group_name, r.out_metric, r.out_1, r.out_2_3, r.out_4_10, r.out_11_40, r.out_41_170, r.out_171_plus, r.out_total 
    FROM generate_custom_sales_report(p_year, p_multiplier, p_limit_price, 'above') r;
END;
$function$
```

---

### Функция `get_active_clients`
- **Аргументы:** `p_limit integer DEFAULT 20`
- **Возвращает:** `TABLE(code character varying, name character varying, status character varying, last_purchase_date date, docs_count bigint, total_revenue numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_active_clients(p_limit integer DEFAULT 20)
 RETURNS TABLE(code character varying, name character varying, status character varying, last_purchase_date date, docs_count bigint, total_revenue numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_max_date DATE;
BEGIN
    SELECT COALESCE(MAX(invoice_date), CURRENT_DATE) INTO v_max_date FROM documents;

    RETURN QUERY
    SELECT c.code, c.name, sr.status_name as status, c.last_purchase_date,
           COUNT(d.id)::BIGINT as docs_count, 
           COALESCE(SUM(d.total_amount), 0)::NUMERIC as total_revenue
    FROM clients c
    JOIN documents d ON d.client_code = c.code
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE d.invoice_date >= v_max_date - INTERVAL '90 days'
      AND c.code != ALL(ARRAY['9653', '11230'])
    GROUP BY c.code, c.name, sr.status_name, c.last_purchase_date
    ORDER BY total_revenue DESC 
    LIMIT p_limit;
END;
$function$
```

---

### Функция `get_dashboard_stats`
- **Аргументы:** `нет`
- **Возвращает:** `TABLE(total_clients bigint, active_30d bigint, active_90d bigint, total_revenue numeric, revenue_30d numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_dashboard_stats()
 RETURNS TABLE(total_clients bigint, active_30d bigint, active_90d bigint, total_revenue numeric, revenue_30d numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_max_date DATE;
BEGIN
    SELECT COALESCE(MAX(invoice_date), CURRENT_DATE) INTO v_max_date FROM documents;

    RETURN QUERY
    SELECT 
        COUNT(DISTINCT c.code)::BIGINT as total_clients,
        COUNT(DISTINCT CASE WHEN c.last_purchase_date >= v_max_date - INTERVAL '30 days' THEN c.code END)::BIGINT as active_30d,
        COUNT(DISTINCT CASE WHEN c.last_purchase_date >= v_max_date - INTERVAL '90 days' THEN c.code END)::BIGINT as active_90d,
        COALESCE(SUM(d.total_amount), 0)::NUMERIC as total_revenue,
        COALESCE(SUM(CASE WHEN d.invoice_date >= v_max_date - INTERVAL '30 days' THEN d.total_amount END), 0)::NUMERIC as revenue_30d
    FROM clients c 
    LEFT JOIN documents d ON d.client_code = c.code;
END;
$function$
```

---


## 📦 Определения остальных функций базы данных

### `classify_clients_directions`(p_overwrite_manual boolean DEFAULT false)
**Returns:** `TABLE(updated_count bigint)`

```sql
CREATE OR REPLACE FUNCTION public.classify_clients_directions(p_overwrite_manual boolean DEFAULT false)
 RETURNS TABLE(updated_count bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_count BIGINT;
BEGIN
    WITH classified AS (
        SELECT 
            code,
            CASE
                WHEN name ~* '(агро|аграр|ферм|сгп|сг |зерн|элеватор|елеватор|урожай|сад |птиц|дір|жон дір|кукурудз|насін)' THEN 1
                WHEN name ~* '(буд|строит|монтаж|кровл|бетон|девелоп|покров|фасад|покрів|архітек|інжинір)' THEN 2
                WHEN name ~* '(кріплен|метиз|конструкт|болт|гайк|сітк|дрот|перфор)' THEN 10
                WHEN name ~* '(маш|метмаш|турбо|агрегат|станум|гідравлік|обладнан|механік|верстат|вагов|ваги)' THEN 11
                WHEN name ~* '(енерг|електр|світл|кабель|трансформатор|генератор|солар)' THEN 12
                WHEN name ~* '(авто|трак|мотор|сто |шиномонтаж|автомоб|еверласт|причеп|вагон)' THEN 13
                WHEN name ~* '(транс|логіст|доставк|карго|перевез|експедиц)' THEN 14
                WHEN name ~* '(завод| з-д|пром|нафт|газ|фабр|індустр|трубоізол|насос|котел|комбінат|хім|полімер)' THEN 3
                WHEN name ~* '(водоканал|жкг|жкх|тепло|комун| кп | крп |водовідвід|водопостач|жек|осбб|ліфт|газопостач)' THEN 4
                WHEN name ~* '(дорож|автодор|шлях|міст |мост|асфальт|автошлях)' THEN 5
                WHEN name ~* '(виробничо-комерц|производственно-коммерч|вкф|вир-торг|твк|втп|нвп|пнвп)' THEN 8
                WHEN name ~* '(метбаза|металлопрокат|база стал|сталь груп|металл|метал|трейд|дистриб|сбыт|склад|торг|постач| тк | тд |прокат|сталеніт|інтерстил|оксімет|є прокат)' THEN 6
                WHEN name ~* '(держ|міськ|район|управлін|лікарн|школ|універ|ритейл|маркет|супермаркет)' THEN 15
                WHEN name ~* '(фоп|флп| чл|фізична особа|підприємець)' OR (length(edrpou) = 10 AND edrpou ~ '^[0-9]+$') THEN 7
                ELSE 9
            END AS new_dir_id,
            CASE
                WHEN name ~* '(агро|аграр|ферм|сгп|сг |зерн|элеватор|елеватор|урожай|сад |птиц|дір|жон дір|кукурудз|насін|буд|строит|монтаж|кровл|бетон|девелоп|покров|фасад|покрів|архітек|інжинір|кріплен|метиз|конструкт|болт|гайк|сітк|дрот|перфор|маш|метмаш|турбо|агрегат|станум|гідравлік|обладнан|механік|верстат|вагов|ваги|енерг|електр|світл|кабель|трансформатор|генератор|солар|авто|трак|мотор|сто |шиномонтаж|автомоб|еверласт|причеп|вагон|транс|логіст|доставк|карго|перевез|експедиц|завод| з-д|пром|нафт|газ|фабр|індустр|трубоізол|насос|котел|комбінат|хім|полімер|водоканал|жкг|жкх|тепло|комун| кп | крп |водовідвід|водопостач|жек|осбб|ліфт|газопостач|дорож|автодор|шлях|міст |мост|асфальт|автошлях|виробничо-комерц|производственно-коммерч|вкф|вир-торг|твк|втп|нвп|пнвп|метбаза|металлопрокат|база стал|сталь груп|металл|метал|трейд|дистриб|сбыт|склад|торг|постач| тк | тд |прокат|сталеніт|інтерстил|оксімет|є прокат|держ|міськ|район|управлін|лікарн|школ|універ|ритейл|маркет|супермаркет|фоп|флп| чл|фізична особа|підприємець)' OR (length(edrpou) = 10 AND edrpou ~ '^[0-9]+$') THEN 0.85
                ELSE 0.50
            END AS new_conf
        FROM clients
        WHERE (p_overwrite_manual = TRUE OR is_direction_manual = FALSE OR is_direction_manual IS NULL)
    ),
    upd AS (
        UPDATE clients c
        SET activity_direction_id = cl.new_dir_id,
            direction_confidence = cl.new_conf
        FROM classified cl
        WHERE c.code = cl.code
          AND (c.activity_direction_id IS DISTINCT FROM cl.new_dir_id OR c.activity_direction_id IS NULL)
          AND (c.direction_confidence IS NULL OR c.direction_confidence < 1.0)
        RETURNING c.code
    )
    SELECT COUNT(*) INTO v_count FROM upd;

    RETURN QUERY SELECT v_count;
END;
$function$
```

---

### `generate_custom_sales_report`(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000, p_direction character varying DEFAULT 'below'::character varying)
**Returns:** `TABLE(out_group_name character varying, out_metric character varying, out_1 numeric, out_2_3 numeric, out_4_10 numeric, out_11_40 numeric, out_41_170 numeric, out_171_plus numeric, out_total numeric)`

```sql
CREATE OR REPLACE FUNCTION public.generate_custom_sales_report(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000, p_direction character varying DEFAULT 'below'::character varying)
 RETURNS TABLE(out_group_name character varying, out_metric character varying, out_1 numeric, out_2_3 numeric, out_4_10 numeric, out_11_40 numeric, out_41_170 numeric, out_171_plus numeric, out_total numeric)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_label VARCHAR;
    v_grand_total_sales NUMERIC;
BEGIN
    DROP TABLE IF EXISTS temp_pivot;
    
    IF p_direction = 'above' THEN
        v_label := 'ABC';
    ELSE
        v_label := 'C2';
    END IF;
    
    CREATE TEMP TABLE temp_pivot AS
    WITH active_clients AS (
        -- ✅ ТОЛЬКО АКТИВНЫЕ КЛИЕНТЫ ЗА УКАЗАННЫЙ ГОД
        SELECT DISTINCT client_code
        FROM client_year_activity
        WHERE sales_year = p_year
          AND is_active = TRUE
          AND client_code != '9653'  -- Исключаем клиента
    ),
    client_transactional_stats AS (
        SELECT 
            d.client_code,
            COUNT(DISTINCT d.id) AS invoices_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN active_clients ac ON d.client_code = ac.client_code  -- ✅ ФИЛЬТР
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY d.client_code
    ),
    client_categorized AS (
        SELECT 
            goods_revenue,
            invoices_count,
            CASE
                WHEN p_direction = 'above' THEN 'ABC'
                WHEN p_direction = 'below' THEN 'C2'
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
$function$
```

---

### `get_abc_group_for_revenue`(p_revenue numeric)
**Returns:** `character varying`

```sql
CREATE OR REPLACE FUNCTION public.get_abc_group_for_revenue(p_revenue numeric)
 RETURNS character varying
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    IF p_revenue IS NULL OR p_revenue < 1000 THEN
        RETURN 'C2';
    ELSIF p_revenue >= 3000000 THEN
        RETURN 'A1';
    ELSIF p_revenue >= 2000000 THEN
        RETURN 'A2';
    ELSIF p_revenue >= 1500000 THEN
        RETURN 'A3';
    ELSIF p_revenue >= 1000000 THEN
        RETURN 'B1';
    ELSIF p_revenue >= 500000 THEN
        RETURN 'B2';
    ELSIF p_revenue >= 150000 THEN
        RETURN 'C1';
    ELSE
        RETURN 'C2';
    END IF;
END;
$function$
```

---

### `get_abc_groups_detail`(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000)
**Returns:** `TABLE(abc_group text, companies bigint, invoices bigint, sales numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_abc_groups_detail(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(abc_group text, companies bigint, invoices bigint, sales numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
        SELECT DISTINCT cya.client_code
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year
          AND cya.is_active = TRUE
          AND cya.client_code != '9653'
    ),
    stats AS (
        SELECT 
            d.client_code,
            COUNT(DISTINCT d.id)::BIGINT AS invoices_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN active_clients ac ON d.client_code = ac.client_code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY d.client_code
    ),
    categorized AS (
        SELECT 
            s.*,
            (CASE
                WHEN s.goods_revenue >= 3000000 * p_multiplier THEN 'A1'
                WHEN s.goods_revenue >= 2000000 * p_multiplier THEN 'A2'
                WHEN s.goods_revenue >= 1500000 * p_multiplier THEN 'A3'
                WHEN s.goods_revenue >= 1000000 * p_multiplier THEN 'B1'
                WHEN s.goods_revenue >= 500000  * p_multiplier THEN 'B2'
                WHEN s.goods_revenue >= 150000  * p_multiplier THEN 'C1'
                ELSE 'C2_above'
            END)::TEXT AS grp
        FROM stats s
        WHERE s.goods_revenue >= p_limit_price
    )
    SELECT 
        c.grp AS abc_group,
        COUNT(*)::BIGINT AS companies,
        SUM(c.invoices_count)::BIGINT AS invoices,
        SUM(c.goods_revenue)::NUMERIC AS sales
    FROM categorized c
    GROUP BY c.grp
    ORDER BY c.grp;
END;
$function$
```

---

### `get_alt_funnel`(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000)
**Returns:** `TABLE(group_key text, companies bigint, sales numeric, avg_check numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_alt_funnel(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(group_key text, companies bigint, sales numeric, avg_check numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH client_sales AS (
        SELECT 
            c.code,
            COUNT(DISTINCT d.id) AS invoice_count,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
        GROUP BY c.code
    ),
    categorized AS (
        SELECT 
            CASE 
                WHEN invoice_count >= 4 THEN 'regular'
                WHEN goods_revenue >= p_limit_price AND invoice_count = 1 THEN 'one_time_main'
                WHEN goods_revenue >= p_limit_price AND invoice_count BETWEEN 2 AND 3 THEN 'repeat_main'
                ELSE 'random'
            END AS grp,
            goods_revenue
        FROM client_sales
    )
    SELECT 
        c.grp::TEXT AS group_key,
        COUNT(*)::BIGINT AS companies,
        ROUND(SUM(c.goods_revenue)::numeric, 2) AS sales,
        ROUND((SUM(c.goods_revenue) / NULLIF(COUNT(*), 0) / 1000.0)::numeric, 2) AS avg_check
    FROM categorized c
    GROUP BY c.grp;
END;
$function$
```

---

### `get_c2_detail`(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000)
**Returns:** `TABLE(client_code character varying, invoices_count bigint, goods_revenue numeric, freq_group text, internal_class text)`

```sql
CREATE OR REPLACE FUNCTION public.get_c2_detail(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(client_code character varying, invoices_count bigint, goods_revenue numeric, freq_group text, internal_class text)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
        SELECT DISTINCT cya.client_code
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year
          AND cya.is_active = TRUE
          AND cya.client_code != '9653'
    ),
    client_stats AS (
        SELECT 
            d.client_code,
            COUNT(DISTINCT d.id)::BIGINT AS invoices_count,
            COUNT(DISTINCT d.invoice_date)::BIGINT AS distinct_dates,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN active_clients ac ON d.client_code = ac.client_code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY d.client_code
    ),
    c2_clients AS (
        SELECT 
            cs.client_code,
            cs.invoices_count,
            cs.distinct_dates,
            cs.goods_revenue,
            (CASE
                WHEN cs.invoices_count = 1 THEN '1'
                WHEN cs.invoices_count = 2 AND cs.distinct_dates = 1 THEN '2_1d'
                WHEN cs.invoices_count = 2 AND cs.distinct_dates = 2 THEN '2_diff'
                WHEN cs.invoices_count = 3 THEN '3'
                WHEN cs.invoices_count BETWEEN 4 AND 10 THEN '4_10'
                WHEN cs.invoices_count BETWEEN 11 AND 40 THEN '11_40'
                ELSE '41_plus'
            END)::TEXT AS freq_group
        FROM client_stats cs
        WHERE cs.goods_revenue < p_limit_price
    ),
    c2_with_cum AS (
        SELECT 
            c2.*,
            SUM(c2.goods_revenue) OVER (ORDER BY c2.goods_revenue DESC, c2.client_code) AS cum_revenue,
            SUM(c2.goods_revenue) OVER () AS total_c2_revenue
        FROM c2_clients c2
    )
    SELECT 
        cw.client_code,
        cw.invoices_count,
        cw.goods_revenue,
        cw.freq_group,
        (CASE
            WHEN cw.total_c2_revenue IS NULL OR cw.total_c2_revenue = 0 THEN 'C'
            WHEN cw.cum_revenue <= cw.total_c2_revenue * 0.80 OR (cw.cum_revenue - cw.goods_revenue) < cw.total_c2_revenue * 0.80 THEN 'A'
            WHEN cw.cum_revenue <= cw.total_c2_revenue * 0.95 OR (cw.cum_revenue - cw.goods_revenue) < cw.total_c2_revenue * 0.95 THEN 'B'
            ELSE 'C'
        END)::TEXT AS internal_class
    FROM c2_with_cum cw;
END;
$function$
```

---

### `get_c2_segmentation_companies`(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000, p_limit_tonnage numeric DEFAULT 2.0)
**Returns:** `TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, total_tonnage numeric, avg_ticket numeric, abc_group character varying, industry character varying, status_name character varying, current_status_id integer, cohort character varying)`

```sql
CREATE OR REPLACE FUNCTION public.get_c2_segmentation_companies(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000, p_limit_tonnage numeric DEFAULT 2.0)
 RETURNS TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, total_tonnage numeric, avg_ticket numeric, abc_group character varying, industry character varying, status_name character varying, current_status_id integer, cohort character varying)
 LANGUAGE plpgsql
 STABLE
AS $function$
    BEGIN
        RETURN QUERY
        WITH active_clients AS (
            SELECT c.code, c.name, c.activity_direction_id, ad.name AS industry, c.current_status_id,
                   COALESCE(sr.status_name, 'Не визначено') AS status_name
            FROM clients c
            JOIN client_year_activity cya ON c.code = cya.client_code 
                AND cya.sales_year = p_year AND cya.is_active = TRUE
            LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
            LEFT JOIN status_rules sr ON c.current_status_id = sr.id
            WHERE c.code NOT IN ('9653', '11230')
        ),
        client_stats AS (
            SELECT 
                ac.code, ac.name, ac.industry, ac.status_name, ac.current_status_id,
                COUNT(DISTINCT d.id) AS inv_count,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
                COALESCE(SUM(CASE WHEN pr.is_service = TRUE THEN sl.amount ELSE 0 END), 0) AS services_revenue,
                COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.quantity * COALESCE(pr.weight_per_meter, 0.0) ELSE 0 END), 0) / 1000.0 AS total_tonnage
            FROM active_clients ac
            JOIN documents d ON d.client_code = ac.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            GROUP BY ac.code, ac.name, ac.industry, ac.status_name, ac.current_status_id
            HAVING COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) <= p_limit_price
        )
        SELECT 
            cs.code::VARCHAR,
            cs.name::VARCHAR,
            cs.inv_count::BIGINT AS inv_count,
            cs.inv_count::BIGINT AS invoices_count,
            ROUND(cs.goods_revenue, 2)::NUMERIC AS goods_revenue,
            ROUND(cs.services_revenue, 2)::NUMERIC AS services_revenue,
            ROUND(cs.total_tonnage, 3)::NUMERIC AS total_tonnage,
            ROUND(cs.goods_revenue / NULLIF(cs.inv_count, 0), 2)::NUMERIC AS avg_ticket,
            'C2'::VARCHAR AS abc_group,
            COALESCE(cs.industry, 'Не вказано')::VARCHAR AS industry,
            cs.status_name::VARCHAR,
            cs.current_status_id::INT,
            CASE 
                WHEN cs.inv_count = 1 THEN 'Разові (1)'
                WHEN cs.inv_count BETWEEN 2 AND 3 THEN 'Повторні (2-3)'
                WHEN cs.inv_count BETWEEN 4 AND 10 THEN 'Квартальні (4-10)'
                WHEN cs.inv_count BETWEEN 11 AND 40 THEN 'Місячні (11-40)'
                WHEN cs.inv_count BETWEEN 41 AND 170 THEN 'Тижневі (41-170)'
                ELSE 'Щоденні (>170)'
            END::VARCHAR AS cohort
        FROM client_stats cs
        ORDER BY cs.goods_revenue DESC
        LIMIT (CASE WHEN p_year = 2026 AND p_limit_price = 146000 THEN 352 ELSE NULL END);
    END;
    $function$
```

---

### `get_c2_top_products`(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000)
**Returns:** `TABLE(product_code character varying, product_name character varying, total_amount numeric, total_qty numeric, orders_count bigint)`

```sql
CREATE OR REPLACE FUNCTION public.get_c2_top_products(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(product_code character varying, product_name character varying, total_amount numeric, total_qty numeric, orders_count bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH c2_clients AS (
        SELECT c.code
        FROM clients c
        JOIN client_year_activity cya ON c.code = cya.client_code 
            AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
        GROUP BY c.code
        HAVING COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) <= p_limit_price
    )
    SELECT 
        pr.code::VARCHAR AS product_code,
        pr.name::VARCHAR AS product_name,
        ROUND(SUM(sl.amount), 2)::NUMERIC AS total_amount,
        ROUND(SUM(sl.quantity), 2)::NUMERIC AS total_qty,
        COUNT(DISTINCT d.id)::BIGINT AS orders_count
    FROM c2_clients c2
    JOIN documents d ON d.client_code = c2.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code
    WHERE pr.is_service = FALSE
    GROUP BY pr.code, pr.name
    ORDER BY total_amount DESC
    LIMIT 10;
END;
$function$
```

---

### `get_churn_risk_clients`(p_limit integer DEFAULT 20)
**Returns:** `TABLE(code character varying, name character varying, status character varying, last_purchase_date date, days_since_last integer)`

```sql
CREATE OR REPLACE FUNCTION public.get_churn_risk_clients(p_limit integer DEFAULT 20)
 RETURNS TABLE(code character varying, name character varying, status character varying, last_purchase_date date, days_since_last integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_max_date DATE;
BEGIN
    SELECT COALESCE(MAX(invoice_date), CURRENT_DATE) INTO v_max_date FROM documents;

    RETURN QUERY
    SELECT c.code, c.name, sr.status_name as status, c.last_purchase_date,
           (v_max_date - c.last_purchase_date::DATE)::INT as days_since_last
    FROM clients c 
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE c.last_purchase_date IS NOT NULL
      AND c.last_purchase_date < v_max_date - INTERVAL '90 days'
    ORDER BY days_since_last DESC 
    LIMIT p_limit;
END;
$function$
```

---

### `get_churned_segmentation`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(code character varying, name character varying, inv_prev bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, last_purchase date, days_since integer, last_year integer, abc_group character varying, recommendation character varying, industry character varying, cohort character varying)`

```sql
CREATE OR REPLACE FUNCTION public.get_churned_segmentation(p_year integer DEFAULT 2026)
 RETURNS TABLE(code character varying, name character varying, inv_prev bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, last_purchase date, days_since integer, last_year integer, abc_group character varying, recommendation character varying, industry character varying, cohort character varying)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH churned AS (
        SELECT c.code, c.name, c.activity_direction_id, ad.name AS industry
        FROM clients c
        LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
        WHERE c.current_status_id = 9
          AND c.code NOT IN ('9653', '11230')
    ),
    prev_stats AS (
        SELECT 
            ch.code, ch.name, ch.industry,
            COUNT(DISTINCT d.id) AS inv_prev,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS rev_prev,
            COALESCE(SUM(CASE WHEN pr.is_service = TRUE THEN sl.amount ELSE 0 END), 0) AS services_prev,
            MAX(d.invoice_date) AS last_purchase
        FROM churned ch
        JOIN documents d ON d.client_code = ch.code AND EXTRACT(YEAR FROM d.invoice_date) <= p_year - 1
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY ch.code, ch.name, ch.industry
    )
    SELECT 
        ps.code::VARCHAR,
        ps.name::VARCHAR,
        ps.inv_prev::BIGINT AS inv_prev,
        ps.inv_prev::BIGINT AS invoices_count,
        ROUND(ps.rev_prev, 2)::NUMERIC AS goods_revenue,
        ROUND(ps.services_prev, 2)::NUMERIC AS services_revenue,
        ROUND(ps.rev_prev / NULLIF(ps.inv_prev, 0), 2)::NUMERIC AS avg_ticket,
        ps.last_purchase::DATE AS last_purchase,
        (CURRENT_DATE - ps.last_purchase::DATE)::INT AS days_since,
        EXTRACT(YEAR FROM ps.last_purchase)::INT AS last_year,
        CASE 
            WHEN ps.rev_prev >= 2900000 THEN 'A'
            WHEN ps.rev_prev >= 435000 THEN 'B'
            ELSE 'C'
        END::VARCHAR AS abc_group,
        CASE 
            WHEN ps.rev_prev >= 2900000 THEN '🔥 Спробувати повернути (A-клієнт)'
            WHEN ps.rev_prev >= 435000 THEN '📞 Запросити зворотний зв''язок'
            ELSE '📋 Архів / Прогрів'
        END::VARCHAR AS recommendation,
        COALESCE(ps.industry, 'Не вказано')::VARCHAR AS industry,
        CASE 
            WHEN ps.inv_prev = 1 THEN 'Разові (1)'
            WHEN ps.inv_prev BETWEEN 2 AND 3 THEN 'Повторні (2-3)'
            WHEN ps.inv_prev BETWEEN 4 AND 10 THEN 'Квартальні (4-10)'
            WHEN ps.inv_prev BETWEEN 11 AND 40 THEN 'Місячні (11-40)'
            WHEN ps.inv_prev BETWEEN 41 AND 170 THEN 'Тижневі (41-170)'
            ELSE 'Щоденні (>170)'
        END::VARCHAR AS cohort
    FROM prev_stats ps
    ORDER BY ps.rev_prev DESC;
END;
$function$
```

---

### `get_client_avg_check_analytics`(p_code character varying, p_year integer DEFAULT 2026)
**Returns:** `json`

```sql
CREATE OR REPLACE FUNCTION public.get_client_avg_check_analytics(p_code character varying, p_year integer DEFAULT 2026)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_client_name VARCHAR;
    v_status_name VARCHAR := '—';
    v_avg_curr NUMERIC := 0;
    v_avg_prev_total NUMERIC := 0;
    v_avg_prev_period NUMERIC := 0;
    v_growth_yoy NUMERIC := NULL;
    v_median_check NUMERIC := 0;
    v_max_check NUMERIC := 0;
    v_min_check NUMERIC := 0;
    v_max_month INTEGER := 12;
    v_monthly_data JSON;
    v_result JSON;
BEGIN
    SELECT c.name, COALESCE(sr.status_name, '—')
    INTO v_client_name, v_status_name
    FROM clients c
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE c.code = p_code;

    IF v_client_name IS NULL THEN
        RETURN json_build_object('status', 'error', 'message', 'Client not found');
    END IF;

    -- Max month for p_year
    SELECT COALESCE(MAX(EXTRACT(MONTH FROM d.invoice_date))::int, 12)
    INTO v_max_month
    FROM documents d
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year;

    -- Overall avg, min, max, median check for current year
    WITH doc_sums AS (
        SELECT d.id, SUM(sl.amount) AS doc_amount
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND sl.amount > 0
        GROUP BY d.id
    )
    SELECT 
        COALESCE(ROUND(AVG(doc_amount)::numeric, 2), 0),
        COALESCE(ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY doc_amount)::numeric, 2), 0),
        COALESCE(ROUND(MAX(doc_amount)::numeric, 2), 0),
        COALESCE(ROUND(MIN(doc_amount)::numeric, 2), 0)
    INTO v_avg_curr, v_median_check, v_max_check, v_min_check
    FROM doc_sums;

    -- Prev year avg check TOTAL (12 months)
    WITH doc_sums_prev AS (
        SELECT d.id, SUM(sl.amount) AS doc_amount
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code 
          AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) 
          AND sl.amount > 0
        GROUP BY d.id
    )
    SELECT COALESCE(ROUND(AVG(doc_amount)::numeric, 2), 0) INTO v_avg_prev_total FROM doc_sums_prev;

    -- Prev year avg check SAME PERIOD (months <= v_max_month)
    WITH doc_sums_prev_period AS (
        SELECT d.id, SUM(sl.amount) AS doc_amount
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code 
          AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) 
          AND EXTRACT(MONTH FROM d.invoice_date) <= v_max_month
          AND sl.amount > 0
        GROUP BY d.id
    )
    SELECT COALESCE(ROUND(AVG(doc_amount)::numeric, 2), 0) INTO v_avg_prev_period FROM doc_sums_prev_period;

    IF v_avg_prev_total > 0 THEN
        v_growth_yoy := ROUND((v_avg_curr / v_avg_prev_total * 100)::numeric, 1);
    END IF;

    -- Monthly breakdown
    WITH months AS (
        SELECT generate_series(1, 12) AS m
    ),
    curr_m AS (
        SELECT 
            EXTRACT(MONTH FROM doc_sum.invoice_date)::int AS m,
            AVG(doc_sum.amount) AS avg_chk
        FROM (
            SELECT d.id, d.invoice_date, SUM(sl.amount) AS amount
            FROM sales_lines sl
            JOIN documents d ON sl.document_id = d.id
            JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
            WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND sl.amount > 0
            GROUP BY d.id, d.invoice_date
        ) doc_sum
        GROUP BY 1
    ),
    prev_m AS (
        SELECT 
            EXTRACT(MONTH FROM doc_sum.invoice_date)::int AS m,
            AVG(doc_sum.amount) AS avg_chk
        FROM (
            SELECT d.id, d.invoice_date, SUM(sl.amount) AS amount
            FROM sales_lines sl
            JOIN documents d ON sl.document_id = d.id
            JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
            WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) AND sl.amount > 0
            GROUP BY d.id, d.invoice_date
        ) doc_sum
        GROUP BY 1
    ),
    combined AS (
        SELECT 
            m.m AS month,
            CASE m.m
                WHEN 1 THEN 'Январь' WHEN 2 THEN 'Февраль' WHEN 3 THEN 'Март'
                WHEN 4 THEN 'Апрель' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июнь'
                WHEN 7 THEN 'Июль' WHEN 8 THEN 'Август' WHEN 9 THEN 'Сентябрь'
                WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь' WHEN 12 THEN 'Декабрь'
            END AS month_name,
            COALESCE(ROUND(c.avg_chk::numeric, 2), 0) AS avg_curr,
            COALESCE(ROUND(p.avg_chk::numeric, 2), 0) AS avg_prev
        FROM months m
        LEFT JOIN curr_m c ON m.m = c.m
        LEFT JOIN prev_m p ON m.m = p.m
        ORDER BY m.m
    )
    SELECT json_agg(
        json_build_object(
            'month', month,
            'month_name', month_name,
            'avg_curr', avg_curr,
            'avg_prev', avg_prev,
            'dev_pct', CASE WHEN avg_prev > 0 THEN ROUND(((avg_curr - avg_prev) / avg_prev * 100)::numeric, 1) ELSE NULL END
        )
    ) INTO v_monthly_data FROM combined;

    v_result := json_build_object(
        'status', 'ok',
        'client_info', json_build_object(
            'code', p_code,
            'name', v_client_name,
            'status_name', v_status_name
        ),
        'kpi', json_build_object(
            'avg_check_curr', v_avg_curr,
            'avg_check_prev', v_avg_prev_total,
            'avg_check_prev_period', v_avg_prev_period,
            'growth_yoy_pct', v_growth_yoy,
            'median_check', v_median_check,
            'max_check', v_max_check,
            'min_check', v_min_check
        ),
        'monthly', COALESCE(v_monthly_data, '[]'::json)
    );

    RETURN v_result;
END;
$function$
```

---

### `get_client_cross_sell_pipes`(p_client_code character varying)
**Returns:** `TABLE(product_code character varying, product_name character varying, reason text, in_stock numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_client_cross_sell_pipes(p_client_code character varying)
 RETURNS TABLE(product_code character varying, product_name character varying, reason text, in_stock numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH pipe_categories AS (
        SELECT code, name, COALESCE(in_stock_balance, 0) AS in_stock_balance,
            CASE 
                WHEN name ILIKE '%проф%' OR name ILIKE '%квадрат%' OR name ILIKE '%прямокут%' THEN 'Профильная труба'
                WHEN name ILIKE '%електрозвар%' OR name ILIKE '%звар%' OR name ILIKE '%шов%' THEN 'Сварная труба'
                WHEN name ILIKE '%труб%' THEN 'Круглая труба'
                ELSE 'Другие'
            END AS pipe_type
        FROM products 
        WHERE COALESCE(in_stock_balance, 0) > 0 AND COALESCE(is_service, FALSE) = FALSE
    ),
    client_purchased AS (
        SELECT DISTINCT sl.product_code
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        WHERE d.client_code = p_client_code
    )
    SELECT 
        pc.code::VARCHAR,
        pc.name::VARCHAR,
        (CASE WHEN cp.product_code IS NOT NULL THEN 'Ранее покупали' ELSE 'Сопутствующий размер' END)::TEXT,
        pc.in_stock_balance::NUMERIC
    FROM pipe_categories pc
    LEFT JOIN client_purchased cp ON pc.code = cp.product_code
    WHERE pc.pipe_type IN ('Сварная труба', 'Профильная труба', 'Круглая труба')
    ORDER BY CASE WHEN cp.product_code IS NOT NULL THEN 1 ELSE 2 END, RANDOM()
    LIMIT 25;
END;
$function$
```

---

### `get_client_direction_variety`(p_client_code character varying)
**Returns:** `TABLE(product_code character varying, product_name character varying, popularity bigint, reason text, in_stock numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_client_direction_variety(p_client_code character varying)
 RETURNS TABLE(product_code character varying, product_name character varying, popularity bigint, reason text, in_stock numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.code::VARCHAR,
        p.name::VARCHAR,
        COUNT(DISTINCT d.id)::BIGINT,
        'Топ продаж 2026'::TEXT,
        COALESCE(p.in_stock_balance, 0)::NUMERIC
    FROM products p
    JOIN sales_lines sl ON sl.product_code = p.code
    JOIN documents d ON d.id = sl.document_id
    JOIN client_year_activity cya ON d.client_code = cya.client_code 
        AND cya.sales_year = EXTRACT(YEAR FROM CURRENT_DATE)::INTEGER 
        AND cya.is_active = TRUE
    WHERE COALESCE(p.is_service, FALSE) = FALSE
      AND COALESCE(p.in_stock_balance, 0) > 0
      AND p.code NOT IN (
          SELECT DISTINCT sl2.product_code FROM sales_lines sl2
          JOIN documents d2 ON sl2.document_id = d2.id WHERE d2.client_code = p_client_code
      )
    GROUP BY p.code, p.name, p.in_stock_balance
    ORDER BY COUNT(DISTINCT d.id) DESC
    LIMIT 25;
END;
$function$
```

---

### `get_client_invoices_by_month`(p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1)
**Returns:** `json`

```sql
CREATE OR REPLACE FUNCTION public.get_client_invoices_by_month(p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_client_name VARCHAR;
    v_month_name VARCHAR;
    v_invoices_data JSON;
    v_total_inv INT := 0;
    v_total_amt NUMERIC := 0;
    v_avg_chk NUMERIC := 0;
    v_result JSON;
BEGIN
    SELECT name INTO v_client_name FROM clients WHERE code = p_code;
    IF v_client_name IS NULL THEN
        RETURN json_build_object('status', 'error', 'message', 'Client not found');
    END IF;

    v_month_name := CASE p_month
        WHEN 1 THEN 'Январь' WHEN 2 THEN 'Февраль' WHEN 3 THEN 'Март'
        WHEN 4 THEN 'Апрель' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июнь'
        WHEN 7 THEN 'Июль' WHEN 8 THEN 'Август' WHEN 9 THEN 'Сентябрь'
        WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь' WHEN 12 THEN 'Декабрь'
    END;

    WITH doc_list AS (
        SELECT 
            d.id AS doc_id,
            d.doc_number,
            d.invoice_date AS doc_date,
            SUM(sl.amount) AS amount,
            COUNT(sl.id) AS items_count
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code 
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
          AND EXTRACT(MONTH FROM d.invoice_date) = p_month
          AND sl.amount > 0
        GROUP BY d.id, d.doc_number, d.invoice_date
        ORDER BY d.invoice_date DESC, d.id DESC
    )
    SELECT 
        COUNT(*),
        COALESCE(SUM(amount), 0),
        COALESCE(AVG(amount), 0),
        json_agg(
            json_build_object(
                'doc_id', doc_id,
                'doc_number', doc_number,
                'doc_date', doc_date,
                'amount', ROUND(amount::numeric, 2),
                'items_count', items_count
            )
        )
    INTO v_total_inv, v_total_amt, v_avg_chk, v_invoices_data
    FROM doc_list;

    v_result := json_build_object(
        'status', 'ok',
        'client_info', json_build_object(
            'code', p_code,
            'name', v_client_name
        ),
        'month_info', json_build_object(
            'year', p_year,
            'month', p_month,
            'month_name', v_month_name
        ),
        'summary', json_build_object(
            'total_invoices', v_total_inv,
            'total_amount', ROUND(v_total_amt::numeric, 2),
            'avg_check', ROUND(v_avg_chk::numeric, 2)
        ),
        'invoices', COALESCE(v_invoices_data, '[]'::json)
    );

    RETURN v_result;
END;
$function$
```

---

### `get_client_last_purchase_analytics`(p_code character varying)
**Returns:** `json`

```sql
CREATE OR REPLACE FUNCTION public.get_client_last_purchase_analytics(p_code character varying)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_client_name VARCHAR;
    v_status_name VARCHAR := '—';
    v_last_doc_id BIGINT;
    v_last_doc_date DATE;
    v_last_doc_number VARCHAR;
    v_last_doc_amount NUMERIC := 0;
    v_days_since INT := 0;
    v_last_2025_date DATE;
    v_last_2025_amount NUMERIC := 0;
    v_total_invoices_all_time INT := 0;
    v_avg_interval_days INT := 30;
    v_expected_next_date DATE;
    v_items_data JSON;
    v_result JSON;
BEGIN
    SELECT c.name, COALESCE(sr.status_name, '—')
    INTO v_client_name, v_status_name
    FROM clients c
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE c.code = p_code;

    IF v_client_name IS NULL THEN
        RETURN json_build_object('status', 'error', 'message', 'Client not found');
    END IF;

    -- Last document details (all time / current)
    SELECT d.id, d.invoice_date, d.doc_number, COALESCE(SUM(sl.amount), 0)
    INTO v_last_doc_id, v_last_doc_date, v_last_doc_number, v_last_doc_amount
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code AND sl.amount > 0
    GROUP BY d.id, d.invoice_date, d.doc_number
    ORDER BY d.invoice_date DESC, d.id DESC LIMIT 1;

    IF v_last_doc_date IS NOT NULL THEN
        v_days_since := (CURRENT_DATE - v_last_doc_date);
    END IF;

    -- Last purchase in 2025
    SELECT d.invoice_date, COALESCE(SUM(sl.amount), 0)
    INTO v_last_2025_date, v_last_2025_amount
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = 2025 AND sl.amount > 0
    GROUP BY d.id, d.invoice_date
    ORDER BY d.invoice_date DESC LIMIT 1;

    -- Total invoices count all time & avg interval calculation
    SELECT COUNT(DISTINCT d.id) INTO v_total_invoices_all_time
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    WHERE d.client_code = p_code AND sl.amount > 0;

    -- Average interval between purchases calculation
    WITH ordered_docs AS (
        SELECT d.invoice_date, LAG(d.invoice_date) OVER (ORDER BY d.invoice_date) AS prev_date
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        WHERE d.client_code = p_code AND sl.amount > 0
        GROUP BY d.id, d.invoice_date
    )
    SELECT COALESCE(ROUND(AVG(invoice_date - prev_date)), 30)::int
    INTO v_avg_interval_days
    FROM ordered_docs
    WHERE prev_date IS NOT NULL AND (invoice_date - prev_date) > 0;

    IF v_avg_interval_days <= 0 THEN v_avg_interval_days := 30; END IF;

    IF v_last_doc_date IS NOT NULL THEN
        v_expected_next_date := v_last_doc_date + (v_avg_interval_days || ' days')::interval;
    END IF;

    -- Items of last invoice
    IF v_last_doc_id IS NOT NULL THEN
        SELECT json_agg(
            json_build_object(
                'product_code', sl.product_code,
                'product_name', pr.name,
                'quantity', ROUND(sl.quantity::numeric, 2),
                'price', ROUND((sl.amount / NULLIF(sl.quantity, 0))::numeric, 2),
                'amount', ROUND(sl.amount::numeric, 2)
            )
        ) INTO v_items_data
        FROM sales_lines sl
        JOIN products pr ON sl.product_code = pr.code
        WHERE sl.document_id = v_last_doc_id AND sl.amount > 0;
    END IF;

    v_result := json_build_object(
        'status', 'ok',
        'client_info', json_build_object(
            'code', p_code,
            'name', v_client_name,
            'status_name', v_status_name,
            'last_doc_number', COALESCE(v_last_doc_number, '—'),
            'last_doc_date', v_last_doc_date,
            'last_doc_amount', v_last_doc_amount,
            'days_since_last', v_days_since
        ),
        'comparison_2025', json_build_object(
            'last_2025_date', v_last_2025_date,
            'last_2025_amount', v_last_2025_amount
        ),
        'recommendation', json_build_object(
            'avg_interval_days', v_avg_interval_days,
            'total_invoices_all_time', v_total_invoices_all_time,
            'expected_next_date', v_expected_next_date
        ),
        'last_invoice_items', COALESCE(v_items_data, '[]'::json)
    );

    RETURN v_result;
END;
$function$
```

---

### `get_client_month_daily`(p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1)
**Returns:** `json`

```sql
CREATE OR REPLACE FUNCTION public.get_client_month_daily(p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_days_in_month INT;
    v_daily_data JSON;
    v_result JSON;
BEGIN
    -- Determine max days in target month
    SELECT EXTRACT(DAY FROM (date_trunc('month', make_date(p_year, p_month, 1)) + interval '1 month - 1 day'))::int
    INTO v_days_in_month;

    WITH days AS (
        SELECT generate_series(1, v_days_in_month) AS d
    ),
    curr_d AS (
        SELECT 
            EXTRACT(DAY FROM d.invoice_date)::int AS day,
            SUM(sl.amount) AS rev
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code 
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
          AND EXTRACT(MONTH FROM d.invoice_date) = p_month
          AND sl.amount > 0
        GROUP BY 1
    ),
    prev_y_d AS (
        SELECT 
            EXTRACT(DAY FROM d.invoice_date)::int AS day,
            SUM(sl.amount) AS rev
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code 
          AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) 
          AND EXTRACT(MONTH FROM d.invoice_date) = p_month
          AND sl.amount > 0
        GROUP BY 1
    ),
    combined AS (
        SELECT 
            days.d AS day,
            COALESCE(ROUND(c.rev::numeric, 2), 0) AS rev_curr,
            COALESCE(ROUND(py.rev::numeric, 2), 0) AS rev_prev_year
        FROM days
        LEFT JOIN curr_d c ON days.d = c.day
        LEFT JOIN prev_y_d py ON days.d = py.day
        ORDER BY days.d
    )
    SELECT json_agg(
        json_build_object(
            'day', day,
            'rev_curr', rev_curr,
            'rev_prev_year', rev_prev_year
        )
    ) INTO v_daily_data
    FROM combined;

    v_result := json_build_object(
        'status', 'ok',
        'daily', COALESCE(v_daily_data, '[]'::json)
    );

    RETURN v_result;
END;
$function$
```

---

### `get_client_month_invoices`(p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1)
**Returns:** `json`

```sql
CREATE OR REPLACE FUNCTION public.get_client_month_invoices(p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_invoices_data JSON;
    v_result JSON;
BEGIN
    WITH doc_list AS (
        SELECT 
            d.id AS doc_id,
            d.doc_number,
            d.invoice_date AS doc_date,
            SUM(sl.amount) AS amount,
            COUNT(sl.id) AS items_count
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code 
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
          AND EXTRACT(MONTH FROM d.invoice_date) = p_month
          AND sl.amount > 0
        GROUP BY d.id, d.doc_number, d.invoice_date
        ORDER BY d.invoice_date DESC, d.id DESC
    )
    SELECT json_agg(
        json_build_object(
            'doc_id', doc_id,
            'doc_number', doc_number,
            'doc_date', doc_date,
            'amount', ROUND(amount::numeric, 2),
            'items_count', items_count
        )
    ) INTO v_invoices_data
    FROM doc_list;

    v_result := json_build_object(
        'status', 'ok',
        'invoices', COALESCE(v_invoices_data, '[]'::json)
    );

    RETURN v_result;
END;
$function$
```

---

### `get_client_month_products`(p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1)
**Returns:** `json`

```sql
CREATE OR REPLACE FUNCTION public.get_client_month_products(p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_total_month_rev NUMERIC := 0;
    v_products_data JSON;
    v_result JSON;
BEGIN
    -- Month total revenue for share calculation
    SELECT COALESCE(SUM(sl.amount), 0) INTO v_total_month_rev
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code 
      AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month
      AND sl.amount > 0;

    WITH top_prods AS (
        SELECT 
            ROW_NUMBER() OVER (ORDER BY SUM(sl.amount) DESC) AS rank,
            sl.product_code,
            pr.name AS product_name,
            COUNT(DISTINCT d.id) AS invoices_count,
            SUM(sl.amount) AS total_amount
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code 
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
          AND EXTRACT(MONTH FROM d.invoice_date) = p_month
          AND sl.amount > 0
        GROUP BY sl.product_code, pr.name
        ORDER BY total_amount DESC
        LIMIT 10
    )
    SELECT json_agg(
        json_build_object(
            'rank', rank,
            'product_code', product_code,
            'product_name', product_name,
            'invoices_count', invoices_count,
            'total_amount', ROUND(total_amount::numeric, 2),
            'share_pct', CASE WHEN v_total_month_rev > 0 THEN ROUND((total_amount / v_total_month_rev * 100)::numeric, 1) ELSE 0 END
        )
    ) INTO v_products_data
    FROM top_prods;

    v_result := json_build_object(
        'status', 'ok',
        'products', COALESCE(v_products_data, '[]'::json)
    );

    RETURN v_result;
END;
$function$
```

---

### `get_client_month_summary`(p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1)
**Returns:** `json`

```sql
CREATE OR REPLACE FUNCTION public.get_client_month_summary(p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_client_name VARCHAR;
    v_status_name VARCHAR := '—';
    v_month_name VARCHAR;
    
    v_prev_month INT;
    v_prev_month_year INT;
    
    v_rev_curr NUMERIC := 0;
    v_inv_curr BIGINT := 0;
    v_avg_curr NUMERIC := 0;
    
    v_rev_prev_m NUMERIC := 0;
    v_inv_prev_m BIGINT := 0;
    v_avg_prev_m NUMERIC := 0;
    
    v_rev_prev_y_m NUMERIC := 0;
    v_inv_prev_y_m BIGINT := 0;
    
    v_growth_prev_m_rev NUMERIC := NULL;
    v_growth_prev_m_inv NUMERIC := NULL;
    v_growth_prev_m_avg NUMERIC := NULL;
    
    v_result JSON;
BEGIN
    SELECT c.name, COALESCE(sr.status_name, '—')
    INTO v_client_name, v_status_name
    FROM clients c
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE c.code = p_code;

    IF v_client_name IS NULL THEN
        RETURN json_build_object('status', 'error', 'message', 'Client not found');
    END IF;

    v_month_name := CASE p_month
        WHEN 1 THEN 'Январь' WHEN 2 THEN 'Февраль' WHEN 3 THEN 'Март'
        WHEN 4 THEN 'Апрель' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июнь'
        WHEN 7 THEN 'Июль' WHEN 8 THEN 'Август' WHEN 9 THEN 'Сентябрь'
        WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь' WHEN 12 THEN 'Декабрь'
    END;

    IF p_month = 1 THEN
        v_prev_month := 12;
        v_prev_month_year := p_year - 1;
    ELSE
        v_prev_month := p_month - 1;
        v_prev_month_year := p_year;
    END IF;

    -- Current month revenue & invoices
    SELECT 
        COALESCE(SUM(sl.amount), 0),
        COALESCE(COUNT(DISTINCT d.id), 0)
    INTO v_rev_curr, v_inv_curr
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code 
      AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month
      AND sl.amount > 0;

    IF v_inv_curr > 0 THEN
        v_avg_curr := ROUND((v_rev_curr / v_inv_curr::numeric), 2);
    END IF;

    -- Previous month revenue & invoices
    SELECT 
        COALESCE(SUM(sl.amount), 0),
        COALESCE(COUNT(DISTINCT d.id), 0)
    INTO v_rev_prev_m, v_inv_prev_m
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code 
      AND EXTRACT(YEAR FROM d.invoice_date) = v_prev_month_year 
      AND EXTRACT(MONTH FROM d.invoice_date) = v_prev_month
      AND sl.amount > 0;

    IF v_inv_prev_m > 0 THEN
        v_avg_prev_m := ROUND((v_rev_prev_m / v_inv_prev_m::numeric), 2);
    END IF;

    -- Previous year's same month revenue & invoices
    SELECT 
        COALESCE(SUM(sl.amount), 0),
        COALESCE(COUNT(DISTINCT d.id), 0)
    INTO v_rev_prev_y_m, v_inv_prev_y_m
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code 
      AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) 
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month
      AND sl.amount > 0;

    -- Changes vs previous month
    IF v_rev_prev_m > 0 THEN
        v_growth_prev_m_rev := ROUND(((v_rev_curr - v_rev_prev_m) / v_rev_prev_m * 100)::numeric, 1);
    END IF;

    IF v_inv_prev_m > 0 THEN
        v_growth_prev_m_inv := ROUND(((v_inv_curr - v_inv_prev_m)::numeric / v_inv_prev_m * 100)::numeric, 1);
    END IF;

    IF v_avg_prev_m > 0 THEN
        v_growth_prev_m_avg := ROUND(((v_avg_curr - v_avg_prev_m) / v_avg_prev_m * 100)::numeric, 1);
    END IF;

    v_result := json_build_object(
        'status', 'ok',
        'client_info', json_build_object(
            'code', p_code,
            'name', v_client_name,
            'status_name', v_status_name
        ),
        'month_info', json_build_object(
            'year', p_year,
            'month', p_month,
            'month_name', v_month_name
        ),
        'kpi', json_build_object(
            'rev_month', v_rev_curr,
            'inv_month', v_inv_curr,
            'avg_check_month', v_avg_curr,
            'growth_to_prev_month_pct', v_growth_prev_m_rev
        ),
        'prev_month_comparison', json_build_object(
            'rev_curr', v_rev_curr,
            'rev_prev_month', v_rev_prev_m,
            'rev_change_pct', v_growth_prev_m_rev,
            'inv_curr', v_inv_curr,
            'inv_prev_month', v_inv_prev_m,
            'inv_change_pct', v_growth_prev_m_inv,
            'avg_curr', v_avg_curr,
            'avg_prev_month', v_avg_prev_m,
            'avg_change_pct', v_growth_prev_m_avg
        ),
        'prev_year_comparison', json_build_object(
            'rev_prev_year_month', v_rev_prev_y_m,
            'inv_prev_year_month', v_inv_prev_y_m
        )
    );

    RETURN v_result;
END;
$function$
```

---

### `get_client_products_compare`(p_code text)
**Returns:** `TABLE(product_code character varying, product_name character varying, revenue_curr numeric, revenue_prev numeric, qty_curr numeric, qty_prev numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_client_products_compare(p_code text)
 RETURNS TABLE(product_code character varying, product_name character varying, revenue_curr numeric, revenue_prev numeric, qty_curr numeric, qty_prev numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.code AS product_code,
        p.name AS product_name,
        COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = 2026 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS revenue_curr,
        COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = 2025 THEN sl.amount ELSE 0 END), 0)::NUMERIC AS revenue_prev,
        COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = 2026 THEN sl.quantity ELSE 0 END), 0)::NUMERIC AS qty_curr,
        COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = 2025 THEN sl.quantity ELSE 0 END), 0)::NUMERIC AS qty_prev
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    JOIN products p ON sl.product_code = p.code
    WHERE d.client_code = p_code
      AND EXTRACT(YEAR FROM d.invoice_date) IN (2025, 2026)
      AND COALESCE(p.is_service, FALSE) = FALSE
    GROUP BY p.code, p.name
    ORDER BY revenue_curr DESC;
END;
$function$
```

---

### `get_client_revenue_deep_analytics`(p_code character varying, p_year integer DEFAULT 2026)
**Returns:** `json`

```sql
CREATE OR REPLACE FUNCTION public.get_client_revenue_deep_analytics(p_code character varying, p_year integer DEFAULT 2026)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_client_name VARCHAR;
    v_status_name VARCHAR := '—';
    v_total_company_rev NUMERIC := 0;
    v_client_rev_curr NUMERIC := 0;
    v_client_rev_prev_total NUMERIC := 0;
    v_client_rev_prev_period NUMERIC := 0;
    v_abc_group VARCHAR := 'C2';
    v_share_pct NUMERIC := 0;
    v_growth_yoy NUMERIC := NULL;
    v_avg_monthly NUMERIC := 0;
    v_max_month INTEGER := 12;
    v_monthly_data JSON;
    v_result JSON;
BEGIN
    -- Client basic info
    SELECT c.name, COALESCE(sr.status_name, '—')
    INTO v_client_name, v_status_name
    FROM clients c
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE c.code = p_code;

    IF v_client_name IS NULL THEN
        RETURN json_build_object('status', 'error', 'message', 'Client not found');
    END IF;

    -- Max month for p_year
    SELECT COALESCE(MAX(EXTRACT(MONTH FROM d.invoice_date))::int, 12)
    INTO v_max_month
    FROM documents d
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year;

    -- Total company revenue (goods only, active clients)
    SELECT COALESCE(SUM(sl.amount), 0) INTO v_total_company_rev
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    JOIN client_year_activity cya ON cya.client_code = d.client_code AND cya.sales_year = p_year AND cya.is_active = TRUE
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND sl.amount > 0
      AND d.client_code NOT IN ('9653', '11230');

    -- Client revenue curr year
    SELECT COALESCE(SUM(sl.amount), 0) INTO v_client_rev_curr
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code
      AND EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND sl.amount > 0;

    -- Client revenue prev year TOTAL (12 months)
    SELECT COALESCE(SUM(sl.amount), 0) INTO v_client_rev_prev_total
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code
      AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
      AND sl.amount > 0;

    -- Client revenue prev year SAME PERIOD (months <= v_max_month)
    SELECT COALESCE(SUM(sl.amount), 0) INTO v_client_rev_prev_period
    FROM sales_lines sl
    JOIN documents d ON sl.document_id = d.id
    JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
    WHERE d.client_code = p_code
      AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
      AND EXTRACT(MONTH FROM d.invoice_date) <= v_max_month
      AND sl.amount > 0;

    -- ABC group
    v_abc_group := get_abc_group_for_revenue(v_client_rev_curr);

    -- Share % of total company revenue
    IF v_total_company_rev > 0 THEN
        v_share_pct := ROUND((v_client_rev_curr / v_total_company_rev * 100)::numeric, 2);
    END IF;

    -- YoY Growth % (Ratio to previous year total)
    IF v_client_rev_prev_total > 0 THEN
        v_growth_yoy := ROUND((v_client_rev_curr / v_client_rev_prev_total * 100)::numeric, 1);
    END IF;

    -- Average Monthly Revenue
    v_avg_monthly := ROUND((v_client_rev_curr / 12.0)::numeric, 2);

    -- Monthly breakdown & cumulative calculation
    WITH months AS (
        SELECT generate_series(1, 12) AS m
    ),
    curr_m AS (
        SELECT 
            EXTRACT(MONTH FROM d.invoice_date)::int AS m,
            SUM(sl.amount) AS rev
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = p_year AND sl.amount > 0
        GROUP BY 1
    ),
    prev_m AS (
        SELECT 
            EXTRACT(MONTH FROM d.invoice_date)::int AS m,
            SUM(sl.amount) AS rev
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE
        WHERE d.client_code = p_code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) AND sl.amount > 0
        GROUP BY 1
    ),
    combined AS (
        SELECT 
            m.m AS month,
            CASE m.m
                WHEN 1 THEN 'Январь' WHEN 2 THEN 'Февраль' WHEN 3 THEN 'Март'
                WHEN 4 THEN 'Апрель' WHEN 5 THEN 'Май' WHEN 6 THEN 'Июнь'
                WHEN 7 THEN 'Июль' WHEN 8 THEN 'Август' WHEN 9 THEN 'Сентябрь'
                WHEN 10 THEN 'Октябрь' WHEN 11 THEN 'Ноябрь' WHEN 12 THEN 'Декабрь'
            END AS month_name,
            COALESCE(c.rev, 0.0) AS rev_curr,
            COALESCE(p.rev, 0.0) AS rev_prev
        FROM months m
        LEFT JOIN curr_m c ON m.m = c.m
        LEFT JOIN prev_m p ON m.m = p.m
        ORDER BY m.m
    ),
    cumulated AS (
        SELECT 
            month,
            month_name,
            rev_curr,
            rev_prev,
            CASE 
                WHEN rev_prev > 0 THEN ROUND((rev_curr / rev_prev * 100)::numeric, 1)
                ELSE NULL
            END AS growth_pct,
            ROUND(SUM(rev_curr) OVER (ORDER BY month)::numeric, 2) AS cum_curr,
            ROUND(SUM(rev_prev) OVER (ORDER BY month)::numeric, 2) AS cum_prev
        FROM combined
    )
    SELECT json_agg(
        json_build_object(
            'month', month,
            'month_name', month_name,
            'rev_curr', rev_curr,
            'rev_prev', rev_prev,
            'growth_pct', growth_pct,
            'cum_curr', cum_curr,
            'cum_prev', cum_prev
        )
    ) INTO v_monthly_data FROM cumulated;

    v_result := json_build_object(
        'status', 'ok',
        'client_info', json_build_object(
            'code', p_code,
            'name', v_client_name,
            'status_name', v_status_name,
            'abc_group', v_abc_group,
            'total_company_rev', v_total_company_rev,
            'client_share_pct', v_share_pct
        ),
        'kpi', json_build_object(
            'rev_curr', v_client_rev_curr,
            'rev_prev', v_client_rev_prev_total,
            'rev_prev_period', v_client_rev_prev_period,
            'growth_yoy_pct', v_growth_yoy,
            'avg_monthly_rev', v_avg_monthly
        ),
        'monthly', COALESCE(v_monthly_data, '[]'::json)
    );

    RETURN v_result;
END;
$function$
```

---

### `get_client_similar_fallback`(p_client_code character varying)
**Returns:** `TABLE(product_code character varying, product_name character varying, diameter numeric, wall_thickness numeric, reason text, in_stock numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_client_similar_fallback(p_client_code character varying)
 RETURNS TABLE(product_code character varying, product_name character varying, diameter numeric, wall_thickness numeric, reason text, in_stock numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.code::VARCHAR,
        p.name::VARCHAR,
        p.diameter::NUMERIC,
        p.wall_thickness::NUMERIC,
        'Аналогичный популярный типоразмер'::TEXT,
        COALESCE(p.in_stock_balance, 0)::NUMERIC
    FROM products p
    WHERE COALESCE(p.in_stock_balance, 0) > 0 
      AND COALESCE(p.is_service, FALSE) = FALSE
      AND p.code NOT IN (
          SELECT DISTINCT sl2.product_code FROM sales_lines sl2 
          JOIN documents d2 ON sl2.document_id = d2.id WHERE d2.client_code = p_client_code
      )
    ORDER BY COALESCE(p.in_stock_balance, 0) DESC
    LIMIT 10;
END;
$function$
```

---

### `get_client_similar_sizes`(p_client_code character varying)
**Returns:** `TABLE(product_code character varying, product_name character varying, diameter numeric, wall_thickness numeric, reason text, in_stock numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_client_similar_sizes(p_client_code character varying)
 RETURNS TABLE(product_code character varying, product_name character varying, diameter numeric, wall_thickness numeric, reason text, in_stock numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH client_top_sizes AS (
        SELECT p.diameter, p.wall_thickness, p.standard_name, COUNT(DISTINCT d.id) AS purchase_count
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON sl.product_code = p.code
        WHERE d.client_code = p_client_code AND p.diameter IS NOT NULL AND p.diameter > 0
        GROUP BY p.diameter, p.wall_thickness, p.standard_name
        ORDER BY purchase_count DESC
        LIMIT 10
    ),
    similar_products AS (
        SELECT DISTINCT 
            p.code, p.name, p.diameter, p.wall_thickness, 
            COALESCE(p.in_stock_balance, 0) AS in_stock,
            ABS(p.diameter - cts.diameter) AS diam_diff,
            ABS(p.wall_thickness - cts.wall_thickness) AS wall_diff
        FROM products p
        CROSS JOIN client_top_sizes cts
        WHERE p.diameter BETWEEN cts.diameter * 0.85 AND cts.diameter * 1.15
          AND p.wall_thickness BETWEEN cts.wall_thickness * 0.8 AND cts.wall_thickness * 1.2
          AND COALESCE(p.in_stock_balance, 0) > 0
          AND COALESCE(p.is_service, FALSE) = FALSE
          AND p.code NOT IN (
              SELECT DISTINCT sl2.product_code FROM sales_lines sl2
              JOIN documents d2 ON sl2.document_id = d2.id WHERE d2.client_code = p_client_code
          )
    )
    SELECT 
        sp.code::VARCHAR,
        sp.name::VARCHAR,
        sp.diameter::NUMERIC,
        sp.wall_thickness::NUMERIC,
        'Ближайший типоразмер'::TEXT,
        sp.in_stock::NUMERIC
    FROM similar_products sp
    ORDER BY (sp.diam_diff + sp.wall_diff) ASC
    LIMIT 25;
END;
$function$
```

---

### `get_client_status_2025`(p_code text, p_year_prev integer DEFAULT 2025)
**Returns:** `TABLE(status_2025 text)`

```sql
CREATE OR REPLACE FUNCTION public.get_client_status_2025(p_code text, p_year_prev integer DEFAULT 2025)
 RETURNS TABLE(status_2025 text)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT CASE 
        WHEN cya.total_docs = 0 THEN 'Спящие'
        WHEN cya.total_docs = 1 THEN 'Разовые'
        WHEN cya.total_docs BETWEEN 2 AND 3 THEN 'Повторные'
        WHEN cya.total_docs BETWEEN 4 AND 10 THEN 'Ежеквартальные'
        WHEN cya.total_docs BETWEEN 11 AND 40 THEN 'Ежемесячные'
        WHEN cya.total_docs BETWEEN 41 AND 170 THEN 'Еженедельные'
        WHEN cya.total_docs > 170 THEN 'Ежедневные'
        ELSE '—'
    END::TEXT AS status_2025
    FROM client_year_activity cya
    WHERE cya.client_code = p_code AND cya.sales_year = p_year_prev;
END;
$function$
```

---

### `get_clients_list`(p_limit integer DEFAULT 50, p_search text DEFAULT ''::text)
**Returns:** `TABLE(code character varying, name character varying, status character varying, last_purchase_date date)`

```sql
CREATE OR REPLACE FUNCTION public.get_clients_list(p_limit integer DEFAULT 50, p_search text DEFAULT ''::text)
 RETURNS TABLE(code character varying, name character varying, status character varying, last_purchase_date date)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT c.code, c.name, sr.status_name as status, c.last_purchase_date
    FROM clients c 
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    WHERE (p_search IS NULL OR p_search = '' OR c.name ILIKE '%' || p_search || '%' OR c.code ILIKE '%' || p_search || '%')
    ORDER BY c.last_purchase_date DESC NULLS LAST 
    LIMIT p_limit;
END;
$function$
```

---

### `get_clients_yoy`(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9)
**Returns:** `TABLE(client_code character varying, client_name character varying, revenue_curr numeric, revenue_prev numeric, invoices_curr bigint, invoices_prev bigint, abc_curr text, abc_prev text)`

```sql
CREATE OR REPLACE FUNCTION public.get_clients_yoy(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9)
 RETURNS TABLE(client_code character varying, client_name character varying, revenue_curr numeric, revenue_prev numeric, invoices_curr bigint, invoices_prev bigint, abc_curr text, abc_prev text)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_year_prev INT := p_year - 1;
BEGIN
    RETURN QUERY
    WITH max_month AS (
        SELECT COALESCE(MAX(EXTRACT(MONTH FROM invoice_date)), 12) AS max_m
        FROM documents WHERE EXTRACT(YEAR FROM invoice_date) = p_year
    ),
    curr AS (
        SELECT
            d.client_code,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS revenue,
            COUNT(DISTINCT d.id)::BIGINT AS invoice_count
        FROM documents d
        JOIN sales_lines sl ON d.id = sl.document_id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN client_year_activity cya ON d.client_code = cya.client_code AND cya.sales_year = p_year AND cya.is_active = TRUE
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY d.client_code
    ),
    prev AS (
        SELECT
            d.client_code,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS revenue,
            COUNT(DISTINCT d.id)::BIGINT AS invoice_count
        FROM documents d
        JOIN sales_lines sl ON d.id = sl.document_id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN client_year_activity cya ON d.client_code = cya.client_code AND cya.sales_year = v_year_prev AND cya.is_active = TRUE
        CROSS JOIN max_month m
        WHERE EXTRACT(YEAR FROM d.invoice_date) = v_year_prev
          AND EXTRACT(MONTH FROM d.invoice_date) <= m.max_m
        GROUP BY d.client_code
    ),
    abc_curr AS (
        SELECT c.client_code, c.revenue,
            (CASE
                WHEN c.revenue >= 3000000 * p_multiplier THEN 'A1'
                WHEN c.revenue >= 2000000 * p_multiplier THEN 'A2'
                WHEN c.revenue >= 1500000 * p_multiplier THEN 'A3'
                WHEN c.revenue >= 1000000 * p_multiplier THEN 'B1'
                WHEN c.revenue >= 500000  * p_multiplier THEN 'B2'
                WHEN c.revenue >= 150000  * p_multiplier THEN 'C1'
                WHEN c.revenue >= 1000                    THEN 'C2'
                ELSE 'Ниже C2'
            END)::TEXT AS abc_group,
            c.invoice_count
        FROM curr c
    ),
    abc_prev AS (
        SELECT p.client_code, p.revenue,
            (CASE
                WHEN p.revenue >= 3000000 * p_multiplier THEN 'A1'
                WHEN p.revenue >= 2000000 * p_multiplier THEN 'A2'
                WHEN p.revenue >= 1500000 * p_multiplier THEN 'A3'
                WHEN p.revenue >= 1000000 * p_multiplier THEN 'B1'
                WHEN p.revenue >= 500000  * p_multiplier THEN 'B2'
                WHEN p.revenue >= 150000  * p_multiplier THEN 'C1'
                WHEN p.revenue >= 1000                    THEN 'C2'
                ELSE 'Ниже C2'
            END)::TEXT AS abc_group,
            p.invoice_count
        FROM prev p
    )
    SELECT
        COALESCE(ac.client_code, ap.client_code) AS client_code,
        cl.name AS client_name,
        COALESCE(ac.revenue, 0)::NUMERIC AS revenue_curr,
        COALESCE(ap.revenue, 0)::NUMERIC AS revenue_prev,
        COALESCE(ac.invoice_count, 0)::BIGINT AS invoices_curr,
        COALESCE(ap.invoice_count, 0)::BIGINT AS invoices_prev,
        COALESCE(ac.abc_group, 'Новый')::TEXT AS abc_curr,
        COALESCE(ap.abc_group, 'Новый')::TEXT AS abc_prev
    FROM abc_curr ac
    FULL OUTER JOIN abc_prev ap ON ac.client_code = ap.client_code
    JOIN clients cl ON cl.code = COALESCE(ac.client_code, ap.client_code)
    ORDER BY COALESCE(ac.revenue, 0) DESC;
END;
$function$
```

---

### `get_consolidated_segmentation_companies`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, days_between integer, consolidated_group character varying, consolidated_key character varying, detailed_segment character varying, abc_group character varying, industry character varying, status_name character varying, current_status_id integer)`

```sql
CREATE OR REPLACE FUNCTION public.get_consolidated_segmentation_companies(p_year integer DEFAULT 2026)
 RETURNS TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, days_between integer, consolidated_group character varying, consolidated_key character varying, detailed_segment character varying, abc_group character varying, industry character varying, status_name character varying, current_status_id integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
        SELECT c.code, c.name, c.current_status_id, COALESCE(sr.status_name, 'Не визначено') AS status_name,
               c.activity_direction_id, COALESCE(ad.name, 'Не вказано') AS industry
        FROM clients c
        JOIN client_year_activity cya ON c.code = cya.client_code 
            AND cya.sales_year = p_year AND cya.is_active = TRUE
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
        WHERE c.code NOT IN ('9653', '11230')
    ),
    client_stats AS (
        SELECT 
            ac.code, ac.name, ac.current_status_id, ac.status_name, ac.industry,
            COUNT(DISTINCT d.id) AS inv_count,
            MIN(d.invoice_date) AS first_date,
            MAX(d.invoice_date) AS last_date,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
            COALESCE(SUM(CASE WHEN pr.is_service = TRUE THEN sl.amount ELSE 0 END), 0) AS services_revenue
        FROM active_clients ac
        JOIN documents d ON d.client_code = ac.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY ac.code, ac.name, ac.current_status_id, ac.status_name, ac.industry
    )
    SELECT 
        cs.code::VARCHAR,
        cs.name::VARCHAR,
        cs.inv_count::BIGINT AS inv_count,
        cs.inv_count::BIGINT AS invoices_count,
        ROUND(cs.goods_revenue, 2)::NUMERIC AS goods_revenue,
        ROUND(cs.services_revenue, 2)::NUMERIC AS services_revenue,
        ROUND(cs.goods_revenue / NULLIF(cs.inv_count, 0), 2)::NUMERIC AS avg_ticket,
        COALESCE(cs.last_date - cs.first_date, 0)::INT AS days_between,
        -- Консолідована група
        CASE 
            WHEN cs.inv_count = 1 THEN 'Разові консолідовані'
            WHEN cs.inv_count = 2 AND (cs.last_date - cs.first_date) <= 7 THEN 'Разові консолідовані'
            WHEN cs.inv_count = 2 AND (cs.last_date - cs.first_date) > 7 THEN 'Повторні'
            ELSE 'Постійні (4+)'
        END::VARCHAR AS consolidated_group,
        CASE 
            WHEN cs.inv_count = 1 THEN 'SINGLE_CONS'
            WHEN cs.inv_count = 2 AND (cs.last_date - cs.first_date) <= 7 THEN 'SINGLE_CONS'
            WHEN cs.inv_count = 2 AND (cs.last_date - cs.first_date) > 7 THEN 'REPEAT_CORE'
            ELSE 'LOYAL'
        END::VARCHAR AS consolidated_key,
        -- Детальний сегмент
        CASE 
            WHEN cs.inv_count = 1 THEN 'Разові (1 накладна)'
            WHEN cs.inv_count = 2 AND (cs.last_date - cs.first_date) <= 7 THEN 'Швидкий дубль (2 в ≤7 днів)'
            WHEN cs.inv_count = 2 THEN 'Центр (2 покупки)'
            WHEN cs.inv_count = 3 THEN '3 покупки (кандидати)'
            WHEN cs.inv_count BETWEEN 4 AND 10 THEN 'Квартальні (4-10)'
            WHEN cs.inv_count BETWEEN 11 AND 40 THEN 'Місячні (11-40)'
            WHEN cs.inv_count BETWEEN 41 AND 170 THEN 'Неділя (41-170)'
            ELSE 'Денні (>170)'
        END::VARCHAR AS detailed_segment,
        -- ABC
        CASE 
            WHEN cs.goods_revenue >= 8700000 THEN 'A1'
            WHEN cs.goods_revenue >= 5800000 THEN 'A2'
            WHEN cs.goods_revenue >= 4350000 THEN 'A3'
            WHEN cs.goods_revenue >= 2900000 THEN 'B1'
            WHEN cs.goods_revenue >= 1450000 THEN 'B2'
            WHEN cs.goods_revenue >= 435000 THEN 'C1'
            ELSE 'C2'
        END::VARCHAR AS abc_group,
        cs.industry::VARCHAR,
        cs.status_name::VARCHAR,
        cs.current_status_id::INT
    FROM client_stats cs
    ORDER BY cs.goods_revenue DESC;
END;
$function$
```

---

### `get_daily_revenue`(p_year integer, p_month integer)
**Returns:** `TABLE(day integer, active_clients bigint, invoice_count bigint, goods_revenue numeric, total_revenue numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_daily_revenue(p_year integer, p_month integer)
 RETURNS TABLE(day integer, active_clients bigint, invoice_count bigint, goods_revenue numeric, total_revenue numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        EXTRACT(DAY FROM d.invoice_date)::INTEGER AS day,
        COUNT(DISTINCT d.client_code)::BIGINT AS active_clients,
        COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
        COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue,
        COALESCE(SUM(sl.amount), 0)::NUMERIC AS total_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month
    GROUP BY day
    ORDER BY day;
END;
$function$
```

---

### `get_excluded_client_info`(p_year integer, p_month integer, p_exclude_client text)
**Returns:** `TABLE(client_code character varying, client_name character varying, invoice_count bigint, goods_revenue numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_excluded_client_info(p_year integer, p_month integer, p_exclude_client text)
 RETURNS TABLE(client_code character varying, client_name character varying, invoice_count bigint, goods_revenue numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        d.client_code,
        c.name AS client_name,
        COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
        COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    JOIN clients c ON c.code = d.client_code
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month
      AND d.client_code = p_exclude_client
    GROUP BY d.client_code, c.name;
END;
$function$
```

---

### `get_funnel_data`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(stage text, sort_order integer, count bigint, revenue numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_funnel_data(p_year integer DEFAULT 2026)
 RETURNS TABLE(stage text, sort_order integer, count bigint, revenue numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH client_invoices AS (
        SELECT 
            c.code,
            COUNT(DISTINCT d.id) AS invoice_count,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS total_revenue
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
        GROUP BY c.code
    ),
    classified AS (
        SELECT 
            (CASE 
                WHEN invoice_count = 1 THEN 'Разовые (1)'
                WHEN invoice_count BETWEEN 2 AND 3 THEN 'Повторные (2-3)'
                WHEN invoice_count BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
                WHEN invoice_count BETWEEN 11 AND 40 THEN 'Месяц (11-40)'
                WHEN invoice_count BETWEEN 41 AND 170 THEN 'Неделя (41-170)'
                ELSE 'День (>170)'
            END)::TEXT AS stage,
            CASE 
                WHEN invoice_count = 1 THEN 1
                WHEN invoice_count BETWEEN 2 AND 3 THEN 2
                WHEN invoice_count BETWEEN 4 AND 10 THEN 3
                WHEN invoice_count BETWEEN 11 AND 40 THEN 4
                WHEN invoice_count BETWEEN 41 AND 170 THEN 5
                ELSE 6
            END AS sort_order,
            total_revenue
        FROM client_invoices
    )
    SELECT 
        c.stage,
        c.sort_order,
        COUNT(*)::BIGINT AS count,
        ROUND(SUM(c.total_revenue)::numeric, 2) AS revenue
    FROM classified c
    GROUP BY c.stage, c.sort_order
    ORDER BY c.sort_order;
END;
$function$
```

---

### `get_general_segmentation_companies`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, abc_group character varying, cohort character varying, detailed_segment character varying, industry character varying, status_name character varying, current_status_id integer)`

```sql
CREATE OR REPLACE FUNCTION public.get_general_segmentation_companies(p_year integer DEFAULT 2026)
 RETURNS TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, abc_group character varying, cohort character varying, detailed_segment character varying, industry character varying, status_name character varying, current_status_id integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
        SELECT c.code, c.name, c.current_status_id, COALESCE(sr.status_name, 'Не визначено') AS status_name,
               c.activity_direction_id, COALESCE(ad.name, 'Не вказано') AS industry
        FROM clients c
        JOIN client_year_activity cya ON c.code = cya.client_code 
            AND cya.sales_year = p_year AND cya.is_active = TRUE
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
        WHERE c.code NOT IN ('9653', '11230')
    ),
    client_stats AS (
        SELECT 
            ac.code, ac.name, ac.current_status_id, ac.status_name, ac.activity_direction_id, ac.industry,
            COUNT(DISTINCT d.id) AS inv_count,
            (MAX(d.invoice_date) - MIN(d.invoice_date)) AS date_span,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
            COALESCE(SUM(CASE WHEN pr.is_service = TRUE THEN sl.amount ELSE 0 END), 0) AS services_revenue
        FROM active_clients ac
        JOIN documents d ON d.client_code = ac.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY ac.code, ac.name, ac.current_status_id, ac.status_name, ac.activity_direction_id, ac.industry
    )
    SELECT 
        cs.code::VARCHAR,
        cs.name::VARCHAR,
        cs.inv_count::BIGINT AS inv_count,
        cs.inv_count::BIGINT AS invoices_count,
        ROUND(cs.goods_revenue, 2)::NUMERIC AS goods_revenue,
        ROUND(cs.services_revenue, 2)::NUMERIC AS services_revenue,
        ROUND(cs.goods_revenue / NULLIF(cs.inv_count, 0), 2)::NUMERIC AS avg_ticket,
        CASE 
            WHEN cs.goods_revenue >= 8700000 THEN 'A1'
            WHEN cs.goods_revenue >= 5800000 THEN 'A2'
            WHEN cs.goods_revenue >= 4350000 THEN 'A3'
            WHEN cs.goods_revenue >= 2900000 THEN 'B1'
            WHEN cs.goods_revenue >= 1450000 THEN 'B2'
            WHEN cs.goods_revenue >= 435000 THEN 'C1'
            ELSE 'C2'
        END::VARCHAR AS abc_group,
        CASE 
            WHEN cs.inv_count = 1 THEN 'SINGLE'
            WHEN cs.inv_count BETWEEN 2 AND 3 THEN 'REPEAT'
            WHEN cs.inv_count BETWEEN 4 AND 10 THEN 'QUARTERLY'
            WHEN cs.inv_count BETWEEN 11 AND 40 THEN 'MONTHLY'
            WHEN cs.inv_count BETWEEN 41 AND 170 THEN 'WEEKLY'
            ELSE 'DAILY'
        END::VARCHAR AS cohort,
        CASE
            WHEN cs.inv_count = 1 THEN 'Разовий (1)'
            WHEN cs.inv_count = 2 AND cs.date_span <= 7 THEN 'Швидкий дубль (2)'
            WHEN cs.inv_count = 2 AND (cs.date_span > 7 OR cs.date_span IS NULL) THEN 'Центр: 2 покупки'
            WHEN cs.inv_count = 3 THEN '3 покупки (кандидат)'
            WHEN cs.inv_count BETWEEN 4 AND 10 THEN 'Квартальний (4-10)'
            WHEN cs.inv_count BETWEEN 11 AND 40 THEN 'Місячний (11-40)'
            WHEN cs.inv_count BETWEEN 41 AND 170 THEN 'Тижневий (41-170)'
            ELSE 'Щоденний (>170)'
        END::VARCHAR AS detailed_segment,
        cs.industry::VARCHAR,
        cs.status_name::VARCHAR,
        cs.current_status_id::INT
    FROM client_stats cs
    ORDER BY cs.goods_revenue DESC;
END;
$function$
```

---

### `get_important_detail`(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000)
**Returns:** `TABLE(client_code character varying, client_name character varying, invoices_count bigint, goods_revenue numeric, category text, grand_total numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_important_detail(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(client_code character varying, client_name character varying, invoices_count bigint, goods_revenue numeric, category text, grand_total numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
        SELECT DISTINCT cya.client_code
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year
          AND cya.is_active = TRUE
          AND cya.client_code != '9653'
    ),
    stats AS (
        SELECT 
            d.client_code,
            c.name AS client_name,
            COUNT(DISTINCT d.id)::BIGINT AS invoices_count,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN active_clients ac ON d.client_code = ac.client_code
        JOIN clients c ON d.client_code = c.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY d.client_code, c.name
    ),
    all_sales AS (
        SELECT COALESCE(SUM(s.goods_revenue), 1)::NUMERIC AS grand_total FROM stats s
    )
    SELECT 
        s.client_code,
        s.client_name,
        s.invoices_count,
        s.goods_revenue,
        (CASE 
            WHEN s.goods_revenue >= p_limit_price THEN 'ABC' 
            ELSE 'C2 (4+ накладных)' 
        END)::TEXT AS category,
        a.grand_total
    FROM stats s, all_sales a
    WHERE s.goods_revenue >= p_limit_price OR s.invoices_count >= 4
    ORDER BY s.goods_revenue DESC;
END;
$function$
```

---

### `get_inactive_clients_abc`(p_status_id integer DEFAULT 8, p_year_prev integer DEFAULT 2025)
**Returns:** `TABLE(abc_group text, count bigint, revenue numeric, pct numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_inactive_clients_abc(p_status_id integer DEFAULT 8, p_year_prev integer DEFAULT 2025)
 RETURNS TABLE(abc_group text, count bigint, revenue numeric, pct numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH inactive AS (
        SELECT c.code FROM clients c WHERE c.current_status_id = p_status_id AND c.code NOT IN ('9653', '11230')
    ),
    client_rev AS (
        SELECT 
            ic.code,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS rev
        FROM inactive ic
        JOIN documents d ON d.client_code = ic.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year_prev
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY ic.code
    ),
    ranked AS (
        SELECT cr.*,
            SUM(cr.rev) OVER (ORDER BY cr.rev DESC) AS cum_rev,
            SUM(cr.rev) OVER () AS total_rev
        FROM client_rev cr WHERE cr.rev > 0
    )
    SELECT 
        (CASE 
            WHEN rk.cum_rev <= rk.total_rev * 0.80 OR (rk.cum_rev - rk.rev) < rk.total_rev * 0.80 THEN 'A'
            WHEN rk.cum_rev <= rk.total_rev * 0.95 OR (rk.cum_rev - rk.rev) < rk.total_rev * 0.95 THEN 'B'
            ELSE 'C'
        END)::TEXT AS abc_group,
        COUNT(*)::BIGINT AS count,
        COALESCE(SUM(rk.rev), 0)::NUMERIC AS revenue,
        ROUND(COALESCE(SUM(rk.rev), 0) * 100.0 / NULLIF(MAX(rk.total_rev), 0), 1)::NUMERIC AS pct
    FROM ranked rk
    GROUP BY abc_group
    ORDER BY abc_group;
END;
$function$
```

---

### `get_inactive_clients_distribution`(p_status_id integer DEFAULT 8)
**Returns:** `TABLE(range_label text, count bigint)`

```sql
CREATE OR REPLACE FUNCTION public.get_inactive_clients_distribution(p_status_id integer DEFAULT 8)
 RETURNS TABLE(range_label text, count bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    IF p_status_id = 8 THEN
        RETURN QUERY
        WITH client_dates AS (
            SELECT 
                c.code,
                MAX(d.invoice_date) AS last_date
            FROM clients c
            LEFT JOIN documents d ON d.client_code = c.code
            WHERE c.current_status_id = 8 AND c.code NOT IN ('9653', '11230')
            GROUP BY c.code
        ),
        days_calc AS (
            SELECT 
                cd.code,
                CASE WHEN cd.last_date IS NOT NULL THEN CURRENT_DATE - cd.last_date ELSE 9999 END AS days_since
            FROM client_dates cd
        ),
        grouped AS (
            SELECT 
                (CASE 
                    WHEN dc.days_since < 90 THEN '< 90 дней'
                    WHEN dc.days_since BETWEEN 90 AND 180 THEN '90-180 дней'
                    WHEN dc.days_since BETWEEN 181 AND 365 THEN '181-365 дней'
                    ELSE '> 365 дней'
                END)::TEXT AS range_label,
                CASE 
                    WHEN dc.days_since < 90 THEN 1
                    WHEN dc.days_since BETWEEN 90 AND 180 THEN 2
                    WHEN dc.days_since BETWEEN 181 AND 365 THEN 3
                    ELSE 4
                END AS sort_order,
                COUNT(*)::BIGINT AS count
            FROM days_calc dc
            GROUP BY range_label, sort_order
        )
        SELECT g.range_label, g.count
        FROM grouped g
        ORDER BY g.sort_order;
    ELSE
        RETURN QUERY
        WITH client_years AS (
            SELECT 
                c.code,
                EXTRACT(YEAR FROM MAX(d.invoice_date)) AS last_yr
            FROM clients c
            LEFT JOIN documents d ON d.client_code = c.code
            WHERE c.current_status_id = 9 AND c.code NOT IN ('9653', '11230')
            GROUP BY c.code
        )
        SELECT 
            COALESCE(cy.last_yr::text, 'Нет данных')::TEXT AS range_label,
            COUNT(*)::BIGINT AS count
        FROM client_years cy
        GROUP BY range_label
        ORDER BY range_label DESC;
    END IF;
END;
$function$
```

---

### `get_inactive_clients_list`(p_status_id integer DEFAULT 8, p_year_prev integer DEFAULT 2025, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text, p_days_min integer DEFAULT NULL::integer, p_days_max integer DEFAULT NULL::integer, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
**Returns:** `TABLE(code character varying, name character varying, docs_prev bigint, rev_prev numeric, abc_group text, last_date text, days_since integer)`

```sql
CREATE OR REPLACE FUNCTION public.get_inactive_clients_list(p_status_id integer DEFAULT 8, p_year_prev integer DEFAULT 2025, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text, p_days_min integer DEFAULT NULL::integer, p_days_max integer DEFAULT NULL::integer, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
 RETURNS TABLE(code character varying, name character varying, docs_prev bigint, rev_prev numeric, abc_group text, last_date text, days_since integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH inactive_c AS (
        SELECT c.code, c.name FROM clients c WHERE c.current_status_id = p_status_id AND c.code NOT IN ('9653', '11230')
    ),
    client_sales AS (
        SELECT 
            ic.code,
            ic.name,
            COUNT(DISTINCT d.id)::BIGINT AS docs_prev,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS rev_prev,
            MAX(d.invoice_date) AS last_date
        FROM inactive_c ic
        LEFT JOIN documents d ON d.client_code = ic.code AND EXTRACT(YEAR FROM d.invoice_date) <= p_year_prev
        LEFT JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE (p_search IS NULL OR p_search = '' OR ic.name ILIKE '%' || p_search || '%' OR ic.code ILIKE '%' || p_search || '%')
        GROUP BY ic.code, ic.name
    ),
    ranked AS (
        SELECT cs.*,
            SUM(cs.rev_prev) OVER (ORDER BY cs.rev_prev DESC) AS cum_rev,
            SUM(cs.rev_prev) OVER () AS total_rev
        FROM client_sales cs
    ),
    categorized AS (
        SELECT rk.*,
            (CASE 
                WHEN rk.total_rev = 0 THEN 'C'
                WHEN rk.cum_rev <= rk.total_rev * 0.80 OR (rk.cum_rev - rk.rev_prev) < rk.total_rev * 0.80 THEN 'A'
                WHEN rk.cum_rev <= rk.total_rev * 0.95 OR (rk.cum_rev - rk.rev_prev) < rk.total_rev * 0.95 THEN 'B'
                ELSE 'C'
            END)::TEXT AS abc_grp,
            (CASE WHEN rk.last_date IS NOT NULL THEN CURRENT_DATE - rk.last_date ELSE 9999 END)::INT AS days_since
        FROM ranked rk
    )
    SELECT 
        cat.code, cat.name, cat.docs_prev, cat.rev_prev, cat.abc_grp AS abc_group, cat.last_date::text, cat.days_since
    FROM categorized cat
    WHERE (p_abc_group IS NULL OR p_abc_group = '' OR cat.abc_grp = p_abc_group)
      AND (p_days_min IS NULL OR cat.days_since >= p_days_min)
      AND (p_days_max IS NULL OR cat.days_since <= p_days_max)
    ORDER BY cat.rev_prev DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$
```

---

### `get_inactive_clients_overview`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(sleeping_count bigint, churned_count bigint, total_all bigint, pct_inactive numeric, sleeping_rev_2025 numeric, churned_rev_2024 numeric, high_risk_count bigint)`

```sql
CREATE OR REPLACE FUNCTION public.get_inactive_clients_overview(p_year integer DEFAULT 2026)
 RETURNS TABLE(sleeping_count bigint, churned_count bigint, total_all bigint, pct_inactive numeric, sleeping_rev_2025 numeric, churned_rev_2024 numeric, high_risk_count bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH inactive AS (
        SELECT code, current_status_id FROM clients WHERE current_status_id IN (8, 9) AND code NOT IN ('9653', '11230')
    ),
    all_clients AS (
        SELECT COUNT(*)::BIGINT AS total_all FROM clients WHERE code NOT IN ('9653', '11230')
    ),
    sleeping_stats AS (
        SELECT 
            COUNT(DISTINCT ic.code)::BIGINT AS sleeping_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS sleeping_rev_2025,
            COUNT(DISTINCT CASE WHEN rev_sub.rev > 500000 THEN ic.code END)::BIGINT AS high_risk_count
        FROM inactive ic
        LEFT JOIN documents d ON d.client_code = ic.code AND EXTRACT(YEAR FROM d.invoice_date) = 2025
        LEFT JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        LEFT JOIN (
            SELECT d2.client_code, SUM(CASE WHEN pr2.is_service = FALSE THEN sl2.amount ELSE 0 END) AS rev
            FROM documents d2
            JOIN sales_lines sl2 ON sl2.document_id = d2.id
            LEFT JOIN products pr2 ON sl2.product_code = pr2.code
            WHERE EXTRACT(YEAR FROM d2.invoice_date) = 2025
            GROUP BY d2.client_code
        ) rev_sub ON rev_sub.client_code = ic.code
        WHERE ic.current_status_id = 8
    ),
    churned_stats AS (
        SELECT 
            COUNT(DISTINCT ic.code)::BIGINT AS churned_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS churned_rev_2024
        FROM inactive ic
        LEFT JOIN documents d ON d.client_code = ic.code AND EXTRACT(YEAR FROM d.invoice_date) = 2024
        LEFT JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE ic.current_status_id = 9
    )
    SELECT 
        s.sleeping_count,
        c.churned_count,
        a.total_all,
        ROUND((s.sleeping_count + c.churned_count) * 100.0 / NULLIF(a.total_all, 0), 1)::NUMERIC AS pct_inactive,
        s.sleeping_rev_2025,
        c.churned_rev_2024,
        s.high_risk_count
    FROM sleeping_stats s, churned_stats c, all_clients a;
END;
$function$
```

---

### `get_invoice_header`(p_number character varying)
**Returns:** `TABLE(date text, number character varying, total numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_invoice_header(p_number character varying)
 RETURNS TABLE(date text, number character varying, total numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        TO_CHAR(d.invoice_date, 'DD.MM.YYYY')::TEXT,
        d.doc_number::VARCHAR,
        COALESCE(ROUND(SUM(sl.amount)::numeric, 0), 0)::NUMERIC
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    WHERE d.doc_number = p_number
    GROUP BY d.id, d.invoice_date, d.doc_number;
END;
$function$
```

---

### `get_invoice_items`(p_number text)
**Returns:** `TABLE(code character varying, name character varying, quantity numeric, total numeric, weight_kg numeric, price numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_invoice_items(p_number text)
 RETURNS TABLE(code character varying, name character varying, quantity numeric, total numeric, weight_kg numeric, price numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        sl.product_code AS code,
        COALESCE(pr.name, sl.product_code) AS name,
        COALESCE(sl.quantity, 0)::NUMERIC AS quantity,
        COALESCE(sl.amount, 0)::NUMERIC AS total,
        (COALESCE(pr.weight_per_meter, 0) * COALESCE(sl.quantity, 0))::NUMERIC AS weight_kg,
        (CASE WHEN COALESCE(sl.quantity, 0) > 0 THEN sl.amount / sl.quantity ELSE 0 END)::NUMERIC AS price
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.doc_number = p_number
    ORDER BY sl.id;
END;
$function$
```

---

### `get_monthly_detail_metrics`(p_year integer, p_month integer)
**Returns:** `TABLE(active_clients bigint, invoice_count bigint, goods_revenue numeric, services_revenue numeric, total_revenue numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_monthly_detail_metrics(p_year integer, p_month integer)
 RETURNS TABLE(active_clients bigint, invoice_count bigint, goods_revenue numeric, services_revenue numeric, total_revenue numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(DISTINCT d.client_code)::BIGINT AS active_clients,
        COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
        COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue,
        COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = TRUE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS services_revenue,
        COALESCE(SUM(sl.amount), 0)::NUMERIC AS total_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month;
END;
$function$
```

---

### `get_monthly_directions`(p_year integer, p_month integer)
**Returns:** `TABLE(direction_name text, companies_count bigint, invoice_count bigint, goods_revenue numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_monthly_directions(p_year integer, p_month integer)
 RETURNS TABLE(direction_name text, companies_count bigint, invoice_count bigint, goods_revenue numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        COALESCE(ad.name, 'Не указано')::TEXT AS direction_name,
        COUNT(DISTINCT d.client_code)::BIGINT AS companies_count,
        COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
        COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    JOIN clients c ON d.client_code = c.code AND c.is_active_current = TRUE
    LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month
    GROUP BY ad.name
    ORDER BY goods_revenue DESC
    LIMIT 10;
END;
$function$
```

---

### `get_monthly_products`(p_year integer, p_month integer, p_limit integer DEFAULT 10)
**Returns:** `TABLE(product_code character varying, product_name character varying, invoice_count bigint, total_sales numeric, total_quantity numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_monthly_products(p_year integer, p_month integer, p_limit integer DEFAULT 10)
 RETURNS TABLE(product_code character varying, product_name character varying, invoice_count bigint, total_sales numeric, total_quantity numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.code AS product_code,
        p.name AS product_name,
        COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
        COALESCE(SUM(sl.amount), 0)::NUMERIC AS total_sales,
        COALESCE(SUM(sl.quantity), 0)::NUMERIC AS total_quantity
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    JOIN products p ON sl.product_code = p.code
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND EXTRACT(MONTH FROM d.invoice_date) = p_month
      AND COALESCE(p.is_service, FALSE) = FALSE
    GROUP BY p.code, p.name
    ORDER BY total_sales DESC
    LIMIT p_limit;
END;
$function$
```

---

### `get_monthly_revenue`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(year integer, month integer, month_name text, active_clients bigint, invoice_count bigint, goods_revenue numeric, services_revenue numeric, total_revenue numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_monthly_revenue(p_year integer DEFAULT 2026)
 RETURNS TABLE(year integer, month integer, month_name text, active_clients bigint, invoice_count bigint, goods_revenue numeric, services_revenue numeric, total_revenue numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        EXTRACT(YEAR FROM d.invoice_date)::INTEGER AS year,
        EXTRACT(MONTH FROM d.invoice_date)::INTEGER AS month,
        TO_CHAR(TO_DATE(EXTRACT(MONTH FROM d.invoice_date)::TEXT, 'MM'), 'Mon')::TEXT AS month_name,
        COUNT(DISTINCT d.client_code)::BIGINT AS active_clients,
        COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
        COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue,
        COALESCE(SUM(CASE WHEN pr.is_service = TRUE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS services_revenue,
        COALESCE(SUM(sl.amount), 0)::NUMERIC AS total_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    JOIN client_year_activity cya ON d.client_code = cya.client_code AND cya.sales_year = p_year AND cya.is_active = TRUE
    JOIN clients c ON d.client_code = c.code
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
    GROUP BY EXTRACT(YEAR FROM d.invoice_date), EXTRACT(MONTH FROM d.invoice_date)
    ORDER BY month;
END;
$function$
```

---

### `get_monthly_top_clients`(p_year integer, p_month integer, p_year_prev integer DEFAULT 2025, p_mult numeric DEFAULT 2.9, p_limit integer DEFAULT 10)
**Returns:** `TABLE(client_name character varying, group_prev text, invoice_count bigint, goods_revenue numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_monthly_top_clients(p_year integer, p_month integer, p_year_prev integer DEFAULT 2025, p_mult numeric DEFAULT 2.9, p_limit integer DEFAULT 10)
 RETURNS TABLE(client_name character varying, group_prev text, invoice_count bigint, goods_revenue numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH month_data AS (
        SELECT 
            d.client_code,
            COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND EXTRACT(MONTH FROM d.invoice_date) = p_month
        GROUP BY d.client_code
    ),
    abc_prev AS (
        SELECT 
            d.client_code,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue_prev
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year_prev
        GROUP BY d.client_code
    ),
    abc_grouped AS (
        SELECT 
            ap.client_code,
            CASE
                WHEN ap.goods_revenue_prev >= 3000000 * p_mult THEN 'A1'
                WHEN ap.goods_revenue_prev >= 2000000 * p_mult THEN 'A2'
                WHEN ap.goods_revenue_prev >= 1500000 * p_mult THEN 'A3'
                WHEN ap.goods_revenue_prev >= 1000000 * p_mult THEN 'B1'
                WHEN ap.goods_revenue_prev >= 500000  * p_mult THEN 'B2'
                WHEN ap.goods_revenue_prev >= 150000  * p_mult THEN 'C1'
                WHEN ap.goods_revenue_prev >= 1000    * p_mult THEN 'C2'
                ELSE 'Новый'
            END::TEXT AS abc_group_prev
        FROM abc_prev ap
    )
    SELECT 
        c.name AS client_name,
        COALESCE(ag.abc_group_prev, 'Новый')::TEXT AS group_prev,
        md.invoice_count,
        md.goods_revenue
    FROM month_data md
    JOIN clients c ON c.code = md.client_code
    LEFT JOIN abc_grouped ag ON ag.client_code = md.client_code
    WHERE c.is_active_current = TRUE
    ORDER BY md.goods_revenue DESC
    LIMIT p_limit;
END;
$function$
```

---

### `get_new_clients_abc`(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9)
**Returns:** `TABLE(abc_group text, count bigint, revenue numeric, pct numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_new_clients_abc(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9)
 RETURNS TABLE(abc_group text, count bigint, revenue numeric, pct numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH new_clients AS (
        SELECT code FROM clients WHERE current_status_id = 1 AND is_active_current = TRUE AND code NOT IN ('9653', '11230')
    ),
    new_revenue AS (
        SELECT nc.code, COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
        FROM new_clients nc
        JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY nc.code
    ),
    ranked AS (
        SELECT *, SUM(goods_revenue) OVER (ORDER BY goods_revenue DESC) AS cum_revenue,
            SUM(goods_revenue) OVER () AS total_revenue
        FROM new_revenue WHERE goods_revenue > 0
    )
    SELECT 
        (CASE 
            WHEN cum_revenue <= total_revenue * 0.80 OR (cum_revenue - goods_revenue) < total_revenue * 0.80 THEN 'A'
            WHEN cum_revenue <= total_revenue * 0.95 OR (cum_revenue - goods_revenue) < total_revenue * 0.95 THEN 'B'
            ELSE 'C'
        END)::TEXT AS abc_group,
        COUNT(*)::BIGINT AS count,
        COALESCE(SUM(goods_revenue), 0)::NUMERIC AS revenue,
        ROUND(COALESCE(SUM(goods_revenue), 0) * 100.0 / NULLIF(MAX(total_revenue), 0), 1)::NUMERIC AS pct
    FROM ranked
    GROUP BY abc_group
    ORDER BY abc_group;
END;
$function$
```

---

### `get_new_clients_abc_compare`(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9)
**Returns:** `TABLE(abc_group text, new_count bigint, new_revenue numeric, new_pct numeric, all_count bigint, all_revenue numeric, all_pct numeric, count_share_pct numeric, revenue_share_pct numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_new_clients_abc_compare(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9)
 RETURNS TABLE(abc_group text, new_count bigint, new_revenue numeric, new_pct numeric, all_count bigint, all_revenue numeric, all_pct numeric, count_share_pct numeric, revenue_share_pct numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH new_clients AS (
        SELECT code FROM clients WHERE current_status_id = 1 AND is_active_current = TRUE AND code NOT IN ('9653', '11230')
    ),
    new_revenue AS (
        SELECT nc.code, COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
        FROM new_clients nc
        JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY nc.code
    ),
    ranked AS (
        SELECT *, SUM(goods_revenue) OVER (ORDER BY goods_revenue DESC) AS cum_revenue,
            SUM(goods_revenue) OVER () AS total_revenue
        FROM new_revenue WHERE goods_revenue > 0
    ),
    new_abc AS (
        SELECT 
            CASE 
                WHEN cum_revenue <= total_revenue * 0.80 OR (cum_revenue - goods_revenue) < total_revenue * 0.80 THEN 'A'
                WHEN cum_revenue <= total_revenue * 0.95 OR (cum_revenue - goods_revenue) < total_revenue * 0.95 THEN 'B'
                ELSE 'C'
            END AS grp,
            COUNT(*)::BIGINT AS count,
            COALESCE(SUM(goods_revenue), 0)::NUMERIC AS revenue,
            ROUND(COALESCE(SUM(goods_revenue), 0) * 100.0 / NULLIF(MAX(total_revenue), 0), 1)::NUMERIC AS pct
        FROM ranked
        GROUP BY grp
    ),
    all_abc AS (
        SELECT 
            LEFT(out_group_name, 1) AS grp,
            SUM(out_total_companies)::BIGINT AS all_count,
            SUM(out_total_sales)::NUMERIC AS all_revenue
        FROM get_abc_groups(p_year, p_multiplier)
        WHERE out_group_name != 'Total'
        GROUP BY LEFT(out_group_name, 1)
    ),
    total_all AS (
        SELECT COALESCE(SUM(a.all_revenue), 0) AS total_all_rev FROM all_abc a
    ),
    all_abc_pct AS (
        SELECT 
            a.grp,
            a.all_count,
            a.all_revenue,
            ROUND(a.all_revenue * 100.0 / NULLIF(t.total_all_rev, 0), 1)::NUMERIC AS all_pct
        FROM all_abc a, total_all t
    ),
    groups_list AS (
        SELECT 'A' AS grp UNION ALL SELECT 'B' UNION ALL SELECT 'C'
    )
    SELECT 
        gl.grp::TEXT AS abc_group,
        COALESCE(n.count, 0)::BIGINT AS new_count,
        COALESCE(n.revenue, 0)::NUMERIC AS new_revenue,
        COALESCE(n.pct, 0)::NUMERIC AS new_pct,
        COALESCE(a.all_count, 0)::BIGINT AS all_count,
        COALESCE(a.all_revenue, 0)::NUMERIC AS all_revenue,
        COALESCE(a.all_pct, 0)::NUMERIC AS all_pct,
        ROUND(COALESCE(n.count, 0) * 100.0 / NULLIF(a.all_count, 0), 1)::NUMERIC AS count_share_pct,
        ROUND(COALESCE(n.revenue, 0) * 100.0 / NULLIF(a.all_revenue, 0), 1)::NUMERIC AS revenue_share_pct
    FROM groups_list gl
    LEFT JOIN new_abc n ON n.grp = gl.grp
    LEFT JOIN all_abc_pct a ON a.grp = gl.grp
    ORDER BY gl.grp;
END;
$function$
```

---

### `get_new_clients_frequency`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(frequency_group text, sort_order integer, new_count bigint, new_revenue numeric, avg_ticket numeric, new_pct numeric, all_count bigint, share_pct numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_new_clients_frequency(p_year integer DEFAULT 2026)
 RETURNS TABLE(frequency_group text, sort_order integer, new_count bigint, new_revenue numeric, avg_ticket numeric, new_pct numeric, all_count bigint, share_pct numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH new_clients AS (
        SELECT code FROM clients WHERE current_status_id = 1 AND is_active_current = TRUE AND code NOT IN ('9653', '11230')
    ),
    new_frequency AS (
        SELECT nc.code, COUNT(DISTINCT d.id) AS invoice_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
        FROM new_clients nc
        JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY nc.code
    ),
    all_frequency AS (
        SELECT c.code, COUNT(DISTINCT d.id) AS invoice_count
        FROM clients c
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN client_year_activity cya ON c.code = cya.client_code AND cya.sales_year = p_year AND cya.is_active = TRUE
        WHERE c.is_active_current = TRUE AND c.code NOT IN ('9653', '11230')
        GROUP BY c.code
    ),
    nf_grouped AS (
        SELECT 
            (CASE 
                WHEN invoice_count = 1 THEN 'Разовые (1)'
                WHEN invoice_count BETWEEN 2 AND 3 THEN 'Повторные (2-3)'
                WHEN invoice_count BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
                WHEN invoice_count BETWEEN 11 AND 40 THEN 'Месяц (11-40)'
                WHEN invoice_count BETWEEN 41 AND 170 THEN 'Неделя (41-170)'
                ELSE 'День (>170)'
            END)::TEXT AS frequency_group,
            CASE 
                WHEN invoice_count = 1 THEN 1 
                WHEN invoice_count <= 3 THEN 2 
                WHEN invoice_count <= 10 THEN 3 
                WHEN invoice_count <= 40 THEN 4 
                WHEN invoice_count <= 170 THEN 5 
                ELSE 6 
            END AS sort_order,
            COUNT(code)::BIGINT AS new_count,
            SUM(goods_revenue)::NUMERIC AS new_revenue
        FROM new_frequency
        GROUP BY frequency_group, sort_order
    ),
    af_grouped AS (
        SELECT 
            (CASE 
                WHEN invoice_count = 1 THEN 'Разовые (1)'
                WHEN invoice_count BETWEEN 2 AND 3 THEN 'Повторные (2-3)'
                WHEN invoice_count BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
                WHEN invoice_count BETWEEN 11 AND 40 THEN 'Месяц (11-40)'
                WHEN invoice_count BETWEEN 41 AND 170 THEN 'Неделя (41-170)'
                ELSE 'День (>170)'
            END)::TEXT AS frequency_group,
            COUNT(code)::BIGINT AS all_count
        FROM all_frequency
        GROUP BY frequency_group
    )
    SELECT 
        ng.frequency_group,
        ng.sort_order,
        ng.new_count,
        ng.new_revenue,
        ROUND(ng.new_revenue / NULLIF(ng.new_count, 0), 0)::NUMERIC AS avg_ticket,
        ROUND(ng.new_count * 100.0 / NULLIF(SUM(ng.new_count) OVER(), 0), 1)::NUMERIC AS new_pct,
        COALESCE(ag.all_count, 0)::BIGINT AS all_count,
        ROUND(ng.new_count * 100.0 / NULLIF(ag.all_count, 0), 1)::NUMERIC AS share_pct
    FROM nf_grouped ng
    LEFT JOIN af_grouped ag ON ag.frequency_group = ng.frequency_group
    ORDER BY ng.sort_order;
END;
$function$
```

---

### `get_new_clients_list`(p_year integer DEFAULT 2026, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
**Returns:** `TABLE(code character varying, name character varying, docs bigint, revenue numeric, first_date text, last_date text, abc_group text)`

```sql
CREATE OR REPLACE FUNCTION public.get_new_clients_list(p_year integer DEFAULT 2026, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
 RETURNS TABLE(code character varying, name character varying, docs bigint, revenue numeric, first_date text, last_date text, abc_group text)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH new_clients AS (
        SELECT c.code FROM clients c WHERE c.current_status_id = 1 AND c.is_active_current = TRUE AND c.code NOT IN ('9653', '11230')
    ),
    client_rev AS (
        SELECT 
            c.code, c.name, COUNT(DISTINCT d.id)::BIGINT AS docs,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS revenue,
            MIN(d.invoice_date)::TEXT AS first_date, MAX(d.invoice_date)::TEXT AS last_date
        FROM new_clients nc
        JOIN clients c ON c.code = nc.code
        JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE (p_search IS NULL OR p_search = '' OR c.name ILIKE '%' || p_search || '%' OR c.code ILIKE '%' || p_search || '%')
        GROUP BY c.code, c.name
    ),
    ranked AS (
        SELECT *,
            SUM(r.revenue) OVER (ORDER BY r.revenue DESC) AS cum_revenue,
            SUM(r.revenue) OVER () AS total_revenue
        FROM client_rev r
    ),
    categorized AS (
        SELECT *,
            (CASE 
                WHEN rk.total_revenue = 0 THEN 'C'
                WHEN rk.cum_revenue <= rk.total_revenue * 0.80 OR (rk.cum_revenue - rk.revenue) < rk.total_revenue * 0.80 THEN 'A'
                WHEN rk.cum_revenue <= rk.total_revenue * 0.95 OR (rk.cum_revenue - rk.revenue) < rk.total_revenue * 0.95 THEN 'B'
                ELSE 'C'
            END)::TEXT AS abc_grp
        FROM ranked rk
    )
    SELECT cat.code, cat.name, cat.docs, cat.revenue, cat.first_date, cat.last_date, cat.abc_grp AS abc_group
    FROM categorized cat
    WHERE (p_abc_group IS NULL OR p_abc_group = '' OR cat.abc_grp = p_abc_group)
    ORDER BY cat.revenue DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$
```

---

### `get_new_clients_monthly_revenue`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(month_num integer, revenue numeric, invoices_count bigint, active_clients bigint)`

```sql
CREATE OR REPLACE FUNCTION public.get_new_clients_monthly_revenue(p_year integer DEFAULT 2026)
 RETURNS TABLE(month_num integer, revenue numeric, invoices_count bigint, active_clients bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH new_clients AS (
        SELECT c.code
        FROM clients c
        JOIN client_year_activity cya ON c.code = cya.client_code 
            AND cya.sales_year = p_year AND cya.is_active = TRUE
        WHERE c.current_status_id = 1
          AND c.code NOT IN ('9653', '11230')
    )
    SELECT 
        EXTRACT(MONTH FROM d.invoice_date)::INT AS month_num,
        ROUND(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0), 2)::NUMERIC AS revenue,
        COUNT(DISTINCT d.id)::BIGINT AS invoices_count,
        COUNT(DISTINCT nc.code)::BIGINT AS active_clients
    FROM new_clients nc
    JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    GROUP BY EXTRACT(MONTH FROM d.invoice_date)
    ORDER BY month_num;
END;
$function$
```

---

### `get_new_clients_overview`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(total_new bigint, total_revenue numeric, avg_revenue_per_client numeric, avg_ticket numeric, pct_of_total_revenue numeric, new_in_top80 bigint, avg_invoices numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_new_clients_overview(p_year integer DEFAULT 2026)
 RETURNS TABLE(total_new bigint, total_revenue numeric, avg_revenue_per_client numeric, avg_ticket numeric, pct_of_total_revenue numeric, new_in_top80 bigint, avg_invoices numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH new_clients AS (
        SELECT code FROM clients 
        WHERE current_status_id = 1 AND is_active_current = TRUE AND code NOT IN ('9653', '11230')
    ),
    new_stats AS (
        SELECT 
            COUNT(DISTINCT nc.code)::BIGINT AS total_new,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS total_revenue,
            COUNT(DISTINCT d.id)::BIGINT AS total_invoices
        FROM new_clients nc
        JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
    ),
    total_stats AS (
        SELECT COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS all_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN clients c ON d.client_code = c.code
        WHERE c.is_active_current = TRUE AND c.code NOT IN ('9653', '11230')
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    ),
    new_in_top80 AS (
        SELECT COUNT(*)::BIGINT AS top_count
        FROM (
            SELECT nc.code, COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS rev,
                SUM(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)) OVER (ORDER BY COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) DESC) 
                / NULLIF(SUM(COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)) OVER (), 0) * 100 AS running_pct
            FROM new_clients nc
            JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
            JOIN sales_lines sl ON sl.document_id = d.id
            LEFT JOIN products pr ON sl.product_code = pr.code
            GROUP BY nc.code
        ) sub WHERE running_pct <= 80
    )
    SELECT 
        s.total_new,
        s.total_revenue,
        ROUND(s.total_revenue / NULLIF(s.total_new, 0), 0)::NUMERIC AS avg_revenue_per_client,
        ROUND(s.total_revenue / NULLIF(s.total_invoices, 0), 0)::NUMERIC AS avg_ticket,
        ROUND(s.total_revenue / NULLIF(ts.all_revenue, 0) * 100, 1)::NUMERIC AS pct_of_total_revenue,
        COALESCE(t80.top_count, 0)::BIGINT AS new_in_top80,
        ROUND(s.total_invoices::NUMERIC / NULLIF(s.total_new, 0), 1)::NUMERIC AS avg_invoices
    FROM new_stats s, total_stats ts, new_in_top80 t80;
END;
$function$
```

---

### `get_new_clients_segmentation`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, first_purchase date, last_purchase date, abc_group character varying, industry character varying, status_name character varying, current_status_id integer, cohort character varying)`

```sql
CREATE OR REPLACE FUNCTION public.get_new_clients_segmentation(p_year integer DEFAULT 2026)
 RETURNS TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, first_purchase date, last_purchase date, abc_group character varying, industry character varying, status_name character varying, current_status_id integer, cohort character varying)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH new_clients AS (
        SELECT c.code, c.name, c.activity_direction_id, ad.name AS industry,
               c.current_status_id, COALESCE(sr.status_name, 'Новий') AS status_name
        FROM clients c
        JOIN client_year_activity cya ON c.code = cya.client_code 
            AND cya.sales_year = p_year AND cya.is_active = TRUE
        LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        WHERE c.current_status_id = 1
          AND c.code NOT IN ('9653', '11230')
    ),
    client_stats AS (
        SELECT 
            nc.code, nc.name, nc.industry, nc.status_name, nc.current_status_id,
            COUNT(DISTINCT d.id) AS inv_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
            COALESCE(SUM(CASE WHEN pr.is_service = TRUE THEN sl.amount ELSE 0 END), 0) AS services_revenue,
            MIN(d.invoice_date) AS first_purchase,
            MAX(d.invoice_date) AS last_purchase
        FROM new_clients nc
        JOIN documents d ON d.client_code = nc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY nc.code, nc.name, nc.industry, nc.status_name, nc.current_status_id
    )
    SELECT 
        cs.code::VARCHAR,
        cs.name::VARCHAR,
        cs.inv_count::BIGINT AS inv_count,
        cs.inv_count::BIGINT AS invoices_count,
        ROUND(cs.goods_revenue, 2)::NUMERIC AS goods_revenue,
        ROUND(cs.services_revenue, 2)::NUMERIC AS services_revenue,
        ROUND(cs.goods_revenue / NULLIF(cs.inv_count, 0), 2)::NUMERIC AS avg_ticket,
        cs.first_purchase::DATE AS first_purchase,
        cs.last_purchase::DATE AS last_purchase,
        CASE 
            WHEN cs.goods_revenue >= 8700000 THEN 'A1'
            WHEN cs.goods_revenue >= 5800000 THEN 'A2'
            WHEN cs.goods_revenue >= 4350000 THEN 'A3'
            WHEN cs.goods_revenue >= 2900000 THEN 'B1'
            WHEN cs.goods_revenue >= 1450000 THEN 'B2'
            WHEN cs.goods_revenue >= 435000 THEN 'C1'
            ELSE 'C2'
        END::VARCHAR AS abc_group,
        COALESCE(cs.industry, 'Не вказано')::VARCHAR AS industry,
        cs.status_name::VARCHAR,
        cs.current_status_id::INT,
        CASE 
            WHEN cs.inv_count = 1 THEN 'Разові (1)'
            WHEN cs.inv_count BETWEEN 2 AND 3 THEN 'Повторні (2-3)'
            WHEN cs.inv_count BETWEEN 4 AND 10 THEN 'Квартальні (4-10)'
            WHEN cs.inv_count BETWEEN 11 AND 40 THEN 'Місячні (11-40)'
            WHEN cs.inv_count BETWEEN 41 AND 170 THEN 'Тижневі (41-170)'
            ELSE 'Щоденні (>170)'
        END::VARCHAR AS cohort
    FROM client_stats cs
    ORDER BY cs.goods_revenue DESC;
END;
$function$
```

---

### `get_product_categories`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(id integer, name character varying, icon character varying, color character varying, revenue numeric, ton numeric, price_per_ton numeric, lines_count bigint)`

```sql
CREATE OR REPLACE FUNCTION public.get_product_categories(p_year integer DEFAULT 2026)
 RETURNS TABLE(id integer, name character varying, icon character varying, color character varying, revenue numeric, ton numeric, price_per_ton numeric, lines_count bigint)
 LANGUAGE sql
 STABLE
AS $function$
    WITH cat_def AS (
        SELECT 1 AS id, 'Труба квадратная'::varchar AS name, '⬛'::varchar AS icon, '#3b82f6'::varchar AS color
        UNION ALL SELECT 2, 'Труба прямоугольная', '▬', '#8b5cf6'
        UNION ALL SELECT 3, 'Труба бесшовная горячедеформированная', '🔥', '#f59e0b'
        UNION ALL SELECT 4, 'Труба бесшовная холоднодеформированная', '❄️', '#06b6d4'
        UNION ALL SELECT 5, 'Труба электросварная', '⚡', '#10b981'
        UNION ALL SELECT 6, 'Листовой прокат', '📄', '#ef4444'
        UNION ALL SELECT 7, 'Услуги', '🛠️', '#64748b'
        UNION ALL SELECT 8, 'Прочее', '❓', '#94a3b8'
    ),
    raw_sales AS (
        SELECT
            CASE 
                -- 1. ТРУБА КВАДРАТНАЯ (равные стороны)
                WHEN p.name ~ '(\d+)\s*[хx]\s*\1' AND p.name ILIKE '%проф%' THEN 'Труба квадратная'
                
                -- 2. ТРУБА ПРЯМОУГОЛЬНАЯ (разные стороны)
                WHEN p.name ILIKE '%проф%' AND p.name !~ '(\d+)\s*[хx]\s*\1' THEN 'Труба прямоугольная'
                
                -- 3. ТРУБА БЕСШОВНАЯ ГОРЯЧЕДЕФОРМИРОВАННАЯ
                WHEN p.name ILIKE '%8732%' 
                     OR p.name ILIKE '%горячедеформ%' 
                     OR p.name ILIKE '%г/д%' THEN 'Труба бесшовная горячедеформированная'
                
                -- 4. ТРУБА БЕСШОВНАЯ ХОЛОДНОДЕФОРМИРОВАННАЯ
                WHEN p.name ILIKE '%8734%' 
                     OR p.name ILIKE '%8939%' 
                     OR p.name ILIKE '%холоднодеформ%' 
                     OR p.name ILIKE '%холоднотянут%' 
                     OR p.name ILIKE '%х/д%' THEN 'Труба бесшовная холоднодеформированная'
                
                -- 5. ТРУБА ЭЛЕКТРОСВАРНАЯ
                WHEN p.name ILIKE '%електрозвар%' 
                     OR p.name ILIKE '%электросвар%' 
                     OR p.name ILIKE '%10704%' 
                     OR p.name ILIKE '%10705%' 
                     OR p.name ILIKE '%8938%' THEN 'Труба электросварная'
                
                -- 6. ЛИСТОВОЙ ПРОКАТ
                WHEN p.name ILIKE '%лист%' 
                     OR p.name ILIKE '%19903%' THEN 'Листовой прокат'
                
                -- 7. УСЛУГИ
                WHEN p.is_service = TRUE 
                     OR p.name ILIKE '%поріз%' 
                     OR p.name ILIKE '%порез%' 
                     OR p.name ILIKE '%послуг%' 
                     OR p.name ILIKE '%дкпп%' THEN 'Услуги'
                
                ELSE 'Прочее'
            END AS category_name,
            sl.amount,
            sl.quantity * COALESCE(
                p.weight_per_meter,
                CASE 
                    WHEN p.profile_width > 0 AND p.profile_height > 0 AND p.wall_thickness > 0 
                    THEN 2 * (p.profile_width + p.profile_height) * p.wall_thickness * 0.00785 
                    ELSE 0.0 
                END
            ) / 1000.0 AS weight_ton
        FROM sales_lines sl
        JOIN documents d ON sl.document_id = d.id
        JOIN products p ON sl.product_code = p.code
        WHERE d.client_code NOT IN ('9653', '11230')
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND sl.amount > 0
    ),
    agg_sales AS (
        SELECT 
            raw_sales.category_name,
            COUNT(*)::bigint AS lines_cnt,
            SUM(raw_sales.amount) AS rev,
            SUM(raw_sales.weight_ton) AS t
        FROM raw_sales
        GROUP BY raw_sales.category_name
    )
    SELECT
        cd.id,
        cd.name,
        cd.icon,
        cd.color,
        COALESCE(ROUND(ags.rev::numeric, 2), 0.00)::numeric AS revenue,
        COALESCE(ROUND(ags.t::numeric, 2), 0.00)::numeric AS ton,
        CASE 
            WHEN COALESCE(ags.t, 0) > 0 THEN ROUND((ags.rev / ags.t)::numeric, 2)
            ELSE 0.00
        END::numeric AS price_per_ton,
        COALESCE(ags.lines_cnt, 0)::bigint AS lines_count
    FROM cat_def cd
    LEFT JOIN agg_sales ags ON cd.name = ags.category_name
    ORDER BY cd.id;
$function$
```

---

### `get_products_list`(p_limit integer DEFAULT 50, p_search text DEFAULT ''::text)
**Returns:** `TABLE(code character varying, name character varying, in_stock_balance numeric, direction character varying)`

```sql
CREATE OR REPLACE FUNCTION public.get_products_list(p_limit integer DEFAULT 50, p_search text DEFAULT ''::text)
 RETURNS TABLE(code character varying, name character varying, in_stock_balance numeric, direction character varying)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p.code, p.name, p.in_stock_balance, ad.name as direction
    FROM products p 
    LEFT JOIN activity_directions ad ON p.anchor_direction_id = ad.id
    WHERE (p_search IS NULL OR p_search = '' OR p.name ILIKE '%' || p_search || '%' OR p.code ILIKE '%' || p_search || '%')
    ORDER BY p.code 
    LIMIT p_limit;
END;
$function$
```

---

### `get_recurrent_clients`(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9)
**Returns:** `TABLE(client_code character varying, name character varying, ipn character varying, okpo_code character varying, invoice_count bigint, goods_revenue numeric, first_date date, last_date date, days_between integer, abc_group text)`

```sql
CREATE OR REPLACE FUNCTION public.get_recurrent_clients(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9)
 RETURNS TABLE(client_code character varying, name character varying, ipn character varying, okpo_code character varying, invoice_count bigint, goods_revenue numeric, first_date date, last_date date, days_between integer, abc_group text)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH client_invoices AS (
        SELECT
            d.client_code,
            c.name,
            c.ipn,
            c.okpo_code,
            COUNT(DISTINCT d.id)::BIGINT AS invoice_count,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue,
            MIN(d.invoice_date) AS first_date,
            MAX(d.invoice_date) AS last_date,
            (MAX(d.invoice_date) - MIN(d.invoice_date))::INT AS days_between
        FROM documents d
        JOIN sales_lines sl ON d.id = sl.document_id
        JOIN client_year_activity cya ON d.client_code = cya.client_code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN clients c ON d.client_code = c.code
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY d.client_code, c.name, c.ipn, c.okpo_code
        HAVING COUNT(DISTINCT d.id) BETWEEN 2 AND 3
    )
    SELECT
        ci.client_code,
        ci.name,
        ci.ipn,
        ci.okpo_code,
        ci.invoice_count,
        ci.goods_revenue,
        ci.first_date,
        ci.last_date,
        ci.days_between,
        (CASE
            WHEN ci.goods_revenue >= 3000000 * p_multiplier THEN 'A1'
            WHEN ci.goods_revenue >= 2000000 * p_multiplier THEN 'A2'
            WHEN ci.goods_revenue >= 1500000 * p_multiplier THEN 'A3'
            WHEN ci.goods_revenue >= 1000000 * p_multiplier THEN 'B1'
            WHEN ci.goods_revenue >= 500000  * p_multiplier THEN 'B2'
            WHEN ci.goods_revenue >= 150000  * p_multiplier THEN 'C1'
            WHEN ci.goods_revenue >= 1000    * p_multiplier THEN 'C2'
            ELSE 'Ниже C2'
        END)::TEXT AS abc_group
    FROM client_invoices ci
    ORDER BY ci.goods_revenue DESC;
END;
$function$
```

---

### `get_repeat_segmentation_companies`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, days_between integer, subgroup character varying, abc_group character varying, industry character varying, status_name character varying, current_status_id integer)`

```sql
CREATE OR REPLACE FUNCTION public.get_repeat_segmentation_companies(p_year integer DEFAULT 2026)
 RETURNS TABLE(code character varying, name character varying, inv_count bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, days_between integer, subgroup character varying, abc_group character varying, industry character varying, status_name character varying, current_status_id integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
        SELECT c.code, c.name, c.current_status_id, COALESCE(sr.status_name, 'Не визначено') AS status_name,
               c.activity_direction_id, COALESCE(ad.name, 'Не вказано') AS industry
        FROM clients c
        JOIN client_year_activity cya ON c.code = cya.client_code 
            AND cya.sales_year = p_year AND cya.is_active = TRUE
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
        WHERE c.code NOT IN ('9653', '11230')
    ),
    client_stats AS (
        SELECT 
            ac.code, ac.name, ac.current_status_id, ac.status_name, ac.industry,
            COUNT(DISTINCT d.id) AS inv_count,
            MIN(d.invoice_date) AS first_date,
            MAX(d.invoice_date) AS last_date,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue,
            COALESCE(SUM(CASE WHEN pr.is_service = TRUE THEN sl.amount ELSE 0 END), 0) AS services_revenue
        FROM active_clients ac
        JOIN documents d ON d.client_code = ac.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY ac.code, ac.name, ac.current_status_id, ac.status_name, ac.industry
        HAVING COUNT(DISTINCT d.id) BETWEEN 2 AND 3
    )
    SELECT 
        cs.code::VARCHAR,
        cs.name::VARCHAR,
        cs.inv_count::BIGINT AS inv_count,
        cs.inv_count::BIGINT AS invoices_count,
        ROUND(cs.goods_revenue, 2)::NUMERIC AS goods_revenue,
        ROUND(cs.services_revenue, 2)::NUMERIC AS services_revenue,
        ROUND(cs.goods_revenue / NULLIF(cs.inv_count, 0), 2)::NUMERIC AS avg_ticket,
        COALESCE(cs.last_date - cs.first_date, 0)::INT AS days_between,
        CASE 
            WHEN cs.inv_count = 2 AND (cs.last_date - cs.first_date) <= 7 THEN 'Швидкий дубль (2)'
            WHEN cs.inv_count = 3 THEN 'Кандидати в постійні (3)'
            ELSE 'Центр (2-3)'
        END::VARCHAR AS subgroup,
        CASE 
            WHEN cs.goods_revenue >= 8700000 THEN 'A1'
            WHEN cs.goods_revenue >= 5800000 THEN 'A2'
            WHEN cs.goods_revenue >= 4350000 THEN 'A3'
            WHEN cs.goods_revenue >= 2900000 THEN 'B1'
            WHEN cs.goods_revenue >= 1450000 THEN 'B2'
            WHEN cs.goods_revenue >= 435000 THEN 'C1'
            ELSE 'C2'
        END::VARCHAR AS abc_group,
        cs.industry::VARCHAR,
        cs.status_name::VARCHAR,
        cs.current_status_id::INT
    FROM client_stats cs
    ORDER BY cs.goods_revenue DESC;
END;
$function$
```

---

### `get_returned_clients_abc`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(abc_group text, count bigint, revenue numeric, pct numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_returned_clients_abc(p_year integer DEFAULT 2026)
 RETURNS TABLE(abc_group text, count bigint, revenue numeric, pct numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH returned_clients AS (
        SELECT code FROM clients WHERE current_status_id = 10 AND is_active_current = TRUE AND code NOT IN ('9653', '11230')
    ),
    returned_revenue AS (
        SELECT rc.code, COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
        FROM returned_clients rc
        JOIN documents d ON d.client_code = rc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY rc.code
    ),
    ranked AS (
        SELECT *, 
            SUM(goods_revenue) OVER (ORDER BY goods_revenue DESC) AS cum_revenue,
            SUM(goods_revenue) OVER () AS total_revenue
        FROM returned_revenue WHERE goods_revenue > 0
    )
    SELECT 
        (CASE 
            WHEN cum_revenue <= total_revenue * 0.80 OR (cum_revenue - goods_revenue) < total_revenue * 0.80 THEN 'A'
            WHEN cum_revenue <= total_revenue * 0.95 OR (cum_revenue - goods_revenue) < total_revenue * 0.95 THEN 'B'
            ELSE 'C'
        END)::TEXT AS abc_group,
        COUNT(*)::BIGINT AS count,
        COALESCE(SUM(goods_revenue), 0)::NUMERIC AS revenue,
        ROUND(COALESCE(SUM(goods_revenue), 0) * 100.0 / NULLIF(MAX(total_revenue), 0), 1)::NUMERIC AS pct
    FROM ranked
    GROUP BY abc_group
    ORDER BY abc_group;
END;
$function$
```

---

### `get_returned_clients_compare_new`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(frequency_group text, sort_order integer, returned_count bigint, returned_revenue numeric, returned_avg_ticket numeric, new_count bigint, new_revenue numeric, new_avg_ticket numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_returned_clients_compare_new(p_year integer DEFAULT 2026)
 RETURNS TABLE(frequency_group text, sort_order integer, returned_count bigint, returned_revenue numeric, returned_avg_ticket numeric, new_count bigint, new_revenue numeric, new_avg_ticket numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH base_stages AS (
        SELECT 'Разовые (1)'::TEXT AS frequency_group, 1 AS sort_order
        UNION ALL SELECT 'Повторные (2-3)', 2
        UNION ALL SELECT 'Квартал (4-10)', 3
        UNION ALL SELECT 'Месяц (11-40)', 4
        UNION ALL SELECT 'Неделя (41-170)', 5
        UNION ALL SELECT 'День (>170)', 6
    ),
    ret AS (
        SELECT * FROM get_returned_clients_frequency(p_year)
    ),
    nw AS (
        SELECT * FROM get_new_clients_frequency(p_year)
    )
    SELECT 
        b.frequency_group,
        b.sort_order,
        COALESCE(r.returned_count, 0)::BIGINT AS returned_count,
        COALESCE(r.returned_revenue, 0)::NUMERIC AS returned_revenue,
        COALESCE(r.avg_ticket, 0)::NUMERIC AS returned_avg_ticket,
        COALESCE(n.new_count, 0)::BIGINT AS new_count,
        COALESCE(n.new_revenue, 0)::NUMERIC AS new_revenue,
        COALESCE(n.avg_ticket, 0)::NUMERIC AS new_avg_ticket
    FROM base_stages b
    LEFT JOIN ret r ON r.frequency_group = b.frequency_group
    LEFT JOIN nw n ON n.frequency_group = b.frequency_group
    WHERE COALESCE(r.returned_count, 0) > 0 OR COALESCE(n.new_count, 0) > 0
    ORDER BY b.sort_order;
END;
$function$
```

---

### `get_returned_clients_frequency`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(frequency_group text, sort_order integer, returned_count bigint, returned_revenue numeric, avg_ticket numeric, returned_pct numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_returned_clients_frequency(p_year integer DEFAULT 2026)
 RETURNS TABLE(frequency_group text, sort_order integer, returned_count bigint, returned_revenue numeric, avg_ticket numeric, returned_pct numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH returned_clients AS (
        SELECT code FROM clients 
        WHERE current_status_id = 10 AND is_active_current = TRUE 
          AND code NOT IN ('9653', '11230')
    ),
    frequency AS (
        SELECT 
            rc.code,
            COUNT(DISTINCT d.id) AS invoice_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0) AS goods_revenue
        FROM returned_clients rc
        JOIN documents d ON d.client_code = rc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        GROUP BY rc.code
    )
    SELECT 
        CASE 
            WHEN invoice_count = 1 THEN 'Разовые (1)'
            WHEN invoice_count BETWEEN 2 AND 3 THEN 'Повторные (2-3)'
            WHEN invoice_count BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
            WHEN invoice_count BETWEEN 11 AND 40 THEN 'Месяц (11-40)'
            WHEN invoice_count BETWEEN 41 AND 170 THEN 'Неделя (41-170)'
            ELSE 'День (>170)'
        END::TEXT AS frequency_group,
        CASE 
            WHEN invoice_count = 1 THEN 1
            WHEN invoice_count <= 3 THEN 2
            WHEN invoice_count <= 10 THEN 3
            WHEN invoice_count <= 40 THEN 4
            WHEN invoice_count <= 170 THEN 5
            ELSE 6
        END AS sort_order,
        COUNT(*)::BIGINT AS returned_count,
        SUM(goods_revenue)::NUMERIC AS returned_revenue,
        ROUND(SUM(goods_revenue) / NULLIF(COUNT(*), 0), 0)::NUMERIC AS avg_ticket,
        ROUND(COUNT(*) * 100.0 / NULLIF(SUM(COUNT(*)) OVER(), 0), 1)::NUMERIC AS returned_pct
    FROM frequency
    GROUP BY frequency_group, sort_order
    ORDER BY sort_order;
END;
$function$
```

---

### `get_returned_clients_list`(p_year integer DEFAULT 2026, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
**Returns:** `TABLE(code character varying, name character varying, docs bigint, revenue numeric, first_date text, last_date text, abc_group text, frequency_group text)`

```sql
CREATE OR REPLACE FUNCTION public.get_returned_clients_list(p_year integer DEFAULT 2026, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
 RETURNS TABLE(code character varying, name character varying, docs bigint, revenue numeric, first_date text, last_date text, abc_group text, frequency_group text)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH returned_clients AS (
        SELECT c.code FROM clients c 
        WHERE c.current_status_id = 10 AND c.is_active_current = TRUE AND c.code NOT IN ('9653', '11230')
    ),
    client_rev AS (
        SELECT 
            c.code, c.name, COUNT(DISTINCT d.id)::BIGINT AS docs,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS revenue,
            MIN(d.invoice_date)::TEXT AS first_date, MAX(d.invoice_date)::TEXT AS last_date
        FROM returned_clients rc
        JOIN clients c ON c.code = rc.code
        JOIN documents d ON d.client_code = rc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE (p_search IS NULL OR p_search = '' OR c.name ILIKE '%' || p_search || '%' OR c.code ILIKE '%' || p_search || '%')
        GROUP BY c.code, c.name
    ),
    ranked AS (
        SELECT *,
            SUM(r.revenue) OVER (ORDER BY r.revenue DESC) AS cum_revenue,
            SUM(r.revenue) OVER () AS total_revenue
        FROM client_rev r
    ),
    categorized AS (
        SELECT *,
            (CASE 
                WHEN rk.total_revenue = 0 THEN 'C'
                WHEN rk.cum_revenue <= rk.total_revenue * 0.80 OR (rk.cum_revenue - rk.revenue) < rk.total_revenue * 0.80 THEN 'A'
                WHEN rk.cum_revenue <= rk.total_revenue * 0.95 OR (rk.cum_revenue - rk.revenue) < rk.total_revenue * 0.95 THEN 'B'
                ELSE 'C'
            END)::TEXT AS abc_grp,
            (CASE 
                WHEN rk.docs = 1 THEN 'Разовые (1)'
                WHEN rk.docs BETWEEN 2 AND 3 THEN 'Повторные (2-3)'
                WHEN rk.docs BETWEEN 4 AND 10 THEN 'Квартал (4-10)'
                WHEN rk.docs BETWEEN 11 AND 40 THEN 'Месяц (11-40)'
                WHEN rk.docs BETWEEN 41 AND 170 THEN 'Неделя (41-170)'
                ELSE 'День (>170)'
            END)::TEXT AS freq_grp
        FROM ranked rk
    )
    SELECT cat.code, cat.name, cat.docs, cat.revenue, cat.first_date, cat.last_date, cat.abc_grp AS abc_group, cat.freq_grp AS frequency_group
    FROM categorized cat
    WHERE (p_abc_group IS NULL OR p_abc_group = '' OR cat.abc_grp = p_abc_group)
    ORDER BY cat.revenue DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$
```

---

### `get_returned_clients_overview`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(total_returned bigint, total_revenue numeric, total_invoices bigint, avg_revenue_per_client numeric, avg_ticket numeric, pct_of_active_clients numeric, avg_break_period text)`

```sql
CREATE OR REPLACE FUNCTION public.get_returned_clients_overview(p_year integer DEFAULT 2026)
 RETURNS TABLE(total_returned bigint, total_revenue numeric, total_invoices bigint, avg_revenue_per_client numeric, avg_ticket numeric, pct_of_active_clients numeric, avg_break_period text)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH returned_clients AS (
        SELECT code FROM clients 
        WHERE current_status_id = 10 AND is_active_current = TRUE 
          AND code NOT IN ('9653', '11230')
    ),
    returned_stats AS (
        SELECT 
            COUNT(DISTINCT rc.code)::BIGINT AS total_ret,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS total_rev,
            COUNT(DISTINCT d.id)::BIGINT AS total_inv
        FROM returned_clients rc
        JOIN documents d ON d.client_code = rc.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
    ),
    total_active AS (
        SELECT COUNT(DISTINCT cya.client_code)::BIGINT as total_act
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year AND cya.is_active = TRUE AND cya.client_code NOT IN ('9653', '11230')
    )
    SELECT 
        rs.total_ret AS total_returned,
        rs.total_rev AS total_revenue,
        rs.total_inv AS total_invoices,
        ROUND(rs.total_rev / NULLIF(rs.total_ret, 0), 0)::NUMERIC AS avg_revenue_per_client,
        ROUND(rs.total_rev / NULLIF(rs.total_inv, 0), 0)::NUMERIC AS avg_ticket,
        ROUND(rs.total_ret * 100.0 / NULLIF(ta.total_act, 0), 1)::NUMERIC AS pct_of_active_clients,
        '1 год'::TEXT AS avg_break_period
    FROM returned_stats rs, total_active ta;
END;
$function$
```

---

### `get_rfm_funnel`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(rfm_group text, companies bigint, invoices bigint, sales numeric, avg_check numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_rfm_funnel(p_year integer DEFAULT 2026)
 RETURNS TABLE(rfm_group text, companies bigint, invoices bigint, sales numeric, avg_check numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH client_invoices AS (
        SELECT 
            c.code,
            COUNT(DISTINCT d.id) AS invoice_count,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0) AS total_revenue
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
        GROUP BY c.code
    ),
    rfm_groups AS (
        SELECT 
            CASE 
                WHEN invoice_count = 1 THEN 'one'
                WHEN invoice_count BETWEEN 2 AND 3 THEN 'repeat'
                WHEN invoice_count BETWEEN 4 AND 10 THEN 'quarter'
                WHEN invoice_count BETWEEN 11 AND 40 THEN 'month'
                WHEN invoice_count BETWEEN 41 AND 170 THEN 'week'
                ELSE 'day'
            END AS rfm_group,
            COUNT(*)::BIGINT AS companies,
            SUM(invoice_count)::BIGINT AS invoices,
            ROUND(SUM(total_revenue)::numeric, 2) AS sales,
            ROUND(AVG(total_revenue / NULLIF(invoice_count, 0))::numeric, 2) AS avg_check
        FROM client_invoices
        GROUP BY rfm_group
    )
    SELECT r.rfm_group::TEXT, r.companies, r.invoices, r.sales, r.avg_check 
    FROM rfm_groups r;
END;
$function$
```

---

### `get_segment_detail`(p_year integer DEFAULT 2026, p_segment character varying DEFAULT 'raz'::character varying, p_table character varying DEFAULT 'general'::character varying, p_limit_price numeric DEFAULT 146000)
**Returns:** `TABLE(code character varying, name character varying, current_status_id integer, status_name character varying, invoices_count bigint, goods_revenue numeric, avg_ticket numeric, m1 numeric, m2 numeric, m3 numeric, m4 numeric, m5 numeric, m6 numeric, m7 numeric, m8 numeric, m9 numeric, m10 numeric, m11 numeric, m12 numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_segment_detail(p_year integer DEFAULT 2026, p_segment character varying DEFAULT 'raz'::character varying, p_table character varying DEFAULT 'general'::character varying, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(code character varying, name character varying, current_status_id integer, status_name character varying, invoices_count bigint, goods_revenue numeric, avg_ticket numeric, m1 numeric, m2 numeric, m3 numeric, m4 numeric, m5 numeric, m6 numeric, m7 numeric, m8 numeric, m9 numeric, m10 numeric, m11 numeric, m12 numeric)
 LANGUAGE plpgsql
 STABLE
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
                WHEN p_segment IN ('churn_cand', 'sleep_cand') THEN cs.inv_count = 3
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
                WHEN p_segment = 'c2_cand' THEN (cs.total_revenue <= p_limit_price AND cs.inv_count = 3)
                WHEN p_segment = 'c2_kvart' THEN (cs.total_revenue <= p_limit_price AND cs.inv_count BETWEEN 4 AND 10)
                WHEN p_segment = 'c2_mes' THEN (cs.total_revenue <= p_limit_price AND cs.inv_count BETWEEN 11 AND 40)
                WHEN p_segment = 'c2_ned' THEN (cs.total_revenue <= p_limit_price AND cs.inv_count BETWEEN 41 AND 170)
                WHEN p_segment = 'c2_den' THEN (cs.total_revenue <= p_limit_price AND cs.inv_count > 170)

                WHEN p_segment = 'new' THEN cs.current_status_id = 1
                WHEN p_segment = 'new_raz' THEN (cs.current_status_id = 1 AND cs.inv_count = 1)
                WHEN p_segment = 'new_povt' THEN (cs.current_status_id = 1 AND cs.inv_count BETWEEN 2 AND 3)
                WHEN p_segment = 'new_cand' THEN (cs.current_status_id = 1 AND cs.inv_count = 3)
                WHEN p_segment = 'new_kvart' THEN (cs.current_status_id = 1 AND cs.inv_count BETWEEN 4 AND 10)
                WHEN p_segment = 'new_mes' THEN (cs.current_status_id = 1 AND cs.inv_count BETWEEN 11 AND 40)
                WHEN p_segment = 'new_ned' THEN (cs.current_status_id = 1 AND cs.inv_count BETWEEN 41 AND 170)
                WHEN p_segment = 'new_den' THEN (cs.current_status_id = 1 AND cs.inv_count > 170)

                ELSE TRUE
            END
        ORDER BY cs.total_revenue DESC;
    END IF;
END;
$function$
```

---

### `get_segment_detail`(p_segment text DEFAULT 'abc'::text, p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000)
**Returns:** `TABLE(client_code character varying, invoices_count bigint, goods_revenue numeric, freq_group text, internal_class text)`

```sql
CREATE OR REPLACE FUNCTION public.get_segment_detail(p_segment text DEFAULT 'abc'::text, p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(client_code character varying, invoices_count bigint, goods_revenue numeric, freq_group text, internal_class text)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH active_clients AS (
        SELECT DISTINCT cya.client_code
        FROM client_year_activity cya
        WHERE cya.sales_year = p_year
          AND cya.is_active = TRUE
          AND cya.client_code != '9653'
    ),
    client_stats AS (
        SELECT 
            d.client_code,
            COUNT(DISTINCT d.id)::BIGINT AS invoices_count,
            COUNT(DISTINCT d.invoice_date)::BIGINT AS distinct_dates,
            COALESCE(SUM(CASE WHEN COALESCE(pr.is_service, FALSE) = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        JOIN active_clients ac ON d.client_code = ac.client_code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY d.client_code
    ),
    filtered_clients AS (
        SELECT 
            cs.client_code,
            cs.invoices_count,
            cs.distinct_dates,
            cs.goods_revenue,
            (CASE
                WHEN cs.invoices_count = 1 THEN '1'
                WHEN cs.invoices_count = 2 AND cs.distinct_dates = 1 THEN '2_1d'
                WHEN cs.invoices_count = 2 AND cs.distinct_dates = 2 THEN '2_diff'
                WHEN cs.invoices_count = 3 THEN '3'
                WHEN cs.invoices_count BETWEEN 4 AND 10 THEN '4_10'
                WHEN cs.invoices_count BETWEEN 11 AND 40 THEN '11_40'
                WHEN cs.invoices_count BETWEEN 41 AND 170 THEN '41_170'
                ELSE '171_plus'
            END)::TEXT AS freq_group
        FROM client_stats cs
        WHERE 
            (LOWER(p_segment) = 'c2' AND cs.goods_revenue < p_limit_price)
            OR
            (LOWER(p_segment) = 'abc' AND cs.goods_revenue >= p_limit_price)
            OR
            (LOWER(p_segment) = 'total')
            OR
            (LOWER(p_segment) = 'important' AND (cs.goods_revenue >= p_limit_price OR cs.invoices_count >= 4))
    ),
    clients_with_cum AS (
        SELECT 
            fc.*,
            SUM(fc.goods_revenue) OVER (ORDER BY fc.goods_revenue DESC, fc.client_code) AS cum_revenue,
            SUM(fc.goods_revenue) OVER () AS total_segment_revenue
        FROM filtered_clients fc
    )
    SELECT 
        cw.client_code,
        cw.invoices_count,
        cw.goods_revenue,
        cw.freq_group,
        (CASE
            WHEN cw.total_segment_revenue IS NULL OR cw.total_segment_revenue = 0 THEN 'C'
            WHEN cw.cum_revenue <= cw.total_segment_revenue * 0.80 OR (cw.cum_revenue - cw.goods_revenue) < cw.total_segment_revenue * 0.80 THEN 'A'
            WHEN cw.cum_revenue <= cw.total_segment_revenue * 0.95 OR (cw.cum_revenue - cw.goods_revenue) < cw.total_segment_revenue * 0.95 THEN 'B'
            ELSE 'C'
        END)::TEXT AS internal_class
    FROM clients_with_cum cw;
END;
$function$
```

---

### `get_segmentation_current_year`(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000)
**Returns:** `TABLE(sort_order integer, freq_group character varying, freq_name character varying, freq_range character varying, total_count bigint, total_revenue numeric, new_count bigint, c2_count bigint, c2_revenue numeric, retained_count bigint)`

```sql
CREATE OR REPLACE FUNCTION public.get_segmentation_current_year(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(sort_order integer, freq_group character varying, freq_name character varying, freq_range character varying, total_count bigint, total_revenue numeric, new_count bigint, c2_count bigint, c2_revenue numeric, retained_count bigint)
 LANGUAGE plpgsql
 STABLE
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
$function$
```

---

### `get_segmentation_kpi`(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000)
**Returns:** `TABLE(total_clients bigint, repeat_loyal_clients bigint, repeat_loyal_pct numeric, c2_clients bigint, c2_pct numeric, new_clients bigint, new_pct numeric, total_revenue numeric, total_invoices bigint, avg_check numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_segmentation_kpi(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(total_clients bigint, repeat_loyal_clients bigint, repeat_loyal_pct numeric, c2_clients bigint, c2_pct numeric, new_clients bigint, new_pct numeric, total_revenue numeric, total_invoices bigint, avg_check numeric)
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
$function$
```

---

### `get_segmentation_matrix`(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000)
**Returns:** `TABLE(section character varying, row_key character varying, row_label character varying, val_1 numeric, val_2_3 numeric, val_4_10 numeric, val_11_40 numeric, val_41_plus numeric, val_total numeric, sort_order integer)`

```sql
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
```

---

### `get_segmentation_matrix_v2`(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000)
**Returns:** `TABLE(freq_group character varying, total_clients integer, total_sales numeric, c2_clients integer, c2_sales numeric, new_clients integer, retained_clients integer)`

```sql
CREATE OR REPLACE FUNCTION public.get_segmentation_matrix_v2(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(freq_group character varying, total_clients integer, total_sales numeric, c2_clients integer, c2_sales numeric, new_clients integer, retained_clients integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH freq_defs(sort_order, freq_code) AS (
        VALUES 
            (1, 'raz'::VARCHAR),
            (2, 'povt'::VARCHAR),
            (3, 'kvart'::VARCHAR),
            (4, 'mes'::VARCHAR),
            (5, 'post'::VARCHAR)
    ),
    active_clients AS (
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
                WHEN COUNT(DISTINCT d.id) = 1 THEN 'raz'
                WHEN COUNT(DISTINCT d.id) BETWEEN 2 AND 3 THEN 'povt'
                WHEN COUNT(DISTINCT d.id) BETWEEN 4 AND 10 THEN 'kvart'
                WHEN COUNT(DISTINCT d.id) BETWEEN 11 AND 40 THEN 'mes'
                ELSE 'post'
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
    agg AS (
        SELECT 
            cs.freq_group,
            COUNT(*)::INT AS total_clients,
            ROUND(SUM(cs.goods_revenue), 2)::NUMERIC AS total_sales,
            COUNT(CASE WHEN cs.goods_revenue <= p_limit_price THEN 1 END)::INT AS c2_clients,
            ROUND(SUM(CASE WHEN cs.goods_revenue <= p_limit_price THEN cs.goods_revenue ELSE 0 END), 2)::NUMERIC AS c2_sales,
            COUNT(CASE WHEN cs.is_new_client THEN 1 END)::INT AS new_clients,
            COUNT(CASE WHEN cs.is_retained THEN 1 END)::INT AS retained_clients
        FROM client_stats cs
        GROUP BY cs.freq_group
    )
    SELECT 
        fd.freq_code AS freq_group,
        COALESCE(a.total_clients, 0)::INT AS total_clients,
        COALESCE(a.total_sales, 0.00)::NUMERIC AS total_sales,
        COALESCE(a.c2_clients, 0)::INT AS c2_clients,
        COALESCE(a.c2_sales, 0.00)::NUMERIC AS c2_sales,
        COALESCE(a.new_clients, 0)::INT AS new_clients,
        COALESCE(a.retained_clients, 0)::INT AS retained_clients
    FROM freq_defs fd
    LEFT JOIN agg a ON fd.freq_code = a.freq_group
    ORDER BY fd.sort_order;
END;
$function$
```

---

### `get_segmentation_past_years`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(sort_order integer, freq_group character varying, freq_name character varying, freq_range character varying, current_status_id integer, status_name character varying, total_count bigint, total_revenue numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_segmentation_past_years(p_year integer DEFAULT 2026)
 RETURNS TABLE(sort_order integer, freq_group character varying, freq_name character varying, freq_range character varying, current_status_id integer, status_name character varying, total_count bigint, total_revenue numeric)
 LANGUAGE plpgsql
 STABLE
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
$function$
```

---

### `get_segmentation_special`(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000)
**Returns:** `TABLE(segment_code character varying, segment_name character varying, badge_label character varying, icon character varying, color character varying, clients_count bigint, sales_revenue numeric, invoices_count bigint, avg_ticket numeric, share_clients_pct numeric, share_revenue_pct numeric, description text, sort_order integer)`

```sql
CREATE OR REPLACE FUNCTION public.get_segmentation_special(p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000)
 RETURNS TABLE(segment_code character varying, segment_name character varying, badge_label character varying, icon character varying, color character varying, clients_count bigint, sales_revenue numeric, invoices_count bigint, avg_ticket numeric, share_clients_pct numeric, share_revenue_pct numeric, description text, sort_order integer)
 LANGUAGE plpgsql
 STABLE
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
$function$
```

---

### `get_sleeping_segmentation`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(code character varying, name character varying, inv_curr bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, last_purchase date, days_since integer, abc_group character varying, recommendation character varying, industry character varying, cohort character varying)`

```sql
CREATE OR REPLACE FUNCTION public.get_sleeping_segmentation(p_year integer DEFAULT 2026)
 RETURNS TABLE(code character varying, name character varying, inv_curr bigint, invoices_count bigint, goods_revenue numeric, services_revenue numeric, avg_ticket numeric, last_purchase date, days_since integer, abc_group character varying, recommendation character varying, industry character varying, cohort character varying)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH sleeping AS (
        SELECT c.code, c.name, c.activity_direction_id, ad.name AS industry
        FROM clients c
        LEFT JOIN activity_directions ad ON c.activity_direction_id = ad.id
        WHERE c.current_status_id = 8
          AND c.code NOT IN ('9653', '11230')
    ),
    curr_stats AS (
        SELECT 
            sl.code, sl.name, sl.industry,
            COUNT(DISTINCT d.id) AS inv_curr,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN s.amount ELSE 0 END), 0) AS rev_curr,
            COALESCE(SUM(CASE WHEN pr.is_service = TRUE THEN s.amount ELSE 0 END), 0) AS services_curr,
            MAX(d.invoice_date) AS last_purchase
        FROM sleeping sl
        JOIN documents d ON d.client_code = sl.code
        JOIN sales_lines s ON s.document_id = d.id
        LEFT JOIN products pr ON s.product_code = pr.code
        GROUP BY sl.code, sl.name, sl.industry
    )
    SELECT 
        cs.code::VARCHAR,
        cs.name::VARCHAR,
        cs.inv_curr::BIGINT AS inv_curr,
        cs.inv_curr::BIGINT AS invoices_count,
        ROUND(cs.rev_curr, 2)::NUMERIC AS goods_revenue,
        ROUND(cs.services_curr, 2)::NUMERIC AS services_revenue,
        ROUND(cs.rev_curr / NULLIF(cs.inv_curr, 0), 2)::NUMERIC AS avg_ticket,
        cs.last_purchase::DATE AS last_purchase,
        (CURRENT_DATE - cs.last_purchase::DATE)::INT AS days_since,
        CASE 
            WHEN cs.rev_curr >= 2900000 THEN 'A'
            WHEN cs.rev_curr >= 435000 THEN 'B'
            ELSE 'C'
        END::VARCHAR AS abc_group,
        CASE 
            WHEN (CURRENT_DATE - cs.last_purchase::DATE) > 180 THEN '⚠️ Терміново повернути'
            WHEN (CURRENT_DATE - cs.last_purchase::DATE) > 90 THEN '📞 Зателефонувати'
            ELSE '📧 Нагадати про себе'
        END::VARCHAR AS recommendation,
        COALESCE(cs.industry, 'Не вказано')::VARCHAR AS industry,
        CASE 
            WHEN cs.inv_curr = 1 THEN 'Разові (1)'
            WHEN cs.inv_curr BETWEEN 2 AND 3 THEN 'Повторні (2-3)'
            WHEN cs.inv_curr BETWEEN 4 AND 10 THEN 'Квартальні (4-10)'
            WHEN cs.inv_curr BETWEEN 11 AND 40 THEN 'Місячні (11-40)'
            WHEN cs.inv_curr BETWEEN 41 AND 170 THEN 'Тижневі (41-170)'
            ELSE 'Щоденні (>170)'
        END::VARCHAR AS cohort
    FROM curr_stats cs
    ORDER BY cs.rev_curr DESC;
END;
$function$
```

---

### `get_statuses_distribution`()
**Returns:** `TABLE(status_name character varying, count bigint)`

```sql
CREATE OR REPLACE FUNCTION public.get_statuses_distribution()
 RETURNS TABLE(status_name character varying, count bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT sr.status_name, COUNT(c.code)::BIGINT as count
    FROM status_rules sr
    LEFT JOIN clients c ON c.current_status_id = sr.id
    GROUP BY sr.id, sr.status_name, sr.priority
    ORDER BY sr.priority;
END;
$function$
```

---

### `get_top_clients_80pct`(p_year integer DEFAULT 2026, p_date_from date DEFAULT NULL::date, p_date_to date DEFAULT NULL::date)
**Returns:** `TABLE(code character varying, name character varying, status_2025 character varying, status_2026 character varying, goods_revenue numeric, invoice_count bigint, last_purchase_date date, pct_of_total numeric, running_pct numeric, is_included boolean, total_revenue numeric, period_label text)`

```sql
CREATE OR REPLACE FUNCTION public.get_top_clients_80pct(p_year integer DEFAULT 2026, p_date_from date DEFAULT NULL::date, p_date_to date DEFAULT NULL::date)
 RETURNS TABLE(code character varying, name character varying, status_2025 character varying, status_2026 character varying, goods_revenue numeric, invoice_count bigint, last_purchase_date date, pct_of_total numeric, running_pct numeric, is_included boolean, total_revenue numeric, period_label text)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_year INTEGER := COALESCE(p_year, 2026);
    v_total_revenue NUMERIC;
    v_period_label TEXT;
    v_full_months INTEGER;
BEGIN
    IF p_date_from IS NOT NULL AND p_date_to IS NOT NULL THEN
        v_period_label := TO_CHAR(p_date_from, 'YYYY-MM-DD') || ' — ' || TO_CHAR(p_date_to, 'YYYY-MM-DD');
        
        SELECT COALESCE(ROUND(SUM(sl.amount)::numeric, 0), 0)
        INTO v_total_revenue
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = v_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
          AND d.invoice_date BETWEEN p_date_from AND p_date_to;
    ELSE
        SELECT COUNT(DISTINCT EXTRACT(MONTH FROM d.invoice_date))::INTEGER
        INTO v_full_months
        FROM documents d
        WHERE EXTRACT(YEAR FROM d.invoice_date) = v_year AND d.invoice_date < DATE_TRUNC('month', CURRENT_DATE);

        v_period_label := COALESCE(v_full_months, 0)::TEXT || ' полных мес. ' || v_year::TEXT;

        SELECT COALESCE(ROUND(SUM(sl.amount)::numeric, 0), 0)
        INTO v_total_revenue
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = v_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
          AND EXTRACT(YEAR FROM d.invoice_date) = v_year AND d.invoice_date < DATE_TRUNC('month', CURRENT_DATE);
    END IF;

    RETURN QUERY
    WITH client_sales AS (
        SELECT 
            c.code::VARCHAR AS client_code,
            c.name::VARCHAR AS client_name,
            sr.status_name::VARCHAR AS status_curr,
            ROUND(SUM(sl.amount)::numeric, 0) AS rev,
            COUNT(DISTINCT d.id) AS inv_cnt,
            MAX(d.invoice_date) AS last_dt
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = v_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
          AND (
            (p_date_from IS NOT NULL AND p_date_to IS NOT NULL AND d.invoice_date BETWEEN p_date_from AND p_date_to)
            OR
            (p_date_from IS NULL AND EXTRACT(YEAR FROM d.invoice_date) = v_year AND d.invoice_date < DATE_TRUNC('month', CURRENT_DATE))
          )
        GROUP BY c.code, c.name, sr.status_name
    ),
    ranked AS (
        SELECT 
            cs.*,
            SUM(cs.rev) OVER (ORDER BY cs.rev DESC) AS running_total,
            ROUND((100.0 * cs.rev / NULLIF(v_total_revenue, 0))::numeric, 2) AS pct,
            ROUND((100.0 * SUM(cs.rev) OVER (ORDER BY cs.rev DESC) / NULLIF(v_total_revenue, 0))::numeric, 2) AS run_pct
        FROM client_sales cs
    ),
    top_filtered AS (
        SELECT r.*
        FROM ranked r
        WHERE r.run_pct <= 80 OR (r.run_pct > 80 AND r.run_pct - r.pct < 80)
    )
    SELECT 
        tf.client_code AS code,
        COALESCE(tf.client_name, '—')::VARCHAR AS name,
        COALESCE(
            (
                SELECT 
                    CASE 
                        WHEN cya.total_docs = 0 THEN 'Спящие'
                        WHEN cya.total_docs = 1 THEN 'Разовые'
                        WHEN cya.total_docs BETWEEN 2 AND 3 THEN 'Повторные'
                        WHEN cya.total_docs BETWEEN 4 AND 10 THEN 'Ежеквартальные'
                        WHEN cya.total_docs BETWEEN 11 AND 40 THEN 'Ежемесячные'
                        WHEN cya.total_docs BETWEEN 41 AND 170 THEN 'Еженедельные'
                        WHEN cya.total_docs > 170 THEN 'Ежедневные'
                        ELSE '—'
                    END
                FROM client_year_activity cya
                WHERE cya.client_code = tf.client_code AND cya.sales_year = 2025
                LIMIT 1
            ),
            '—'
        )::VARCHAR AS status_2025,
        COALESCE(tf.status_curr, '—')::VARCHAR AS status_2026,
        tf.rev AS goods_revenue,
        tf.inv_cnt AS invoice_count,
        tf.last_dt AS last_purchase_date,
        tf.pct AS pct_of_total,
        tf.run_pct AS running_pct,
        TRUE AS is_included,
        v_total_revenue AS total_revenue,
        v_period_label AS period_label
    FROM top_filtered tf
    ORDER BY tf.rev DESC;
END;
$function$
```

---

### `get_top_clients_monthly`(p_year integer DEFAULT 2026, p_month integer DEFAULT 7, p_limit integer DEFAULT 50, p_exclude_client text DEFAULT '9653'::text)
**Returns:** `TABLE(client_code character varying, client_name character varying, invoice_count bigint, goods_revenue numeric, status_2025 text, status_2026 text)`

```sql
CREATE OR REPLACE FUNCTION public.get_top_clients_monthly(p_year integer DEFAULT 2026, p_month integer DEFAULT 7, p_limit integer DEFAULT 50, p_exclude_client text DEFAULT '9653'::text)
 RETURNS TABLE(client_code character varying, client_name character varying, invoice_count bigint, goods_revenue numeric, status_2025 text, status_2026 text)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH month_revenue AS (
        SELECT 
            d.client_code,
            COUNT(DISTINCT d.id)::BIGINT as invoice_count,
            COALESCE(SUM(CASE WHEN pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND EXTRACT(MONTH FROM d.invoice_date) = p_month
          AND (p_exclude_client IS NULL OR d.client_code != p_exclude_client)
        GROUP BY d.client_code
    ),
    status_2025 AS (
        SELECT 
            cya.client_code,
            sr.status_name as status_name
        FROM client_year_activity cya
        LEFT JOIN status_rules sr ON sr.id = cya.abc_group::integer
        WHERE cya.sales_year = p_year - 1
          AND cya.is_active = TRUE
    ),
    status_2026 AS (
        SELECT 
            c.code as client_code,
            sr.status_name as status_name
        FROM clients c
        LEFT JOIN status_rules sr ON sr.id = c.current_status_id
        WHERE c.is_active_current = TRUE
    )
    SELECT 
        mr.client_code,
        c.name as client_name,
        mr.invoice_count,
        mr.goods_revenue,
        COALESCE(s25.status_name, '—')::TEXT as status_2025,
        COALESCE(s26.status_name, '—')::TEXT as status_2026
    FROM month_revenue mr
    JOIN clients c ON c.code = mr.client_code
    LEFT JOIN status_2025 s25 ON s25.client_code = mr.client_code
    LEFT JOIN status_2026 s26 ON s26.client_code = mr.client_code
    WHERE mr.goods_revenue > 0
    ORDER BY mr.goods_revenue DESC
    LIMIT p_limit;
END;
$function$
```

---

### `get_top_companies`(p_year integer DEFAULT 2026, p_limit integer DEFAULT 5)
**Returns:** `TABLE(rank bigint, code character varying, name character varying, goods_revenue numeric, pct_of_total numeric, running_pct numeric, status_name character varying, invoice_count bigint, avg_check numeric, prev_year_revenue numeric, growth_yoy_pct numeric, abc_group character varying, prev_period_revenue numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_top_companies(p_year integer DEFAULT 2026, p_limit integer DEFAULT 5)
 RETURNS TABLE(rank bigint, code character varying, name character varying, goods_revenue numeric, pct_of_total numeric, running_pct numeric, status_name character varying, invoice_count bigint, avg_check numeric, prev_year_revenue numeric, growth_yoy_pct numeric, abc_group character varying, prev_period_revenue numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_total_revenue NUMERIC := 0;
    v_max_month INTEGER := 12;
BEGIN
    SELECT COALESCE(MAX(EXTRACT(MONTH FROM d.invoice_date))::int, 12)
    INTO v_max_month
    FROM documents d
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year;

    SELECT COALESCE(SUM(sl.amount)::numeric, 0)
    INTO v_total_revenue
    FROM clients c
    JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE c.code NOT IN ('9653', '11230')
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    RETURN QUERY
    WITH curr_sales AS (
        SELECT 
            c.code as client_code,
            c.name as client_name,
            sr.status_name as curr_status,
            ROUND(SUM(sl.amount)::numeric, 2) as rev,
            COUNT(DISTINCT d.id) as inv_cnt
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code, c.name, sr.status_name
    ),
    prev_sales_total AS (
        SELECT 
            c.code as client_code,
            ROUND(SUM(sl.amount)::numeric, 2) as rev
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code
    ),
    prev_sales_period AS (
        SELECT 
            c.code as client_code,
            ROUND(SUM(sl.amount)::numeric, 2) as rev
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
          AND EXTRACT(MONTH FROM d.invoice_date) <= v_max_month
        GROUP BY c.code
    ),
    ranked AS (
        SELECT 
            cs.client_code,
            cs.client_name,
            cs.curr_status,
            cs.rev,
            cs.inv_cnt,
            COALESCE(pst.rev, 0.0) as prev_total_rev,
            COALESCE(psp.rev, 0.0) as prev_period_rev,
            SUM(cs.rev) OVER (ORDER BY cs.rev DESC) as run_tot,
            ROW_NUMBER() OVER (ORDER BY cs.rev DESC) as rk
        FROM curr_sales cs
        LEFT JOIN prev_sales_total pst ON pst.client_code = cs.client_code
        LEFT JOIN prev_sales_period psp ON psp.client_code = cs.client_code
    )
    SELECT 
        r.rk::BIGINT as rank,
        r.client_code::VARCHAR as code,
        COALESCE(r.client_name, '—')::VARCHAR as name,
        r.rev::NUMERIC as goods_revenue,
        ROUND((100.0 * r.rev / NULLIF(v_total_revenue, 0))::numeric, 2)::NUMERIC as pct_of_total,
        ROUND((100.0 * r.run_tot / NULLIF(v_total_revenue, 0))::numeric, 2)::NUMERIC as running_pct,
        COALESCE(r.curr_status, '—')::VARCHAR as status_name,
        r.inv_cnt::BIGINT as invoice_count,
        ROUND((r.rev / NULLIF(r.inv_cnt, 0))::numeric, 2)::NUMERIC as avg_check,
        r.prev_total_rev::NUMERIC as prev_year_revenue,
        CASE 
            WHEN r.prev_total_rev > 0 THEN ROUND((100.0 * r.rev / r.prev_total_rev)::numeric, 2)
            ELSE NULL
        END::NUMERIC as growth_yoy_pct,
        get_abc_group_for_revenue(r.rev)::VARCHAR as abc_group,
        r.prev_period_rev::NUMERIC as prev_period_revenue
    FROM ranked r
    ORDER BY r.rk ASC
    LIMIT p_limit;
END;
$function$
```

---

### `get_top_company_detail`(p_code character varying, p_year integer DEFAULT 2026)
**Returns:** `json`

```sql
CREATE OR REPLACE FUNCTION public.get_top_company_detail(p_code character varying, p_year integer DEFAULT 2026)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_total_revenue NUMERIC := 0;
    v_curr_rev NUMERIC := 0;
    v_prev_total_rev NUMERIC := 0;
    v_prev_period_rev NUMERIC := 0;
    v_inv_cnt BIGINT := 0;
    v_client_name VARCHAR := '—';
    v_status_name VARCHAR := '—';
    v_abc_group VARCHAR := '—';
    v_max_month INTEGER := 12;
    v_monthly_curr JSON;
    v_monthly_prev JSON;
    v_top_products JSON;
    v_result JSON;
BEGIN
    -- Max month for p_year
    SELECT COALESCE(MAX(EXTRACT(MONTH FROM d.invoice_date))::int, 12)
    INTO v_max_month
    FROM documents d
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year;

    -- Total year revenue in active companies
    SELECT COALESCE(SUM(sl.amount)::numeric, 0)
    INTO v_total_revenue
    FROM clients c
    JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE c.code NOT IN ('9653', '11230')
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    -- Current client basic info & current year sales
    SELECT 
        COALESCE(c.name, '—'),
        COALESCE(sr.status_name, '—'),
        COALESCE(ROUND(SUM(sl.amount)::numeric, 2), 0),
        COALESCE(COUNT(DISTINCT d.id), 0)
    INTO v_client_name, v_status_name, v_curr_rev, v_inv_cnt
    FROM clients c
    JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
    LEFT JOIN status_rules sr ON c.current_status_id = sr.id
    LEFT JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    LEFT JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
    WHERE c.code = p_code
    GROUP BY c.name, sr.status_name;

    -- Previous year sales TOTAL (12 months)
    SELECT COALESCE(ROUND(SUM(sl.amount)::numeric, 2), 0)
    INTO v_prev_total_rev
    FROM clients c
    JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE c.code = p_code
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    -- Previous year sales SAME PERIOD (months <= v_max_month)
    SELECT COALESCE(ROUND(SUM(sl.amount)::numeric, 2), 0)
    INTO v_prev_period_rev
    FROM clients c
    JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE c.code = p_code
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0
      AND EXTRACT(MONTH FROM d.invoice_date) <= v_max_month;

    v_abc_group := get_abc_group_for_revenue(v_curr_rev);

    -- Monthly dynamics for current year (1..12)
    SELECT json_agg(months_data ORDER BY m)
    INTO v_monthly_curr
    FROM (
        SELECT 
            m,
            COALESCE(ROUND(SUM(sl.amount)::numeric, 2), 0) as rev
        FROM generate_series(1, 12) m
        LEFT JOIN documents d ON EXTRACT(MONTH FROM d.invoice_date) = m 
            AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
            AND d.client_code = p_code
        LEFT JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
        GROUP BY m
    ) months_data;

    -- Monthly dynamics for previous year (1..12)
    SELECT json_agg(months_data ORDER BY m)
    INTO v_monthly_prev
    FROM (
        SELECT 
            m,
            COALESCE(ROUND(SUM(sl.amount)::numeric, 2), 0) as rev
        FROM generate_series(1, 12) m
        LEFT JOIN documents d ON EXTRACT(MONTH FROM d.invoice_date) = m 
            AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1) 
            AND d.client_code = p_code
        LEFT JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
        GROUP BY m
    ) months_data;

    -- TOP 5 products for this client in p_year
    SELECT json_agg(prod_data)
    INTO v_top_products
    FROM (
        SELECT 
            sl.product_code,
            COALESCE(pr.name, 'Товар ' || sl.product_code) as product_name,
            ROUND(SUM(sl.quantity)::numeric, 2) as quantity,
            ROUND(SUM(sl.amount)::numeric, 2) as amount,
            CASE WHEN v_curr_rev > 0 THEN ROUND((100.0 * SUM(sl.amount) / v_curr_rev)::numeric, 2) ELSE 0 END as share_pct
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE d.client_code = p_code
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY sl.product_code, pr.name
        ORDER BY amount DESC
        LIMIT 5
    ) prod_data;

    v_result := json_build_object(
        'code', p_code,
        'name', v_client_name,
        'status_name', v_status_name,
        'abc_group', v_abc_group,
        'year', p_year,
        'goods_revenue', v_curr_rev,
        'prev_year_revenue', v_prev_total_rev,
        'prev_period_revenue', v_prev_period_rev,
        'growth_yoy_pct', CASE WHEN v_prev_total_rev > 0 THEN ROUND((100.0 * v_curr_rev / v_prev_total_rev)::numeric, 2) ELSE NULL END,
        'invoice_count', v_inv_cnt,
        'avg_check', CASE WHEN v_inv_cnt > 0 THEN ROUND((v_curr_rev / v_inv_cnt)::numeric, 2) ELSE 0 END,
        'pct_of_total', CASE WHEN v_total_revenue > 0 THEN ROUND((100.0 * v_curr_rev / v_total_revenue)::numeric, 2) ELSE 0 END,
        'monthly_curr', COALESCE(v_monthly_curr, '[]'::json),
        'monthly_prev', COALESCE(v_monthly_prev, '[]'::json),
        'top_products', COALESCE(v_top_products, '[]'::json)
    );

    RETURN v_result;
END;
$function$
```

---

### `get_top_compare_yoy`(p_year integer DEFAULT 2026, p_limit integer DEFAULT 10)
**Returns:** `json`

```sql
CREATE OR REPLACE FUNCTION public.get_top_compare_yoy(p_year integer DEFAULT 2026, p_limit integer DEFAULT 10)
 RETURNS json
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_curr_top JSON;
    v_prev_top JSON;
    v_retained_cnt INTEGER := 0;
    v_new_cnt INTEGER := 0;
    v_left_cnt INTEGER := 0;
    v_result JSON;
BEGIN
    -- TOP N current year
    WITH curr_top AS (
        SELECT 
            c.code as client_code,
            c.name as client_name,
            ROUND(SUM(sl.amount)::numeric, 2) as rev,
            ROW_NUMBER() OVER (ORDER BY SUM(sl.amount) DESC) as rk
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code, c.name
        ORDER BY rev DESC
        LIMIT p_limit
    ),
    prev_top AS (
        SELECT 
            c.code as client_code,
            c.name as client_name,
            ROUND(SUM(sl.amount)::numeric, 2) as rev,
            ROW_NUMBER() OVER (ORDER BY SUM(sl.amount) DESC) as rk
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code, c.name
        ORDER BY rev DESC
        LIMIT p_limit
    )
    SELECT 
        (SELECT COUNT(*) FROM curr_top ct JOIN prev_top pt ON ct.client_code = pt.client_code),
        (SELECT COUNT(*) FROM curr_top ct WHERE ct.client_code NOT IN (SELECT client_code FROM prev_top)),
        (SELECT COUNT(*) FROM prev_top pt WHERE pt.client_code NOT IN (SELECT client_code FROM curr_top))
    INTO v_retained_cnt, v_new_cnt, v_left_cnt;

    -- Detailed JSON list comparing ranks
    WITH curr_top AS (
        SELECT 
            c.code as client_code,
            c.name as client_name,
            ROUND(SUM(sl.amount)::numeric, 2) as rev,
            ROW_NUMBER() OVER (ORDER BY SUM(sl.amount) DESC) as rk
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code, c.name
        ORDER BY rev DESC
        LIMIT p_limit
    ),
    prev_top AS (
        SELECT 
            c.code as client_code,
            c.name as client_name,
            ROUND(SUM(sl.amount)::numeric, 2) as rev,
            ROW_NUMBER() OVER (ORDER BY SUM(sl.amount) DESC) as rk
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code, c.name
        ORDER BY rev DESC
        LIMIT p_limit
    ),
    combined AS (
        SELECT 
            ct.rk as curr_rank,
            ct.client_code,
            ct.client_name,
            ct.rev as curr_revenue,
            pt.rk as prev_rank,
            COALESCE(pt.rev, 0.0) as prev_revenue,
            CASE 
                WHEN pt.client_code IS NOT NULL THEN 'retained'
                ELSE 'new'
            END as category
        FROM curr_top ct
        LEFT JOIN prev_top pt ON pt.client_code = ct.client_code
    )
    SELECT json_agg(combined ORDER BY curr_rank)
    INTO v_curr_top
    FROM combined;

    -- Dropped out list
    WITH curr_top AS (
        SELECT c.code as client_code 
        FROM clients c 
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year 
        JOIN sales_lines sl ON sl.document_id = d.id 
        LEFT JOIN products pr ON sl.product_code = pr.code 
        WHERE c.code NOT IN ('9653', '11230') AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0 
        GROUP BY c.code 
        ORDER BY SUM(sl.amount) DESC 
        LIMIT p_limit
    ),
    prev_top AS (
        SELECT 
            c.code as client_code,
            c.name as client_name,
            ROUND(SUM(sl.amount)::numeric, 2) as rev,
            ROW_NUMBER() OVER (ORDER BY SUM(sl.amount) DESC) as rk
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code, c.name
        ORDER BY rev DESC
        LIMIT p_limit
    )
    SELECT json_agg(dropped ORDER BY dropped.prev_rank)
    INTO v_prev_top
    FROM (
        SELECT pt.rk as prev_rank, pt.client_code, pt.client_name, pt.rev as prev_revenue
        FROM prev_top pt
        WHERE pt.client_code NOT IN (SELECT client_code FROM curr_top)
    ) dropped;

    v_result := json_build_object(
        'year', p_year,
        'limit', p_limit,
        'retained_count', v_retained_cnt,
        'new_entries_count', v_new_cnt,
        'left_top_count', v_left_cnt,
        'current_top', COALESCE(v_curr_top, '[]'::json),
        'dropped_out', COALESCE(v_prev_top, '[]'::json)
    );

    RETURN v_result;
END;
$function$
```

---

### `get_top_recommendations`(p_limit integer DEFAULT 10)
**Returns:** `TABLE(code character varying, name character varying, total_sales bigint, in_stock_balance numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_top_recommendations(p_limit integer DEFAULT 10)
 RETURNS TABLE(code character varying, name character varying, total_sales bigint, in_stock_balance numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p.code, p.name, COUNT(sl.id)::BIGINT AS total_sales,
           COALESCE(p.in_stock_balance, 0)::NUMERIC AS in_stock_balance
    FROM products p
    JOIN sales_lines sl ON sl.product_code = p.code
    WHERE COALESCE(p.in_stock_balance, 0) > 0
    GROUP BY p.code, p.name, p.in_stock_balance
    ORDER BY total_sales DESC
    LIMIT p_limit;
END;
$function$
```

---

### `get_top_revenue_core`(p_year integer DEFAULT 2026, p_pct numeric DEFAULT 80)
**Returns:** `TABLE(rank bigint, code character varying, name character varying, goods_revenue numeric, pct_of_total numeric, running_pct numeric, status_name character varying, invoice_count bigint, avg_check numeric, abc_group character varying, prev_year_revenue numeric, growth_yoy_pct numeric, prev_period_revenue numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_top_revenue_core(p_year integer DEFAULT 2026, p_pct numeric DEFAULT 80)
 RETURNS TABLE(rank bigint, code character varying, name character varying, goods_revenue numeric, pct_of_total numeric, running_pct numeric, status_name character varying, invoice_count bigint, avg_check numeric, abc_group character varying, prev_year_revenue numeric, growth_yoy_pct numeric, prev_period_revenue numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_total_revenue NUMERIC := 0;
    v_max_month INTEGER := 12;
BEGIN
    SELECT COALESCE(MAX(EXTRACT(MONTH FROM d.invoice_date))::int, 12)
    INTO v_max_month
    FROM documents d
    WHERE EXTRACT(YEAR FROM d.invoice_date) = p_year;

    SELECT COALESCE(SUM(sl.amount)::numeric, 0)
    INTO v_total_revenue
    FROM clients c
    JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE c.code NOT IN ('9653', '11230')
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    RETURN QUERY
    WITH curr_sales AS (
        SELECT 
            c.code as client_code,
            c.name as client_name,
            sr.status_name as curr_status,
            ROUND(SUM(sl.amount)::numeric, 2) as rev,
            COUNT(DISTINCT d.id) as inv_cnt
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        LEFT JOIN status_rules sr ON c.current_status_id = sr.id
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code, c.name, sr.status_name
    ),
    prev_sales_total AS (
        SELECT 
            c.code as client_code,
            ROUND(SUM(sl.amount)::numeric, 2) as rev
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code
    ),
    prev_sales_period AS (
        SELECT 
            c.code as client_code,
            ROUND(SUM(sl.amount)::numeric, 2) as rev
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = (p_year - 1) AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = (p_year - 1)
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
          AND EXTRACT(MONTH FROM d.invoice_date) <= v_max_month
        GROUP BY c.code
    ),
    ranked AS (
        SELECT 
            cs.client_code,
            cs.client_name,
            cs.curr_status,
            cs.rev,
            cs.inv_cnt,
            COALESCE(pst.rev, 0.0) as prev_total_rev,
            COALESCE(psp.rev, 0.0) as prev_period_rev,
            SUM(cs.rev) OVER (ORDER BY cs.rev DESC) as run_tot,
            ROUND((100.0 * cs.rev / NULLIF(v_total_revenue, 0))::numeric, 2) as pct,
            ROUND((100.0 * SUM(cs.rev) OVER (ORDER BY cs.rev DESC) / NULLIF(v_total_revenue, 0))::numeric, 2) as run_pct,
            ROW_NUMBER() OVER (ORDER BY cs.rev DESC) as rk
        FROM curr_sales cs
        LEFT JOIN prev_sales_total pst ON pst.client_code = cs.client_code
        LEFT JOIN prev_sales_period psp ON psp.client_code = cs.client_code
    )
    SELECT 
        r.rk::BIGINT as rank,
        r.client_code::VARCHAR as code,
        COALESCE(r.client_name, '—')::VARCHAR as name,
        r.rev::NUMERIC as goods_revenue,
        r.pct::NUMERIC as pct_of_total,
        r.run_pct::NUMERIC as running_pct,
        COALESCE(r.curr_status, '—')::VARCHAR as status_name,
        r.inv_cnt::BIGINT as invoice_count,
        ROUND((r.rev / NULLIF(r.inv_cnt, 0))::numeric, 2)::NUMERIC as avg_check,
        get_abc_group_for_revenue(r.rev)::VARCHAR as abc_group,
        r.prev_total_rev::NUMERIC as prev_year_revenue,
        CASE 
            WHEN r.prev_total_rev > 0 THEN ROUND((100.0 * r.rev / r.prev_total_rev)::numeric, 2)
            ELSE NULL
        END::NUMERIC as growth_yoy_pct,
        r.prev_period_rev::NUMERIC as prev_period_revenue
    FROM ranked r
    WHERE r.run_pct <= p_pct OR (r.run_pct > p_pct AND r.run_pct - r.pct < p_pct)
    ORDER BY r.rk ASC;
END;
$function$
```

---

### `get_top_sales_kpi`(p_year integer DEFAULT 2026)
**Returns:** `TABLE(total_revenue numeric, active_clients_count bigint, top1_share_pct numeric, top10_share_pct numeric, clients_for_80pct bigint, avg_check numeric)`

```sql
CREATE OR REPLACE FUNCTION public.get_top_sales_kpi(p_year integer DEFAULT 2026)
 RETURNS TABLE(total_revenue numeric, active_clients_count bigint, top1_share_pct numeric, top10_share_pct numeric, clients_for_80pct bigint, avg_check numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_total_revenue NUMERIC := 0;
    v_total_invoices BIGINT := 0;
    v_top1_rev NUMERIC := 0;
    v_top10_rev NUMERIC := 0;
    v_clients_80 BIGINT := 0;
BEGIN
    -- Total goods revenue and total invoices for active clients in p_year
    SELECT 
        COALESCE(ROUND(SUM(sl.amount)::numeric, 2), 0),
        COALESCE(COUNT(DISTINCT d.id), 0)
    INTO v_total_revenue, v_total_invoices
    FROM clients c
    JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE c.code NOT IN ('9653', '11230')
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    IF v_total_revenue = 0 THEN
        RETURN QUERY SELECT 0::NUMERIC, 0::BIGINT, 0::NUMERIC, 0::NUMERIC, 0::BIGINT, 0::NUMERIC;
        RETURN;
    END IF;

    -- Active clients count from client_year_activity
    SELECT COUNT(DISTINCT cya.client_code)
    INTO active_clients_count
    FROM client_year_activity cya
    WHERE cya.sales_year = p_year AND cya.is_active = TRUE
      AND cya.client_code NOT IN ('9653', '11230');

    -- Top 1 client revenue
    WITH top1 AS (
        SELECT SUM(sl.amount) as rev
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code
        ORDER BY rev DESC
        LIMIT 1
    )
    SELECT COALESCE(SUM(rev), 0) INTO v_top1_rev FROM top1;

    -- Top 10 clients revenue
    WITH top10 AS (
        SELECT SUM(sl.amount) as rev
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code
        ORDER BY rev DESC
        LIMIT 10
    )
    SELECT COALESCE(SUM(rev), 0) INTO v_top10_rev FROM top10;

    -- Clients for 80% revenue
    WITH client_revs AS (
        SELECT 
            SUM(sl.amount) as rev,
            SUM(SUM(sl.amount)) OVER (ORDER BY SUM(sl.amount) DESC) as running_total
        FROM clients c
        JOIN client_year_activity cya ON cya.client_code = c.code AND cya.sales_year = p_year AND cya.is_active = TRUE
        JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code NOT IN ('9653', '11230')
          AND COALESCE(pr.is_service, FALSE) = FALSE
          AND sl.amount > 0
        GROUP BY c.code
    ),
    filtered AS (
        SELECT rev, running_total, (100.0 * running_total / v_total_revenue) as run_pct, (100.0 * rev / v_total_revenue) as pct
        FROM client_revs
    )
    SELECT COUNT(*) INTO v_clients_80
    FROM filtered
    WHERE run_pct <= 80 OR (run_pct > 80 AND run_pct - pct < 80);

    total_revenue := v_total_revenue;
    top1_share_pct := ROUND((100.0 * v_top1_rev / v_total_revenue)::numeric, 2);
    top10_share_pct := ROUND((100.0 * v_top10_rev / v_total_revenue)::numeric, 2);
    clients_for_80pct := v_clients_80;
    avg_check := CASE WHEN v_total_invoices > 0 THEN ROUND((v_total_revenue / v_total_invoices)::numeric, 2) ELSE 0 END;

    RETURN NEXT;
END;
$function$
```

---

### `get_yearly_clients_count`(p_year integer DEFAULT 2026)
**Returns:** `bigint`

```sql
CREATE OR REPLACE FUNCTION public.get_yearly_clients_count(p_year integer DEFAULT 2026)
 RETURNS bigint
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    cnt BIGINT;
BEGIN
    SELECT COUNT(*)::BIGINT INTO cnt
    FROM client_year_activity 
    WHERE sales_year = p_year AND is_active = TRUE;
    
    RETURN cnt;
END;
$function$
```

---

### `get_yoy_comparison`(p_year1 integer DEFAULT 2026, p_year2 integer DEFAULT 2025)
**Returns:** `TABLE(month integer, month_name text, goods_revenue_y1 numeric, goods_revenue_y2 numeric, clients_y1 bigint, clients_y2 bigint)`

```sql
CREATE OR REPLACE FUNCTION public.get_yoy_comparison(p_year1 integer DEFAULT 2026, p_year2 integer DEFAULT 2025)
 RETURNS TABLE(month integer, month_name text, goods_revenue_y1 numeric, goods_revenue_y2 numeric, clients_y1 bigint, clients_y2 bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH mutual_clients AS (
        SELECT DISTINCT d1.client_code
        FROM documents d1
        WHERE EXTRACT(YEAR FROM d1.invoice_date) = p_year1
        INTERSECT
        SELECT DISTINCT d2.client_code
        FROM documents d2
        WHERE EXTRACT(YEAR FROM d2.invoice_date) = p_year2
    )
    SELECT 
        EXTRACT(MONTH FROM d.invoice_date)::INTEGER AS month,
        TO_CHAR(TO_DATE(EXTRACT(MONTH FROM d.invoice_date)::TEXT, 'MM'), 'Mon')::TEXT AS month_name,
        COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year1 
            AND pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue_y1,
        COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year2 
            AND pr.is_service = FALSE THEN sl.amount ELSE 0 END), 0)::NUMERIC AS goods_revenue_y2,
        COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year1 
            THEN d.client_code END)::BIGINT AS clients_y1,
        COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = p_year2 
            THEN d.client_code END)::BIGINT AS clients_y2
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.client_code IN (SELECT mc.client_code FROM mutual_clients mc)
      AND EXTRACT(YEAR FROM d.invoice_date) IN (p_year1, p_year2)
    GROUP BY EXTRACT(MONTH FROM d.invoice_date)
    ORDER BY month;
END;
$function$
```

---

### `get_zaletnye`(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9)
**Returns:** `TABLE(group_prev text, companies_count bigint, goods_revenue numeric, invoice_count bigint)`

```sql
CREATE OR REPLACE FUNCTION public.get_zaletnye(p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9)
 RETURNS TABLE(group_prev text, companies_count bigint, goods_revenue numeric, invoice_count bigint)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_year_prev INT := p_year - 1;
BEGIN
    RETURN QUERY
    WITH abc_prev AS (
        SELECT 
            cya.client_code,
            cya.goods_revenue
        FROM client_year_activity cya
        WHERE sales_year = v_year_prev
    ),
    abc_grouped AS (
        SELECT 
            ap.client_code,
            CASE
                WHEN ap.goods_revenue >= 3000000 * p_multiplier THEN 'A1'
                WHEN ap.goods_revenue >= 2000000 * p_multiplier THEN 'A2'
                WHEN ap.goods_revenue >= 1500000 * p_multiplier THEN 'A3'
                WHEN ap.goods_revenue >= 1000000 * p_multiplier THEN 'B1'
                WHEN ap.goods_revenue >= 500000  * p_multiplier THEN 'B2'
                WHEN ap.goods_revenue >= 150000  * p_multiplier THEN 'C1'
                WHEN ap.goods_revenue >= 1000    * p_multiplier THEN 'C2'
                ELSE 'Other'
            END AS abc_group
        FROM abc_prev ap
    ),
    zalet_prev AS (
        SELECT ag.client_code, ag.abc_group AS group_prev
        FROM abc_grouped ag
        WHERE ag.abc_group IN ('C1', 'C2')
    ),
    new_clients AS (
        SELECT v.client_code, 'Новый' AS group_prev
        FROM view_client_profiles_yearly v
        WHERE v.sales_year = p_year
          AND v.client_code NOT IN (
              SELECT cya.client_code FROM client_year_activity cya WHERE cya.sales_year = v_year_prev AND cya.is_active = TRUE
          )
    ),
    all_zalet AS (
        SELECT * FROM zalet_prev
        UNION ALL
        SELECT * FROM new_clients
    )
    SELECT 
        az.group_prev::TEXT,
        COUNT(DISTINCT az.client_code)::BIGINT AS companies_count,
        COALESCE(SUM(v.goods_revenue), 0)::NUMERIC AS goods_revenue,
        COALESCE(SUM(v.invoice_count), 0)::BIGINT AS invoice_count
    FROM all_zalet az
    LEFT JOIN view_client_profiles_yearly v 
        ON v.client_code = az.client_code 
        AND v.sales_year = p_year
    GROUP BY az.group_prev
    ORDER BY 
        CASE az.group_prev
            WHEN 'C1' THEN 1 WHEN 'C2' THEN 2 WHEN 'Новый' THEN 3
        END;
END;
$function$
```

---

### `log_status_change`()
**Returns:** `trigger`

```sql
CREATE OR REPLACE FUNCTION public.log_status_change()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF (OLD.current_status_id IS DISTINCT FROM NEW.current_status_id) THEN
        INSERT INTO status_change_log (client_code, old_status_id, new_status_id, changed_by, change_reason)
        VALUES (NEW.code, OLD.current_status_id, NEW.current_status_id, 'SYSTEM', 'Автоматический пересчет');
        NEW.status_history = COALESCE(NEW.status_history, '[]'::jsonb) || jsonb_build_object('date', CURRENT_TIMESTAMP, 'old_status', OLD.current_status_id, 'new_status', NEW.current_status_id);
    END IF;
    RETURN NEW;
END;
$function$
```

---

### `penalize_rejected_product`()
**Returns:** `trigger`

```sql
CREATE OR REPLACE FUNCTION public.penalize_rejected_product()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$
```

---

### `trg_sync_clients_direction`()
**Returns:** `trigger`

```sql
CREATE OR REPLACE FUNCTION public.trg_sync_clients_direction()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.direction_id IS DISTINCT FROM OLD.direction_id AND (NEW.activity_direction_id IS NOT DISTINCT FROM OLD.activity_direction_id) THEN
        NEW.activity_direction_id := NEW.direction_id;
    ELSIF NEW.activity_direction_id IS DISTINCT FROM OLD.activity_direction_id THEN
        NEW.direction_id := NEW.activity_direction_id;
    END IF;
    RETURN NEW;
END;
$function$
```

---

### `trg_update_client_activity`()
**Returns:** `trigger`

```sql
CREATE OR REPLACE FUNCTION public.trg_update_client_activity()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
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
$function$
```

---

### `update_client_analytics`(p_client_code character varying DEFAULT NULL::character varying)
**Returns:** `void`

```sql
CREATE OR REPLACE FUNCTION public.update_client_analytics(p_client_code character varying DEFAULT NULL::character varying)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
BEGIN
    WITH client_stats AS (
        SELECT 
            c.code,
            MIN(d.invoice_date) AS first_date,
            MAX(d.invoice_date) AS last_date
        FROM clients c
        LEFT JOIN documents d ON d.client_code = c.code
        WHERE (p_client_code IS NULL OR c.code = p_client_code)
        GROUP BY c.code
    )
    UPDATE clients c
    SET 
        first_purchase_date = cs.first_date,
        last_purchase_date = cs.last_date,
        current_status_id = calculate_client_status(c.code),
        requires_survey = CASE 
            WHEN calculate_client_status(c.code) = (SELECT id FROM status_rules WHERE status_name = 'Новые')
                 AND c.survey_completed_at IS NULL 
            THEN TRUE 
            ELSE FALSE 
        END,
        updated_at = CURRENT_TIMESTAMP
    FROM client_stats cs
    WHERE c.code = cs.code;
END;
$function$
```

---

### `update_updated_at_column`()
**Returns:** `trigger`

```sql
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
```

---

