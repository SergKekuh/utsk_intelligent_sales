#!/bin/bash
# get_full_structure.sh - Получение полной структуры БД

DB="bd_intelligent_sales"
OUTPUT_DIR="bd_intelligent_sales_structure_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

echo "=== ПОЛУЧЕНИЕ СТРУКТУРЫ БД: $DB ==="
echo "Дата: $(date)"
echo "========================================"

# 1. SQL-дамп схемы
echo "1. Создание SQL-дампа схемы..."
sudo -u postgres pg_dump -d "$DB" --schema-only --no-owner --no-privileges > "$OUTPUT_DIR/schema_dump.sql"
echo "   ✅ $OUTPUT_DIR/schema_dump.sql"

# 2. Полная структура в читаемом формате
echo "2. Создание читаемой структуры..."
{
    echo "=== СТРУКТУРА БАЗЫ ДАННЫХ: $DB ==="
    echo "Дата: $(date)"
    echo "========================================"
    echo ""
    
    echo "--- ОБЩАЯ ИНФОРМАЦИЯ ---"
    sudo -u postgres psql -d "$DB" -c "\l $DB"
    echo ""
    
    echo "--- РАЗМЕР БД ---"
    sudo -u postgres psql -d "$DB" -c "SELECT pg_size_pretty(pg_database_size('$DB')) as size;"
    echo ""
    
    echo "--- ВСЕ СХЕМЫ ---"
    sudo -u postgres psql -d "$DB" -c "\dn+"
    echo ""
    
    echo "--- ВСЕ ТАБЛИЦЫ И КОЛОНКИ ---"
    sudo -u postgres psql -d "$DB" -c "\d+"
    echo ""
    
    echo "--- ДЕТАЛЬНАЯ СТРУКТУРА КАЖДОЙ ТАБЛИЦЫ ---"
    TABLES=$(sudo -u postgres psql -d "$DB" -t -c "SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename;")
    
    for TABLE in $TABLES; do
        echo ""
        echo "========================================="
        echo "ТАБЛИЦА: $TABLE"
        echo "========================================="
        sudo -u postgres psql -d "$DB" -c "\d+ $TABLE"
        echo ""
        echo "--- Количество записей ---"
        sudo -u postgres psql -d "$DB" -c "SELECT COUNT(*) as total_rows FROM $TABLE;"
        echo ""
        echo "--- Размер таблицы ---"
        sudo -u postgres psql -d "$DB" -c "SELECT pg_size_pretty(pg_total_relation_size('$TABLE')) as size;"
        echo ""
        echo "--- Индексы таблицы ---"
        sudo -u postgres psql -d "$DB" -c "SELECT indexname, indexdef FROM pg_indexes WHERE schemaname='public' AND tablename='$TABLE';"
    done
    
    echo ""
    echo "--- ВСЕ ИНДЕКСЫ ---"
    sudo -u postgres psql -d "$DB" -c "\di+"
    echo ""
    
    echo "--- ВСЕ ВЬЮХИ (VIEWS) ---"
    sudo -u postgres psql -d "$DB" -c "\dv+"
    echo ""
    
    echo "--- ВСЕ ПОСЛЕДОВАТЕЛЬНОСТИ ---"
    sudo -u postgres psql -d "$DB" -c "\ds+"
    echo ""
    
    echo "--- ВНЕШНИЕ КЛЮЧИ ---"
    sudo -u postgres psql -d "$DB" -c "SELECT conname, conrelid::regclass AS table_name, pg_get_constraintdef(oid) AS constraint_def FROM pg_constraint WHERE contype='f' AND connamespace='public'::regnamespace ORDER BY conname;"
    echo ""
    
    echo "--- СТАТИСТИКА ТАБЛИЦ ---"
    sudo -u postgres psql -d "$DB" -c "SELECT schemaname, tablename, pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as total_size, n_live_tup as rows FROM pg_stat_user_tables ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;"
    
} > "$OUTPUT_DIR/full_structure.txt"

echo "   ✅ $OUTPUT_DIR/full_structure.txt"

# 3. Создание ER-диаграммы (текстовое описание связей)
echo "3. Создание описания связей..."
{
    echo "=== СВЯЗИ МЕЖДУ ТАБЛИЦАМИ БД: $DB ==="
    echo "Дата: $(date)"
    echo "========================================"
    echo ""
    
    sudo -u postgres psql -d "$DB" -c "
    SELECT 
        tc.table_name as source_table,
        kcu.column_name as source_column,
        ccu.table_name as target_table,
        ccu.column_name as target_column,
        tc.constraint_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu 
        ON ccu.constraint_name = tc.constraint_name
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'public'
    ORDER BY tc.table_name;
    "
    
} > "$OUTPUT_DIR/relationships.txt"

echo "   ✅ $OUTPUT_DIR/relationships.txt"

# 4. Создание архива
echo "4. Создание архива..."
tar -czf "$OUTPUT_DIR.tar.gz" "$OUTPUT_DIR" 2>/dev/null
echo "   ✅ $OUTPUT_DIR.tar.gz"

echo ""
echo "========================================"
echo "✅ ВСЕ ДАННЫЕ СОХРАНЕНЫ В: $OUTPUT_DIR/"
echo "📦 Архив: $OUTPUT_DIR.tar.gz"
echo "========================================"

# Показываем содержимое
echo ""
echo "Содержимое папки:"
ls -lh "$OUTPUT_DIR/"
