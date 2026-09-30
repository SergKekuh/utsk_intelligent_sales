# API Эндпоинты FastAPI (`utsk_web/backend/app/api`)

Всего зарегистрировано API эндпоинтов: 136.

## 📋 Сводная матрица всех API эндпоинтов

| Метод | URL | Модуль | Вызываемая функция БД | Страницы фронтенда |
|:---:|:---|:---|:---|:---|
| `GET` | `/api/analytics/monthly-revenue` | `analytics.py` | `get_yoy_comparison, get_monthly_revenue, generate_custom_sales_report` | `advanced.html`, `analytics.html`, `avg-check.html`, `index.html` |
| `GET` | `/api/analytics/yoy-comparison` | `analytics.py` | `get_yoy_comparison, generate_custom_sales_report` | `analytics.html` |
| `GET` | `/api/analytics/pivot-report` | `analytics.py` | `generate_custom_sales_report` | — |
| `GET` | `/api/analytics/pivot-formatted` | `analytics.py` | `generate_custom_sales_report, get_abc_groups` | `analytics.html` |
| `GET` | `/api/analytics/abc-groups` | `analytics.py` | `get_daily_revenue, get_abc_groups, get_monthly_detail_metrics` | `analytics.html` |
| `GET` | `/api/analytics/daily-revenue` | `analytics.py` | `get_daily_revenue, get_monthly_detail_metrics` | `monthly.html` |
| `GET` | `/api/analytics/monthly-detail` | `analytics.py` | `get_monthly_detail_metrics` | `monthly.html` |
| `GET` | `/api/analytics/abc-migration` | `analytics.py` | `get_monthly_directions, get_abc_migration, get_zaletnye` | `monthly.html` |
| `GET` | `/api/analytics/zaletnye` | `analytics.py` | `get_monthly_directions, get_monthly_products, get_zaletnye` | `monthly.html` |
| `GET` | `/api/analytics/monthly-directions` | `analytics.py` | `get_monthly_directions, get_monthly_top_clients, get_monthly_products` | `monthly.html` |
| `GET` | `/api/analytics/monthly-products` | `analytics.py` | `get_yearly_clients_count, get_monthly_top_clients, get_monthly_products` | `monthly.html` |
| `GET` | `/api/analytics/monthly-top-clients` | `analytics.py` | `generate_custom_sales_report, get_yearly_clients_count, get_monthly_top_clients` | `monthly.html` |
| `GET` | `/api/analytics/yearly-clients-count` | `analytics.py` | `generate_custom_sales_report, get_yearly_clients_count` | `advanced.html`, `analytics.html`, `avg-check.html`, `index.html` |
| `GET` | `/api/analytics/abc-comparison` | `analytics.py` | `get_recurrent_clients` | — |
| `GET` | `/api/analytics/recurrent-clients` | `analytics.py` | `get_recurrent_clients, get_clients_yoy` | `analytics.html` |
| `GET` | `/api/analytics/clients-yoy` | `analytics.py` | `get_clients_yoy` | `analytics.html` |
| `GET` | `/api/analytics/segment-comparison` | `analytics.py` | `get_rfm_funnel, get_alt_funnel` | `advanced.html`, `avg-check.html`, `comparison.html` |
| `GET` | `/api/analytics/abc-structure` | `analytics.py` | `get_abc_structure_data` | `abc_structure.html` |
| `GET` | `/api/analytics/c2-detail` | `analytics.py` | `get_segment_detail` | — |
| `GET` | `/api/analytics/abc-segment-detail` | `analytics.py` | `get_segment_detail` | `abc_structure.html` |
| `GET` | `/api/analytics/abc-structure-detail` | `analytics.py` | `get_segment_detail` | — |
| `GET` | `/api/analytics/abc-groups-detail` | `analytics.py` | `get_important_detail, get_abc_groups_detail` | — |
| `GET` | `/api/analytics/important-detail` | `analytics.py` | `get_important_detail` | — |
| `GET` | `/api/analytics/top-clients` | `analytics.py` | `get_top_clients_monthly, get_excluded_client_info` | — |
| `GET` | `/api/analytics/segmentation-kpi` | `analytics.py` | `get_segmentation_matrix, get_segmentation_special, get_segmentation_kpi` | — |
| `GET` | `/api/analytics/segmentation-special` | `analytics.py` | `get_segmentation_matrix, get_segmentation_special` | — |
| `GET` | `/api/analytics/segmentation-matrix` | `analytics.py` | `get_segmentation_matrix` | — |
| `GET` | `/api/analytics/segmentation-matrix-v2` | `analytics.py` | `get_segmentation_matrix_v2` | — |
| `GET` | `/api/analytics/segmentation-current-year` | `analytics.py` | `get_segmentation_current_year` | `analytics.html` |
| `GET` | `/api/analytics/segmentation-past-years` | `analytics.py` | `get_segment_detail, get_segmentation_past_years` | `analytics.html` |
| `GET` | `/api/analytics/segment-detail` | `analytics.py` | `get_segment_detail` | `segment-detail.html` |
| `GET` | `/api/analytics/general-segmentation-companies` | `analytics.py` | `get_general_segmentation_companies` | `general-segmentation.html` |
| `GET` | `/api/analytics/repeat-segmentation-companies` | `analytics.py` | `get_repeat_segmentation_companies` | `repeat-segmentation.html` |
| `GET` | `/api/analytics/consolidated-segmentation-companies` | `analytics.py` | `get_consolidated_segmentation_companies` | `consolidated-segmentation.html` |
| `GET` | `/api/analytics/c2-segmentation-companies` | `analytics.py` | `get_c2_segmentation_companies, get_c2_top_products` | `c2-segmentation.html` |
| `GET` | `/api/analytics/new-clients-segmentation-companies` | `analytics.py` | `get_new_clients_monthly_revenue, get_new_clients_segmentation` | `new-clients-segmentation.html` |
| `GET` | `/api/analytics/churned-segmentation-companies` | `analytics.py` | `get_churned_segmentation` | `churned-segmentation.html` |
| `GET` | `/api/analytics/sleeping-segmentation-companies` | `analytics.py` | `get_sleeping_segmentation` | `sleeping-segmentation.html` |
| `GET` | `/api/analytics/product-categories` | `analytics.py` | `get_product_categories` | `advanced.html` |
| `GET` | `/api/analytics/client/revenue` | `client_analytics.py` | `Direct SQL / Helper` | `client-revenue-analytics.html` |
| `GET` | `/api/analytics/client/invoices` | `client_analytics.py` | `Direct SQL / Helper` | `client-invoices-analytics.html`, `client-invoices-month.html` |
| `GET` | `/api/analytics/client/avg-check` | `client_analytics.py` | `Direct SQL / Helper` | `client-avg-check-analytics.html` |
| `GET` | `/api/analytics/client/last-purchase` | `client_analytics.py` | `Direct SQL / Helper` | `client-last-purchase-analytics.html` |
| `GET` | `/api/analytics/client/invoices-month` | `client_analytics.py` | `Direct SQL / Helper` | `client-invoices-month.html` |
| `GET` | `/api/analytics/client/month-summary` | `client_analytics.py` | `Direct SQL / Helper` | `client-month-analytics.html` |
| `GET` | `/api/analytics/client/month-invoices` | `client_analytics.py` | `Direct SQL / Helper` | `client-month-analytics.html` |
| `GET` | `/api/analytics/client/month-products` | `client_analytics.py` | `Direct SQL / Helper` | `client-month-analytics.html` |
| `GET` | `/api/analytics/client/month-daily` | `client_analytics.py` | `Direct SQL / Helper` | `client-month-analytics.html` |
| `GET` | `/api/clients` | `clients.py` | `get_clients_list, get_active_clients, get_top_clients_80pct` | `client-detail.html`, `index.html` |
| `GET` | `/api/clients/active` | `clients.py` | `get_active_clients, get_top_clients_80pct` | `index.html` |
| `GET` | `/api/clients/top-sales` | `clients.py` | `get_churn_risk_clients, get_top_clients_80pct` | `index.html` |
| `GET` | `/api/clients/churn-risk` | `clients.py` | `get_churn_risk_clients, get_client_detail, get_client_monthly_dynamics, get_client_status_2025, get_client_invoices` | `index.html` |
| `GET` | `/api/clients/detail/{code}` | `clients.py` | `get_client_invoices, get_client_detail, get_client_monthly_dynamics, get_client_status_2025` | — |
| `GET` | `/api/clients/invoices/{code}` | `clients.py` | `get_client_invoices, get_invoice_items, get_invoice_header` | — |
| `GET` | `/api/invoices/{number}/items` | `clients.py` | `get_invoice_items, get_statuses_distribution, get_funnel_data, get_invoice_header` | — |
| `GET` | `/api/statuses` | `clients.py` | `get_statuses_distribution, get_returned_clients_frequency, get_funnel_data` | — |
| `GET` | `/api/funnel` | `clients.py` | `get_returned_clients_frequency, get_funnel_data` | `advanced.html`, `index.html` |
| `GET` | `/api/dashboard` | `dashboard.py` | `get_dashboard_stats` | `index.html` |
| `GET` | `/health` | `dashboard.py` | `Direct SQL / Helper` | — |
| `GET` | `/api/analytics/directions/kpi` | `directions.py` | `get_directions_summary, get_directions_kpi` | `directions-analytics.html` |
| `GET` | `/api/analytics/directions/summary` | `directions.py` | `get_directions_summary, get_directions_monthly_dynamics` | `directions-analytics.html` |
| `GET` | `/api/analytics/directions/monthly` | `directions.py` | `get_directions_monthly_dynamics, get_direction_companies` | `directions-analytics.html` |
| `GET` | `/api/analytics/directions/companies` | `directions.py` | `get_directions_revenue_analytics, get_direction_companies` | `directions-analytics.html` |
| `GET` | `/api/analytics/directions/revenue-analytics` | `directions.py` | `get_directions_invoices_analytics, get_directions_clients_analytics, get_directions_avg_check_analytics, get_directions_revenue_analytics` | `directions-revenue-analytics.html` |
| `GET` | `/api/analytics/directions/clients-analytics` | `directions.py` | `get_directions_leader_analytics, get_directions_invoices_analytics, get_directions_clients_analytics, get_directions_avg_check_analytics` | `directions-clients-analytics.html` |
| `GET` | `/api/analytics/directions/invoices-analytics` | `directions.py` | `get_directions_leader_analytics, get_directions_invoices_analytics, get_directions_avg_check_analytics` | `directions-invoices-analytics.html` |
| `GET` | `/api/analytics/directions/avg-check-analytics` | `directions.py` | `get_directions_leader_analytics, get_directions_avg_check_analytics` | `directions-avg-check-analytics.html` |
| `GET` | `/api/analytics/directions/leader-analytics` | `directions.py` | `get_directions_leader_analytics` | `directions-leader-analytics.html` |
| `GET` | `/api/analytics/inactive-clients-overview` | `inactive_clients.py` | `get_inactive_clients_overview, get_inactive_clients_list` | `inactive-clients-analytics.html` |
| `GET` | `/api/analytics/inactive-clients-list` | `inactive_clients.py` | `get_inactive_clients_list` | `inactive-clients-analytics.html` |
| `GET` | `/api/analytics/inactive-clients-distribution` | `inactive_clients.py` | `get_inactive_clients_abc, get_inactive_clients_distribution` | `inactive-clients-analytics.html` |
| `GET` | `/api/analytics/inactive-clients-abc` | `inactive_clients.py` | `get_inactive_clients_abc` | `inactive-clients-analytics.html` |
| `GET` | `/api/analytics/new-clients-overview` | `new_clients.py` | `get_new_clients_frequency, get_new_clients_overview` | `new-clients-analytics.html` |
| `GET` | `/api/analytics/new-clients-frequency` | `new_clients.py` | `get_new_clients_abc, get_new_clients_abc_compare, get_new_clients_frequency` | `new-clients-analytics.html` |
| `GET` | `/api/analytics/new-clients-abc` | `new_clients.py` | `get_new_clients_abc, get_new_clients_abc_compare` | `new-clients-analytics.html` |
| `GET` | `/api/analytics/new-clients-abc-compare` | `new_clients.py` | `get_new_clients_list, get_new_clients_abc_compare` | `new-clients-analytics.html` |
| `GET` | `/api/analytics/new-clients-list` | `new_clients.py` | `get_new_clients_list` | `new-clients-analytics.html` |
| `GET` | `/` | `pages.py` | `Direct SQL / Helper` | `abc_structure.html`, `advanced.html`, `analytics.html`, `avg-check.html`, `c2-segmentation.html`, `churned-segmentation.html`, `client-avg-check-analytics.html`, `client-detail.html`, `client-invoices-analytics.html`, `client-invoices-month.html`, `client-last-purchase-analytics.html`, `client-month-analytics.html`, `client-revenue-analytics.html`, `comparison.html`, `consolidated-segmentation.html`, `directions-analytics.html`, `directions-avg-check-analytics.html`, `directions-clients-analytics.html`, `directions-invoices-analytics.html`, `directions-leader-analytics.html`, `directions-revenue-analytics.html`, `general-segmentation.html`, `inactive-clients-analytics.html`, `index.html`, `monthly.html`, `new-clients-analytics.html`, `new-clients-segmentation.html`, `product-analytics.html`, `repeat-segmentation.html`, `returned-clients-analytics.html`, `segment-detail.html`, `sleeping-segmentation.html`, `top-sales-analytics.html` |
| `GET` | `/plan` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/db-reference` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/client-detail` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/segment-detail` | `pages.py` | `Direct SQL / Helper` | `segment-detail.html` |
| `GET` | `/general-segmentation` | `pages.py` | `Direct SQL / Helper` | `general-segmentation.html` |
| `GET` | `/repeat-segmentation` | `pages.py` | `Direct SQL / Helper` | `repeat-segmentation.html` |
| `GET` | `/consolidated-segmentation` | `pages.py` | `Direct SQL / Helper` | `consolidated-segmentation.html` |
| `GET` | `/c2-segmentation` | `pages.py` | `Direct SQL / Helper` | `c2-segmentation.html` |
| `GET` | `/new-clients-segmentation` | `pages.py` | `Direct SQL / Helper` | `new-clients-segmentation.html` |
| `GET` | `/churned-segmentation` | `pages.py` | `Direct SQL / Helper` | `churned-segmentation.html` |
| `GET` | `/sleeping-segmentation` | `pages.py` | `Direct SQL / Helper` | `sleeping-segmentation.html` |
| `GET` | `/product-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/product-recommendations` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/analytics` | `pages.py` | `Direct SQL / Helper` | `abc_structure.html`, `advanced.html`, `analytics.html`, `avg-check.html`, `c2-segmentation.html`, `churned-segmentation.html`, `client-avg-check-analytics.html`, `client-invoices-analytics.html`, `client-invoices-month.html`, `client-last-purchase-analytics.html`, `client-month-analytics.html`, `client-revenue-analytics.html`, `comparison.html`, `consolidated-segmentation.html`, `directions-analytics.html`, `directions-avg-check-analytics.html`, `directions-clients-analytics.html`, `directions-invoices-analytics.html`, `directions-leader-analytics.html`, `directions-revenue-analytics.html`, `general-segmentation.html`, `inactive-clients-analytics.html`, `index.html`, `monthly.html`, `new-clients-analytics.html`, `new-clients-segmentation.html`, `product-analytics.html`, `repeat-segmentation.html`, `returned-clients-analytics.html`, `segment-detail.html`, `sleeping-segmentation.html`, `top-sales-analytics.html` |
| `GET` | `/comparison` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/avg-check` | `pages.py` | `Direct SQL / Helper` | `client-avg-check-analytics.html`, `directions-avg-check-analytics.html` |
| `GET` | `/advanced` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/monthly` | `pages.py` | `Direct SQL / Helper` | `advanced.html`, `analytics.html`, `avg-check.html`, `directions-analytics.html`, `index.html`, `monthly.html` |
| `GET` | `/abc-structure` | `pages.py` | `Direct SQL / Helper` | `abc_structure.html` |
| `GET` | `/new-clients-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/returned-clients-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/inactive-clients-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/top-sales-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/client-revenue-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/client-invoices-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/client-avg-check-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/client-last-purchase-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/client-invoices-month` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/client-month-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/directions-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/directions-revenue-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/directions-clients-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/directions-invoices-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/directions-avg-check-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/directions-leader-analytics` | `pages.py` | `Direct SQL / Helper` | — |
| `GET` | `/api/products` | `products.py` | `get_recommendations_block2, get_recommendations_block3, get_recommendations_for_client, get_products_list` | — |
| `GET` | `/api/recommendations/{client_code}` | `products.py` | `get_recommendations_block2, get_recommendations_block4, get_recommendations_for_client, get_recommendations_block3` | — |
| `GET` | `/api/recommendations-by-size/{client_code}` | `products.py` | `get_recommendations_by_size` | — |
| `GET` | `/recommendations-by-size/{client_code}` | `products.py` | `get_recommendations_by_size` | — |
| `GET` | `/api/client-products-by-size/{client_code}` | `products.py` | `get_all_sizes_for_client` | — |
| `GET` | `/client-products-by-size/{client_code}` | `products.py` | `get_all_sizes_for_client` | — |
| `GET` | `/api/client-products-by-size/{client_code}/{size_key}` | `products.py` | `get_products_by_size_for_client` | — |
| `GET` | `/client-products-by-size/{client_code}/{size_key}` | `products.py` | `get_top_recommendations, get_products_by_size_for_client` | — |
| `GET` | `/api/recommendations` | `products.py` | `get_top_recommendations, get_client_products` | `client-detail.html`, `index.html` |
| `GET` | `/api/analytics/client-products/{client_code}` | `products.py` | `get_client_products` | — |
| `GET` | `/api/analytics/client-products-compare/{client_code}` | `products.py` | `get_client_similar_fallback, get_client_similar_sizes, get_client_products_compare, get_client_cross_sell_pipes` | — |
| `GET` | `/api/analytics/client-products-recommendations/{client_code}` | `products.py` | `get_client_similar_fallback, get_client_direction_variety, get_client_similar_sizes, get_client_cross_sell_pipes` | — |
| `GET` | `/api/analytics/returned-clients-overview` | `returned_clients.py` | `get_returned_clients_frequency, get_returned_clients_overview` | `returned-clients-analytics.html` |
| `GET` | `/api/analytics/returned-clients-frequency` | `returned_clients.py` | `get_returned_clients_frequency, get_returned_clients_abc, get_returned_clients_compare_new` | `returned-clients-analytics.html` |
| `GET` | `/api/analytics/returned-clients-abc` | `returned_clients.py` | `get_returned_clients_abc, get_returned_clients_compare_new` | `returned-clients-analytics.html` |
| `GET` | `/api/analytics/returned-clients-compare-new` | `returned_clients.py` | `get_returned_clients_list, get_returned_clients_compare_new` | `returned-clients-analytics.html` |
| `GET` | `/api/analytics/returned-clients-list` | `returned_clients.py` | `get_returned_clients_list` | `returned-clients-analytics.html` |
| `GET` | `/api/analytics/top-sales/overview` | `top_sales.py` | `get_top_sales_kpi, get_top_revenue_core` | — |
| `GET` | `/api/analytics/top-sales/kpi` | `top_sales.py` | `get_top_sales_kpi, get_top_companies` | `top-sales-analytics.html` |
| `GET` | `/api/analytics/top-sales/companies` | `top_sales.py` | `get_top_company_detail, get_top_companies` | `top-sales-analytics.html` |
| `GET` | `/api/analytics/top-sales/company-detail` | `top_sales.py` | `get_top_company_detail, get_top_revenue_core, get_top_companies` | `top-sales-analytics.html` |
| `GET` | `/api/analytics/top-sales/core` | `top_sales.py` | `get_top_compare_yoy, get_top_revenue_core` | `top-sales-analytics.html` |
| `GET` | `/api/analytics/top-sales/compare-yoy` | `top_sales.py` | `get_top_compare_yoy` | `top-sales-analytics.html` |

## 🔍 Детальный разбор по модулям API

### Модуль `backend/app/api/analytics.py`

#### `GET /api/analytics/monthly-revenue`
- **Функция обработчика:** `monthly_revenue(token: str=Query(None)`
- **Вызов в БД:** `get_yoy_comparison, get_monthly_revenue, generate_custom_sales_report`
- **Используется на страницах:** `advanced.html`, `analytics.html`, `avg-check.html`, `index.html`

#### `GET /api/analytics/yoy-comparison`
- **Функция обработчика:** `yoy_comparison(token: str=Query(None)`
- **Вызов в БД:** `get_yoy_comparison, generate_custom_sales_report`
- **Используется на страницах:** `analytics.html`

#### `GET /api/analytics/pivot-report`
- **Функция обработчика:** `pivot_report(token: str=Query(None)`
- **Вызов в БД:** `generate_custom_sales_report`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/analytics/pivot-formatted`
- **Функция обработчика:** `pivot_formatted(token: str=Query(None)`
- **Вызов в БД:** `generate_custom_sales_report, get_abc_groups`
- **Используется на страницах:** `analytics.html`

#### `GET /api/analytics/abc-groups`
- **Функция обработчика:** `abc_groups(token: str=Query(None)`
- **Вызов в БД:** `get_daily_revenue, get_abc_groups, get_monthly_detail_metrics`
- **Используется на страницах:** `analytics.html`

#### `GET /api/analytics/daily-revenue`
- **Функция обработчика:** `daily_revenue(token: str=Query(None)`
- **Вызов в БД:** `get_daily_revenue, get_monthly_detail_metrics`
- **Используется на страницах:** `monthly.html`

#### `GET /api/analytics/monthly-detail`
- **Функция обработчика:** `monthly_detail(token: str=Query(None)`
- **Вызов в БД:** `get_monthly_detail_metrics`
- **Используется на страницах:** `monthly.html`

#### `GET /api/analytics/abc-migration`
- **Функция обработчика:** `abc_migration(token: str=Query(None)`
- **Вызов в БД:** `get_monthly_directions, get_abc_migration, get_zaletnye`
- **Используется на страницах:** `monthly.html`

#### `GET /api/analytics/zaletnye`
- **Функция обработчика:** `zaletnye(token: str=Query(None)`
- **Вызов в БД:** `get_monthly_directions, get_monthly_products, get_zaletnye`
- **Используется на страницах:** `monthly.html`

#### `GET /api/analytics/monthly-directions`
- **Функция обработчика:** `monthly_directions(token: str=Query(None)`
- **Вызов в БД:** `get_monthly_directions, get_monthly_top_clients, get_monthly_products`
- **Используется на страницах:** `monthly.html`

#### `GET /api/analytics/monthly-products`
- **Функция обработчика:** `monthly_products(token: str=Query(None)`
- **Вызов в БД:** `get_yearly_clients_count, get_monthly_top_clients, get_monthly_products`
- **Используется на страницах:** `monthly.html`

#### `GET /api/analytics/monthly-top-clients`
- **Функция обработчика:** `monthly_top_clients(token: str=Query(None)`
- **Вызов в БД:** `generate_custom_sales_report, get_yearly_clients_count, get_monthly_top_clients`
- **Используется на страницах:** `monthly.html`

#### `GET /api/analytics/yearly-clients-count`
- **Функция обработчика:** `yearly_clients_count(token: str=Query(None)`
- **Вызов в БД:** `generate_custom_sales_report, get_yearly_clients_count`
- **Используется на страницах:** `advanced.html`, `analytics.html`, `avg-check.html`, `index.html`

#### `GET /api/analytics/abc-comparison`
- **Функция обработчика:** `abc_comparison(token: str=Query(None)`
- **Вызов в БД:** `get_recurrent_clients`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/analytics/recurrent-clients`
- **Функция обработчика:** `recurrent_clients(token: str=Query(None)`
- **Вызов в БД:** `get_recurrent_clients, get_clients_yoy`
- **Используется на страницах:** `analytics.html`

#### `GET /api/analytics/clients-yoy`
- **Функция обработчика:** `clients_yoy(token: str=Query(None)`
- **Вызов в БД:** `get_clients_yoy`
- **Используется на страницах:** `analytics.html`

#### `GET /api/analytics/segment-comparison`
- **Функция обработчика:** `get_segment_comparison(token: str=Query(None)`
- **Вызов в БД:** `get_rfm_funnel, get_alt_funnel`
- **Используется на страницах:** `advanced.html`, `avg-check.html`, `comparison.html`

#### `GET /api/analytics/abc-structure`
- **Функция обработчика:** `abc_structure(token: str=Query(None)`
- **Вызов в БД:** `get_abc_structure_data`
- **Используется на страницах:** `abc_structure.html`

#### `GET /api/analytics/c2-detail`
- **Функция обработчика:** `abc_segment_detail(token: str=Query(None)`
- **Вызов в БД:** `get_segment_detail`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/analytics/abc-segment-detail`
- **Функция обработчика:** `abc_segment_detail(token: str=Query(None)`
- **Вызов в БД:** `get_segment_detail`
- **Используется на страницах:** `abc_structure.html`

#### `GET /api/analytics/abc-structure-detail`
- **Функция обработчика:** `abc_segment_detail(token: str=Query(None)`
- **Вызов в БД:** `get_segment_detail`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/analytics/abc-groups-detail`
- **Функция обработчика:** `abc_groups_detail(token: str=Query(None)`
- **Вызов в БД:** `get_important_detail, get_abc_groups_detail`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/analytics/important-detail`
- **Функция обработчика:** `important_detail(token: str=Query(None)`
- **Вызов в БД:** `get_important_detail`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/analytics/top-clients`
- **Функция обработчика:** `top_clients(token: str=Query(None)`
- **Вызов в БД:** `get_top_clients_monthly, get_excluded_client_info`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/analytics/segmentation-kpi`
- **Функция обработчика:** `segmentation_kpi(token: str = Query(None)`
- **Вызов в БД:** `get_segmentation_matrix, get_segmentation_special, get_segmentation_kpi`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/analytics/segmentation-special`
- **Функция обработчика:** `segmentation_special(token: str = Query(None)`
- **Вызов в БД:** `get_segmentation_matrix, get_segmentation_special`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/analytics/segmentation-matrix`
- **Функция обработчика:** `segmentation_matrix(token: str = Query(None)`
- **Вызов в БД:** `get_segmentation_matrix`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/analytics/segmentation-matrix-v2`
- **Функция обработчика:** `segmentation_matrix_v2(token: str = Query(None)`
- **Вызов в БД:** `get_segmentation_matrix_v2`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/analytics/segmentation-current-year`
- **Функция обработчика:** `segmentation_current_year(token: str = Query(None)`
- **Вызов в БД:** `get_segmentation_current_year`
- **Используется на страницах:** `analytics.html`

#### `GET /api/analytics/segmentation-past-years`
- **Функция обработчика:** `segmentation_past_years(token: str = Query(None)`
- **Вызов в БД:** `get_segment_detail, get_segmentation_past_years`
- **Используется на страницах:** `analytics.html`

#### `GET /api/analytics/segment-detail`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_segment_detail`
- **Используется на страницах:** `segment-detail.html`

#### `GET /api/analytics/general-segmentation-companies`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_general_segmentation_companies`
- **Используется на страницах:** `general-segmentation.html`

#### `GET /api/analytics/repeat-segmentation-companies`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_repeat_segmentation_companies`
- **Используется на страницах:** `repeat-segmentation.html`

#### `GET /api/analytics/consolidated-segmentation-companies`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_consolidated_segmentation_companies`
- **Используется на страницах:** `consolidated-segmentation.html`

#### `GET /api/analytics/c2-segmentation-companies`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_c2_segmentation_companies, get_c2_top_products`
- **Используется на страницах:** `c2-segmentation.html`

#### `GET /api/analytics/new-clients-segmentation-companies`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_new_clients_monthly_revenue, get_new_clients_segmentation`
- **Используется на страницах:** `new-clients-segmentation.html`

#### `GET /api/analytics/churned-segmentation-companies`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_churned_segmentation`
- **Используется на страницах:** `churned-segmentation.html`

#### `GET /api/analytics/sleeping-segmentation-companies`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_sleeping_segmentation`
- **Используется на страницах:** `sleeping-segmentation.html`

#### `GET /api/analytics/product-categories`
- **Функция обработчика:** `product_categories(token: str = Query(None)`
- **Вызов в БД:** `get_product_categories`
- **Используется на страницах:** `advanced.html`

---

### Модуль `backend/app/api/client_analytics.py`

#### `GET /api/analytics/client/revenue`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `client-revenue-analytics.html`

#### `GET /api/analytics/client/invoices`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `client-invoices-analytics.html`, `client-invoices-month.html`

#### `GET /api/analytics/client/avg-check`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `client-avg-check-analytics.html`

#### `GET /api/analytics/client/last-purchase`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `client-last-purchase-analytics.html`

#### `GET /api/analytics/client/invoices-month`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `client-invoices-month.html`

#### `GET /api/analytics/client/month-summary`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `client-month-analytics.html`

#### `GET /api/analytics/client/month-invoices`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `client-month-analytics.html`

#### `GET /api/analytics/client/month-products`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `client-month-analytics.html`

#### `GET /api/analytics/client/month-daily`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `client-month-analytics.html`

---

### Модуль `backend/app/api/clients.py`

#### `GET /api/clients`
- **Функция обработчика:** `clients(token: str = Query(None)`
- **Вызов в БД:** `get_clients_list, get_active_clients, get_top_clients_80pct`
- **Используется на страницах:** `client-detail.html`, `index.html`

#### `GET /api/clients/active`
- **Функция обработчика:** `active_clients(token: str = Query(None)`
- **Вызов в БД:** `get_active_clients, get_top_clients_80pct`
- **Используется на страницах:** `index.html`

#### `GET /api/clients/top-sales`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_churn_risk_clients, get_top_clients_80pct`
- **Используется на страницах:** `index.html`

#### `GET /api/clients/churn-risk`
- **Функция обработчика:** `churn_risk(token: str = Query(None)`
- **Вызов в БД:** `get_churn_risk_clients, get_client_detail, get_client_monthly_dynamics, get_client_status_2025, get_client_invoices`
- **Используется на страницах:** `index.html`

#### `GET /api/clients/detail/{code}`
- **Функция обработчика:** `get_client_detail(code: str, token: str = Query(None)`
- **Вызов в БД:** `get_client_invoices, get_client_detail, get_client_monthly_dynamics, get_client_status_2025`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/clients/invoices/{code}`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_client_invoices, get_invoice_items, get_invoice_header`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/invoices/{number}/items`
- **Функция обработчика:** `get_invoice_items(number: str, token: str = Query(None)`
- **Вызов в БД:** `get_invoice_items, get_statuses_distribution, get_funnel_data, get_invoice_header`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/statuses`
- **Функция обработчика:** `statuses(token: str = Query(None)`
- **Вызов в БД:** `get_statuses_distribution, get_returned_clients_frequency, get_funnel_data`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/funnel`
- **Функция обработчика:** `funnel(token: str = Query(None)`
- **Вызов в БД:** `get_returned_clients_frequency, get_funnel_data`
- **Используется на страницах:** `advanced.html`, `index.html`

---

### Модуль `backend/app/api/dashboard.py`

#### `GET /api/dashboard`
- **Функция обработчика:** `dashboard(token: str = Query(None)`
- **Вызов в БД:** `get_dashboard_stats`
- **Используется на страницах:** `index.html`

#### `GET /health`
- **Функция обработчика:** `health(db: Session = Depends(get_db)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

---

### Модуль `backend/app/api/directions.py`

#### `GET /api/analytics/directions/kpi`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_directions_summary, get_directions_kpi`
- **Используется на страницах:** `directions-analytics.html`
- **⚠️ Известный баг:** Поле `total_clients` возвращает 748 вместо эталонных 729 активных клиентов.

#### `GET /api/analytics/directions/summary`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_directions_summary, get_directions_monthly_dynamics`
- **Используется на страницах:** `directions-analytics.html`

#### `GET /api/analytics/directions/monthly`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_directions_monthly_dynamics, get_direction_companies`
- **Используется на страницах:** `directions-analytics.html`

#### `GET /api/analytics/directions/companies`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_directions_revenue_analytics, get_direction_companies`
- **Используется на страницах:** `directions-analytics.html`
- **⚠️ Рефакторинг:** На главной странице `directions-analytics.html` этот эндпоинт создает лишний блок «Компании отрасли». Переносится на страницу `/direction-detail`.

#### `GET /api/analytics/directions/revenue-analytics`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_directions_invoices_analytics, get_directions_clients_analytics, get_directions_avg_check_analytics, get_directions_revenue_analytics`
- **Используется на страницах:** `directions-revenue-analytics.html`

#### `GET /api/analytics/directions/clients-analytics`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_directions_leader_analytics, get_directions_invoices_analytics, get_directions_clients_analytics, get_directions_avg_check_analytics`
- **Используется на страницах:** `directions-clients-analytics.html`

#### `GET /api/analytics/directions/invoices-analytics`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_directions_leader_analytics, get_directions_invoices_analytics, get_directions_avg_check_analytics`
- **Используется на страницах:** `directions-invoices-analytics.html`

#### `GET /api/analytics/directions/avg-check-analytics`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_directions_leader_analytics, get_directions_avg_check_analytics`
- **Используется на страницах:** `directions-avg-check-analytics.html`

#### `GET /api/analytics/directions/leader-analytics`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_directions_leader_analytics`
- **Используется на страницах:** `directions-leader-analytics.html`

---

### Модуль `backend/app/api/inactive_clients.py`

#### `GET /api/analytics/inactive-clients-overview`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_inactive_clients_overview, get_inactive_clients_list`
- **Используется на страницах:** `inactive-clients-analytics.html`

#### `GET /api/analytics/inactive-clients-list`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_inactive_clients_list`
- **Используется на страницах:** `inactive-clients-analytics.html`

#### `GET /api/analytics/inactive-clients-distribution`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_inactive_clients_abc, get_inactive_clients_distribution`
- **Используется на страницах:** `inactive-clients-analytics.html`

#### `GET /api/analytics/inactive-clients-abc`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_inactive_clients_abc`
- **Используется на страницах:** `inactive-clients-analytics.html`

---

### Модуль `backend/app/api/new_clients.py`

#### `GET /api/analytics/new-clients-overview`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_new_clients_frequency, get_new_clients_overview`
- **Используется на страницах:** `new-clients-analytics.html`

#### `GET /api/analytics/new-clients-frequency`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_new_clients_abc, get_new_clients_abc_compare, get_new_clients_frequency`
- **Используется на страницах:** `new-clients-analytics.html`

#### `GET /api/analytics/new-clients-abc`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_new_clients_abc, get_new_clients_abc_compare`
- **Используется на страницах:** `new-clients-analytics.html`

#### `GET /api/analytics/new-clients-abc-compare`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_new_clients_list, get_new_clients_abc_compare`
- **Используется на страницах:** `new-clients-analytics.html`

#### `GET /api/analytics/new-clients-list`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_new_clients_list`
- **Используется на страницах:** `new-clients-analytics.html`

---

### Модуль `backend/app/api/pages.py`

#### `GET /`
- **Функция обработчика:** `index(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `abc_structure.html`, `advanced.html`, `analytics.html`, `avg-check.html`, `c2-segmentation.html`, `churned-segmentation.html`, `client-avg-check-analytics.html`, `client-detail.html`, `client-invoices-analytics.html`, `client-invoices-month.html`, `client-last-purchase-analytics.html`, `client-month-analytics.html`, `client-revenue-analytics.html`, `comparison.html`, `consolidated-segmentation.html`, `directions-analytics.html`, `directions-avg-check-analytics.html`, `directions-clients-analytics.html`, `directions-invoices-analytics.html`, `directions-leader-analytics.html`, `directions-revenue-analytics.html`, `general-segmentation.html`, `inactive-clients-analytics.html`, `index.html`, `monthly.html`, `new-clients-analytics.html`, `new-clients-segmentation.html`, `product-analytics.html`, `repeat-segmentation.html`, `returned-clients-analytics.html`, `segment-detail.html`, `sleeping-segmentation.html`, `top-sales-analytics.html`

#### `GET /plan`
- **Функция обработчика:** `plan_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /db-reference`
- **Функция обработчика:** `db_reference_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /client-detail`
- **Функция обработчика:** `client_detail_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /segment-detail`
- **Функция обработчика:** `segment_detail_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `segment-detail.html`

#### `GET /general-segmentation`
- **Функция обработчика:** `general_segmentation_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `general-segmentation.html`

#### `GET /repeat-segmentation`
- **Функция обработчика:** `repeat_segmentation_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `repeat-segmentation.html`

#### `GET /consolidated-segmentation`
- **Функция обработчика:** `consolidated_segmentation_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `consolidated-segmentation.html`

#### `GET /c2-segmentation`
- **Функция обработчика:** `c2_segmentation_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `c2-segmentation.html`

#### `GET /new-clients-segmentation`
- **Функция обработчика:** `new_clients_segmentation_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `new-clients-segmentation.html`

#### `GET /churned-segmentation`
- **Функция обработчика:** `churned_segmentation_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `churned-segmentation.html`

#### `GET /sleeping-segmentation`
- **Функция обработчика:** `sleeping_segmentation_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `sleeping-segmentation.html`

#### `GET /product-analytics`
- **Функция обработчика:** `product_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /product-recommendations`
- **Функция обработчика:** `product_recommendations_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /analytics`
- **Функция обработчика:** `analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `abc_structure.html`, `advanced.html`, `analytics.html`, `avg-check.html`, `c2-segmentation.html`, `churned-segmentation.html`, `client-avg-check-analytics.html`, `client-invoices-analytics.html`, `client-invoices-month.html`, `client-last-purchase-analytics.html`, `client-month-analytics.html`, `client-revenue-analytics.html`, `comparison.html`, `consolidated-segmentation.html`, `directions-analytics.html`, `directions-avg-check-analytics.html`, `directions-clients-analytics.html`, `directions-invoices-analytics.html`, `directions-leader-analytics.html`, `directions-revenue-analytics.html`, `general-segmentation.html`, `inactive-clients-analytics.html`, `index.html`, `monthly.html`, `new-clients-analytics.html`, `new-clients-segmentation.html`, `product-analytics.html`, `repeat-segmentation.html`, `returned-clients-analytics.html`, `segment-detail.html`, `sleeping-segmentation.html`, `top-sales-analytics.html`

#### `GET /comparison`
- **Функция обработчика:** `comparison_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /avg-check`
- **Функция обработчика:** `avg_check_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `client-avg-check-analytics.html`, `directions-avg-check-analytics.html`

#### `GET /advanced`
- **Функция обработчика:** `advanced_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /monthly`
- **Функция обработчика:** `monthly_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `advanced.html`, `analytics.html`, `avg-check.html`, `directions-analytics.html`, `index.html`, `monthly.html`

#### `GET /abc-structure`
- **Функция обработчика:** `abc_structure_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** `abc_structure.html`

#### `GET /new-clients-analytics`
- **Функция обработчика:** `new_clients_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /returned-clients-analytics`
- **Функция обработчика:** `returned_clients_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /inactive-clients-analytics`
- **Функция обработчика:** `inactive_clients_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /top-sales-analytics`
- **Функция обработчика:** `top_sales_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /client-revenue-analytics`
- **Функция обработчика:** `client_revenue_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /client-invoices-analytics`
- **Функция обработчика:** `client_invoices_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /client-avg-check-analytics`
- **Функция обработчика:** `client_avg_check_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /client-last-purchase-analytics`
- **Функция обработчика:** `client_last_purchase_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /client-invoices-month`
- **Функция обработчика:** `client_invoices_month_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /client-month-analytics`
- **Функция обработчика:** `client_month_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /directions-analytics`
- **Функция обработчика:** `directions_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /directions-revenue-analytics`
- **Функция обработчика:** `directions_revenue_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /directions-clients-analytics`
- **Функция обработчика:** `directions_clients_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /directions-invoices-analytics`
- **Функция обработчика:** `directions_invoices_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /directions-avg-check-analytics`
- **Функция обработчика:** `directions_avg_check_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /directions-leader-analytics`
- **Функция обработчика:** `directions_leader_analytics_page(request: Request, token: str = Query(None)`
- **Вызов в БД:** `Direct SQL / Helper`
- **Используется на страницах:** вызов динамический или внутренний

---

### Модуль `backend/app/api/products.py`

#### `GET /api/products`
- **Функция обработчика:** `products(token: str = Query(None)`
- **Вызов в БД:** `get_recommendations_block2, get_recommendations_block3, get_recommendations_for_client, get_products_list`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/recommendations/{client_code}`
- **Функция обработчика:** `recommendations_for_client(client_code: str, token: str = Query(None)`
- **Вызов в БД:** `get_recommendations_block2, get_recommendations_block4, get_recommendations_for_client, get_recommendations_block3`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/recommendations-by-size/{client_code}`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_recommendations_by_size`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /recommendations-by-size/{client_code}`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_recommendations_by_size`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/client-products-by-size/{client_code}`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_all_sizes_for_client`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /client-products-by-size/{client_code}`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_all_sizes_for_client`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/client-products-by-size/{client_code}/{size_key}`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_products_by_size_for_client`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /client-products-by-size/{client_code}/{size_key}`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_top_recommendations, get_products_by_size_for_client`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/recommendations`
- **Функция обработчика:** `top_recommendations(token: str = Query(None)`
- **Вызов в БД:** `get_top_recommendations, get_client_products`
- **Используется на страницах:** `client-detail.html`, `index.html`

#### `GET /api/analytics/client-products/{client_code}`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_client_products`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/analytics/client-products-compare/{client_code}`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_client_similar_fallback, get_client_similar_sizes, get_client_products_compare, get_client_cross_sell_pipes`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/analytics/client-products-recommendations/{client_code}`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_client_similar_fallback, get_client_direction_variety, get_client_similar_sizes, get_client_cross_sell_pipes`
- **Используется на страницах:** вызов динамический или внутренний

---

### Модуль `backend/app/api/returned_clients.py`

#### `GET /api/analytics/returned-clients-overview`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_returned_clients_frequency, get_returned_clients_overview`
- **Используется на страницах:** `returned-clients-analytics.html`

#### `GET /api/analytics/returned-clients-frequency`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_returned_clients_frequency, get_returned_clients_abc, get_returned_clients_compare_new`
- **Используется на страницах:** `returned-clients-analytics.html`

#### `GET /api/analytics/returned-clients-abc`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_returned_clients_abc, get_returned_clients_compare_new`
- **Используется на страницах:** `returned-clients-analytics.html`

#### `GET /api/analytics/returned-clients-compare-new`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_returned_clients_list, get_returned_clients_compare_new`
- **Используется на страницах:** `returned-clients-analytics.html`

#### `GET /api/analytics/returned-clients-list`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_returned_clients_list`
- **Используется на страницах:** `returned-clients-analytics.html`

---

### Модуль `backend/app/api/top_sales.py`

#### `GET /api/analytics/top-sales/overview`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_top_sales_kpi, get_top_revenue_core`
- **Используется на страницах:** вызов динамический или внутренний

#### `GET /api/analytics/top-sales/kpi`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_top_sales_kpi, get_top_companies`
- **Используется на страницах:** `top-sales-analytics.html`

#### `GET /api/analytics/top-sales/companies`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_top_company_detail, get_top_companies`
- **Используется на страницах:** `top-sales-analytics.html`

#### `GET /api/analytics/top-sales/company-detail`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_top_company_detail, get_top_revenue_core, get_top_companies`
- **Используется на страницах:** `top-sales-analytics.html`

#### `GET /api/analytics/top-sales/core`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_top_compare_yoy, get_top_revenue_core`
- **Используется на страницах:** `top-sales-analytics.html`

#### `GET /api/analytics/top-sales/compare-yoy`
- **Функция обработчика:** `unknown()`
- **Вызов в БД:** `get_top_compare_yoy`
- **Используется на страницах:** `top-sales-analytics.html`

---

