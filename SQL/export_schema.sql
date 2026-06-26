-- 1.1 Информация о БД
SELECT 
    current_database() as database_name,
    current_schema() as schema_name,
    version() as postgres_version;
    
    -- 2.1 Полная структура всех таблиц
SELECT 
    t.table_name,
    c.column_name,
    c.data_type,
    c.is_nullable,
    c.column_default,
    c.character_maximum_length,
    c.numeric_precision,
    c.numeric_scale,
    CASE 
        WHEN tc.constraint_type = 'PRIMARY KEY' THEN 'PRIMARY KEY'
        WHEN tc.constraint_type = 'FOREIGN KEY' THEN 'FOREIGN KEY'
        ELSE ''
    END AS constraint_type
FROM information_schema.tables t
JOIN information_schema.columns c ON t.table_name = c.table_name
LEFT JOIN (
    SELECT 
        kcu.table_name,
        kcu.column_name,
        tc.constraint_type
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_name = kcu.table_name
    WHERE tc.constraint_type IN ('PRIMARY KEY', 'FOREIGN KEY')
) tc ON tc.table_name = c.table_name AND tc.column_name = c.column_name
WHERE t.table_schema = 'public'
  AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name, c.ordinal_position;

-- 3.1 Все индексы в БД
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;


-- 4.1 Все пользовательские функции
SELECT 
    proname as function_name,
    pronargs as arg_count,
    pg_get_function_arguments(oid) as arguments,
    pg_get_function_result(oid) as return_type,
    prosrc as function_body
FROM pg_proc
WHERE pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public')
  AND proname NOT LIKE 'pg_%'
  AND proname NOT LIKE '_%'
ORDER BY proname;

-- 5.1 Все триггеры
SELECT 
    tgname as trigger_name,
    tgrelid::regclass as table_name,
    tgfoid::regproc as function_name,
    pg_get_triggerdef(oid) as trigger_definition
FROM pg_trigger
WHERE tgrelid IN (SELECT oid FROM pg_class WHERE relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public'))
  AND tgname NOT LIKE 'pg_%'
ORDER BY tgname;

-- 6.1 Все последовательности
SELECT 
    sequence_schema,
    sequence_name,
    data_type,
    start_value,
    increment,
    minimum_value,
    maximum_value
FROM information_schema.sequences
WHERE sequence_schema = 'public'
ORDER BY sequence_name;

-- 7.1 Размеры таблиц и количество записей
SELECT 
    relname as table_name,
    n_live_tup as row_count,
    pg_size_pretty(pg_total_relation_size(relid)) as total_size,
    pg_size_pretty(pg_relation_size(relid)) as table_size,
    pg_size_pretty(pg_total_relation_size(relid) - pg_relation_size(relid)) as index_size
FROM pg_stat_user_tables
WHERE schemaname = 'public'
ORDER BY n_live_tup DESC;

-- 8.1 Все ограничения
SELECT 
    tc.constraint_name,
    tc.table_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name as foreign_table,
    ccu.column_name as foreign_column
FROM information_schema.table_constraints tc
LEFT JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_name = kcu.table_name
LEFT JOIN information_schema.constraint_column_usage ccu 
    ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;

-- 9.1 Информация о ключевых таблицах
SELECT 
    'clients' as table_name,
    COUNT(*)::text as record_count,
    COUNT(DISTINCT code)::text as unique_clients,
    COUNT(DISTINCT client_type)::text as client_types,
    SUM(CASE WHEN is_active_current THEN 1 ELSE 0 END)::text as active_clients,
    '' as min_date,
    '' as max_date,
    '' as total_amount
FROM clients

UNION ALL

SELECT 
    'documents' as table_name,
    COUNT(*)::text,
    COUNT(DISTINCT client_code)::text,
    '' as client_types,
    '' as active_clients,
    MIN(invoice_date)::text as min_date,
    MAX(invoice_date)::text as max_date,
    SUM(total_amount)::text as total_amount
FROM documents

UNION ALL

SELECT 
    'sales_lines' as table_name,
    COUNT(*)::text,
    COUNT(DISTINCT product_code)::text,
    '' as client_types,
    '' as active_clients,
    '' as min_date,
    '' as max_date,
    SUM(amount)::text as total_amount
FROM sales_lines

UNION ALL

SELECT 
    'client_year_activity' as table_name,
    COUNT(*)::text,
    COUNT(DISTINCT client_code)::text,
    '' as client_types,
    '' as active_clients,
    MIN(sales_year)::text as min_year,
    MAX(sales_year)::text as max_year,
    SUM(goods_revenue)::text as total_goods
FROM client_year_activity;

-- 10.1 Проверка внешних ключей
SELECT 
    'Документы без клиентов' as check_name,
    COUNT(*) as count
FROM documents d
LEFT JOIN clients c ON d.client_code = c.code
WHERE c.code IS NULL

UNION ALL

SELECT 
    'Sales_lines без документов' as check_name,
    COUNT(*) as count
FROM sales_lines sl
LEFT JOIN documents d ON sl.document_id = d.id
WHERE d.id IS NULL

UNION ALL

SELECT 
    'Клиенты в client_year_activity без clients' as check_name,
    COUNT(DISTINCT cya.client_code) as count
FROM client_year_activity cya
LEFT JOIN clients c ON cya.client_code = c.code
WHERE c.code IS NULL

UNION ALL

SELECT 
    'Документы без sales_lines' as check_name,
    COUNT(*) as count
FROM documents d
LEFT JOIN sales_lines sl ON sl.document_id = d.id
WHERE sl.id IS NULL;

-- 11.1 Проверка данных по годам
SELECT 
    'documents' as source,
    EXTRACT(YEAR FROM invoice_date)::int as year,
    COUNT(*) as count,
    COUNT(DISTINCT client_code) as clients
FROM documents
GROUP BY source, year

UNION ALL

SELECT 
    'client_year_activity' as source,
    sales_year as year,
    COUNT(*) as count,
    COUNT(DISTINCT client_code) as clients
FROM client_year_activity
GROUP BY source, sales_year

UNION ALL

SELECT 
    'sales_lines (via documents)' as source,
    EXTRACT(YEAR FROM d.invoice_date)::int as year,
    COUNT(sl.id) as count,
    COUNT(DISTINCT d.client_code) as clients
FROM sales_lines sl
JOIN documents d ON sl.document_id = d.id
GROUP BY source, year
ORDER BY source, year;

-- 12.1 Проверка ABC-групп
WITH abc_data AS (
    SELECT 
        '2025' as year,
        out_group_name,
        out_total_companies,
        out_total_sales,
        CASE out_group_name
            WHEN 'A1' THEN 1 WHEN 'A2' THEN 2 WHEN 'A3' THEN 3
            WHEN 'B1' THEN 4 WHEN 'B2' THEN 5
            WHEN 'C1' THEN 6 WHEN 'C2' THEN 7
            WHEN 'Total' THEN 8
            ELSE 9
        END as sort_order
    FROM get_abc_groups(2025, 2.9)
    
    UNION ALL
    
    SELECT 
        '2026' as year,
        out_group_name,
        out_total_companies,
        out_total_sales,
        CASE out_group_name
            WHEN 'A1' THEN 1 WHEN 'A2' THEN 2 WHEN 'A3' THEN 3
            WHEN 'B1' THEN 4 WHEN 'B2' THEN 5
            WHEN 'C1' THEN 6 WHEN 'C2' THEN 7
            WHEN 'Total' THEN 8
            ELSE 9
        END as sort_order
    FROM get_abc_groups(2026, 2.9)
)
SELECT 
    year,
    out_group_name,
    out_total_companies,
    out_total_sales
FROM abc_data
ORDER BY year, sort_order;

-- 13.1 Проверка PIVOT-отчёта для 2025 года
SELECT '2025 (above)' as year_direction, *
FROM generate_custom_sales_report(2025, 2.9, 146000, 'above')
WHERE out_metric = 'Кол-во компаний'
UNION ALL
SELECT '2026 (above)' as year_direction, *
FROM generate_custom_sales_report(2026, 2.9, 146000, 'above')
WHERE out_metric = 'Кол-во компаний'
ORDER BY year_direction;


