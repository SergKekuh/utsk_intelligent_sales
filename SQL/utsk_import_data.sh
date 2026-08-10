#!/bin/bash
# ================================================================
# UTSK — Универсальная загрузка данных v5.3
# ИСПРАВЛЕНИЯ:
#   - Защита от BOM в client_codes (удаление \xEF\xBB\xBF)
#   - Фильтр заголовков (client_code, code, client, и т.д.)
#   - Пустые строки игнорируются
# ================================================================
set -e

if [ -z "$1" ]; then
    echo "❌ Ошибка: Не указан год для загрузки."
    echo "👉 Использование: $0 <ГОД>"
    exit 1
fi

TARGET_YEAR=$1

if ! [[ "$TARGET_YEAR" =~ ^[0-9]{4}$ ]]; then
    echo "❌ Ошибка: Неверный формат года ($TARGET_YEAR)."
    exit 1
fi

DB_NAME="bd_intelligent_sales"
DB_USER="postgres"
SQL_DIR="/home/serg/Documents/SQL_postgresql/Intelligent_Sales/SQL"
TMP_DIR="/tmp/utsk_import_$TARGET_YEAR"

SALES_CSV="$SQL_DIR/unified_sales_$TARGET_YEAR.csv"
STOCK_CSV="$SQL_DIR/stock_balance_$TARGET_YEAR.csv"
CLIENT_CODES_CSV="$SQL_DIR/client_codes_$TARGET_YEAR.csv"

echo "================================================"
echo "  ЗАГРУЗКА ДАННЫХ ЗА $TARGET_YEAR ГОД (v5.3)"
echo "================================================"

[ ! -f "$SALES_CSV" ] && echo "❌ Нет $SALES_CSV" && exit 1
[ ! -f "$STOCK_CSV" ] && echo "❌ Нет $STOCK_CSV" && exit 1
[ ! -f "$CLIENT_CODES_CSV" ] && echo "❌ Нет $CLIENT_CODES_CSV" && exit 1
echo "📋 Все файлы найдены"

# ============================================================
# ШАГ 1: Конвертация CSV
# ============================================================
echo ""
echo "[1/6] Конвертация CSV..."
mkdir -p "$TMP_DIR"
sed 's/,/./g' "$SALES_CSV" | iconv -f WINDOWS-1251 -t UTF-8 > "$TMP_DIR/sales.csv" 2>/dev/null || sed 's/,/./g' "$SALES_CSV" > "$TMP_DIR/sales.csv"
sed 's/,/./g' "$STOCK_CSV" | iconv -f WINDOWS-1251 -t UTF-8 > "$TMP_DIR/stock.csv" 2>/dev/null || sed 's/,/./g' "$STOCK_CSV" > "$TMP_DIR/stock.csv"
echo "  ✅ Продажи: $(wc -l < "$TMP_DIR/sales.csv") строк"
echo "  ✅ Остатки: $(wc -l < "$TMP_DIR/stock.csv") строк"

# ============================================================
# ШАГ 2: Загрузка данных
# ============================================================
echo ""
echo "[2/6] Загрузка в PostgreSQL..."
sudo -u "$DB_USER" psql -d "$DB_NAME" <<SQL
BEGIN;

DROP TABLE IF EXISTS temp_sales;
CREATE TEMP TABLE temp_sales (
    client_code VARCHAR(50), client_name VARCHAR(255), client_ipn VARCHAR(20), client_okpo VARCHAR(20),
    doc_date DATE, doc_number VARCHAR(50), product_code VARCHAR(50), product_name VARCHAR(255),
    doc_total NUMERIC(15,2), quantity NUMERIC(15,3), amount NUMERIC(15,2)
);

DROP TABLE IF EXISTS temp_stock;
CREATE TEMP TABLE temp_stock (
    product_code VARCHAR(50), product_name VARCHAR(255), in_stock_balance NUMERIC(15,3)
);

\copy temp_sales FROM '$TMP_DIR/sales.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'UTF8');
\copy temp_stock FROM '$TMP_DIR/stock.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'UTF8');

SELECT '📥 ЗАГРУЖЕНО ИЗ CSV:' as stage, 'Строк продаж' as metric, COUNT(*)::TEXT as value FROM temp_sales
UNION ALL SELECT '', 'Строк остатков', COUNT(*)::TEXT FROM temp_stock
UNION ALL SELECT '', 'Уникальных компаний', COUNT(DISTINCT client_code)::TEXT FROM temp_sales;

ALTER TABLE documents DROP CONSTRAINT IF EXISTS documents_total_amount_check;
ALTER TABLE sales_lines DROP CONSTRAINT IF EXISTS sales_lines_amount_check;
ALTER TABLE sales_lines DISABLE TRIGGER trg_sales_lines_activity;

DELETE FROM sales_lines WHERE document_id IN (SELECT id FROM documents WHERE EXTRACT(YEAR FROM invoice_date) = $TARGET_YEAR);
DELETE FROM documents WHERE EXTRACT(YEAR FROM invoice_date) = $TARGET_YEAR;
DELETE FROM client_year_activity WHERE sales_year = $TARGET_YEAR;

SELECT '🗑️  ОЧИСТКА:' as stage, 'Удалены старые данные за ' || $TARGET_YEAR as metric, 'OK' as value;

INSERT INTO clients (code, name, ipn, okpo_code)
SELECT DISTINCT client_code, client_name, client_ipn, client_okpo
FROM temp_sales WHERE client_code IS NOT NULL AND client_code != '0'
ON CONFLICT (code) DO UPDATE SET 
    name = EXCLUDED.name, 
    ipn = COALESCE(NULLIF(EXCLUDED.ipn, ''), clients.ipn),
    okpo_code = COALESCE(NULLIF(EXCLUDED.okpo_code, ''), clients.okpo_code), 
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO products (code, name, in_stock_balance)
SELECT DISTINCT product_code, product_name, in_stock_balance
FROM temp_stock WHERE product_code IS NOT NULL AND product_code != '0'
ON CONFLICT (code) DO UPDATE SET 
    name = EXCLUDED.name, 
    in_stock_balance = EXCLUDED.in_stock_balance, 
    updated_at = CURRENT_TIMESTAMP;

INSERT INTO products (code, name, in_stock_balance)
SELECT DISTINCT product_code, product_name, 0 
FROM temp_sales 
WHERE product_code IS NOT NULL AND product_code != '0' 
  AND product_code NOT IN (SELECT code FROM products)
ON CONFLICT (code) DO NOTHING;

INSERT INTO documents (client_code, invoice_date, doc_number, total_amount)
SELECT client_code, doc_date, doc_number, SUM(amount)
FROM temp_sales WHERE client_code IS NOT NULL AND client_code != '0' AND doc_number IS NOT NULL
GROUP BY client_code, doc_date, doc_number;

INSERT INTO sales_lines (document_id, product_code, quantity, amount)
SELECT d.id, t.product_code, t.quantity, t.amount
FROM temp_sales t 
JOIN documents d ON d.client_code = t.client_code 
    AND d.invoice_date = t.doc_date AND d.doc_number = t.doc_number
WHERE t.product_code IS NOT NULL AND t.product_code != '0';

ALTER TABLE sales_lines ENABLE TRIGGER trg_sales_lines_activity;

SELECT '✅ ИТОГО ЗАГРУЖЕНО:' as stage, 'Документов' as metric, COUNT(*)::TEXT as value 
FROM documents WHERE EXTRACT(YEAR FROM invoice_date) = $TARGET_YEAR
UNION ALL SELECT '', 'Строк продаж', COUNT(*)::TEXT 
FROM sales_lines sl JOIN documents d ON sl.document_id = d.id 
WHERE EXTRACT(YEAR FROM d.invoice_date) = $TARGET_YEAR;

COMMIT;
SQL
echo "  ✅ Данные за $TARGET_YEAR загружены в БД"

# ============================================================
# ШАГ 3: Очистка и загрузка client_codes (с защитой от BOM)
# ============================================================
echo ""
echo "[3/6] Очистка и загрузка client_codes_$TARGET_YEAR.csv..."

# 🔥 Удаляем BOM, заголовки и пустые строки на уровне bash
# Берём все строки, кроме первой (заголовок), удаляем BOM, убираем пустые
tail -n +2 "$CLIENT_CODES_CSV" | sed 's/^\xEF\xBB\xBF//' | grep -v '^$' | grep -v '^[[:space:]]*$' > "$TMP_DIR/client_codes_clean.csv"

CODES_COUNT=$(wc -l < "$TMP_DIR/client_codes_clean.csv")
echo "  📋 Чистых кодов: $CODES_COUNT"

sudo -u "$DB_USER" psql -d "$DB_NAME" <<SQL
BEGIN;
DROP TABLE IF EXISTS temp_client_codes;
CREATE TEMP TABLE temp_client_codes (client_code VARCHAR(50));

-- Загружаем уже очищенный файл (без BOM, без заголовка, без пустых строк)
\copy temp_client_codes FROM '$TMP_DIR/client_codes_clean.csv' WITH (FORMAT csv, DELIMITER ';', HEADER false, ENCODING 'UTF8');

-- 🔥 Дополнительная защита в SQL: удаляем мусор
DELETE FROM temp_client_codes 
WHERE client_code IS NULL 
   OR client_code = '' 
   OR client_code = '0' 
   OR client_code ILIKE '%client%code%'   -- ловит client_code, ﻿client_code, CLIENT_CODE и т.д.
   OR client_code !~ '^[0-9]+$';           -- только цифровые коды

SELECT '📋 ЗАГРУЖЕНО КОДОВ (после очистки):' as stage, COUNT(*)::TEXT as value FROM temp_client_codes;

INSERT INTO client_year_activity (client_code, sales_year, is_active, is_manual, activation_reason)
SELECT t.client_code, $TARGET_YEAR, TRUE, TRUE, 'Ручная отметка из client_codes_' || $TARGET_YEAR || '.csv'
FROM temp_client_codes t
ON CONFLICT (client_code, sales_year) DO UPDATE SET
    is_active = TRUE, is_manual = TRUE,
    activation_reason = 'Ручная отметка из client_codes_' || $TARGET_YEAR || '.csv',
    updated_at = CURRENT_TIMESTAMP;
COMMIT;
SQL
echo "  ✅ Активные клиенты отмечены"

# ============================================================
# ШАГ 4: Пересчёт метрик
# ============================================================
echo ""
echo "[4/6] Пересчёт метрик..."
sudo -u "$DB_USER" psql -d "$DB_NAME" <<SQL
SELECT calculate_client_year_activity($TARGET_YEAR);
SELECT '📊 ПОСЛЕ ПЕРЕСЧЁТА:' as info, 
    'Всего: ' || COUNT(*)::TEXT || ', Активных: ' || SUM(CASE WHEN is_active THEN 1 ELSE 0 END)::TEXT || ', Ручных: ' || SUM(CASE WHEN is_manual THEN 1 ELSE 0 END)::TEXT as value
FROM client_year_activity WHERE sales_year = $TARGET_YEAR;
SQL
echo "  ✅ Метрики пересчитаны"

# ============================================================
# ШАГ 5: Отключение нецелевых
# ============================================================
echo ""
echo "[5/6] Отключение нецелевых компаний..."
sudo -u "$DB_USER" psql -d "$DB_NAME" <<SQL
UPDATE client_year_activity 
SET is_active = FALSE, is_manual = FALSE,
    activation_reason = 'Собственная компания',
    deactivation_reason = 'Не в списке аналитики',
    updated_at = NOW()
WHERE sales_year = $TARGET_YEAR AND is_manual = FALSE;

SELECT '🔒 ПОСЛЕ ОТКЛЮЧЕНИЯ:' as info, 
    'Всего: ' || COUNT(*)::TEXT || ', Активных: ' || SUM(CASE WHEN is_active THEN 1 ELSE 0 END)::TEXT || ', Ручных: ' || SUM(CASE WHEN is_manual THEN 1 ELSE 0 END)::TEXT as value
FROM client_year_activity WHERE sales_year = $TARGET_YEAR;
SQL
echo "  ✅ Нецелевые компании отключены"

# ============================================================
# ШАГ 6: Статусы и проверка
# ============================================================
echo ""
echo "[6/6] Обновление статусов и проверка..."
sudo -u "$DB_USER" psql -d "$DB_NAME" <<SQL
UPDATE clients c SET
    first_purchase_date = sub.first_date,
    last_purchase_date = sub.last_date,
    updated_at = NOW()
FROM (SELECT client_code, MIN(invoice_date) as first_date, MAX(invoice_date) as last_date FROM documents GROUP BY client_code) sub
WHERE c.code = sub.client_code AND (c.first_purchase_date IS NULL OR c.first_purchase_date > sub.first_date);

SELECT update_client_analytics(NULL);

-- Статусы
SELECT '📈 СТАТУСЫ КЛИЕНТОВ:' as s1, '' as s2, '' as s3;
SELECT '', status_name, cnt || ' (' || pct || '%)'
FROM (SELECT sr.status_name, sr.priority, COUNT(*)::TEXT as cnt, ROUND(COUNT(*)*100.0/SUM(COUNT(*)) OVER(),1)::TEXT as pct FROM clients c JOIN status_rules sr ON c.current_status_id=sr.id GROUP BY sr.status_name, sr.priority ORDER BY sr.priority) s;

-- Данные по годам
SELECT '', '━━━━━━━━━━━━━━━━━━━', '';
SELECT '📅 ДАННЫЕ ПО ГОДАМ:', '', '';
SELECT '', 'Год: '||year::TEXT, 'Док-тов: '||docs::TEXT||' | Клиентов: '||clients::TEXT||' | Сумма: '||ROUND(revenue/1000000,1)::TEXT||' млн ₴'
FROM (SELECT EXTRACT(YEAR FROM invoice_date)::INTEGER as year, COUNT(*) as docs, COUNT(DISTINCT client_code) as clients, SUM(total_amount) as revenue FROM documents GROUP BY year ORDER BY year) sub;

-- Активность
SELECT '', '━━━━━━━━━━━━━━━━━━━', '';
SELECT '📋 АКТИВНОСТЬ ПО ГОДАМ:', '', '';
SELECT '', 'Год: '||sales_year::TEXT, 'Всего: '||total::TEXT||' | Активных: '||active::TEXT||' | Ручных: '||manual::TEXT||' '||status
FROM (SELECT sales_year, COUNT(*)::TEXT as total, SUM(CASE WHEN is_active THEN 1 ELSE 0 END)::TEXT as active, SUM(CASE WHEN is_manual THEN 1 ELSE 0 END)::TEXT as manual, CASE WHEN SUM(CASE WHEN is_active THEN 1 ELSE 0 END)=SUM(CASE WHEN is_manual THEN 1 ELSE 0 END) THEN '✅' ELSE '❌' END as status FROM client_year_activity WHERE sales_year IN (2024,2025,2026) GROUP BY sales_year ORDER BY sales_year) sub;

-- ABC
SELECT '', '━━━━━━━━━━━━━━━━━━━', '';
SELECT '📊 ABC-АНАЛИЗ '||$TARGET_YEAR||':', '', '';
SELECT '', out_group_name, 'Компаний: '||out_total_companies::TEXT||' | Продажи: '||ROUND(out_total_sales/1000000,1)::TEXT||' млн ₴'
FROM get_abc_groups($TARGET_YEAR, 2.9) WHERE out_group_name != 'Total' ORDER BY out_total_companies DESC;

-- Сверка
SELECT '', '━━━━━━━━━━━━━━━━━━━', '';
SELECT '🔍 СВЕРКА:', '', '';
SELECT '', 'Кодов в файле: '||codes_cnt::TEXT, 'Активных в БД: '||active_cnt::TEXT
FROM (SELECT (SELECT COUNT(*) FROM client_year_activity WHERE sales_year=$TARGET_YEAR AND is_manual=TRUE) as codes_cnt, (SELECT COUNT(*) FROM client_year_activity WHERE sales_year=$TARGET_YEAR AND is_active=TRUE AND is_manual=TRUE) as active_cnt) x;

SELECT '', '━━━━━━━━━━━━━━━━━━━', '';
SELECT '✅ ЗАГРУЗКА '||$TARGET_YEAR||' ЗАВЕРШЕНА!', '', '';
SQL
echo "  ✅ Проверка завершена"

rm -rf "$TMP_DIR"
echo ""
echo "================================================"
echo "✅ ЗАГРУЗКА $TARGET_YEAR ГОДА ЗАВЕРШЕНА! (v5.3)"
echo "================================================"
