#!/bin/bash

# =========================================================================
# СКРИПТ ИМПОРТА CSV В БАЗУ ДАННЫХ UTSK (LINUX BASH)
# Версия: Исправленная кодировка (UTF-8 -> UTF-8 очистка) и АВТО-СОЗДАНИЕ
# =========================================================================

# --- НАСТРОЙКИ БАЗЫ ДАННЫХ ---
DB_NAME="bd_intelligent_sales" 
DB_USER="postgres"             
DB_HOST="localhost"            

# Установка пароля для PostgreSQL
export PGPASSWORD="root"

# --- АВТОМАТИЧЕСКОЕ ОПРЕДЕЛЕНИЕ ПУТИ ---
WORK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"

# Цвета для красивого вывода
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}=== Старт импорта данных в БД: $DB_NAME ===${NC}"
echo -e "Рабочая директория: ${GREEN}$WORK_DIR${NC}"

cd "$WORK_DIR" || { echo -e "${RED}Ошибка: Не удалось перейти в папку $WORK_DIR!${NC}"; exit 1; }

# 1. Проверка файлов и их ОЧИСТКА (UTF-8 в UTF-8)
FILES=("clients.csv" "products.csv" "documents.csv" "sales_lines.csv")
echo "Очистка файлов от битых символов..."

for FILE in "${FILES[@]}"; do
    if [ ! -f "$FILE" ]; then
        echo -e "${RED}Ошибка: Файл $FILE не найден рядом со скриптом!${NC}"
        exit 1
    fi
    # МАГИЯ: Файлы уже в UTF-8. Мы просто чистим их от мусора флагом -c
    iconv -f UTF-8 -t UTF-8 -c "$FILE" > "utf8_$FILE"
done

echo -e "${GREEN}Файлы успешно очищены. Подключение к БД...${NC}"

# 2. Выполнение SQL кода через psql
psql -U "$DB_USER" -h "$DB_HOST" -d "$DB_NAME" <<EOF

\set ON_ERROR_STOP on

BEGIN;

-- Очистка таблиц перед импортом
TRUNCATE TABLE sales_lines, documents, products, clients CASCADE;
\echo 'Таблицы очищены.'

-- -------------------------------------------------------------------------
-- ШАГ 1. ЗАГРУЗКА КЛИЕНТОВ
-- -------------------------------------------------------------------------
CREATE TEMP TABLE tmp_clients (code VARCHAR, name VARCHAR);
\copy tmp_clients FROM 'utf8_clients.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'UTF8');

INSERT INTO clients (code, name) 
SELECT 
    TRIM(REPLACE(code, CHR(160), '')), 
    COALESCE(NULLIF(TRIM(name), ''), 'Без названия (' || TRIM(REPLACE(code, CHR(160), '')) || ')') 
FROM tmp_clients 
WHERE code IS NOT NULL AND TRIM(REPLACE(code, CHR(160), '')) <> '';
\echo 'Клиенты загружены.'

-- -------------------------------------------------------------------------
-- ШАГ 2. ЗАГРУЗКА ТОВАРОВ
-- -------------------------------------------------------------------------
CREATE TEMP TABLE tmp_products (code VARCHAR, name VARCHAR);
\copy tmp_products FROM 'utf8_products.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'UTF8');

INSERT INTO products (code, name) 
SELECT 
    TRIM(REPLACE(code, CHR(160), '')), 
    COALESCE(NULLIF(TRIM(name), ''), 'Неизвестный товар (' || TRIM(REPLACE(code, CHR(160), '')) || ')')
FROM tmp_products
WHERE code IS NOT NULL AND TRIM(REPLACE(code, CHR(160), '')) <> '';
\echo 'Товары загружены.'

-- -------------------------------------------------------------------------
-- ШАГ 3. ЗАГРУЗКА НАКЛАДНЫХ (С АВТО-СОЗДАНИЕМ КЛИЕНТОВ)
-- -------------------------------------------------------------------------
CREATE TEMP TABLE tmp_documents (id BIGINT, client_code VARCHAR, invoice_date VARCHAR);
\copy tmp_documents FROM 'utf8_documents.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'UTF8');

INSERT INTO clients (code, name)
SELECT DISTINCT 
    TRIM(REPLACE(client_code, CHR(160), '')), 
    'Авто-клиент (' || TRIM(REPLACE(client_code, CHR(160), '')) || ')'
FROM tmp_documents
WHERE TRIM(REPLACE(client_code, CHR(160), '')) NOT IN (SELECT code FROM clients)
  AND client_code IS NOT NULL AND TRIM(REPLACE(client_code, CHR(160), '')) <> '';
\echo 'Синхронизация клиентов выполнена.'

INSERT INTO documents (id, client_code, invoice_date)
SELECT 
    id, 
    TRIM(REPLACE(client_code, CHR(160), '')), 
    TO_DATE(TRIM(invoice_date), 'DD.MM.YYYY')
FROM tmp_documents
WHERE id IS NOT NULL;
\echo 'Документы загружены.'

-- -------------------------------------------------------------------------
-- ШАГ 4. ЗАГРУЗКА ОТГРУЗОК (С АВТО-СОЗДАНИЕМ ТОВАРОВ)
-- -------------------------------------------------------------------------
CREATE TEMP TABLE tmp_sales_lines (document_id BIGINT, product_code VARCHAR, quantity VARCHAR, amount VARCHAR);
\copy tmp_sales_lines FROM 'utf8_sales_lines.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'UTF8');

INSERT INTO products (code, name)
SELECT DISTINCT 
    TRIM(REPLACE(product_code, CHR(160), '')), 
    'Авто-товар (' || TRIM(REPLACE(product_code, CHR(160), '')) || ')'
FROM tmp_sales_lines
WHERE TRIM(REPLACE(product_code, CHR(160), '')) NOT IN (SELECT code FROM products)
  AND product_code IS NOT NULL AND TRIM(REPLACE(product_code, CHR(160), '')) <> '';
\echo 'Синхронизация товаров выполнена.'

INSERT INTO sales_lines (document_id, product_code, quantity, amount)
SELECT 
    document_id, 
    TRIM(REPLACE(product_code, CHR(160), '')), 
    REPLACE(TRIM(quantity), ',', '.')::NUMERIC,
    REPLACE(TRIM(amount), ',', '.')::NUMERIC
FROM tmp_sales_lines
WHERE document_id IS NOT NULL 
  AND document_id IN (SELECT id FROM documents);
\echo 'Строки отгрузок загружены.'

-- -------------------------------------------------------------------------
-- ШАГ 5. ЗАПУСК АНАЛИТИКИ
-- -------------------------------------------------------------------------
\echo 'Пересчет статусов и направлений (RFM)...'
SELECT update_client_analytics();

COMMIT;
EOF

PSQL_EXIT_CODE=$?

# 3. Уборка: удаление временных файлов
for FILE in "${FILES[@]}"; do
    rm -f "utf8_$FILE"
done

# Проверка статуса
if [ $PSQL_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}ДАННЫЕ ИЗ 1С УСПЕШНО ЗАГРУЖЕНЫ В БАЗУ!${NC}"
    echo -e "${GREEN}========================================${NC}"
else
    echo -e "${RED}========================================${NC}"
    echo -e "${RED}ПРОИЗОШЛА ОШИБКА ПРИ ИМПОРТЕ!${NC}"
    echo -e "${RED}========================================${NC}"
fi
