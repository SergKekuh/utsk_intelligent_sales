# 📊 ОТЧЁТ: Все запросы и API платформы UTSK Intelligent Sales
**Дата:** 07 сентября 2026 г.  
**Проект:** UTSK Intelligent Sales  
**Статус:** Завершён (Полный аудит REST API бэкенда, fetch-запросов фронтенда и объектов PostgreSQL)  

---

## 🌐 ВВЕДЕНИЕ И АРХИТЕКТУРНЫЙ КОНТЕКСТ

Настоящий отчёт представляет собой исчерпывающий технический реестр всех точек сопряжения между фронтендом, бэкендом и базой данных PostgreSQL аналитической платформы **UTSK Intelligent Sales**.

Взаимодействие компонентов платформы организовано по трехуровневой схеме:
1. **Frontend (`static/*.html`):** 30 страниц, выполняющих асинхронные HTTP-запросы `fetch()` к REST API бэкенда;
2. **Backend (`app/api/*.py`):** 10 модульных роутеров FastAPI, реализующих 83 валидированных эндпоинта с проверкой авторизационного токена;
3. **Database (`PostgreSQL / bd_intelligent_sales`):** 105 хранимых процедур и функций, 4 оптимизированных представления и 9 триггеров целостности данных.

---

## 1. REST API ЭНДПОИНТЫ БЭКЕНДА (83 шт)

Все эндпоинты бэкенда распределены по **9 специализированным функциональным модулям** в директории `utsk_web/backend/app/api/`.

### 1.1. Распределение эндпоинтов по модулям бэкенда

| # | Модуль роутера | Файл модуля | Кол-во эндпоинтов | Основное назначение |
|:---:|:---|:---|:---:|:---|
| 1 | `analytics` | `api/analytics.py` | **38** | Расчет ABC-структуры, PIVOT-отчетов, матриц сегментации, когорт YoY |
| 2 | `client_analytics` | `api/client_analytics.py` | **9** | Углубленная микро-аналитика клиента (выручка, чеки, накладные, дни) |
| 3 | `clients` | `api/clients.py` | **9** | Реестры клиентов, воронка частоты, риск оттока, карточка клиента |
| 4 | `top_sales` | `api/top_sales.py` | **6** | Рейтинг лидеров продаж, 7 срезов ТОП (1, 5, 10, 25, 50, 70, 80%) |
| 5 | `products` | `api/products.py` | **6** | Каталог номенклатуры металлопроката, товарные корзины, ML-рекомендации |
| 6 | `new_clients` | `api/new_clients.py` | **5** | Когортный анализ впервые привлеченных клиентов и частоты покупок |
| 7 | `returned_clients` | `api/returned_clients.py` | **5** | Анализ реактивированных клиентов, вернувшихся после простоя |
| 8 | `inactive_clients` | `api/inactive_clients.py` | **4** | Аналитика базы оттока (спящие и ушедшие клиенты, давность потерь) |
| 9 | `dashboard` | `api/dashboard.py` | **1** | Сводные агрегированные KPI компании для верхнеуровневого экрана |
| **ИТОГО** | **9 модулей** | — | **83** | **Полный REST API слой платформы** |

### 1.2. Полный реестр всех 83 REST API эндпоинтов

| # | Метод | URL эндпоинта | Роутер / Функция | Параметры | Описание и назначение |
|:---:|:---:|:---|:---|:---|:---|
| 1 | `GET` | `/api/analytics/abc-comparison` | `analytics.abc_comparison` | `token, year, multiplier, limit_price` | Сравнительный срез структуры ABC-категорий между смежными годами |
| 2 | `GET` | `/api/analytics/abc-groups` | `analytics.abc_groups` | `token, year, multiplier` | Расчет групп A, B, C с настраиваемыми границами мультипликатора и лимита |
| 3 | `GET` | `/api/analytics/abc-groups-detail` | `analytics.abc_groups_detail` | `token, year, multiplier, limit_price` | Анализ распределения клиентской базы внутри групп A1, A2, B1, B2, C1, C2 |
| 4 | `GET` | `/api/analytics/abc-migration` | `analytics.abc_migration` | `token, year, groups, multiplier` | Матрица миграции клиентов между ABC-классами от месяца к месяцу |
| 5 | `GET` | `/api/analytics/abc-segment-detail` | `analytics.abc_segment_detail` | `token, segment, year, multiplier, limit_price, active_only` | Глубокая расшифровка параметров конкретного сегмента ABC-структуры |
| 6 | `GET` | `/api/analytics/abc-structure` | `analytics.abc_structure` | `token, year, multiplier, limit_price, active_only` | Агрегированные данные структурного ABC-анализа по 4-м секциям (Лайт/Премиум/Все/VIP) |
| 7 | `GET` | `/api/analytics/abc-structure-detail` | `analytics.abc_segment_detail` | `token, segment, year, multiplier, limit_price, active_only` | Детализация строк и когорт структурного ABC-отчета |
| 8 | `GET` | `/api/analytics/c2-detail` | `analytics.abc_segment_detail` | `token, segment, year, multiplier, limit_price, active_only` | Детализированная структура мелких клиентов группы C2 (< 146 тыс. ₴) |
| 9 | `GET` | `/api/analytics/c2-segmentation-companies` | `analytics.c2_segmentation_companies` | `token, year, limit_price, limit_tonnage, filter_mode` | Реестр мелких клиентов категории Лайт (C2) для программ доращивания |
| 10 | `GET` | `/api/analytics/churned-segmentation-companies` | `analytics.churned_segmentation_companies` | `token, year` | Реестр ушедших клиентов ('Вибули') с оценкой упущенной выгоды |
| 11 | `GET` | `/api/analytics/clients-yoy` | `analytics.clients_yoy` | `token, year, multiplier` | Годовая матрица удержания и оттока клиентской базы (YoY динамика когорт) |
| 12 | `GET` | `/api/analytics/consolidated-segmentation-companies` | `analytics.consolidated_segmentation_companies` | `token, year` | Консолидированный реестр всех активных компаний клиентской базы |
| 13 | `GET` | `/api/analytics/daily-revenue` | `analytics.daily_revenue` | `token, year, month` | Посуточная динамика выручки за выбранный календарный месяц |
| 14 | `GET` | `/api/analytics/general-segmentation-companies` | `analytics.general_segmentation_companies` | `token, year` | Полный реестр компаний общей частотной сегментации с пагинацией |
| 15 | `GET` | `/api/analytics/important-detail` | `analytics.important_detail` | `token, year, multiplier, limit_price` | Анализ пула критически важных (VIP) клиентов платформы |
| 16 | `GET` | `/api/analytics/monthly-detail` | `analytics.monthly_detail` | `token, year, month` | Детальные KPI выбранного месяца (выручка, чеки, накладные, план/факт) |
| 17 | `GET` | `/api/analytics/monthly-directions` | `analytics.monthly_directions` | `token, year, month` | Распределение продаж месяца по отраслевым направлениям металлопроката |
| 18 | `GET` | `/api/analytics/monthly-products` | `analytics.monthly_products` | `token, year, month, limit` | Рейтинг наиболее продаваемых товарных позиций за выбранный месяц |
| 19 | `GET` | `/api/analytics/monthly-revenue` | `analytics.monthly_revenue` | `token, year` | Помесячная товарная выручка компании за выбранный год с разбивкой по месяцам |
| 20 | `GET` | `/api/analytics/monthly-top-clients` | `analytics.monthly_top_clients` | `token, year, month, limit, multiplier` | Топ-10 компаний-лидеров по объему закупок в выбранном месяце |
| 21 | `GET` | `/api/analytics/new-clients-segmentation-companies` | `analytics.new_clients_segmentation_companies` | `token, year` | Реестр 152 новых клиентов с распределением по частоте сделок |
| 22 | `GET` | `/api/analytics/pivot-formatted` | `analytics.pivot_formatted` | `token, year, multiplier, limit_price` | Форматированная матрица ABC PIVOT-отчета с суммами, накладными и средними чеками |
| 23 | `GET` | `/api/analytics/pivot-report` | `analytics.pivot_report` | `token, year, multiplier, limit_price, direction` | Сырые данные сводного PIVOT-отчета ABC-сегментации |
| 24 | `GET` | `/api/analytics/recurrent-clients` | `analytics.recurrent_clients` | `token, year, multiplier` | Аналитика повторных покупок: удержание, когорты и цикл возврата клиентов |
| 25 | `GET` | `/api/analytics/repeat-segmentation-companies` | `analytics.repeat_segmentation_companies` | `token, year` | Реестр 174 компаний ядра повторных покупок с детализацией сделок |
| 26 | `GET` | `/api/analytics/segment-comparison` | `analytics.get_segment_comparison` | `token, year_current, year_previous` | Матричное сравнение частотных сегментов между периодами |
| 27 | `GET` | `/api/analytics/segment-detail` | `analytics.segment_detail` | `token, year, segment, table, category, limit_price` | Параметрическая выборка списка компаний выбранного сегмента |
| 28 | `GET` | `/api/analytics/segmentation-current-year` | `analytics.segmentation_current_year` | `token, year, limit_price` | Таблица 1 Загальної сегментації: частотные когорты текущего года |
| 29 | `GET` | `/api/analytics/segmentation-kpi` | `analytics.segmentation_kpi` | `token, year, limit_price` | Сводные индикаторы качества сегментации (доля ядра, средние чеки, отток) |
| 30 | `GET` | `/api/analytics/segmentation-matrix` | `analytics.segmentation_matrix` | `token, year, limit_price` | Матрица взаимного распределения RFM/ABC сегментов |
| 31 | `GET` | `/api/analytics/segmentation-matrix-v2` | `analytics.segmentation_matrix_v2` | `token, year, limit_price` | Оптимизированная версия матрицы сегментации с расширенными метриками |
| 32 | `GET` | `/api/analytics/segmentation-past-years` | `analytics.segmentation_past_years` | `token, year` | Сравнительные когорты сегментации за предыдущие отчетные годы |
| 33 | `GET` | `/api/analytics/segmentation-special` | `analytics.segmentation_special` | `token, year, limit_price` | Специализированные аналитические срезы клиентской сегментации |
| 34 | `GET` | `/api/analytics/sleeping-segmentation-companies` | `analytics.sleeping_segmentation_companies` | `token, year` | Реестр спящих клиентов ('Сплячі') для запуска реактивационных цепочек |
| 35 | `GET` | `/api/analytics/top-clients` | `analytics.top_clients` | `token, year, month, limit, exclude_client` | Рейтинг крупнейших клиентов компании по выручке с долями рынка |
| 36 | `GET` | `/api/analytics/yearly-clients-count` | `analytics.yearly_clients_count` | `token, year` | Количество уникальных покупателей по годам для оценки динамики базы |
| 37 | `GET` | `/api/analytics/yoy-comparison` | `analytics.yoy_comparison` | `token, year1, year2` | Честное сопоставление выручки YoY (год к году) по месяцам с расчетом дельты % |
| 38 | `GET` | `/api/analytics/zaletnye` | `analytics.zaletnye` | `token, year, multiplier` | Анализ разовых нетипичных покупателей ('залётные' клиенты) за месяц |
| 39 | `GET` | `/api/analytics/client/avg-check` | `client_analytics.get_client_avg_check_analytics_api` | `code, year, token` | Аналитика динамики среднего чека конкретного клиента по месяцам |
| 40 | `GET` | `/api/analytics/client/invoices` | `client_analytics.get_client_invoices_analytics_api` | `code, year, token` | Помесячная динамика количества накладных и товарных позиций клиента |
| 41 | `GET` | `/api/analytics/client/invoices-month` | `client_analytics.get_client_invoices_by_month_api` | `code, year, month, token` | Список накладных клиента за конкретный выбранный календарный месяц |
| 42 | `GET` | `/api/analytics/client/last-purchase` | `client_analytics.get_client_last_purchase_analytics_api` | `code, token` | Анализ давности последней отгрузки, расчет риска оттока клиента |
| 43 | `GET` | `/api/analytics/client/month-daily` | `client_analytics.get_client_month_daily_api` | `code, year, month, token` | Посуточный график закупок клиента на протяжении выбранного месяца |
| 44 | `GET` | `/api/analytics/client/month-invoices` | `client_analytics.get_client_month_invoices_api` | `code, year, month, token` | Реестр накладных клиента за выбранный месяц с суммами |
| 45 | `GET` | `/api/analytics/client/month-products` | `client_analytics.get_client_month_products_api` | `code, year, month, token` | Товарные позиции металлопроката, приобретенные клиентом за месяц |
| 46 | `GET` | `/api/analytics/client/month-summary` | `client_analytics.get_client_month_summary_api` | `code, year, month, token` | Сводные метрики активности клиента в выбранном месяце |
| 47 | `GET` | `/api/analytics/client/revenue` | `client_analytics.get_client_revenue_analytics_api` | `code, year, token` | Помесячная декомпозиция выручки клиента: 2026 vs 2025 с темпами прироста |
| 48 | `GET` | `/api/clients` | `clients.clients` | `token, limit, search` | Полнотекстовый поиск и постраничный реестр клиентов с фильтрацией по активности |
| 49 | `GET` | `/api/clients/active` | `clients.active_clients` | `token, limit` | Список топ-активных клиентов с наибольшей частотой сделок за последние 30 дней |
| 50 | `GET` | `/api/clients/churn-risk` | `clients.churn_risk` | `token, limit` | Список компаний в зоне риска оттока на основе превышения межзакупочного интервала |
| 51 | `GET` | `/api/clients/detail/{code}` | `clients.get_client_detail` | `code, token, year` | Полная карточка клиента 360°: профиль, статусы 2025/2026, KPI, помесячная динамика |
| 52 | `GET` | `/api/clients/invoices/{code}` | `clients.get_client_invoices` | `code, token, year, month, date_from, date_to, limit` | Реестр расходных накладных клиента с фильтрацией по годам, месяцам и датам |
| 53 | `GET` | `/api/clients/top-sales` | `clients.get_top_clients_sales` | `token, year, date_from, date_to` | Выборка ключевых клиентов по правилу 80% выручки (Парето) с кумулятивными долями |
| 54 | `GET` | `/api/funnel` | `clients.funnel` | `token, year` | Воронка продаж: распределение базы по частотным когортам (1 покупка, 2, 3..10, 11+ сделок) |
| 55 | `GET` | `/api/invoices/{number}/items` | `clients.get_invoice_items` | `number, token` | Спецификация товаров в накладной: артикул, наименование, количество, вес (кг), цена, сумма |
| 56 | `GET` | `/api/statuses` | `clients.statuses` | `token` | Распределение клиентской базы по аналитическим статусам активности |
| 57 | `GET` | `/api/dashboard` | `dashboard.dashboard` | `token` | Сводные KPI компании за текущий и прошлый год: выручка, накладные, активные клиенты, средний чек |
| 58 | `GET` | `/api/analytics/inactive-clients-abc` | `inactive_clients.inactive_clients_abc` | `token, status_id, year_prev` | Историческая ABC-структура потерь в сегменте неактивной базы |
| 59 | `GET` | `/api/analytics/inactive-clients-distribution` | `inactive_clients.inactive_clients_distribution` | `token, status_id` | Распределение клиентов по временным интервалам неактивности |
| 60 | `GET` | `/api/analytics/inactive-clients-list` | `inactive_clients.inactive_clients_list` | `token, status_id, search, abc_group, days_min, days_max, limit, offset` | Реестр неактивных клиентов с фильтрами по длительности простоя |
| 61 | `GET` | `/api/analytics/inactive-clients-overview` | `inactive_clients.inactive_clients_overview` | `token, year` | Общий объем потерь от спящих и ушедших клиентов компании |
| 62 | `GET` | `/api/analytics/new-clients-abc` | `new_clients.new_clients_abc` | `token, year, multiplier` | ABC-структура выручки внутри когорты новых клиентов |
| 63 | `GET` | `/api/analytics/new-clients-abc-compare` | `new_clients.new_clients_abc_compare` | `token, year, multiplier` | Сопоставление пропорций ABC новых клиентов с пропорциями всей базы |
| 64 | `GET` | `/api/analytics/new-clients-frequency` | `new_clients.new_clients_frequency` | `token, year` | Распределение новых клиентов по числу совершенных покупок |
| 65 | `GET` | `/api/analytics/new-clients-list` | `new_clients.new_clients_list` | `token, year, search, abc_group, limit, offset` | Постраничный список новых клиентов с контактами и датами первого чека |
| 66 | `GET` | `/api/analytics/new-clients-overview` | `new_clients.new_clients_overview` | `token, year` | Сводные макро-показатели когорты новых клиентов за год |
| 67 | `GET` | `/api/analytics/client-products-compare/{client_code}` | `products.client_products_compare` | `client_code, token` | Сравнение закупленной номенклатуры клиента между 2026 и 2025 годами |
| 68 | `GET` | `/api/analytics/client-products-recommendations/{client_code}` | `products.client_products_recommendations` | `client_code, token` | ML-рекомендации продукции для клиента с учетом остатков и истории покупок |
| 69 | `GET` | `/api/analytics/client-products/{client_code}` | `products.client_products_analytics` | `client_code, token, year` | Товарный портфель клиента: структура закупленного металлопроката по категориям |
| 70 | `GET` | `/api/products` | `products.products` | `token, limit, search` | Каталог номенклатуры металлопроката с агрегированными объемами продаж и остатками |
| 71 | `GET` | `/api/recommendations` | `products.top_recommendations` | `token, limit` | Топ наиболее востребованных рекомендаций кросс-продаж по всей компании |
| 72 | `GET` | `/api/recommendations/{client_code}` | `products.recommendations_for_client` | `client_code, token` | Персонализированные ML-рекомендации допродаж товаров для конкретного клиента |
| 73 | `GET` | `/api/analytics/returned-clients-abc` | `returned_clients.returned_clients_abc` | `token, year` | ABC-ранжирование выручки вернувшихся клиентов |
| 74 | `GET` | `/api/analytics/returned-clients-compare-new` | `returned_clients.returned_clients_compare_new` | `token, year` | Сравнительный анализ когорт вернувшихся и впервые привлеченных клиентов |
| 75 | `GET` | `/api/analytics/returned-clients-frequency` | `returned_clients.returned_clients_frequency` | `token, year` | Частота сделок вернувшихся клиентов после периода неактивности |
| 76 | `GET` | `/api/analytics/returned-clients-list` | `returned_clients.returned_clients_list` | `token, year, search, abc_group, limit, offset` | Постраничный реестр реактивированных компаний с историей оттока |
| 77 | `GET` | `/api/analytics/returned-clients-overview` | `returned_clients.returned_clients_overview` | `token, year` | Сводные показатели вернувшихся (реактивированных) клиентов за год |
| 78 | `GET` | `/api/analytics/top-sales/companies` | `top_sales.get_top_companies_api` | `token, year, limit` | Списки компаний для каждого эшелона ТОП-рейтинга продаж |
| 79 | `GET` | `/api/analytics/top-sales/company-detail` | `top_sales.get_top_company_detail_api` | `token, code, year` | Углубленный профиль лидера продаж с динамикой и ТОП-товарами |
| 80 | `GET` | `/api/analytics/top-sales/compare-yoy` | `top_sales.get_top_compare_yoy_api` | `token, year, limit` | Темпы роста выручки крупнейших клиентов в сравнении с прошлым годом |
| 81 | `GET` | `/api/analytics/top-sales/core` | `top_sales.get_top_revenue_core_api` | `token, year, pct` | Анализ ядра выручки компании (клиенты, формирующие 80% оборота) |
| 82 | `GET` | `/api/analytics/top-sales/kpi` | `top_sales.get_top_sales_kpi_api` | `token, year` | Контрольные точки (чекпоинты) долей выручки ТОП-1, 5, 10, 25, 50%, 70%, 80% |
| 83 | `GET` | `/api/analytics/top-sales/overview` | `top_sales.get_top_sales_overview_api` | `token, year` | Сводные индикаторы концентрации продаж в ТОП-клиентах |

---

## 2. FETCH-ЗАПРОСЫ ФРОНТЕНДА (107 вызовов)

Анализ клиентского кода выявил **107 точек инициализации вызовов `fetch()`** на 27 HTML-страницах (3 служебные страницы `db_reference.html`, `plan.html`, `product-recommendations.html` не инициируют AJAX-запросов).

### 2.1. Сводная таблица всех 107 вызовов fetch() по страницам

| # | Страница фронтенда | Строка | URL / Шаблон запроса | Метод | Назначение запроса на странице |
|:---:|:---|:---:|:---|:---:|:---|
| 1 | `abc_structure.html` | L611 | `/api/analytics/abc-structure` | `GET` | Загрузка сводной картины 4-х секций структурного ABC-анализа |
| 2 | `abc_structure.html` | L619 | `/api/analytics/abc-segment-detail` | `GET` | Детализация вкладок структурного ABC-анализа (Лайт, Премиум, VIP) |
| 3 | `advanced.html` | L329 | `/api/analytics/monthly-revenue` | `GET` | Построение графиков ежемесячной динамики выручки компании |
| 4 | `advanced.html` | L330 | `/api/analytics/monthly-revenue` | `GET` | Построение графиков ежемесячной динамики выручки компании |
| 5 | `advanced.html` | L331 | `/api/funnel` | `GET` | Рендеринг визуализатора частотной воронки продаж |
| 6 | `advanced.html` | L341 | `/api/analytics/yearly-clients-count` | `GET` | Отображение динамики количества активных покупателей по годам |
| 7 | `advanced.html` | L436 | `/api/analytics/monthly-revenue` | `GET` | Построение графиков ежемесячной динамики выручки компании |
| 8 | `advanced.html` | L437 | `/api/analytics/monthly-revenue` | `GET` | Построение графиков ежемесячной динамики выручки компании |
| 9 | `advanced.html` | L523 | `/api/analytics/segment-comparison` | `GET` | Матричное сравнение объемов и чеков сегментов между годами |
| 10 | `advanced.html` | L605 | `/api/analytics/monthly-revenue` | `GET` | Построение графиков ежемесячной динамики выручки компании |
| 11 | `analytics.html` | L2655 | `/api/analytics/monthly-revenue` | `GET` | Построение графиков ежемесячной динамики выручки компании |
| 12 | `analytics.html` | L2798 | `/api/analytics/yoy-comparison` | `GET` | Построение графика и таблицы честного YoY сравнения 2026 vs 2025 |
| 13 | `analytics.html` | L2801 | `/api/analytics/monthly-revenue` | `GET` | Построение графиков ежемесячной динамики выручки компании |
| 14 | `analytics.html` | L2803 | `/api/analytics/monthly-revenue` | `GET` | Построение графиков ежемесячной динамики выручки компании |
| 15 | `analytics.html` | L2893 | `/api/analytics/clients-yoy` | `GET` | Рендеринг годовой матрицы движения и удержания клиентских когорт |
| 16 | `analytics.html` | L2932 | `/api/analytics/abc-groups` | `GET` | Расчет и визуализация распределения групп A, B, C с фильтрами |
| 17 | `analytics.html` | L2968 | `/api/analytics/abc-groups` | `GET` | Расчет и визуализация распределения групп A, B, C с фильтрами |
| 18 | `analytics.html` | L2969 | `/api/analytics/abc-groups` | `GET` | Расчет и визуализация распределения групп A, B, C с фильтрами |
| 19 | `analytics.html` | L3034 | `/api/analytics/pivot-formatted` | `GET` | Отображение форматированного PIVOT-отчета ABC-сегментации |
| 20 | `analytics.html` | L3043 | `/api/analytics/yoy-comparison` | `GET` | Построение графика и таблицы честного YoY сравнения 2026 vs 2025 |
| 21 | `analytics.html` | L3267 | `/api/analytics/yearly-clients-count` | `GET` | Отображение динамики количества активных покупателей по годам |
| 22 | `analytics.html` | L3279 | `/api/analytics/monthly-revenue` | `GET` | Построение графиков ежемесячной динамики выручки компании |
| 23 | `analytics.html` | L3298 | `/api/analytics/yoy-comparison` | `GET` | Построение графика и таблицы честного YoY сравнения 2026 vs 2025 |
| 24 | `analytics.html` | L3370 | `/api/analytics/pivot-formatted` | `GET` | Отображение форматированного PIVOT-отчета ABC-сегментации |
| 25 | `analytics.html` | L3434 | `/api/analytics/recurrent-clients` | `GET` | Построение аналитики повторных закупок и стабильности базы |
| 26 | `analytics.html` | L3539 | `/api/analytics/clients-yoy` | `GET` | Рендеринг годовой матрицы движения и удержания клиентских когорт |
| 27 | `analytics.html` | L3751 | `/api/analytics/segmentation-current-year` | `GET` | Рендеринг Таблицы 1 общей сегментации за текущий год |
| 28 | `analytics.html` | L3752 | `/api/analytics/segmentation-past-years` | `GET` | Сравнение структуры сегментации с прошлыми годами |
| 29 | `avg-check.html` | L356 | `/api/analytics/monthly-revenue` | `GET` | Построение графиков ежемесячной динамики выручки компании |
| 30 | `avg-check.html` | L357 | `/api/analytics/monthly-revenue` | `GET` | Построение графиков ежемесячной динамики выручки компании |
| 31 | `avg-check.html` | L358 | `/api/analytics/yearly-clients-count` | `GET` | Отображение динамики количества активных покупателей по годам |
| 32 | `avg-check.html` | L359 | `/api/analytics/segment-comparison` | `GET` | Матричное сравнение объемов и чеков сегментов между годами |
| 33 | `c2-segmentation.html` | L873 | `/api/analytics/c2-segmentation-companies` | `GET` | Загрузка реестра мелких клиентов категории Лайт (C2) |
| 34 | `churned-segmentation.html` | L880 | `/api/analytics/churned-segmentation-companies` | `GET` | Загрузка реестра клиентов в оттоке ('Вибули') |
| 35 | `client-avg-check-analytics.html` | L357 | `/api/analytics/client/avg-check` | `GET` | Аналитика среднего чека клиента по месяцам |
| 36 | `client-detail.html` | L713 | `/api/clients/detail/${CLIENT_CODE}` | `GET` | Загрузка профиля клиента 360°, статусов и годовой динамики |
| 37 | `client-detail.html` | L857 | `/api/clients/invoices/${CLIENT_CODE}` | `GET` | Загрузка таблицы расходных накладных клиента с фильтрами дат |
| 38 | `client-detail.html` | L913 | `/api/invoices/${encodeURIComponent(invoiceNumber)}/items` | `GET` | Открытие модального окна состава товаров накладной |
| 39 | `client-detail.html` | L965 | `/api/recommendations/${CLIENT_CODE}` | `GET` | Отображение товарных рекомендаций в карточке клиента |
| 40 | `client-invoices-analytics.html` | L387 | `/api/analytics/client/invoices` | `GET` | Помесячная динамика накладных и позиций конкретного клиента |
| 41 | `client-invoices-month.html` | L336 | `/api/analytics/client/invoices-month` | `GET` | Реестр накладных клиента за конкретный месяц |
| 42 | `client-invoices-month.html` | L388 | `/api/client/${CLIENT_CODE}/invoice/${docId}` | `GET` | Устаревший/немаршрутизируемый вызов спецификации накладной (404) |
| 43 | `client-last-purchase-analytics.html` | L330 | `/api/analytics/client/last-purchase` | `GET` | Анализ последней покупки и оценка давности оттока |
| 44 | `client-month-analytics.html` | L476 | `/api/analytics/client/month-summary` | `GET` | Сводные показатели клиента за конкретный месяц |
| 45 | `client-month-analytics.html` | L536 | `/api/analytics/client/month-daily` | `GET` | График посуточных отгрузок клиенту в выбранном месяце |
| 46 | `client-month-analytics.html` | L569 | `/api/analytics/client/month-invoices` | `GET` | Таблица накладных клиента за выбранный месяц |
| 47 | `client-month-analytics.html` | L602 | `/api/analytics/client/month-products` | `GET` | Товарная корзина клиента за выбранный месяц |
| 48 | `client-month-analytics.html` | L639 | `/api/client/${CLIENT_CODE}/invoice/${docId}` | `GET` | Устаревший/немаршрутизируемый вызов спецификации накладной (404) |
| 49 | `client-revenue-analytics.html` | L381 | `/api/analytics/client/revenue` | `GET` | Помесячный график и таблица выручки клиента 2026 vs 2025 |
| 50 | `comparison.html` | L431 | `/api/analytics/segment-comparison` | `GET` | Матричное сравнение объемов и чеков сегментов между годами |
| 51 | `consolidated-segmentation.html` | L909 | `/api/analytics/consolidated-segmentation-companies` | `GET` | Загрузка консолидированного реестра всей клиентской базы |
| 52 | `general-segmentation.html` | L954 | `/api/analytics/general-segmentation-companies` | `GET` | Загрузка таблицы общей сегментации клиентской базы |
| 53 | `inactive-clients-analytics.html` | L514 | `/api/analytics/inactive-clients-overview` | `GET` | Сводка объемов спящей и ушедшей клиентской базы |
| 54 | `inactive-clients-analytics.html` | L515 | `/api/analytics/inactive-clients-distribution` | `GET` | Распределение неактивных компаний по длительности паузы |
| 55 | `inactive-clients-analytics.html` | L516 | `/api/analytics/inactive-clients-distribution` | `GET` | Распределение неактивных компаний по длительности паузы |
| 56 | `inactive-clients-analytics.html` | L517 | `/api/analytics/inactive-clients-abc` | `GET` | ABC-структура потерь в неактивном сегменте |
| 57 | `inactive-clients-analytics.html` | L518 | `/api/analytics/inactive-clients-abc` | `GET` | ABC-структура потерь в неактивном сегменте |
| 58 | `inactive-clients-analytics.html` | L646 | `/api/analytics/inactive-clients-list` | `GET` | Таблица неактивных клиентов для работы менеджеров |
| 59 | `inactive-clients-analytics.html` | L697 | `/api/analytics/inactive-clients-list` | `GET` | Таблица неактивных клиентов для работы менеджеров |
| 60 | `index.html` | L840 | `/api/dashboard` | `GET` | Загрузка макро-KPI для главной страницы (выручка, клиенты, средний чек) |
| 61 | `index.html` | L846 | `/api/analytics/yearly-clients-count` | `GET` | Отображение динамики количества активных покупателей по годам |
| 62 | `index.html` | L847 | `/api/analytics/monthly-revenue` | `GET` | Построение графиков ежемесячной динамики выручки компании |
| 63 | `index.html` | L878 | `/api/clients/top-sales` | `GET` | Отображение ключевых клиентов ядра 80% на дашборде |
| 64 | `index.html` | L977 | `/api/clients/active` | `GET` | Загрузка топ-активных клиентов для виджета мониторинга |
| 65 | `index.html` | L1007 | `/api/funnel` | `GET` | Рендеринг визуализатора частотной воронки продаж |
| 66 | `index.html` | L1333 | `/api/clients/churn-risk` | `GET` | Отображение списка клиентов в зоне риска оттока |
| 67 | `index.html` | L1368 | `/api/clients` | `GET` | Постраничная загрузка реестра клиентов и поисковая выдача |
| 68 | `index.html` | L1406 | `/api/recommendations/${clientCode}` | `GET` | Загрузка персонализированных ML-рекомендаций для клиента |
| 69 | `index.html` | L1561 | `/api/clients` | `GET` | Постраничная загрузка реестра клиентов и поисковая выдача |
| 70 | `index.html` | L1655 | `/api/clients` | `GET` | Постраничная загрузка реестра клиентов и поисковая выдача |
| 71 | `monthly.html` | L581 | `/api/analytics/daily-revenue` | `GET` | График посуточных отгрузок выбранного месяца |
| 72 | `monthly.html` | L615 | `/api/analytics/monthly-detail` | `GET` | Сводные индикаторы и план/факт выбранного месяца |
| 73 | `monthly.html` | L665 | `/api/analytics/abc-migration` | `GET` | Матрица миграции клиентов между ABC-группами по месяцам |
| 74 | `monthly.html` | L685 | `/api/analytics/zaletnye` | `GET` | Таблица разовых нетипичных клиентов ('залётные') месяца |
| 75 | `monthly.html` | L700 | `/api/analytics/monthly-directions` | `GET` | Диаграмма распределения продаж по отраслевым направлениям |
| 76 | `monthly.html` | L701 | `/api/analytics/monthly-products` | `GET` | Рейтинг топ-продуктов металлопроката за месяц |
| 77 | `monthly.html` | L724 | `/api/analytics/monthly-top-clients` | `GET` | Таблица топ-10 клиентов месяца по сумме закупок |
| 78 | `new-clients-analytics.html` | L507 | `/api/analytics/new-clients-overview` | `GET` | Сводные KPI и карточки прироста новых клиентов за год |
| 79 | `new-clients-analytics.html` | L508 | `/api/analytics/new-clients-frequency` | `GET` | Гистограмма частоты покупок среди новых клиентов |
| 80 | `new-clients-analytics.html` | L509 | `/api/analytics/new-clients-abc` | `GET` | ABC-распределение выручки в когорте новых клиентов |
| 81 | `new-clients-analytics.html` | L510 | `/api/analytics/new-clients-abc-compare` | `GET` | Сравнение долей ABC новых клиентов со структурой всей базы |
| 82 | `new-clients-analytics.html` | L511 | `/api/analytics/new-clients-list` | `GET` | Таблица новых клиентов с фильтрацией и переходом в карточку |
| 83 | `new-clients-analytics.html` | L754 | `/api/analytics/new-clients-list` | `GET` | Таблица новых клиентов с фильтрацией и переходом в карточку |
| 84 | `new-clients-segmentation.html` | L909 | `/api/analytics/new-clients-segmentation-companies` | `GET` | Загрузка реестра новых клиентов по частотным когортам |
| 85 | `product-analytics.html` | L563 | `/api/analytics/client-products/${CLIENT_CODE}` | `GET` | Портфель закупленной продукции клиента по видам проката |
| 86 | `product-analytics.html` | L564 | `/api/analytics/client-products-compare/${CLIENT_CODE}` | `GET` | Сравнение структуры номенклатуры 2026 vs 2025 |
| 87 | `product-analytics.html` | L565 | `/api/analytics/client-products-recommendations/${CLIENT_CODE}` | `GET` | ML-рекомендации сопутствующего металлопроката |
| 88 | `repeat-segmentation.html` | L923 | `/api/analytics/repeat-segmentation-companies` | `GET` | Загрузка реестра 174 компаний с повторными покупками |
| 89 | `returned-clients-analytics.html` | L488 | `/api/analytics/returned-clients-overview` | `GET` | Сводные KPI реактивированных (вернувшихся) клиентов |
| 90 | `returned-clients-analytics.html` | L489 | `/api/analytics/returned-clients-frequency` | `GET` | Частотное распределение вернувшихся покупателей |
| 91 | `returned-clients-analytics.html` | L490 | `/api/analytics/returned-clients-abc` | `GET` | ABC-анализ вернувшихся клиентов |
| 92 | `returned-clients-analytics.html` | L491 | `/api/analytics/returned-clients-compare-new` | `GET` | Сопоставление динамики вернувшихся клиентов с новыми |
| 93 | `returned-clients-analytics.html` | L492 | `/api/analytics/returned-clients-list` | `GET` | Таблица вернувшихся клиентов с историей сделок |
| 94 | `returned-clients-analytics.html` | L790 | `/api/analytics/returned-clients-list` | `GET` | Таблица вернувшихся клиентов с историей сделок |
| 95 | `segment-detail.html` | L523 | `/api/analytics/segment-detail` | `GET` | Универсальная загрузка компаний выбранного сегмента матрицы |
| 96 | `sleeping-segmentation.html` | L887 | `/api/analytics/sleeping-segmentation-companies` | `GET` | Загрузка реестра спящих клиентов для реактивации |
| 97 | `top-sales-analytics.html` | L1267 | `/api/analytics/top-sales/kpi` | `GET` | Загрузка чекпоинтов и макро-долей выручки лидеров продаж |
| 98 | `top-sales-analytics.html` | L1281 | `/api/analytics/top-sales/company-detail` | `GET` | Карточка и товары компании-лидера рейтинга продаж |
| 99 | `top-sales-analytics.html` | L1370 | `/api/analytics/top-sales/companies` | `GET` | Таблицы компаний для вкладок ТОП-1, 5, 10, 25, 50, 70, 80% |
| 100 | `top-sales-analytics.html` | L1426 | `/api/analytics/top-sales/kpi` | `GET` | Загрузка чекпоинтов и макро-долей выручки лидеров продаж |
| 101 | `top-sales-analytics.html` | L1443 | `/api/analytics/top-sales/companies` | `GET` | Таблицы компаний для вкладок ТОП-1, 5, 10, 25, 50, 70, 80% |
| 102 | `top-sales-analytics.html` | L1444 | `/api/analytics/top-sales/compare-yoy` | `GET` | Сравнение выручки крупнейших клиентов с прошлым годом |
| 103 | `top-sales-analytics.html` | L1502 | `/api/analytics/top-sales/companies` | `GET` | Таблицы компаний для вкладок ТОП-1, 5, 10, 25, 50, 70, 80% |
| 104 | `top-sales-analytics.html` | L1549 | `/api/analytics/top-sales/kpi` | `GET` | Загрузка чекпоинтов и макро-долей выручки лидеров продаж |
| 105 | `top-sales-analytics.html` | L1565 | `/api/analytics/top-sales/core` | `GET` | Аналитика Парето-ядра 80% выручки |
| 106 | `top-sales-analytics.html` | L1616 | `/api/analytics/top-sales/core` | `GET` | Аналитика Парето-ядра 80% выручки |
| 107 | `top-sales-analytics.html` | L1667 | `/api/analytics/top-sales/core` | `GET` | Аналитика Парето-ядра 80% выручки |

### 2.2. Аналитические выводы по сопряжению фронтенда и бэкенда

1. **Уникальные эндпоинты фронтенда:** Из 83 эндпоинтов бэкенда непосредственно через пользовательский интерфейс 27 страниц фронтенда вызываются **45 уникальных эндпоинтов**;
2. **Сервисный и экспортный пул API (38 эндпоинтов):** Остальные эндпоинты бэкенда служат для параметрических фильтров, экспорта таблиц, альтернативных матриц сегментации (`segmentation-matrix-v2`, `c2-detail`, `abc-groups-detail`) и глубоких микросервисных срезов;
3. **⚠️ Архитектурная аномалия / Немаршрутизируемый URL:**
   - На страницах `client-invoices-month.html` (L388) и `client-month-analytics.html` (L639) обнаружен вызов:
     `fetch('/api/client/${CLIENT_CODE}/invoice/${docId}?token=${TOKEN}')`
   - В роутерах FastAPI данный маршрут отсутствует, так как спецификация накладной реализована через эндпоинт:
     `/api/invoices/{number}/items`
   - Это приводит к ошибке 404 при попытке открыть товарный состав накладной из этих двух вспомогательных страниц. Рекомендуется унифицировать клиентский вызов с `client-detail.html`, где используется корректный `/api/invoices/${number}/items`.

---

## 3. ФУНКЦИИ POSTGRESQL (105 шт)

В схеме `public` базы данных `bd_intelligent_sales` зарегистрировано **105 функций и процедур**.
Из них:
- **96 функций** — специализированные аналитические процедуры выборки данных (`get_%`), напрямую питающие REST API;
- **9 функций** — системные триггеры, процедуры логирования статусов, парсеры и пакетные калькуляторы активности.

### 3.1. Группировка функций по бизнес-доменам

| Доменная группа | Кол-во функций | Ключевые процедуры |
|:---|:---:|:---|
| **ABC-анализ, PIVOT и матричная сегментация** | **29** | `generate_custom_sales_report`, `get_abc_groups`, `get_segmentation_matrix`, `get_c2_segmentation_companies` |
| **Клиенты и жизненный цикл (Новые, Вернувшиеся, Отток)** | **18** | `get_new_clients_overview`, `get_returned_clients_list`, `get_inactive_clients_distribution`, `get_churn_risk_clients` |
| **Помесячная и посуточная динамика продаж** | **13** | `get_monthly_revenue`, `get_yoy_comparison`, `get_daily_revenue`, `get_zaletnye`, `get_monthly_directions` |
| **Клиентская микро-аналитика 360° и KPI** | **13** | `get_client_detail`, `get_client_revenue_analytics`, `get_client_avg_check_analytics`, `get_client_last_purchase_analytics` |
| **Товарный портфель и ML-рекомендации** | **13** | `get_products_list`, `get_client_products`, `get_recommendations_for_client`, `get_client_cross_sell_pipes` |
| **ТОП продажи и Парето-ядро (80/20)** | **7** | `get_top_clients_80pct`, `get_top_companies`, `get_top_revenue_core`, `get_top_sales_kpi`, `get_top_company_detail` |
| **Накладные и спецификации документов** | **6** | `get_client_invoices`, `get_invoice_header`, `get_invoice_items`, `get_client_invoices_by_month` |
| **Системные, триггерные и сервисные функции** | **6** | `log_status_change`, `trg_update_client_activity`, `update_updated_at_column`, `parse_pipe_attributes` |
| **ИТОГО** | **105** | **Полный каталог функций PostgreSQL схемы public** |

### 3.2. Полный реестр всех 105 функций PostgreSQL

| # | Имя функции | Аргументы функции | Возвращаемый тип | Назначение и бизнес-роль |
|:---:|:---|:---|:---|:---|
| 1 | `calculate_client_status` | `p_client_code character varying` | `integer` | Микро-аналитика профиля и метрик конкретного клиента |
| 2 | `calculate_client_year_activity` | `p_year integer, p_client_code character varying DEFAULT NULL::character varying` | `void` | Микро-аналитика профиля и метрик конкретного клиента |
| 3 | `generate_custom_sales_report` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000, p_direction character varying DEFAULT 'below'::character varying` | `TABLE(out_group_name character varying, out_metric charac...` | Системная аналитическая процедура БД |
| 4 | `get_abc_group_for_revenue` | `p_revenue numeric` | `character varying` | Анализ ABC-структуры, расчет порогов и группировок |
| 5 | `get_abc_groups` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9` | `TABLE(out_group_name character varying, out_total_sales n...` | Анализ ABC-структуры, расчет порогов и группировок |
| 6 | `get_abc_groups_detail` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000` | `TABLE(abc_group text, companies bigint, invoices bigint, ...` | Анализ ABC-структуры, расчет порогов и группировок |
| 7 | `get_abc_migration` | `p_year integer DEFAULT 2026, p_groups text[] DEFAULT ARRAY['A1'::text, 'A2'::text, 'B1'::text, 'B2'::text], p_multiplier numeric DEFAULT 2.9` | `TABLE(group_prev text, companies_count bigint, goods_reve...` | Анализ ABC-структуры, расчет порогов и группировок |
| 8 | `get_abc_segmentation` | `p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer` | `TABLE(out_group_name text, out_total_sales numeric, out_t...` | Анализ ABC-структуры, расчет порогов и группировок |
| 9 | `get_abc_segmentation` | `p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer, p_multiplier numeric DEFAULT 1.0` | `TABLE(out_group_name text, out_total_sales numeric, out_t...` | Анализ ABC-структуры, расчет порогов и группировок |
| 10 | `get_abc_structure_data` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000` | `TABLE(out_direction text, out_group_name character varyin...` | Анализ ABC-структуры, расчет порогов и группировок |
| 11 | `get_active_clients` | `p_limit integer DEFAULT 20` | `TABLE(code character varying, name character varying, sta...` | Микро-аналитика профиля и метрик конкретного клиента |
| 12 | `get_alt_funnel` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000` | `TABLE(group_key text, companies bigint, sales numeric, av...` | Системная аналитическая процедура БД |
| 13 | `get_c2_detail` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000` | `TABLE(client_code character varying, invoices_count bigin...` | Анализ ABC-структуры, расчет порогов и группировок |
| 14 | `get_c2_segmentation_companies` | `p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000, p_limit_tonnage numeric DEFAULT 2.0` | `TABLE(code character varying, name character varying, inv...` | Анализ ABC-структуры, расчет порогов и группировок |
| 15 | `get_c2_top_products` | `p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000` | `TABLE(product_code character varying, product_name charac...` | Анализ ABC-структуры, расчет порогов и группировок |
| 16 | `get_churn_risk_clients` | `p_limit integer DEFAULT 20` | `TABLE(code character varying, name character varying, sta...` | Аналитика оттока, спящих клиентов и интервалов паузы |
| 17 | `get_churned_segmentation` | `p_year integer DEFAULT 2026` | `TABLE(code character varying, name character varying, inv...` | Аналитика оттока, спящих клиентов и интервалов паузы |
| 18 | `get_client_avg_check_analytics` | `p_code character varying, p_year integer DEFAULT 2026` | `json` | Микро-аналитика профиля и метрик конкретного клиента |
| 19 | `get_client_cross_sell_pipes` | `p_client_code character varying` | `TABLE(product_code character varying, product_name charac...` | Товарная номенклатура, скоринг и алгоритмы ML-рекомендаций |
| 20 | `get_client_detail` | `p_code text, p_year integer DEFAULT 2026` | `TABLE(code character varying, name character varying, sta...` | Микро-аналитика профиля и метрик конкретного клиента |
| 21 | `get_client_direction_variety` | `p_client_code character varying` | `TABLE(product_code character varying, product_name charac...` | Микро-аналитика профиля и метрик конкретного клиента |
| 22 | `get_client_invoices` | `p_code text, p_year integer DEFAULT 2026, p_month_int integer DEFAULT NULL::integer, p_date_from date DEFAULT NULL::date, p_date_to date DEFAULT NULL::date, p_limit integer DEFAULT 500` | `TABLE(date text, number character varying, total numeric,...` | Выборка накладных и построчной спецификации товаров |
| 23 | `get_client_invoices_analytics` | `p_code character varying, p_year integer DEFAULT 2026` | `json` | Выборка накладных и построчной спецификации товаров |
| 24 | `get_client_invoices_by_month` | `p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1` | `json` | Выборка накладных и построчной спецификации товаров |
| 25 | `get_client_last_purchase_analytics` | `p_code character varying` | `json` | Микро-аналитика профиля и метрик конкретного клиента |
| 26 | `get_client_month_daily` | `p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1` | `json` | Помесячные, посуточные тренды выручки и темпы прироста |
| 27 | `get_client_month_invoices` | `p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1` | `json` | Выборка накладных и построчной спецификации товаров |
| 28 | `get_client_month_products` | `p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1` | `json` | Товарная номенклатура, скоринг и алгоритмы ML-рекомендаций |
| 29 | `get_client_month_summary` | `p_code character varying, p_year integer DEFAULT 2026, p_month integer DEFAULT 1` | `json` | Микро-аналитика профиля и метрик конкретного клиента |
| 30 | `get_client_monthly_dynamics` | `p_code text, p_year integer DEFAULT 2026, p_year_prev integer DEFAULT 2025` | `TABLE(month integer, revenue_current numeric, revenue_pre...` | Помесячные, посуточные тренды выручки и темпы прироста |
| 31 | `get_client_products` | `p_code text, p_year integer DEFAULT 2026` | `TABLE(product_code character varying, product_name charac...` | Товарная номенклатура, скоринг и алгоритмы ML-рекомендаций |
| 32 | `get_client_products_compare` | `p_code text` | `TABLE(product_code character varying, product_name charac...` | Товарная номенклатура, скоринг и алгоритмы ML-рекомендаций |
| 33 | `get_client_revenue_analytics` | `p_code character varying, p_year integer DEFAULT 2026` | `json` | Микро-аналитика профиля и метрик конкретного клиента |
| 34 | `get_client_revenue_deep_analytics` | `p_code character varying, p_year integer DEFAULT 2026` | `json` | Микро-аналитика профиля и метрик конкретного клиента |
| 35 | `get_client_similar_fallback` | `p_client_code character varying` | `TABLE(product_code character varying, product_name charac...` | Микро-аналитика профиля и метрик конкретного клиента |
| 36 | `get_client_similar_sizes` | `p_client_code character varying` | `TABLE(product_code character varying, product_name charac...` | Микро-аналитика профиля и метрик конкретного клиента |
| 37 | `get_client_status_2025` | `p_code text, p_year_prev integer DEFAULT 2025` | `TABLE(status_2025 text)` | Микро-аналитика профиля и метрик конкретного клиента |
| 38 | `get_clients_list` | `p_limit integer DEFAULT 50, p_search text DEFAULT ''::text` | `TABLE(code character varying, name character varying, sta...` | Микро-аналитика профиля и метрик конкретного клиента |
| 39 | `get_clients_yoy` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9` | `TABLE(client_code character varying, client_name characte...` | Помесячные, посуточные тренды выручки и темпы прироста |
| 40 | `get_consolidated_segmentation_companies` | `p_year integer DEFAULT 2026` | `TABLE(code character varying, name character varying, inv...` | Системная аналитическая процедура БД |
| 41 | `get_daily_revenue` | `p_year integer, p_month integer` | `TABLE(day integer, active_clients bigint, invoice_count b...` | Помесячные, посуточные тренды выручки и темпы прироста |
| 42 | `get_dashboard_stats` | `—` | `TABLE(total_clients bigint, active_30d bigint, active_90d...` | Системная аналитическая процедура БД |
| 43 | `get_excluded_client_info` | `p_year integer, p_month integer, p_exclude_client text` | `TABLE(client_code character varying, client_name characte...` | Микро-аналитика профиля и метрик конкретного клиента |
| 44 | `get_funnel_data` | `p_year integer DEFAULT 2026` | `TABLE(stage text, sort_order integer, count bigint, reven...` | Системная аналитическая процедура БД |
| 45 | `get_general_segmentation_companies` | `p_year integer DEFAULT 2026` | `TABLE(code character varying, name character varying, inv...` | Системная аналитическая процедура БД |
| 46 | `get_important_detail` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000` | `TABLE(client_code character varying, client_name characte...` | Системная аналитическая процедура БД |
| 47 | `get_inactive_clients_abc` | `p_status_id integer DEFAULT 8, p_year_prev integer DEFAULT 2025` | `TABLE(abc_group text, count bigint, revenue numeric, pct ...` | Анализ ABC-структуры, расчет порогов и группировок |
| 48 | `get_inactive_clients_distribution` | `p_status_id integer DEFAULT 8` | `TABLE(range_label text, count bigint)` | Аналитика оттока, спящих клиентов и интервалов паузы |
| 49 | `get_inactive_clients_list` | `p_status_id integer DEFAULT 8, p_year_prev integer DEFAULT 2025, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text, p_days_min integer DEFAULT NULL::integer, p_days_max integer DEFAULT NULL::integer, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0` | `TABLE(code character varying, name character varying, doc...` | Аналитика оттока, спящих клиентов и интервалов паузы |
| 50 | `get_inactive_clients_overview` | `p_year integer DEFAULT 2026` | `TABLE(sleeping_count bigint, churned_count bigint, total_...` | Аналитика оттока, спящих клиентов и интервалов паузы |
| 51 | `get_invoice_header` | `p_number character varying` | `TABLE(date text, number character varying, total numeric)` | Выборка накладных и построчной спецификации товаров |
| 52 | `get_invoice_items` | `p_number text` | `TABLE(code character varying, name character varying, qua...` | Выборка накладных и построчной спецификации товаров |
| 53 | `get_monthly_detail_metrics` | `p_year integer, p_month integer` | `TABLE(active_clients bigint, invoice_count bigint, goods_...` | Помесячные, посуточные тренды выручки и темпы прироста |
| 54 | `get_monthly_directions` | `p_year integer, p_month integer` | `TABLE(direction_name text, companies_count bigint, invoic...` | Помесячные, посуточные тренды выручки и темпы прироста |
| 55 | `get_monthly_products` | `p_year integer, p_month integer, p_limit integer DEFAULT 10` | `TABLE(product_code character varying, product_name charac...` | Помесячные, посуточные тренды выручки и темпы прироста |
| 56 | `get_monthly_revenue` | `p_year integer DEFAULT 2026` | `TABLE(year integer, month integer, month_name text, activ...` | Помесячные, посуточные тренды выручки и темпы прироста |
| 57 | `get_monthly_top_clients` | `p_year integer, p_month integer, p_year_prev integer DEFAULT 2025, p_mult numeric DEFAULT 2.9, p_limit integer DEFAULT 10` | `TABLE(client_name character varying, group_prev text, inv...` | Выборка лидеров продаж и расчет кумулятивных долей ядра 80% |
| 58 | `get_new_clients_abc` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9` | `TABLE(abc_group text, count bigint, revenue numeric, pct ...` | Анализ ABC-структуры, расчет порогов и группировок |
| 59 | `get_new_clients_abc_compare` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9` | `TABLE(abc_group text, new_count bigint, new_revenue numer...` | Анализ ABC-структуры, расчет порогов и группировок |
| 60 | `get_new_clients_frequency` | `p_year integer DEFAULT 2026` | `TABLE(frequency_group text, sort_order integer, new_count...` | Метрики и списки впервые привлеченных клиентов |
| 61 | `get_new_clients_list` | `p_year integer DEFAULT 2026, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0` | `TABLE(code character varying, name character varying, doc...` | Метрики и списки впервые привлеченных клиентов |
| 62 | `get_new_clients_monthly_revenue` | `p_year integer DEFAULT 2026` | `TABLE(month_num integer, revenue numeric, invoices_count ...` | Метрики и списки впервые привлеченных клиентов |
| 63 | `get_new_clients_overview` | `p_year integer DEFAULT 2026` | `TABLE(total_new bigint, total_revenue numeric, avg_revenu...` | Метрики и списки впервые привлеченных клиентов |
| 64 | `get_new_clients_segmentation` | `p_year integer DEFAULT 2026` | `TABLE(code character varying, name character varying, inv...` | Метрики и списки впервые привлеченных клиентов |
| 65 | `get_products_list` | `p_limit integer DEFAULT 50, p_search text DEFAULT ''::text` | `TABLE(code character varying, name character varying, in_...` | Товарная номенклатура, скоринг и алгоритмы ML-рекомендаций |
| 66 | `get_recommendations_block2` | `p_direction_id integer, p_client_code text` | `TABLE(code character varying, name character varying, rea...` | Товарная номенклатура, скоринг и алгоритмы ML-рекомендаций |
| 67 | `get_recommendations_block3` | `p_client_code text` | `TABLE(code character varying, name character varying, rea...` | Товарная номенклатура, скоринг и алгоритмы ML-рекомендаций |
| 68 | `get_recommendations_block4` | `p_client_code text` | `TABLE(code character varying, name character varying, rea...` | Товарная номенклатура, скоринг и алгоритмы ML-рекомендаций |
| 69 | `get_recommendations_fallback` | `—` | `TABLE(code character varying, name character varying, rea...` | Товарная номенклатура, скоринг и алгоритмы ML-рекомендаций |
| 70 | `get_recommendations_for_client` | `p_client_code text` | `TABLE(code character varying, name character varying, in_...` | Товарная номенклатура, скоринг и алгоритмы ML-рекомендаций |
| 71 | `get_recurrent_clients` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9` | `TABLE(client_code character varying, name character varyi...` | Микро-аналитика профиля и метрик конкретного клиента |
| 72 | `get_repeat_segmentation_companies` | `p_year integer DEFAULT 2026` | `TABLE(code character varying, name character varying, inv...` | Системная аналитическая процедура БД |
| 73 | `get_returned_clients_abc` | `p_year integer DEFAULT 2026` | `TABLE(abc_group text, count bigint, revenue numeric, pct ...` | Анализ ABC-структуры, расчет порогов и группировок |
| 74 | `get_returned_clients_compare_new` | `p_year integer DEFAULT 2026` | `TABLE(frequency_group text, sort_order integer, returned_...` | Аналитика вернувшихся (реактивированных) клиентов |
| 75 | `get_returned_clients_frequency` | `p_year integer DEFAULT 2026` | `TABLE(frequency_group text, sort_order integer, returned_...` | Аналитика вернувшихся (реактивированных) клиентов |
| 76 | `get_returned_clients_list` | `p_year integer DEFAULT 2026, p_search text DEFAULT NULL::text, p_abc_group text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0` | `TABLE(code character varying, name character varying, doc...` | Аналитика вернувшихся (реактивированных) клиентов |
| 77 | `get_returned_clients_overview` | `p_year integer DEFAULT 2026` | `TABLE(total_returned bigint, total_revenue numeric, total...` | Аналитика вернувшихся (реактивированных) клиентов |
| 78 | `get_rfm_funnel` | `p_year integer DEFAULT 2026` | `TABLE(rfm_group text, companies bigint, invoices bigint, ...` | Системная аналитическая процедура БД |
| 79 | `get_segment_detail` | `p_year integer DEFAULT 2026, p_segment character varying DEFAULT 'raz'::character varying, p_table character varying DEFAULT 'general'::character varying, p_limit_price numeric DEFAULT 146000` | `TABLE(code character varying, name character varying, cur...` | Системная аналитическая процедура БД |
| 80 | `get_segment_detail` | `p_segment text DEFAULT 'abc'::text, p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9, p_limit_price numeric DEFAULT 146000` | `TABLE(client_code character varying, invoices_count bigin...` | Системная аналитическая процедура БД |
| 81 | `get_segmentation_current_year` | `p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000` | `TABLE(sort_order integer, freq_group character varying, f...` | Системная аналитическая процедура БД |
| 82 | `get_segmentation_kpi` | `p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000` | `TABLE(total_clients bigint, repeat_loyal_clients bigint, ...` | Системная аналитическая процедура БД |
| 83 | `get_segmentation_matrix` | `p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000` | `TABLE(section character varying, row_key character varyin...` | Системная аналитическая процедура БД |
| 84 | `get_segmentation_matrix_v2` | `p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000` | `TABLE(freq_group character varying, total_clients integer...` | Системная аналитическая процедура БД |
| 85 | `get_segmentation_past_years` | `p_year integer DEFAULT 2026` | `TABLE(sort_order integer, freq_group character varying, f...` | Системная аналитическая процедура БД |
| 86 | `get_segmentation_special` | `p_year integer DEFAULT 2026, p_limit_price numeric DEFAULT 146000` | `TABLE(segment_code character varying, segment_name charac...` | Системная аналитическая процедура БД |
| 87 | `get_sleeping_segmentation` | `p_year integer DEFAULT 2026` | `TABLE(code character varying, name character varying, inv...` | Системная аналитическая процедура БД |
| 88 | `get_statuses_distribution` | `—` | `TABLE(status_name character varying, count bigint)` | Системная аналитическая процедура БД |
| 89 | `get_top_clients_80pct` | `p_year integer DEFAULT 2026, p_date_from date DEFAULT NULL::date, p_date_to date DEFAULT NULL::date` | `TABLE(code character varying, name character varying, sta...` | Выборка лидеров продаж и расчет кумулятивных долей ядра 80% |
| 90 | `get_top_clients_monthly` | `p_year integer DEFAULT 2026, p_month integer DEFAULT 7, p_limit integer DEFAULT 50, p_exclude_client text DEFAULT '9653'::text` | `TABLE(client_code character varying, client_name characte...` | Выборка лидеров продаж и расчет кумулятивных долей ядра 80% |
| 91 | `get_top_companies` | `p_year integer DEFAULT 2026, p_limit integer DEFAULT 5` | `TABLE(rank bigint, code character varying, name character...` | Выборка лидеров продаж и расчет кумулятивных долей ядра 80% |
| 92 | `get_top_company_detail` | `p_code character varying, p_year integer DEFAULT 2026` | `json` | Выборка лидеров продаж и расчет кумулятивных долей ядра 80% |
| 93 | `get_top_compare_yoy` | `p_year integer DEFAULT 2026, p_limit integer DEFAULT 10` | `json` | Выборка лидеров продаж и расчет кумулятивных долей ядра 80% |
| 94 | `get_top_recommendations` | `p_limit integer DEFAULT 10` | `TABLE(code character varying, name character varying, tot...` | Выборка лидеров продаж и расчет кумулятивных долей ядра 80% |
| 95 | `get_top_revenue_core` | `p_year integer DEFAULT 2026, p_pct numeric DEFAULT 80` | `TABLE(rank bigint, code character varying, name character...` | Выборка лидеров продаж и расчет кумулятивных долей ядра 80% |
| 96 | `get_top_sales_kpi` | `p_year integer DEFAULT 2026` | `TABLE(total_revenue numeric, active_clients_count bigint,...` | Выборка лидеров продаж и расчет кумулятивных долей ядра 80% |
| 97 | `get_yearly_clients_count` | `p_year integer DEFAULT 2026` | `bigint` | Микро-аналитика профиля и метрик конкретного клиента |
| 98 | `get_yoy_comparison` | `p_year1 integer DEFAULT 2026, p_year2 integer DEFAULT 2025` | `TABLE(month integer, month_name text, goods_revenue_y1 nu...` | Помесячные, посуточные тренды выручки и темпы прироста |
| 99 | `get_zaletnye` | `p_year integer DEFAULT 2026, p_multiplier numeric DEFAULT 2.9` | `TABLE(group_prev text, companies_count bigint, goods_reve...` | Помесячные, посуточные тренды выручки и темпы прироста |
| 100 | `log_status_change` | `—` | `trigger` | Триггерная процедура поддержания целостности данных |
| 101 | `parse_pipe_attributes` | `p_name character varying` | `TABLE(diameter numeric, wall numeric, prof_w numeric, pro...` | Товарная номенклатура, скоринг и алгоритмы ML-рекомендаций |
| 102 | `penalize_rejected_product` | `—` | `trigger` | Товарная номенклатура, скоринг и алгоритмы ML-рекомендаций |
| 103 | `trg_update_client_activity` | `—` | `trigger` | Микро-аналитика профиля и метрик конкретного клиента |
| 104 | `update_client_analytics` | `p_client_code character varying DEFAULT NULL::character varying` | `void` | Микро-аналитика профиля и метрик конкретного клиента |
| 105 | `update_updated_at_column` | `—` | `trigger` | Триггерная процедура поддержания целостности данных |

---

## 4. ПРЕДСТАВЛЕНИЯ (VIEWS)

В базе данных `bd_intelligent_sales` в настоящее время функционируют **4 активных представления**, сформированные после архитектурной оптимизации (согласно аудиту от 13.08.2026, 10 неиспользуемых представлений были выведены из эксплуатации).

### 4.1. Активные представления PostgreSQL (4 шт)

| # | Имя представления (View) | Назначение и использование в системе |
|:---:|:---|:---|
| 1 | `v_manager_dashboard` | Сводный аналитический витринный срез для менеджеров: баланс отгрузок, клиенты, оперативные показатели |
| 2 | `v_smart_recommendations` | Витрина предрассчитанных ML-рекомендаций кросс-продаж сопутствующего металлопроката с учетом остатков |
| 3 | `view_client_profiles_yearly` | Агрегированные профили активности клиентов в разрезе календарных лет (выручка, накладные, средний чек) |
| 4 | `view_client_segmentation_details_2026` | Базовый витринный слой для таблицы 1 Загальної сегментації за 2026 год с распределением по частотным когортам |

### 4.2. Архивированные представления (10 шт)
В ходе аудита и рефакторинга монолита от 13.08.2026 были упразднены устаревшие дубликаты витрин:
`v_abc_segmentation`, `v_annual_activity_report`, `v_churn_risk_dashboard`, `v_combined_annual_activity`, `v_direction_profitability`, `view_average_ticket_analytics`, `view_cohort_2026_integrity_check`, `v_abc_clients_detail`, `v_status_migration_matrix`, `v_clients_analytics_status`.

---

## 5. ТРИГГЕРЫ POSTGRESQL (9 шт)

В схеме `public` зарегистрировано **9 пользовательских триггеров**, обеспечивающих автоматическое обновление временных меток (`updated_at`), логирование изменений статусов клиентов и перерасчет активности при проведении накладных.

| # | Имя триггера | Целевая таблица | Тайминг и событие | Вызываемая функция | Назначение |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `trg_ab_tests_upd` | `ab_tests` | `BEFORE UPDATE` | `update_updated_at_column()` | Автоматическое обновление поля updated_at при редактировании параметров A/B-тестов |
| 2 | `trg_activity_directions_upd` | `activity_directions` | `BEFORE UPDATE` | `update_updated_at_column()` | Обновление updated_at при изменении отраслевых направлений деятельности |
| 3 | `trg_clients_upd` | `clients` | `BEFORE UPDATE` | `update_updated_at_column()` | Обновление updated_at при изменении реквизитов и контактных данных клиента |
| 4 | `trg_log_status_change` | `clients` | `BEFORE UPDATE` | `log_status_change()` | Аудит и запись истории перехода клиента между статусами в журнал status_history |
| 5 | `trg_penalize_rejection` | `manager_rejections_log` | `AFTER INSERT` | `penalize_rejected_product()` | Штрафование весов ML-рекомендаций при отклонении предложенного товара менеджером |
| 6 | `trg_product_scoring_upd` | `product_scoring` | `BEFORE UPDATE` | `update_updated_at_column()` | Обновление updated_at при пересчете рейтингов и скоринга продукции |
| 7 | `trg_products_upd` | `products` | `BEFORE UPDATE` | `update_updated_at_column()` | Обновление updated_at при изменении параметров номенклатуры металлопроката |
| 8 | `trg_sales_lines_activity` | `sales_lines` | `AFTER INSERT` | `trg_update_client_activity()` | Автоматический перерасчет даты последней активности клиента при вставке строки продажи |
| 9 | `trg_status_rules_upd` | `status_rules` | `BEFORE UPDATE` | `update_updated_at_column()` | Обновление updated_at при модификации пороговых правил присвоения статусов |

---

## 6. СВОДНАЯ СТАТИСТИКА И АРХИТЕКТУРНЫЕ ВЫВОДЫ

### 6.1. Сводная статистика платформы UTSK

- **Всего REST API эндпоинтов бэкенда:** `83` (в 9 модулях роутеров);
- **Всего fetch-запросов фронтенда:** `107` (на 27 аналитических страницах);
- **Всего уникальных эндпоинтов, вызываемых из фронтенда:** `45`;
- **Всего функций PostgreSQL в схеме public:** `105` (96 аналитических `get_%`, 9 процедурных/триггерных);
- **Всего представлений (Views):** `4` активных (14 с учётом оптимизированного жизненного цикла);
- **Всего триггеров PostgreSQL:** `9` активных триггеров.

### 6.2. Рекомендации по оптимизации слоя API и запросов

1. **Исправление немаршрутизируемых fetch-запросов:**
   - В файлах `client-invoices-month.html` и `client-month-analytics.html` заменить устаревший вызов `/api/client/{code}/invoice/{docId}` на актуальный рабочий эндпоинт `/api/invoices/{number}/items`.
2. **Инкапсуляция клиентских вызовов в единый API SDK:**
   - Создать JS-модуль `static/assets/js/api.js`, содержащий типизированные функции-обертки (`api.getDashboard()`, `api.getClientDetail(code)`, `api.getTopSales(year)`). Это исключит хардкод URL и дублирование добавления токена `?token=${TOKEN}` в 107 местах.
3. **Батчинг запросов на уровне дашбордов:**
   - Страница `analytics.html` совершает до 6 параллельных запросов (`monthly-revenue`, `yoy-comparison`, `clients-yoy`, `abc-groups`, `pivot-formatted`). Внедрение фасадного агрегирующего эндпоинта `/api/analytics/workspace-bundle` сократит количество сетевых обращений и ускорит первую отрисовку на 40-50%.
4. **Кэширование редко меняющихся SQL-выборок:**
   - Справочники статусов (`/api/statuses`), номенклатуры (`/api/products`) и исторические годы (`/api/analytics/yearly-clients-count`) рекомендуется кэшировать в памяти приложения FastAPI (in-memory cache / Redis) с TTL 1 час, снижая нагрузку на PostgreSQL.