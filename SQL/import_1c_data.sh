#!/bin/bash
set -e

DB_HOST="localhost"; DB_PORT="5432"; DB_NAME="bd_intelligent_sales"; DB_USER="postgres"
export PGPASSWORD="root"

[ $# -lt 2 ] && echo "Использование: $0 <sales_csv> <stock_csv>" && exit 1

SALES_FILE="$1"; STOCK_FILE="$2"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${YELLOW}══════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  🚀 ИМПОРТ ДАННЫХ ИЗ 1С В UTSK${NC}"
echo -e "${YELLOW}  $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo -e "${YELLOW}══════════════════════════════════════════════════${NC}"

[ ! -f "$SALES_FILE" ] && echo -e "${RED}❌ Нет файла: $SALES_FILE${NC}" && exit 1
[ ! -f "$STOCK_FILE" ] && echo -e "${RED}❌ Нет файла: $STOCK_FILE${NC}" && exit 1

echo -e "${CYAN}📥 Продажи:${NC} $SALES_FILE"
echo -e "${CYAN}📥 Остатки:${NC} $STOCK_FILE"

TMP_SALES="/tmp/utsk_sales_$$.csv"
TMP_STOCK="/tmp/utsk_stock_$$.csv"

# Пробуем UTF-8, если ошибка — конвертируем из CP1251
if iconv -f UTF-8 -t UTF-8 "$SALES_FILE" >/dev/null 2>&1; then
    sed 's/\r$//' "$SALES_FILE" > "$TMP_SALES"
else
    iconv -f CP1251 -t UTF-8 "$SALES_FILE" | sed 's/\r$//' > "$TMP_SALES"
fi

if iconv -f UTF-8 -t UTF-8 "$STOCK_FILE" >/dev/null 2>&1; then
    sed 's/\r$//' "$STOCK_FILE" > "$TMP_STOCK"
else
    iconv -f CP1251 -t UTF-8 "$STOCK_FILE" | sed 's/\r$//' > "$TMP_STOCK"
fi

echo "Файлы подготовлены"

psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" <<SQL
\set ON_ERROR_STOP on
\timing on

BEGIN;

-- Отключаем триггеры на время импорта (ускорение)
ALTER TABLE clients DISABLE TRIGGER ALL;
ALTER TABLE products DISABLE TRIGGER ALL;
ALTER TABLE documents DISABLE TRIGGER ALL;
ALTER TABLE sales_lines DISABLE TRIGGER ALL;

-- Временные таблицы
DROP TABLE IF EXISTS tmp_sales;
CREATE TEMP TABLE tmp_sales (
    client_code TEXT, client_name TEXT, client_ipn TEXT, client_okpo TEXT,
    doc_date TEXT, doc_number TEXT,
    product_code TEXT, product_name TEXT,
    doc_total TEXT, quantity TEXT, amount TEXT
);
DROP TABLE IF EXISTS tmp_stock;
CREATE TEMP TABLE tmp_stock (
    product_code TEXT, product_name TEXT, in_stock_balance TEXT
);

-- Загрузка
\echo '📥 Загрузка CSV...'
\copy tmp_sales FROM '$TMP_SALES' WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'UTF8')
\echo 'OK: продажи'
\copy tmp_stock FROM '$TMP_STOCK' WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'UTF8')
\echo 'OK: остатки'

-- Индексы на временные таблицы (ускорение JOIN)
CREATE INDEX ON tmp_sales(client_code);
CREATE INDEX ON tmp_sales(product_code);
CREATE INDEX ON tmp_sales(doc_number);
CREATE INDEX ON tmp_stock(product_code);

-- Клиенты
\echo '👥 Клиенты...'
INSERT INTO clients (code, name, ipn, okpo_code)
SELECT DISTINCT ON (TRIM(client_code)) TRIM(client_code), TRIM(client_name),
       NULLIF(TRIM(client_ipn), ''), NULLIF(TRIM(client_okpo), '')
FROM tmp_sales WHERE client_code IS NOT NULL AND TRIM(client_code) <> ''
ON CONFLICT (code) DO UPDATE SET
    name = EXCLUDED.name,
    ipn = COALESCE(NULLIF(EXCLUDED.ipn, ''), clients.ipn),
    okpo_code = COALESCE(NULLIF(EXCLUDED.okpo_code, ''), clients.okpo_code),
    updated_at = CURRENT_TIMESTAMP;

-- Товары
\echo '📦 Товары...'
INSERT INTO products (code, name)
SELECT DISTINCT ON (TRIM(product_code)) TRIM(product_code), TRIM(product_name)
FROM tmp_sales WHERE product_code IS NOT NULL AND TRIM(product_code) <> ''
ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, updated_at = CURRENT_TIMESTAMP;

-- Остатки
\echo '🏗️  Остатки...'
INSERT INTO products (code, name, in_stock_balance)
SELECT TRIM(product_code), TRIM(product_name),
       REPLACE(TRIM(COALESCE(in_stock_balance, '0')), ',', '.')::NUMERIC
FROM tmp_stock WHERE product_code IS NOT NULL AND TRIM(product_code) <> ''
ON CONFLICT (code) DO UPDATE SET
    in_stock_balance = EXCLUDED.in_stock_balance,
    name = COALESCE(NULLIF(EXCLUDED.name, ''), products.name),
    updated_at = CURRENT_TIMESTAMP;

UPDATE products SET in_stock_balance = 0, updated_at = CURRENT_TIMESTAMP
WHERE code NOT IN (SELECT TRIM(product_code) FROM tmp_stock WHERE product_code IS NOT NULL);

--- Документы (берём первого клиента при дубликатах doc_number)
INSERT INTO documents (doc_number, client_code, invoice_date, total_amount)
SELECT TRIM(doc_number), 
       MIN(TRIM(client_code)),
       MIN(TO_DATE(TRIM(doc_date), 'YYYY-MM-DD')),
       SUM(ABS(REPLACE(TRIM(COALESCE(amount, '0')), ',', '.')::NUMERIC))
FROM tmp_sales WHERE doc_number IS NOT NULL AND TRIM(doc_number) <> ''
GROUP BY TRIM(doc_number)
ON CONFLICT (doc_number) DO UPDATE SET
    client_code = EXCLUDED.client_code,
    invoice_date = EXCLUDED.invoice_date,
    total_amount = EXCLUDED.total_amount;

-- Строки продаж
\echo '📋 Строки продаж...'
DELETE FROM sales_lines WHERE document_id IN (
    SELECT id FROM documents WHERE doc_number IN (
        SELECT DISTINCT TRIM(doc_number) FROM tmp_sales WHERE doc_number IS NOT NULL
    )
);

INSERT INTO sales_lines (document_id, product_code, quantity, amount)
SELECT d.id, TRIM(s.product_code),
       ABS(REPLACE(TRIM(COALESCE(s.quantity, '0')), ',', '.')::NUMERIC),
       ABS(REPLACE(TRIM(COALESCE(s.amount, '0')), ',', '.')::NUMERIC)
FROM tmp_sales s
JOIN documents d ON d.doc_number = TRIM(s.doc_number)
WHERE s.product_code IS NOT NULL AND TRIM(s.product_code) <> '';

-- Включаем триггеры обратно
ALTER TABLE clients ENABLE TRIGGER ALL;
ALTER TABLE products ENABLE TRIGGER ALL;
ALTER TABLE documents ENABLE TRIGGER ALL;
ALTER TABLE sales_lines ENABLE TRIGGER ALL;

-- Статусы
\echo '🔄 Статусы...'
SELECT update_client_analytics(NULL);

COMMIT;
SQL

rm -f "$TMP_SALES" "$TMP_STOCK"

echo ""
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ ИМПОРТ УСПЕШНО ЗАВЕРШЁН${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════${NC}"
