# Схема базы данных PostgreSQL (`bd_intelligent_sales`)

Аудит проведен: 2026-09-21. Всего таблиц в схеме `public`: 36.

## 📊 Размеры таблиц и количество строк (pg_stat_user_tables)

| Таблица | Количество строк | Общий размер на диске |
|:---|:---:|:---:|
| `product_similarities` | 0 | 84 MB |
| `sales_lines` | 0 | 21 MB |
| `documents` | 0 | 9536 kB |
| `clients` | 1,754 | 6688 kB |
| `backup_sales_lines_20260810` | 0 | 5016 kB |
| `backup_documents_20260810` | 0 | 2424 kB |
| `client_year_activity` | 0 | 2080 kB |
| `products` | 0 | 1512 kB |
| `clients_backup_20260904` | 0 | 1096 kB |
| `backup_clients_20260810` | 0 | 1064 kB |
| `status_change_log` | 0 | 728 kB |
| `backup_products_20260810` | 0 | 656 kB |
| `backup_status_change_log_20260810` | 0 | 552 kB |
| `backup_client_year_activity_20260810` | 0 | 440 kB |
| `clients_status_backup_20260806` | 0 | 416 kB |
| `status_change_log_backup_20260806` | 0 | 408 kB |
| `clients_direction_bkp_20260917_v3` | 1,754 | 208 kB |
| `backup_functions_20260813` | 0 | 152 kB |
| `status_rules` | 0 | 80 kB |
| `activity_directions` | 7 | 48 kB |
| `client_groups` | 0 | 48 kB |
| `historical_client_activity` | 0 | 40 kB |
| `manager_rejections_log` | 0 | 32 kB |
| `product_scoring` | 0 | 32 kB |
| `website_behavior_log` | 0 | 32 kB |
| `backup_views_20260813` | 0 | 24 kB |
| `ab_tests` | 0 | 24 kB |
| `activity_directions_bkp_20260917_v3` | 9 | 16 kB |
| `client_year_active` | 0 | 16 kB |
| `backup_status_rules_20260810` | 0 | 16 kB |
| `product_cross_sells` | 0 | 16 kB |
| `status_rules_backup_20260904` | 0 | 16 kB |
| `product_aliases` | 0 | 16 kB |
| `status_rules_backup_20260806` | 0 | 16 kB |
| `production_lead_times` | 0 | 8192 bytes |
| `temp_ushed_id` | 0 | 8192 bytes |

## 🔗 Связи и внешние ключи (Foreign Keys)

| Исходная таблица | Колонка | Связанная таблица | Колонка назначения | Имя FK-ограничения |
|:---|:---|:---|:---|:---|
| `client_year_active` | `client_code` | `clients` | `code` | `client_year_active_client_code_fkey` |
| `clients` | `activity_direction_id` | `activity_directions` | `id` | `clients_activity_direction_id_fkey` |
| `clients` | `current_status_id` | `status_rules` | `id` | `clients_current_status_id_fkey` |
| `clients` | `direction_id` | `activity_directions` | `id` | `clients_direction_id_fkey` |
| `documents` | `client_code` | `clients` | `code` | `documents_client_code_fkey` |
| `historical_client_activity` | `group_id` | `client_groups` | `id` | `historical_client_activity_group_id_fkey` |
| `manager_rejections_log` | `client_code` | `clients` | `code` | `manager_rejections_log_client_code_fkey` |
| `manager_rejections_log` | `document_id` | `documents` | `id` | `manager_rejections_log_document_id_fkey` |
| `manager_rejections_log` | `product_code` | `products` | `code` | `manager_rejections_log_product_code_fkey` |
| `product_aliases` | `product_code` | `products` | `code` | `product_aliases_product_code_fkey` |
| `product_cross_sells` | `main_product_code` | `products` | `code` | `product_cross_sells_main_product_code_fkey` |
| `product_cross_sells` | `related_product_code` | `products` | `code` | `product_cross_sells_related_product_code_fkey` |
| `product_scoring` | `client_code` | `clients` | `code` | `product_scoring_client_code_fkey` |
| `product_scoring` | `product_code` | `products` | `code` | `product_scoring_product_code_fkey` |
| `production_lead_times` | `alternative_blank_code` | `products` | `code` | `production_lead_times_alternative_blank_code_fkey` |
| `production_lead_times` | `product_code` | `products` | `code` | `production_lead_times_product_code_fkey` |
| `products` | `anchor_direction_id` | `activity_directions` | `id` | `products_anchor_direction_id_fkey` |
| `sales_lines` | `document_id` | `documents` | `id` | `sales_lines_document_id_fkey` |
| `sales_lines` | `product_code` | `products` | `code` | `sales_lines_product_code_fkey` |
| `status_change_log` | `client_code` | `clients` | `code` | `status_change_log_client_code_fkey` |
| `status_change_log` | `new_status_id` | `status_rules` | `id` | `status_change_log_new_status_id_fkey` |
| `status_change_log` | `old_status_id` | `status_rules` | `id` | `status_change_log_old_status_id_fkey` |
| `website_behavior_log` | `client_code` | `clients` | `code` | `website_behavior_log_client_code_fkey` |
| `website_behavior_log` | `product_code` | `products` | `code` | `website_behavior_log_product_code_fkey` |

## 📋 Справочник отраслей (`activity_directions`) — 16 записей

| ID | Иконка | Название отрасли | Цвет | Sort | Описание |
|:---:|:---:|:---|:---:|:---:|:---|
| 1 | 🌾 | **Сельское хозяйство** | `#10b981` | 10 | Агросектор: теплицы, ангары, фермы |
| 2 | 🏗️ | **Строительство** | `#0ea5e9` | 20 | Строительные металлоконструкции, сваи, каркасы зданий, проф. труба |
| 3 | 🏭 | **Промышленность / Нефтегаз** | `#f59e0b` | 30 | Магистральные, толстостенные и бесшовные трубы |
| 4 | 🚰 | **ЖКХ и Водоканалы** | `#06b6d4` | 40 | Закупка труб ВГП, задвижек, фитингов для коммунальных нужд |
| 5 | 🛣️ | **Дорожное строительство** | `#84cc16` | 50 | Мосты, ограждения, дорожные конструкции |
| 6 | 💼 | **Трейдер** | `#8b5cf6` | 60 | Перепродавец металлопроката, торговая компания |
| 7 | 👤 | **Конечный потребитель** | `#ec4899` | 70 | Использует продукцию для собственных нужд |
| 8 | ⚙️ | **Трейдер с производством** | `#6366f1` | 80 | Перепродажа + собственная переработка/производство |
| 9 | 🌐 | **Универсальный/Смешанное** | `#64748b` | 90 | Смешанные закупки, невозможно определить однозначно |
| 10 | 🔩 | **Металлоконструкции** | `#d97706` | 100 | — |
| 11 | ⚙️ | **Машиностроение** | `#475569` | 110 | — |
| 12 | ⚡ | **Энергетика** | `#eab308` | 120 | — |
| 13 | 🚗 | **Автомобильная отрасль / Спецтехника** | `#ef4444` | 130 | — |
| 14 | 🚚 | **Логистика / Транспорт** | `#14b8a6` | 140 | — |
| 15 | 🏛️ | **Госструктуры / Ритейл** | `#a855f7` | 150 | — |
| 16 | ❓ | **Не определено** | `#94a3b8` | 999 | — |

## 🗃 Структура всех таблиц базы данных


### Таблица `ab_tests`
- **Строк:** 0 | **Размер:** 24 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `integer` | NO | `nextval('ab_tests_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `test_name` | `character varying(100)` | NO | `—` | — |
| 3 | `variant` | `character(1)` | NO | `—` | — |
| 4 | `content` | `jsonb` | NO | `—` | — |
| 5 | `impressions` | `integer` | YES | `0` | — |
| 6 | `clicks` | `integer` | YES | `0` | — |
| 7 | `add_to_cart` | `integer` | YES | `0` | — |
| 8 | `ctr` | `numeric` | YES | `—` | — |
| 9 | `conversion_rate` | `numeric` | YES | `—` | — |
| 10 | `is_active` | `boolean` | YES | `true` | — |
| 11 | `start_date` | `date` | YES | `CURRENT_DATE` | — |
| 12 | `end_date` | `date` | YES | `—` | — |
| 13 | `created_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |
| 14 | `updated_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |

### Таблица `activity_directions`
- **Строк:** 7 | **Размер:** 48 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `integer` | NO | `nextval('activity_directions_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `name` | `character varying(100)` | NO | `—` | — |
| 3 | `description` | `text` | YES | `—` | — |
| 4 | `created_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |
| 5 | `updated_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |
| 6 | `icon` | `character varying(10)` | YES | `—` | — |
| 7 | `sort_order` | `integer` | YES | `—` | — |
| 8 | `color` | `character varying(20)` | YES | `—` | — |

### Таблица `activity_directions_bkp_20260917_v3`
- **Строк:** 9 | **Размер:** 16 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `integer` | YES | `—` | Первичный ключ (Surrogate PK) |
| 2 | `name` | `character varying(100)` | YES | `—` | — |
| 3 | `description` | `text` | YES | `—` | — |
| 4 | `created_at` | `timestamp without time zone` | YES | `—` | — |
| 5 | `updated_at` | `timestamp without time zone` | YES | `—` | — |
| 6 | `icon` | `character varying(10)` | YES | `—` | — |
| 7 | `sort_order` | `integer` | YES | `—` | — |

### Таблица `backup_client_year_activity_20260810`
- **Строк:** 0 | **Размер:** 440 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `bigint` | YES | `—` | Первичный ключ (Surrogate PK) |
| 2 | `client_code` | `character varying(50)` | YES | `—` | FK -> clients.code |
| 3 | `sales_year` | `integer` | YES | `—` | — |
| 4 | `is_active` | `boolean` | YES | `—` | — |
| 5 | `is_manual` | `boolean` | YES | `—` | — |
| 6 | `activation_reason` | `character varying(100)` | YES | `—` | — |
| 7 | `deactivation_reason` | `character varying(100)` | YES | `—` | — |
| 8 | `total_revenue` | `numeric` | YES | `—` | — |
| 9 | `goods_revenue` | `numeric` | YES | `—` | — |
| 10 | `total_docs` | `integer` | YES | `—` | — |
| 11 | `abc_group` | `character varying(5)` | YES | `—` | — |
| 12 | `created_at` | `timestamp without time zone` | YES | `—` | — |
| 13 | `updated_at` | `timestamp without time zone` | YES | `—` | — |

### Таблица `backup_clients_20260810`
- **Строк:** 0 | **Размер:** 1064 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `code` | `character varying(50)` | YES | `—` | Первичный ключ / Код 1С |
| 2 | `name` | `character varying(255)` | YES | `—` | — |
| 3 | `client_type` | `character varying(50)` | YES | `—` | — |
| 4 | `current_status_id` | `integer` | YES | `—` | FK -> status_rules.id |
| 5 | `status_history` | `jsonb` | YES | `—` | — |
| 6 | `last_status_push_to_crm` | `timestamp without time zone` | YES | `—` | — |
| 7 | `first_purchase_date` | `date` | YES | `—` | — |
| 8 | `last_purchase_date` | `date` | YES | `—` | — |
| 9 | `activity_direction_id` | `integer` | YES | `—` | FK -> activity_directions.id |
| 10 | `direction_confidence` | `numeric` | YES | `—` | — |
| 11 | `is_direction_manual` | `boolean` | YES | `—` | — |
| 12 | `requires_survey` | `boolean` | YES | `—` | — |
| 13 | `survey_completed_at` | `timestamp without time zone` | YES | `—` | — |
| 14 | `survey_completed_by` | `character varying(100)` | YES | `—` | — |
| 15 | `created_at` | `timestamp without time zone` | YES | `—` | — |
| 16 | `updated_at` | `timestamp without time zone` | YES | `—` | — |
| 17 | `legacy_unit_id` | `integer` | YES | `—` | — |
| 18 | `okpo_code` | `character varying(20)` | YES | `—` | — |
| 19 | `okpo_s1c8` | `character varying(20)` | YES | `—` | — |
| 20 | `ipn` | `character varying(20)` | YES | `—` | — |
| 21 | `legal_entity_type` | `character varying(50)` | YES | `—` | — |
| 22 | `full_unit_name` | `text` | YES | `—` | — |
| 23 | `group_id` | `integer` | YES | `—` | — |
| 24 | `active_years` | `ARRAY` | YES | `—` | — |
| 25 | `is_active_current` | `boolean` | YES | `—` | — |
| 26 | `analysis_updated_at` | `timestamp without time zone` | YES | `—` | — |

### Таблица `backup_documents_20260810`
- **Строк:** 0 | **Размер:** 2424 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `bigint` | YES | `—` | Первичный ключ (Surrogate PK) |
| 2 | `client_code` | `character varying(50)` | YES | `—` | FK -> clients.code |
| 3 | `invoice_date` | `date` | YES | `—` | — |
| 4 | `total_amount` | `numeric` | YES | `—` | — |
| 5 | `created_at` | `timestamp without time zone` | YES | `—` | — |
| 6 | `doc_number` | `character varying(50)` | YES | `—` | — |

### Таблица `backup_functions_20260813`
- **Строк:** 0 | **Размер:** 152 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `proname` | `name` | YES | `—` | — |
| 2 | `definition` | `text` | YES | `—` | — |

### Таблица `backup_products_20260810`
- **Строк:** 0 | **Размер:** 656 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `code` | `character varying(50)` | YES | `—` | Первичный ключ / Код 1С |
| 2 | `name` | `character varying(255)` | YES | `—` | — |
| 3 | `anchor_direction_id` | `integer` | YES | `—` | — |
| 4 | `is_auto_tagged` | `boolean` | YES | `—` | — |
| 5 | `material_grade` | `character varying(50)` | YES | `—` | — |
| 6 | `is_new_arrival` | `boolean` | YES | `—` | — |
| 7 | `in_stock_balance` | `numeric` | YES | `—` | — |
| 8 | `created_at` | `timestamp without time zone` | YES | `—` | — |
| 9 | `updated_at` | `timestamp without time zone` | YES | `—` | — |
| 10 | `diameter` | `numeric` | YES | `—` | — |
| 11 | `wall_thickness` | `numeric` | YES | `—` | — |
| 12 | `profile_width` | `numeric` | YES | `—` | — |
| 13 | `profile_height` | `numeric` | YES | `—` | — |
| 14 | `is_profile` | `boolean` | YES | `—` | — |
| 15 | `standard_name` | `character varying(100)` | YES | `—` | — |
| 16 | `weight_per_meter` | `numeric` | YES | `—` | — |
| 17 | `first_purchase_date` | `date` | YES | `—` | — |
| 18 | `last_purchase_date` | `date` | YES | `—` | — |
| 19 | `unit` | `character varying(20)` | YES | `—` | — |
| 20 | `is_service` | `boolean` | YES | `—` | — |

### Таблица `backup_sales_lines_20260810`
- **Строк:** 0 | **Размер:** 5016 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `bigint` | YES | `—` | Первичный ключ (Surrogate PK) |
| 2 | `document_id` | `bigint` | YES | `—` | FK -> documents.id |
| 3 | `product_code` | `character varying(50)` | YES | `—` | FK -> products.code |
| 4 | `quantity` | `numeric` | YES | `—` | — |
| 5 | `amount` | `numeric` | YES | `—` | — |
| 6 | `recorded_at` | `timestamp without time zone` | YES | `—` | — |

### Таблица `backup_status_change_log_20260810`
- **Строк:** 0 | **Размер:** 552 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `bigint` | YES | `—` | Первичный ключ (Surrogate PK) |
| 2 | `client_code` | `character varying(50)` | YES | `—` | FK -> clients.code |
| 3 | `old_status_id` | `integer` | YES | `—` | — |
| 4 | `new_status_id` | `integer` | YES | `—` | — |
| 5 | `changed_by` | `character varying(50)` | YES | `—` | — |
| 6 | `change_reason` | `text` | YES | `—` | — |
| 7 | `documents_count_current_year` | `integer` | YES | `—` | — |
| 8 | `documents_count_prev_year` | `integer` | YES | `—` | — |
| 9 | `changed_at` | `timestamp without time zone` | YES | `—` | — |

### Таблица `backup_status_rules_20260810`
- **Строк:** 0 | **Размер:** 16 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `integer` | YES | `—` | Первичный ключ (Surrogate PK) |
| 2 | `status_name` | `character varying(50)` | YES | `—` | — |
| 3 | `min_current_year` | `integer` | YES | `—` | — |
| 4 | `max_current_year` | `integer` | YES | `—` | — |
| 5 | `min_prev_year` | `integer` | YES | `—` | — |
| 6 | `max_prev_year` | `integer` | YES | `—` | — |
| 7 | `min_days_since_last_purchase` | `integer` | YES | `—` | — |
| 8 | `min_days_between_purchases` | `integer` | YES | `—` | — |
| 9 | `priority` | `integer` | YES | `—` | — |
| 10 | `description` | `text` | YES | `—` | — |
| 11 | `created_at` | `timestamp without time zone` | YES | `—` | — |
| 12 | `updated_at` | `timestamp without time zone` | YES | `—` | — |

### Таблица `backup_views_20260813`
- **Строк:** 0 | **Размер:** 24 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `table_name` | `name` | YES | `—` | — |
| 2 | `view_definition` | `character varying` | YES | `—` | — |

### Таблица `client_groups`
- **Строк:** 0 | **Размер:** 48 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `integer` | NO | `nextval('client_groups_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `group_name` | `character varying(100)` | NO | `—` | — |
| 3 | `note` | `text` | YES | `—` | — |
| 4 | `created_at` | `timestamp without time zone` | YES | `now()` | — |

### Таблица `client_year_active`
- **Строк:** 0 | **Размер:** 16 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `bigint` | NO | `—` | Первичный ключ (Surrogate PK) |
| 2 | `client_code` | `character varying(50)` | NO | `—` | FK -> clients.code |
| 3 | `sales_year` | `integer` | NO | `—` | — |
| 4 | `is_active` | `boolean` | YES | `true` | — |
| 5 | `created_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |

### Таблица `client_year_activity`
- **Строк:** 0 | **Размер:** 2080 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `bigint` | NO | `nextval('client_year_activity_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `client_code` | `character varying(50)` | NO | `—` | FK -> clients.code |
| 3 | `sales_year` | `integer` | NO | `—` | — |
| 4 | `is_active` | `boolean` | YES | `false` | — |
| 5 | `is_manual` | `boolean` | YES | `false` | — |
| 6 | `activation_reason` | `character varying(100)` | YES | `—` | — |
| 7 | `deactivation_reason` | `character varying(100)` | YES | `—` | — |
| 8 | `total_revenue` | `numeric` | YES | `0` | — |
| 9 | `goods_revenue` | `numeric` | YES | `0` | — |
| 10 | `total_docs` | `integer` | YES | `0` | — |
| 11 | `abc_group` | `character varying(5)` | YES | `—` | — |
| 12 | `created_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |
| 13 | `updated_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |

### Таблица `clients`
- **Строк:** 1,754 | **Размер:** 6688 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `code` | `character varying(50)` | NO | `—` | Первичный ключ / Код 1С |
| 2 | `name` | `character varying(255)` | NO | `—` | — |
| 3 | `client_type` | `character varying(50)` | YES | `—` | — |
| 4 | `current_status_id` | `integer` | YES | `—` | FK -> status_rules.id |
| 5 | `status_history` | `jsonb` | YES | `'[]'::jsonb` | — |
| 6 | `last_status_push_to_crm` | `timestamp without time zone` | YES | `—` | — |
| 7 | `first_purchase_date` | `date` | YES | `—` | — |
| 8 | `last_purchase_date` | `date` | YES | `—` | — |
| 9 | `activity_direction_id` | `integer` | YES | `—` | FK -> activity_directions.id |
| 10 | `direction_confidence` | `numeric` | YES | `—` | — |
| 11 | `is_direction_manual` | `boolean` | YES | `false` | — |
| 12 | `requires_survey` | `boolean` | YES | `false` | — |
| 13 | `survey_completed_at` | `timestamp without time zone` | YES | `—` | — |
| 14 | `survey_completed_by` | `character varying(100)` | YES | `—` | — |
| 15 | `created_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |
| 16 | `updated_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |
| 17 | `legacy_unit_id` | `integer` | YES | `—` | — |
| 18 | `okpo_code` | `character varying(20)` | YES | `—` | — |
| 19 | `okpo_s1c8` | `character varying(20)` | YES | `—` | — |
| 20 | `ipn` | `character varying(20)` | YES | `—` | — |
| 21 | `legal_entity_type` | `character varying(50)` | YES | `—` | — |
| 22 | `full_unit_name` | `text` | YES | `—` | — |
| 23 | `group_id` | `integer` | YES | `—` | — |
| 24 | `active_years` | `ARRAY` | YES | `'{}'::integer[]` | — |
| 25 | `is_active_current` | `boolean` | YES | `false` | — |
| 26 | `analysis_updated_at` | `timestamp without time zone` | YES | `—` | — |
| 27 | `edrpou` | `character varying(20)` | YES | `—` | — |
| 28 | `direction_id` | `integer` | YES | `—` | Дублирующее поле (синхронизируется триггером) |

### Таблица `clients_backup_20260904`
- **Строк:** 0 | **Размер:** 1096 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `code` | `character varying(50)` | YES | `—` | Первичный ключ / Код 1С |
| 2 | `name` | `character varying(255)` | YES | `—` | — |
| 3 | `client_type` | `character varying(50)` | YES | `—` | — |
| 4 | `current_status_id` | `integer` | YES | `—` | FK -> status_rules.id |
| 5 | `status_history` | `jsonb` | YES | `—` | — |
| 6 | `last_status_push_to_crm` | `timestamp without time zone` | YES | `—` | — |
| 7 | `first_purchase_date` | `date` | YES | `—` | — |
| 8 | `last_purchase_date` | `date` | YES | `—` | — |
| 9 | `activity_direction_id` | `integer` | YES | `—` | FK -> activity_directions.id |
| 10 | `direction_confidence` | `numeric` | YES | `—` | — |
| 11 | `is_direction_manual` | `boolean` | YES | `—` | — |
| 12 | `requires_survey` | `boolean` | YES | `—` | — |
| 13 | `survey_completed_at` | `timestamp without time zone` | YES | `—` | — |
| 14 | `survey_completed_by` | `character varying(100)` | YES | `—` | — |
| 15 | `created_at` | `timestamp without time zone` | YES | `—` | — |
| 16 | `updated_at` | `timestamp without time zone` | YES | `—` | — |
| 17 | `legacy_unit_id` | `integer` | YES | `—` | — |
| 18 | `okpo_code` | `character varying(20)` | YES | `—` | — |
| 19 | `okpo_s1c8` | `character varying(20)` | YES | `—` | — |
| 20 | `ipn` | `character varying(20)` | YES | `—` | — |
| 21 | `legal_entity_type` | `character varying(50)` | YES | `—` | — |
| 22 | `full_unit_name` | `text` | YES | `—` | — |
| 23 | `group_id` | `integer` | YES | `—` | — |
| 24 | `active_years` | `ARRAY` | YES | `—` | — |
| 25 | `is_active_current` | `boolean` | YES | `—` | — |
| 26 | `analysis_updated_at` | `timestamp without time zone` | YES | `—` | — |

### Таблица `clients_direction_bkp_20260917_v3`
- **Строк:** 1,754 | **Размер:** 208 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `code` | `character varying(50)` | YES | `—` | Первичный ключ / Код 1С |
| 2 | `name` | `character varying(255)` | YES | `—` | — |
| 3 | `edrpou` | `character varying(20)` | YES | `—` | — |
| 4 | `activity_direction_id` | `integer` | YES | `—` | FK -> activity_directions.id |
| 5 | `direction_id` | `integer` | YES | `—` | Дублирующее поле (синхронизируется триггером) |
| 6 | `direction_confidence` | `numeric` | YES | `—` | — |

### Таблица `clients_status_backup_20260806`
- **Строк:** 0 | **Размер:** 416 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `code` | `character varying(50)` | YES | `—` | Первичный ключ / Код 1С |
| 2 | `current_status_id` | `integer` | YES | `—` | FK -> status_rules.id |
| 3 | `status_history` | `jsonb` | YES | `—` | — |
| 4 | `requires_survey` | `boolean` | YES | `—` | — |

### Таблица `documents`
- **Строк:** 0 | **Размер:** 9536 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `bigint` | NO | `nextval('documents_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `client_code` | `character varying(50)` | NO | `—` | FK -> clients.code |
| 3 | `invoice_date` | `date` | NO | `—` | — |
| 4 | `total_amount` | `numeric` | YES | `0.00` | — |
| 5 | `created_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |
| 6 | `doc_number` | `character varying(50)` | YES | `—` | — |

### Таблица `historical_client_activity`
- **Строк:** 0 | **Размер:** 40 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `bigint` | NO | `nextval('historical_client_activity_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `client_code` | `character varying(50)` | NO | `—` | FK -> clients.code |
| 3 | `sales_year` | `integer` | NO | `—` | — |
| 4 | `group_id` | `integer` | YES | `—` | — |
| 5 | `expense_invoices` | `numeric` | YES | `0` | — |
| 6 | `sales_amount` | `numeric` | YES | `0` | — |
| 7 | `note` | `text` | YES | `—` | — |

### Таблица `manager_rejections_log`
- **Строк:** 0 | **Размер:** 32 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `bigint` | NO | `nextval('manager_rejections_log_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `client_code` | `character varying(50)` | NO | `—` | FK -> clients.code |
| 3 | `product_code` | `character varying(50)` | NO | `—` | FK -> products.code |
| 4 | `manager_login` | `character varying(100)` | YES | `—` | — |
| 5 | `reject_reason` | `text` | YES | `—` | — |
| 6 | `document_id` | `bigint` | YES | `—` | FK -> documents.id |
| 7 | `rejected_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |

### Таблица `product_aliases`
- **Строк:** 0 | **Размер:** 16 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `integer` | NO | `nextval('product_aliases_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `product_code` | `character varying(50)` | NO | `—` | FK -> products.code |
| 3 | `alias_text` | `character varying(255)` | NO | `—` | — |
| 4 | `created_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |

### Таблица `product_cross_sells`
- **Строк:** 0 | **Размер:** 16 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `integer` | NO | `nextval('product_cross_sells_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `main_product_code` | `character varying(50)` | YES | `—` | — |
| 3 | `related_product_code` | `character varying(50)` | YES | `—` | — |
| 4 | `relation_type` | `character varying(50)` | YES | `—` | — |

### Таблица `product_scoring`
- **Строк:** 0 | **Размер:** 32 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `bigint` | NO | `nextval('product_scoring_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `client_code` | `character varying(50)` | NO | `—` | FK -> clients.code |
| 3 | `product_code` | `character varying(50)` | NO | `—` | FK -> products.code |
| 4 | `base_score` | `integer` | YES | `10` | — |
| 5 | `positive_reinforcement` | `integer` | YES | `0` | — |
| 6 | `negative_reinforcement` | `integer` | YES | `0` | — |
| 7 | `current_weight` | `integer` | YES | `—` | — |
| 8 | `is_blocked` | `boolean` | YES | `false` | — |
| 9 | `blocked_until` | `date` | YES | `—` | — |
| 10 | `segment_agro_weight` | `integer` | YES | `0` | — |
| 11 | `segment_build_weight` | `integer` | YES | `0` | — |
| 12 | `created_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |
| 13 | `updated_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |

### Таблица `product_similarities`
- **Строк:** 0 | **Размер:** 84 MB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `bigint` | NO | `nextval('product_similarities_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `source_product_code` | `character varying(50)` | NO | `—` | — |
| 3 | `similar_product_code` | `character varying(50)` | NO | `—` | — |
| 4 | `similarity_score` | `numeric` | YES | `0` | — |
| 5 | `match_type` | `character varying(50)` | NO | `—` | — |
| 6 | `source_diameter` | `numeric` | YES | `—` | — |
| 7 | `source_wall` | `numeric` | YES | `—` | — |
| 8 | `similar_diameter` | `numeric` | YES | `—` | — |
| 9 | `similar_wall` | `numeric` | YES | `—` | — |

### Таблица `production_lead_times`
- **Строк:** 0 | **Размер:** 8192 bytes
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `integer` | NO | `nextval('production_lead_times_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `product_code` | `character varying(50)` | NO | `—` | FK -> products.code |
| 3 | `from_blank_days` | `integer` | YES | `—` | — |
| 4 | `from_sheet_days` | `integer` | YES | `—` | — |
| 5 | `transit_days` | `integer` | YES | `—` | — |
| 6 | `alternative_blank_code` | `character varying(50)` | YES | `—` | — |
| 7 | `created_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |
| 8 | `updated_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |

### Таблица `products`
- **Строк:** 0 | **Размер:** 1512 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `code` | `character varying(50)` | NO | `—` | Первичный ключ / Код 1С |
| 2 | `name` | `character varying(255)` | NO | `—` | — |
| 3 | `anchor_direction_id` | `integer` | YES | `—` | — |
| 4 | `is_auto_tagged` | `boolean` | YES | `false` | — |
| 5 | `material_grade` | `character varying(50)` | YES | `—` | — |
| 6 | `is_new_arrival` | `boolean` | YES | `false` | — |
| 7 | `in_stock_balance` | `numeric` | YES | `0.00` | — |
| 8 | `created_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |
| 9 | `updated_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |
| 10 | `diameter` | `numeric` | YES | `—` | — |
| 11 | `wall_thickness` | `numeric` | YES | `—` | — |
| 12 | `profile_width` | `numeric` | YES | `—` | — |
| 13 | `profile_height` | `numeric` | YES | `—` | — |
| 14 | `is_profile` | `boolean` | YES | `false` | — |
| 15 | `standard_name` | `character varying(100)` | YES | `—` | — |
| 16 | `weight_per_meter` | `numeric` | YES | `—` | — |
| 17 | `first_purchase_date` | `date` | YES | `—` | — |
| 18 | `last_purchase_date` | `date` | YES | `—` | — |
| 19 | `unit` | `character varying(20)` | YES | `'т'::character varying` | — |
| 20 | `is_service` | `boolean` | YES | `false` | — |

### Таблица `sales_lines`
- **Строк:** 0 | **Размер:** 21 MB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `bigint` | NO | `nextval('sales_lines_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `document_id` | `bigint` | NO | `—` | FK -> documents.id |
| 3 | `product_code` | `character varying(50)` | NO | `—` | FK -> products.code |
| 4 | `quantity` | `numeric` | NO | `—` | — |
| 5 | `amount` | `numeric` | NO | `0.00` | — |
| 6 | `recorded_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |

### Таблица `status_change_log`
- **Строк:** 0 | **Размер:** 728 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `bigint` | NO | `nextval('status_change_log_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `client_code` | `character varying(50)` | NO | `—` | FK -> clients.code |
| 3 | `old_status_id` | `integer` | YES | `—` | — |
| 4 | `new_status_id` | `integer` | YES | `—` | — |
| 5 | `changed_by` | `character varying(50)` | NO | `—` | — |
| 6 | `change_reason` | `text` | YES | `—` | — |
| 7 | `documents_count_current_year` | `integer` | YES | `—` | — |
| 8 | `documents_count_prev_year` | `integer` | YES | `—` | — |
| 9 | `changed_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |

### Таблица `status_change_log_backup_20260806`
- **Строк:** 0 | **Размер:** 408 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `bigint` | YES | `—` | Первичный ключ (Surrogate PK) |
| 2 | `client_code` | `character varying(50)` | YES | `—` | FK -> clients.code |
| 3 | `old_status_id` | `integer` | YES | `—` | — |
| 4 | `new_status_id` | `integer` | YES | `—` | — |
| 5 | `changed_by` | `character varying(50)` | YES | `—` | — |
| 6 | `change_reason` | `text` | YES | `—` | — |
| 7 | `documents_count_current_year` | `integer` | YES | `—` | — |
| 8 | `documents_count_prev_year` | `integer` | YES | `—` | — |
| 9 | `changed_at` | `timestamp without time zone` | YES | `—` | — |

### Таблица `status_rules`
- **Строк:** 0 | **Размер:** 80 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `integer` | NO | `nextval('status_rules_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `status_name` | `character varying(50)` | NO | `—` | — |
| 3 | `min_current_year` | `integer` | YES | `—` | — |
| 4 | `max_current_year` | `integer` | YES | `—` | — |
| 5 | `min_prev_year` | `integer` | YES | `—` | — |
| 6 | `max_prev_year` | `integer` | YES | `—` | — |
| 7 | `min_days_since_last_purchase` | `integer` | YES | `—` | — |
| 8 | `min_days_between_purchases` | `integer` | YES | `—` | — |
| 9 | `priority` | `integer` | NO | `—` | — |
| 10 | `description` | `text` | YES | `—` | — |
| 11 | `created_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |
| 12 | `updated_at` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |

### Таблица `status_rules_backup_20260806`
- **Строк:** 0 | **Размер:** 16 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `integer` | YES | `—` | Первичный ключ (Surrogate PK) |
| 2 | `status_name` | `character varying(50)` | YES | `—` | — |
| 3 | `min_current_year` | `integer` | YES | `—` | — |
| 4 | `max_current_year` | `integer` | YES | `—` | — |
| 5 | `min_prev_year` | `integer` | YES | `—` | — |
| 6 | `max_prev_year` | `integer` | YES | `—` | — |
| 7 | `min_days_since_last_purchase` | `integer` | YES | `—` | — |
| 8 | `min_days_between_purchases` | `integer` | YES | `—` | — |
| 9 | `priority` | `integer` | YES | `—` | — |
| 10 | `description` | `text` | YES | `—` | — |
| 11 | `created_at` | `timestamp without time zone` | YES | `—` | — |
| 12 | `updated_at` | `timestamp without time zone` | YES | `—` | — |

### Таблица `status_rules_backup_20260904`
- **Строк:** 0 | **Размер:** 16 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `integer` | YES | `—` | Первичный ключ (Surrogate PK) |
| 2 | `status_name` | `character varying(50)` | YES | `—` | — |
| 3 | `min_current_year` | `integer` | YES | `—` | — |
| 4 | `max_current_year` | `integer` | YES | `—` | — |
| 5 | `min_prev_year` | `integer` | YES | `—` | — |
| 6 | `max_prev_year` | `integer` | YES | `—` | — |
| 7 | `min_days_since_last_purchase` | `integer` | YES | `—` | — |
| 8 | `min_days_between_purchases` | `integer` | YES | `—` | — |
| 9 | `priority` | `integer` | YES | `—` | — |
| 10 | `description` | `text` | YES | `—` | — |
| 11 | `created_at` | `timestamp without time zone` | YES | `—` | — |
| 12 | `updated_at` | `timestamp without time zone` | YES | `—` | — |

### Таблица `temp_ushed_id`
- **Строк:** 0 | **Размер:** 8192 bytes
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `integer` | YES | `—` | Первичный ключ (Surrogate PK) |

### Таблица `website_behavior_log`
- **Строк:** 0 | **Размер:** 32 kB
| № | Поле | Тип данных | Nullable | По умолчанию | Примечание |
|:---:|:---|:---|:---:|:---|:---|
| 1 | `id` | `bigint` | NO | `nextval('website_behavior_log_id_seq'::regclass)` | Первичный ключ (Surrogate PK) |
| 2 | `client_code` | `character varying(50)` | NO | `—` | FK -> clients.code |
| 3 | `product_category` | `character varying(100)` | YES | `—` | — |
| 4 | `product_code` | `character varying(50)` | YES | `—` | FK -> products.code |
| 5 | `action_type` | `character varying(50)` | YES | `—` | — |
| 6 | `timestamp` | `timestamp without time zone` | YES | `CURRENT_TIMESTAMP` | — |
