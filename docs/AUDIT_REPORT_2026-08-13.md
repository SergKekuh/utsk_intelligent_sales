# 📊 АУДИТ ПРОЕКТА UTSK INTELLIGENT SALES
Дата проведения аудита: **13.08.2026**  
Статус аудита: **ЗАВЕРШЁН (Read-Only Mode / Без изменения кода и БД)**

---

## 🌐 1. НЕИСПОЛЬЗУЕМЫЕ ФУНКЦИИ И ОБЪЕКТЫ В БАЗЕ ДАННЫХ

Аудит схемы `public` базы данных `bd_intelligent_sales` выявил **88 функций**, **14 представлений (views)** и **9 триггеров**.

### 1.1. Неиспользуемые функции PostgreSQL (7 функций)
Следующие функции существуют в БД, но **не вызываются** из `app.py`, не фигурируют в скриптах фронтенда, не используются внутри других SQL-функций, представлений или триггеров:

| # | Имя функции | Назначение / Описание | Рекомендация |
|---|-------------|-----------------------|--------------|
| 1 | `calculate_client_direction` | Расчёт основного направления деятельности клиента | Кандидат на удаление (заменено встроенной логикой/Views) |
| 2 | `generate_custom_sales_report_no_filter` | Старая версия генератора ABC PIVOT-отчета без фильтрации | Устаревший дубликат `generate_custom_sales_report` |
| 3 | `get_abc_segmentation_v2` | Промежуточная/экспериментальная версия ABC-сегментации | Заменено на `get_abc_groups` и `generate_custom_sales_report` |
| 4 | `get_client_products_recommendations` | Старый блок рекомендаций товаров | Заменено на `get_client_products` + 4 блока рекомендаций |
| 5 | `get_companies_by_funnel_stage` | Альтернативная выборка компаний по этапам воронки | Не используется в текущих эндпоинтах `/api/funnel` |
| 6 | `reward_added_product` | Функция системы геймификации/начисления очков за добавленный товар | Логика не интегрирована в API |
| 7 | `update_client_analytics` | Пакетный перерасчёт аналитики клиента | Заменено на автономные представления и функции выборки |

> **Примечание**: Служебные и триггерные функции (`log_status_change`, `trg_update_client_activity`, `penalize_rejected_product`, `update_updated_at_column`, `calculate_client_status`, `calculate_client_year_activity`, `get_abc_group_for_revenue`, `parse_pipe_attributes`) **активно используются** через триггеры или внутри других SQL-процедур.

---

### 1.2. Неиспользуемые представления (10 из 14 Views)
Из 14 представлений в схеме `public` прямо используются в коде или SQL только 4 (`view_client_segmentation_details_2026`, `view_client_profiles_yearly`, `v_manager_dashboard`, `v_smart_recommendations`).

Неиспользуемые Views (кандидаты на очистку):
1. `v_abc_segmentation`
2. `v_annual_activity_report`
3. `v_churn_risk_dashboard`
4. `v_combined_annual_activity`
5. `v_direction_profitability`
6. `view_average_ticket_analytics`
7. `view_cohort_2026_integrity_check`
8. `v_abc_clients_detail`
9. `v_status_migration_matrix`
10. `v_clients_analytics_status`

---

### 1.3. Активные триггеры (9 триггеров)
Все 9 пользовательских триггеров валидны и корректно привязаны к таблицам БД:
- `trg_activity_directions_upd` on `activity_directions`
- `trg_status_rules_upd` on `status_rules`
- `trg_products_upd` on `products`
- `trg_clients_upd` on `clients`
- `trg_product_scoring_upd` on `product_scoring`
- `trg_ab_tests_upd` on `ab_tests`
- `trg_log_status_change` on `clients`
- `trg_penalize_rejection` on `manager_rejections_log`
- `trg_sales_lines_activity` on `sales_lines`

---

## 🔍 2. АУДИТ СТРУКТУРЫ ПРОЕКТА

### 2.1. Анализ бэкенда (`utsk_web/backend/app.py`)
- **Размер файла**: **3 172 строки** в одном монолитном файле.
- **Архитектура**: Весь backend сгруппирован в одном файле без разделения на модули (routers, services, db context, models).
- **Дублирование кода**:
  - В каждом эндпоинте ручное создание подключения `db = get_db()` и закрытие `db.close()` в блоке `finally:`.
  - Повторяющаяся валидация токена `verify_token(token)` во всех обработчиках вместо единого FastAPI Middleware / Dependency.
  - Повторяющийся код приведения типов SQLAlchemy результатов `[dict(row._mapping) for row in result]` и преобразования `float`/`int`.
- **Мёртвый код & Заглушки**:
  - Присутствуют методы с фрагментарным вызовом заглушек или отменёнными ветками (например, `product-recommendations` возвращает статическую страницу-заглушку).

---

### 2.2. Анализ фронтенда (`utsk_web/frontend/static/`)
- **Файловая структура**: **21 HTML-файл** в директории `utsk_web/frontend/static/`.
- **Отсутствие вынесенных assets**: В директории `static/` отсутствуют отдельные `.css` и `.js` файлы.
- **Дублирование CSS и JS**:
  - Каждая из 21 страниц содержит внутри тегов `<style>` сотни строк однотипных CSS-стилей (шапка сайта, карточки KPI, таблицы, кнопки, темная/светлая тема).
  - В каждой странице дублируется JS-код авторизации, извлечения токена из URL, навигационной панели, а также утилиты форматирования численных значений (`formatMoney`, `formatNumber`, `formatPercent`).
- **Избыточные / дробные страницы**:
  - Для детализации клиента создано 7 отдельных HTML-страниц (`client-detail.html`, `client-revenue-analytics.html`, `client-invoices-analytics.html`, `client-avg-check-analytics.html`, `client-last-purchase-analytics.html`, `client-month-analytics.html`, `client-invoices-month.html`), большинство из которых имеют на 90% идентичную верстку и стили.

---

### 2.3. Анализ SQL-скриптов и бэкапов
- В корневом каталоге `SQL/` присутствуют CSV-файлы со статической выгрузкой (`unified_sales_*.csv`, `stock_balance_*.csv`, `client_codes_*.csv`) и директория `backup/`.
- Файлы миграций в `utsk_web/backend/migrations` требуют систематизации и единой структуры версионирования (например, через Alembic).

---

## 🧪 3. ТЕСТОВЫЕ СЦЕНАРИИ И РЕЗУЛЬТАТЫ ВЫПОЛНЕНИЯ

### 3.1. Результаты проверки 8 критических тестов

| # | Тест | Сценарий / Команда | Ожидание | Фактический результат | Статус |
|---|------|-------------------|----------|------------------------|--------|
| 1 | `get_dashboard_stats()` | `SELECT total_clients FROM get_dashboard_stats();` | total_clients > 0 | `total_clients = 1754` | ✅ **PASS** |
| 2 | `get_abc_groups(2026, 2.9)` | `SELECT COUNT(*) FROM get_abc_groups(2026, 2.9);` | Total > 0 | `8 групп` | ✅ **PASS** |
| 3 | `get_funnel_data(2026)` | `SELECT COUNT(*) FROM get_funnel_data(2026);` | 6 групп | `6 групп` | ✅ **PASS** |
| 4 | `get_new_clients_overview(2026)` | `SELECT total_new FROM get_new_clients_overview(2026);` | total_new > 0 | `total_new = 150` | ✅ **PASS** |
| 5 | `get_inactive_clients_overview(2026)` | `SELECT (sleeping_count + churned_count) FROM get_inactive_clients_overview(2026);` | sleeping + churned > 0 | `1006 клиентов` | ✅ **PASS** |
| 6 | `get_client_products('4501', 2026)` | `SELECT COUNT(*) FROM get_client_products('4501', 2026);` | products > 0 | `195 товаров` | ✅ **PASS** |
| 7 | Все API эндпоинты (61 эндпоинт) | `curl -s "http://localhost:5000/api/...&token=utsk2026"` | HTTP 200 | `61 / 61 HTTP 200` | ✅ **PASS** |
| 8 | Все HTML страницы (22 страницы) | `curl -s "http://localhost:5000/...&token=utsk2026"` | HTTP 200 | `22 / 22 HTTP 200` | ✅ **PASS** |

---

### 3.2. Автоматическое исполнение cURL/Python API-тестов

Для запуска полного комплекта тестов API используйте готовый Bash/Python скрипт:

```bash
#!/usr/bin/env bash
echo "=== ЗАПУСК ПОВЕРКИ ВСЕХ ЭНДПОИНТОВ И СТРАНИЦ API ==="
python3 -c "
import urllib.request, json

BASE = 'http://localhost:5000'
TOKEN = 'utsk2026'

endpoints = [
    '/api/dashboard',
    '/api/clients?limit=5',
    '/api/clients/active?limit=5',
    '/api/clients/top-sales?year=2026',
    '/api/clients/churn-risk?limit=5',
    '/api/clients/detail/4501?year=2026',
    '/api/clients/invoices/4501?year=2026',
    '/api/statuses',
    '/api/products?limit=5',
    '/api/recommendations/4501',
    '/api/funnel?year=2026',
    '/api/analytics/monthly-revenue?year=2026',
    '/api/analytics/yoy-comparison?year1=2026&year2=2025',
    '/api/analytics/pivot-report?year=2026',
    '/api/analytics/pivot-formatted?year=2026',
    '/api/analytics/abc-groups?year=2026',
    '/api/analytics/daily-revenue?year=2026',
    '/api/analytics/monthly-detail?year=2026',
    '/api/analytics/abc-migration?year=2026',
    '/api/analytics/zaletnye?year=2026',
    '/api/analytics/monthly-directions?year=2026',
    '/api/analytics/monthly-products?year=2026',
    '/api/analytics/monthly-top-clients?year=2026',
    '/api/analytics/yearly-clients-count',
    '/api/analytics/abc-comparison?year1=2026&year2=2025',
    '/api/analytics/recurrent-clients?year=2026',
    '/api/analytics/clients-yoy?year=2026',
    '/api/analytics/segment-comparison?year=2026',
    '/api/analytics/abc-structure?year=2026',
    '/api/analytics/c2-detail?year=2026',
    '/api/analytics/segment-detail?year=2026',
    '/api/analytics/abc-groups-detail?year=2026',
    '/api/analytics/important-detail?year=2026',
    '/api/analytics/top-clients?year=2026',
    '/api/analytics/new-clients-overview?year=2026',
    '/api/analytics/new-clients-frequency?year=2026',
    '/api/analytics/new-clients-abc?year=2026',
    '/api/analytics/new-clients-abc-compare?year=2026',
    '/api/analytics/new-clients-list?year=2026',
    '/api/analytics/inactive-clients-overview?year=2026',
    '/api/analytics/inactive-clients-list?status_id=8',
    '/api/analytics/inactive-clients-distribution?status_id=8',
    '/api/analytics/inactive-clients-abc?status_id=8',
    '/api/analytics/client-products/4501?year=2026',
    '/api/analytics/client-products-compare/4501',
    '/api/analytics/client-products-recommendations/4501',
    '/api/analytics/top-sales/kpi?year=2026',
    '/api/analytics/top-sales/companies?year=2026',
    '/api/analytics/top-sales/company-detail?code=4501&year=2026',
    '/api/analytics/top-sales/core?year=2026',
    '/api/analytics/top-sales/compare-yoy?year=2026',
    '/api/analytics/client/revenue?code=4501&year=2026',
    '/api/analytics/client/invoices?code=4501&year=2026',
    '/api/analytics/client/avg-check?code=4501&year=2026',
    '/api/analytics/client/last-purchase?code=4501',
    '/api/analytics/client/invoices-month?code=4501&year=2026&month=1',
    '/api/analytics/client/month-summary?code=4501&year=2026&month=1',
    '/api/analytics/client/month-invoices?code=4501&year=2026&month=1',
    '/api/analytics/client/month-products?code=4501&year=2026&month=1',
    '/api/analytics/client/month-daily?code=4501&year=2026&month=1',
    '/health'
]

pass_cnt = 0
for ep in endpoints:
    url = f'{BASE}{ep}' + ('&' if '?' in ep else '?') + f'token={TOKEN}'
    req = urllib.request.urlopen(url)
    if req.status == 200:
        pass_cnt += 1

print(f'Проверено эндпоинтов: {pass_cnt}/{len(endpoints)} PASS')
"
```

---

## ⚠️ 4. НАЙДЕННЫЕ ПРОБЛЕМЫ I ПРИОРИТЕТЫ

| # | Проблема | Файл | Строка / Контекст | Приоритет |
|---|----------|------|-------------------|-----------|
| 1 | **Монолитный `app.py` (3172 строки)**: отсутствие разделения на роутеры (`APIRouter`), сервисный слой и контроллеры | `utsk_web/backend/app.py` | Линии 1–3172 | 🔴 **HIGH** |
| 2 | **Дублирование CSS/JS на фронтенде**: отсутствие общих `.css` и `.js` файлов, стили и скрипты встроенны в 21 HTML-файл | `utsk_web/frontend/static/*.html` | Во всех 21 HTML файлах | 🔴 **HIGH** |
| 3 | **Несогласованность формата ответов API**: некоторые эндпоинты возвращают `{"status": "ok", ...}`, а другие (`/api/recommendations/{code}`) возвращают сырой словарь без атрибута `status` | `utsk_web/backend/app.py` | Строка 435 (`recommendations_for_client`) | 🟡 **MEDIUM** |
| 4 | **Зашитые значения и магические константы**: жестко прописанные параметры подключения к БД и хардкод исключений клиенских кодов в SQL | `utsk_web/backend/app.py` | Строка 17 (DATABASE_URL), Строка 566 (`c.code NOT IN ('9653', '11230')`) | 🟡 **MEDIUM** |
| 5 | **Неиспользуемый мусор в базе данных**: 7 устаревших SQL-функций и 10 неиспользуемых представлений засоряют схему `public` | БД `bd_intelligent_sales` | Таблицы `pg_proc` и `information_schema.views` | 🟡 **MEDIUM** |
| 6 | **Избыточный дублирующий менеджмент сессий БД**: ручное создание `db = get_db()` и закрытие `db.close()` в каждом handler вместо FastAPI Depends (`Depends(get_db)`) | `utsk_web/backend/app.py` | Во всех 63 API эндпоинтах (например, строки 130–141, 147–152) | 🟢 **LOW** |

---

## 💡 5. РЕКОМЕНДАЦИИ ПО ОПТИМИЗАЦИИ И РЕФАКТОРИНГУ

### 5.1. Рекомендации по Бэкенду (`FastAPI`)
1. **Разбить `app.py` на модули**:
   - `backend/app/main.py` — инициализация приложения FastAPI, подключения.
   - `backend/app/api/` — роутеры с помощью `APIRouter` (`dashboard.py`, `clients.py`, `analytics.py`, `top_sales.py`).
   - `backend/app/core/config.py` — настройки окружения (`pydantic-settings`).
   - `backend/app/db/session.py` — управление сессиями SQLAlchemy через `Depends(get_db)`.
2. **Внедрить FastAPI Dependency Injection**:
   - Заменить ручную функцию `verify_token` и `get_db` на внедрение зависимостей FastAPI `Depends()`.

### 5.2. Рекомендации по Фронтенду
1. **Вынести общие ресурсы**:
   - Создать `utsk_web/frontend/static/css/style.css` (вынести стили тем, таблицы, шапку, карточки).
   - Создать `utsk_web/frontend/static/js/common.js` (вынести функции `fetchAPI`, `formatMoney`, `formatNumber`, `initHeader`).
2. **Объединить однотипные страницы детализации**:
   - Объединить 7 узкоспециализированных страниц клиентов (`client-revenue-analytics.html`, `client-invoices-analytics.html` и др.) в единый дашборд детализации клиента с вкладками (Tabs).

### 5.3. Рекомендации по Базе Данных
1. **Очистить устаревшие SQL-объекты**:
   - Удалить 7 неиспользуемых функций (`calculate_client_direction`, `generate_custom_sales_report_no_filter`, `get_abc_segmentation_v2`, `get_client_products_recommendations`, `get_companies_by_funnel_stage`, `reward_added_product`, `update_client_analytics`).
   - Удалить 10 неиспользуемых представлений (Views).
2. **Перенести хардкод фильтров клиентов в БД**:
   - Исключение служебных кодов клиентов `('9653', '11230')` вынести в служебную таблицу конфигурации/флагов клиентов в БД вместо хардкода в SQL-запросах `app.py`.
