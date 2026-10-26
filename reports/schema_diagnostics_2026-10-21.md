# 📋 Результаты диагностики схемы базы данных (`bd_intelligent_sales`)

**Дата выполнения:** 2026-10-21  
**База данных:** `bd_intelligent_sales` (PostgreSQL)  
**Контекст:** Проверка структуры ключевых таблиц, наличия складских таблиц, первичных ключей, логики активности клиентов и идентификаторов компаний.

---

## 1. 📑 Колонки ключевых таблиц

### SQL-запрос
```sql
SELECT table_name, column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name IN ('clients', 'products', 'documents', 'sales_lines', 'stock_balance')
ORDER BY table_name, ordinal_position;
```

### Результат (61 колонка)

| Таблица | Колонка | Тип данных | Nullable |
| :--- | :--- | :--- | :--- |
| `clients` | `code` | `character varying` | NO (PK) |
| `clients` | `name` | `character varying` | NO |
| `clients` | `client_type` | `character varying` | YES |
| `clients` | `current_status_id` | `integer` | YES |
| `clients` | `status_history` | `jsonb` | YES |
| `clients` | `last_status_push_to_crm` | `timestamp without time zone` | YES |
| `clients` | `first_purchase_date` | `date` | YES |
| `clients` | `last_purchase_date` | `date` | YES |
| `clients` | `activity_direction_id` | `integer` | YES |
| `clients` | `direction_confidence` | `numeric` | YES |
| `clients` | `is_direction_manual` | `boolean` | YES |
| `clients` | `requires_survey` | `boolean` | YES |
| `clients` | `survey_completed_at` | `timestamp without time zone` | YES |
| `clients` | `survey_completed_by` | `character varying` | YES |
| `clients` | `created_at` | `timestamp without time zone` | YES |
| `clients` | `updated_at` | `timestamp without time zone` | YES |
| `clients` | `legacy_unit_id` | `integer` | YES |
| `clients` | `okpo_code` | `character varying` | YES |
| `clients` | `okpo_s1c8` | `character varying` | YES |
| `clients` | `ipn` | `character varying` | YES |
| `clients` | `legal_entity_type` | `character varying` | YES |
| `clients` | `full_unit_name` | `text` | YES |
| `clients` | `group_id` | `integer` | YES |
| `clients` | `active_years` | `ARRAY` | YES |
| `clients` | `is_active_current` | `boolean` | YES |
| `clients` | `analysis_updated_at` | `timestamp without time zone` | YES |
| `clients` | `edrpou` | `character varying` | YES |
| `clients` | `direction_id` | `integer` | YES |
| `clients` | `direction_source` | `character varying` | YES |
| `documents` | `id` | `bigint` | NO (PK) |
| `documents` | `client_code` | `character varying` | NO |
| `documents` | `invoice_date` | `date` | NO |
| `documents` | `total_amount` | `numeric` | YES |
| `documents` | `created_at` | `timestamp without time zone` | YES |
| `documents` | `doc_number` | `character varying` | YES |
| `products` | `code` | `character varying` | NO (PK) |
| `products` | `name` | `character varying` | NO |
| `products` | `anchor_direction_id` | `integer` | YES |
| `products` | `is_auto_tagged` | `boolean` | YES |
| `products` | `material_grade` | `character varying` | YES |
| `products` | `is_new_arrival` | `boolean` | YES |
| `products` | `in_stock_balance` | `numeric` | YES |
| `products` | `created_at` | `timestamp without time zone` | YES |
| `products` | `updated_at` | `timestamp without time zone` | YES |
| `products` | `diameter` | `numeric` | YES |
| `products` | `wall_thickness` | `numeric` | YES |
| `products` | `profile_width` | `numeric` | YES |
| `products` | `profile_height` | `numeric` | YES |
| `products` | `is_profile` | `boolean` | YES |
| `products` | `standard_name` | `character varying` | YES |
| `products` | `weight_per_meter` | `numeric` | YES |
| `products` | `first_purchase_date` | `date` | YES |
| `products` | `last_purchase_date` | `date` | YES |
| `products` | `unit` | `character varying` | YES |
| `products` | `is_service` | `boolean` | YES |
| `sales_lines` | `id` | `bigint` | NO (PK) |
| `sales_lines` | `document_id` | `bigint` | NO |
| `sales_lines` | `product_code` | `character varying` | NO |
| `sales_lines` | `quantity` | `numeric` | NO |
| `sales_lines` | `amount` | `numeric` | NO |
| `sales_lines` | `recorded_at` | `timestamp without time zone` | YES |

> **Примечание:** Таблица `stock_balance` в базе данных отсутствует (0 строк в выборке).

---

## 2. 🔍 Существует ли таблица `stock_balance`

### SQL-запрос
```sql
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' AND table_name LIKE '%stock%';
```

### Результат
```
(0 строк)
```

**Вывод:**
Отдельная таблица `stock_balance` (или любые таблицы/представления с паттерном `%stock%`) в БД **отсутствует**.  
Текущий складской остаток хранится денормализованно в таблице `products` в колонке `in_stock_balance numeric`.

---

## 3. 🔑 Первичные и уникальные ключи (PK / UNIQUE)

### SQL-запрос
```sql
SELECT tc.table_name, tc.constraint_type, kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public'
  AND tc.table_name IN ('clients', 'products', 'documents', 'sales_lines', 'stock_balance')
  AND tc.constraint_type IN ('PRIMARY KEY', 'UNIQUE')
ORDER BY tc.table_name, kcu.ordinal_position;
```

### Результат

| Таблица | Тип ограничения | Колонка ключа |
| :--- | :--- | :--- |
| `clients` | `PRIMARY KEY` | `code` |
| `documents` | `PRIMARY KEY` | `id` |
| `products` | `PRIMARY KEY` | `code` |
| `sales_lines` | `PRIMARY KEY` | `id` |

**Вывод:**
- `clients`: первичный ключ — строковый код клиента (`code`).
- `products`: первичный ключ — строковый код номенклатуры (`code`).
- `documents`: первичный ключ — целочисленный суррогатный `id` (`bigint`).
- `sales_lines`: первичный ключ — целочисленный суррогатный `id` (`bigint`).
- Отдельных дополнительных ограничений `UNIQUE` на уровне этих таблиц нет (индексы уникальности могут быть объявлены отдельно или контролироваться на уровне внешних связей/бизнес-логики).

---

## 4. 📦 Поля `snapshot_date` / `unit` в таблице `stock_balance`

### SQL-запрос
```sql
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'stock_balance'
  AND column_name IN ('snapshot_date', 'unit', 'quantity', 'product_id', 'product_code');
```

### Результат
```
(0 строк)
```

**Вывод:**
Поскольку таблица `stock_balance` не создана, поля не найдены.  
При этом:
- Единица измерения хранится в `products.unit` (`character varying`).
- Текущий остаток хранится в `products.in_stock_balance` (`numeric`).
- Исторические срезы (`snapshot_date`) по остаткам в текущей схеме отсутствуют.

---

## 5. 👥 Как определяется активность клиентов (`clients_active`)

### SQL-запрос
```sql
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'clients'
  AND column_name IN ('is_active', 'status_id', 'activity_direction_id');
```

### Результат

| Колонка |
| :--- |
| `activity_direction_id` |

*(Строки `is_active` и `status_id` не найдены в исходном виде)*

### Детальный анализ архитектуры активности клиентов:
В таблице `clients` используются другие имена полей:
1. `is_active_current` (`boolean`) — флаг активности клиента в текущем периоде (2026 год). Значение `true` имеют ровно **729** клиентов.
2. `current_status_id` (`integer`) — ссылка на текущий статус жизненного цикла клиента.
3. `active_years` (`integer[]`) — массив лет, в которых клиент совершал покупки.

Кроме того, историческая активность по годам нормализована в отдельной таблице **`client_year_activity`**:
- Поля: `client_code`, `sales_year`, `is_active`, `total_revenue`, `goods_revenue`, `total_docs`, `abc_group`.
- Baseline-запрос для подсчёта активных клиентов за 2026 год:
  ```sql
  SELECT COUNT(*) FROM client_year_activity WHERE sales_year = 2026 AND is_active = true;
  -- Результат: 729
  ```
- Значение полностью эквивалентно:
  ```sql
  SELECT COUNT(*) FROM clients WHERE is_active_current = true;
  -- Результат: 729
  ```

---

## 6. 🏢 Идентификаторы компаний в `clients` (`ipn`, `okpo`, `edrpou`)

### SQL-запрос
```sql
SELECT column_name FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'clients'
  AND column_name ~ 'ipn|okpo|edrpou|tax';
```

### Результат

| Колонка | Описание |
| :--- | :--- |
| `okpo_code` | ОКПО / ЕГРПОУ контрагента |
| `okpo_s1c8` | Исходный ОКПО из базы 1С8 УТП |
| `ipn` | Индивидуальный налоговый номер (ІПН / ИНН) |
| `edrpou` | ЕДРПОУ (очищенный код юридического лица/ФОП) |

**Вывод:**
В таблице `clients` присутствуют все 4 поля: `okpo_code`, `okpo_s1c8`, `ipn` и `edrpou`.
