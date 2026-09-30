# Фронтенд-страницы (`utsk_web/frontend/static/*.html`)

Всего HTML-страниц в системе: 36.

## 📋 Реестр всех 36 HTML-страниц

| № | Имя файла | Заголовок (`<title>`) | Строк | Вызываемые API эндпоинты |
|:---:|:---|:---|:---:|:---|
| 1 | `abc_structure.html` | UTSK — Структурный анализ ABC (5 Вкладок) | 897 | `/api/analytics/abc-segment-detail`<br>`/api/analytics/abc-structure` |
| 2 | `advanced.html` | UTSK Intelligent Sales — Расширенная Аналитика | 707 | `/api/analytics/monthly-revenue`<br>`/api/analytics/product-categories`<br>`/api/analytics/segment-comparison`<br>`/api/analytics/yearly-clients-count`<br>*(еще 1)* |
| 3 | `analytics.html` | UTSK — Аналитика по клиентам | 4102 | `/api/analytics/abc-groups`<br>`/api/analytics/clients-yoy`<br>`/api/analytics/monthly-revenue`<br>`/api/analytics/pivot-formatted`<br>*(еще 5)* |
| 4 | `avg-check.html` | UTSK Intelligent Sales — Аналитика Среднего Чека | 566 | `/api/analytics/monthly-revenue`<br>`/api/analytics/segment-comparison`<br>`/api/analytics/yearly-clients-count` |
| 5 | `c2-segmentation.html` | UTSK — 💡 Лайт (Дрібні клієнти) | 1159 | `/api/analytics/c2-segmentation-companies` |
| 6 | `churned-segmentation.html` | UTSK — 👻 Вибули (Ушедшие) клієнти | 1151 | `/api/analytics/churned-segmentation-companies` |
| 7 | `client-avg-check-analytics.html` | 🛒 UTSK — Анализ среднего чека клиента | 450 | `/api/analytics/client/avg-check` |
| 8 | `client-detail.html` | UTSK — Детализация клиента | 1071 | `/api/clients/detail/`<br>`/api/clients/invoices/`<br>`/api/invoices/`<br>`/api/recommendations-by-size/` |
| 9 | `client-invoices-analytics.html` | 📄 UTSK — Анализ накладных клиента | 542 | `/api/analytics/client/invoices` |
| 10 | `client-invoices-month.html` | 📄 UTSK — Накладные клиента за месяц | 425 | `/api/analytics/client/invoices-month`<br>`/api/invoices/` |
| 11 | `client-last-purchase-analytics.html` | 🕒 UTSK — Анализ последней покупки клиента | 387 | `/api/analytics/client/last-purchase` |
| 12 | `client-month-analytics.html` | 📅 UTSK — Анализ месяца компании | 689 | `/api/analytics/client/month-daily`<br>`/api/analytics/client/month-invoices`<br>`/api/analytics/client/month-products`<br>`/api/analytics/client/month-summary`<br>*(еще 1)* |
| 13 | `client-revenue-analytics.html` | 💰 UTSK — Анализ выручки клиента | 499 | `/api/analytics/client/revenue` |
| 14 | `comparison.html` | Сравнительный анализ сегментов — UTSK | 650 | `/api/analytics/segment-comparison` |
| 15 | `consolidated-segmentation.html` | UTSK — Всі (консолідовано) реєстр компаній | 1176 | `/api/analytics/consolidated-segmentation-companies` |
| 16 | `db_reference.html` | Справочник по базе данных UTSK v7.1 | 1723 | — |
| 17 | `directions-analytics.html` | UTSK Intelligent Sales — Аналитика Отраслей и Направлений | 1215 | `/api/analytics/directions/companies`<br>`/api/analytics/directions/kpi`<br>`/api/analytics/directions/monthly`<br>`/api/analytics/directions/summary` |
| 18 | `directions-avg-check-analytics.html` | 💵 UTSK — Аналитика среднего чека по отраслям | 507 | `/api/analytics/directions/avg-check-analytics` |
| 19 | `directions-clients-analytics.html` | 👥 UTSK — Аналитика клиентов по отраслям | 527 | `/api/analytics/directions/clients-analytics` |
| 20 | `directions-invoices-analytics.html` | 📑 UTSK — Аналитика накладных по отраслям | 513 | `/api/analytics/directions/invoices-analytics` |
| 21 | `directions-leader-analytics.html` | 🏆 UTSK — Аналитика отрасли-лидера и концентрации | 553 | `/api/analytics/directions/leader-analytics` |
| 22 | `directions-revenue-analytics.html` | 💰 UTSK — Аналитика выручки по отраслям | 538 | `/api/analytics/directions/revenue-analytics` |
| 23 | `general-segmentation.html` | UTSK — Загальна сегментація клієнтської бази | 1262 | `/api/analytics/general-segmentation-companies` |
| 24 | `inactive-clients-analytics.html` | UTSK Intelligent Sales — Аналитика Неактивных Клиентов | 819 | `/api/analytics/inactive-clients-abc`<br>`/api/analytics/inactive-clients-distribution`<br>`/api/analytics/inactive-clients-list`<br>`/api/analytics/inactive-clients-overview` |
| 25 | `index.html` | UTSK Intelligent Sales — Аналитика | 1725 | `/api/analytics/monthly-revenue`<br>`/api/analytics/yearly-clients-count`<br>`/api/clients`<br>`/api/clients/active`<br>*(еще 5)* |
| 26 | `monthly.html` | UTSK — Аналитика за месяц | 768 | `/api/analytics/abc-migration`<br>`/api/analytics/daily-revenue`<br>`/api/analytics/monthly-detail`<br>`/api/analytics/monthly-directions`<br>*(еще 3)* |
| 27 | `new-clients-analytics.html` | UTSK Intelligent Sales — Аналитика Новых Клиентов | 777 | `/api/analytics/new-clients-abc`<br>`/api/analytics/new-clients-abc-compare`<br>`/api/analytics/new-clients-frequency`<br>`/api/analytics/new-clients-list`<br>*(еще 1)* |
| 28 | `new-clients-segmentation.html` | UTSK — Нові клієнти: Сегментація за частотою | 1219 | `/api/analytics/new-clients-segmentation-companies` |
| 29 | `plan.html` | UTSK Intelligent Sales — План разработки v7.1 | 1409 | — |
| 30 | `product-analytics.html` | UTSK — Продуктовая аналитика клиента | 1603 | `/api/analytics/client-products-compare/`<br>`/api/analytics/client-products-recommendations/`<br>`/api/analytics/client-products/`<br>`/api/client-products-by-size/` |
| 31 | `product-recommendations.html` | UTSK — Рекомендации по продукту | 72 | — |
| 32 | `repeat-segmentation.html` | UTSK — Повторні (розкладені) деталізація | 1190 | `/api/analytics/repeat-segmentation-companies` |
| 33 | `returned-clients-analytics.html` | UTSK Intelligent Sales — Аналитика Вернувшихся Клиентов | 812 | `/api/analytics/returned-clients-abc`<br>`/api/analytics/returned-clients-compare-new`<br>`/api/analytics/returned-clients-frequency`<br>`/api/analytics/returned-clients-list`<br>*(еще 1)* |
| 34 | `segment-detail.html` | UTSK — Деталізація сегменту | 652 | `/api/analytics/segment-detail` |
| 35 | `sleeping-segmentation.html` | UTSK — 💤 Сплячі клієнти (Аналіз бази) | 1160 | `/api/analytics/sleeping-segmentation-companies` |
| 36 | `top-sales-analytics.html` | 📊 ТОП продаж — Визуализация | UTSK Intelligent Sales | 1824 | `/api/analytics/top-sales/companies`<br>`/api/analytics/top-sales/company-detail`<br>`/api/analytics/top-sales/compare-yoy`<br>`/api/analytics/top-sales/core`<br>*(еще 1)* |

## 🔍 Детальный разбор ключевых аналитических страниц

### `index.html`
- **Заголовок:** UTSK Intelligent Sales — Аналитика
- **Размер файла:** 1725 строк
- **Вызываемые API эндпоинты:**
  - `/api/analytics/monthly-revenue`
  - `/api/analytics/yearly-clients-count`
  - `/api/clients`
  - `/api/clients/active`
  - `/api/clients/churn-risk`
  - `/api/clients/top-sales`
  - `/api/dashboard`
  - `/api/funnel`
  - `/api/recommendations/`

---

### `directions-analytics.html`
- **Заголовок:** UTSK Intelligent Sales — Аналитика Отраслей и Направлений
- **Размер файла:** 1215 строк
- **Вызываемые API эндпоинты:**
  - `/api/analytics/directions/companies`
  - `/api/analytics/directions/kpi`
  - `/api/analytics/directions/monthly`
  - `/api/analytics/directions/summary`
- **Компоненты UI:**
  1. Карточки KPI (Выручка, Клиенты, Накладные, Средний чек, Отрасль-лидер)
  2. Круговая диаграмма долей отраслей (Chart.js Pie)
  3. График помесячной динамики топ-отраслей (Chart.js Bar/Line)
  4. Сводная матрица всех 16 отраслей
  5. Таблица «Компании отрасли» (блок выбора компаний конкретной отрасли)
- **Выявленные проблемы и доработки:**
  - KPI клиентов показывает 748 вместо 729
  - Блок «Компании отрасли» перегружает интерфейс и должен быть удален с главной страницы
  - Строки сводной таблицы должны быть кликабельными со ссылкой на `/direction-detail?direction_id={id}`

---

### `directions-revenue-analytics.html`
- **Заголовок:** 💰 UTSK — Аналитика выручки по отраслям
- **Размер файла:** 538 строк
- **Вызываемые API эндпоинты:**
  - `/api/analytics/directions/revenue-analytics`

---

### `directions-clients-analytics.html`
- **Заголовок:** 👥 UTSK — Аналитика клиентов по отраслям
- **Размер файла:** 527 строк
- **Вызываемые API эндпоинты:**
  - `/api/analytics/directions/clients-analytics`

---

### `directions-invoices-analytics.html`
- **Заголовок:** 📑 UTSK — Аналитика накладных по отраслям
- **Размер файла:** 513 строк
- **Вызываемые API эндпоинты:**
  - `/api/analytics/directions/invoices-analytics`

---

### `directions-avg-check-analytics.html`
- **Заголовок:** 💵 UTSK — Аналитика среднего чека по отраслям
- **Размер файла:** 507 строк
- **Вызываемые API эндпоинты:**
  - `/api/analytics/directions/avg-check-analytics`

---

### `directions-leader-analytics.html`
- **Заголовок:** 🏆 UTSK — Аналитика отрасли-лидера и концентрации
- **Размер файла:** 553 строк
- **Вызываемые API эндпоинты:**
  - `/api/analytics/directions/leader-analytics`

---

### `client-detail.html`
- **Заголовок:** UTSK — Детализация клиента
- **Размер файла:** 1071 строк
- **Вызываемые API эндпоинты:**
  - `/api/clients/detail/`
  - `/api/clients/invoices/`
  - `/api/invoices/`
  - `/api/recommendations-by-size/`
- **Компоненты UI:**
  1. Паспорт клиента (ЄДРПОУ, статус, отрасль, контактные данные)
  2. Финансовые показатели за 3 года (2024-2026)
  3. Помесячная история накладных с переходом в `client-month-analytics.html`
  4. Таблица рекомендованных к допродаже типоразмеров труб
  5. Модальное окно drilldown по остаткам и купленным позициям

---

### `product-analytics.html`
- **Заголовок:** UTSK — Продуктовая аналитика клиента
- **Размер файла:** 1603 строк
- **Вызываемые API эндпоинты:**
  - `/api/analytics/client-products-compare/`
  - `/api/analytics/client-products-recommendations/`
  - `/api/analytics/client-products/`
  - `/api/client-products-by-size/`
- **Компоненты UI:**
  1. Таблица всех размеров труб клиента (размер, частота, выручка, остаток на складе)
  2. Вкладка ABC-анализа номенклатуры
  3. Вкладка сравнения динамики 2026 vs 2025
  4. Вкладка рекомендаций ML

---

### `general-segmentation.html`
- **Заголовок:** UTSK — Загальна сегментація клієнтської бази
- **Размер файла:** 1262 строк
- **Вызываемые API эндпоинты:**
  - `/api/analytics/general-segmentation-companies`

---

### `consolidated-segmentation.html`
- **Заголовок:** UTSK — Всі (консолідовано) реєстр компаній
- **Размер файла:** 1176 строк
- **Вызываемые API эндпоинты:**
  - `/api/analytics/consolidated-segmentation-companies`

---

