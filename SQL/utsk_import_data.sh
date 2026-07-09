#!/bin/bash
# ================================================================
# UTSK — Универсальная загрузка данных (с поддержкой выбора года)
# Ключевое: отключение триггера trg_sales_lines_activity на время удаления
# ================================================================
set -e

# --- 1. ПРОВЕРКА АРГУМЕНТОВ ---
if [ -z "$1" ]; then
    echo "❌ Ошибка: Не указан год для загрузки."
    echo "👉 Использование: $0 <ГОД>"
    echo "💡 Пример: $0 2025"
    echo "💡 Пример: $0 2026"
    exit 1
fi

TARGET_YEAR=$1

# Проверка, что год состоит из 4 цифр
if ! [[ "$TARGET_YEAR" =~ ^[0-9]{4}$ ]]; then
    echo "❌ Ошибка: Неверный формат года ($TARGET_YEAR). Ожидаются 4 цифры."
    exit 1
fi

DB_NAME="bd_intelligent_sales"
DB_USER="postgres"
SQL_DIR="/home/serg/Documents/SQL_postgresql/Intelligent_Sales/SQL"
TMP_DIR="/tmp/utsk_import_$TARGET_YEAR"

# Имена файлов теперь зависят от выбранного года
SALES_CSV="$SQL_DIR/unified_sales_$TARGET_YEAR.csv"
STOCK_CSV="$SQL_DIR/stock_balance_$TARGET_YEAR.csv"

echo "=== ЗАГРУЗКА $TARGET_YEAR v3.3 (Универсальная) ==="

# Проверка существования файлов перед началом
if [ ! -f "$SALES_CSV" ] || [ ! -f "$STOCK_CSV" ]; then
    echo "❌ Ошибка: Файлы для $TARGET_YEAR года не найдены в директории $SQL_DIR"
    echo "Ожидаются файлы:"
    echo " - unified_sales_$TARGET_YEAR.csv"
    echo " - stock_balance_$TARGET_YEAR.csv"
    exit 1
fi

# ШАГ 1: Конвертация CSV
echo "[1/4] Конвертация CSV за $TARGET_YEAR год..."
mkdir -p "$TMP_DIR"
sed 's/,/./g' "$SALES_CSV" | iconv -f WINDOWS-1251 -t UTF-8 > "$TMP_DIR/sales.csv" 2>/dev/null || sed 's/,/./g' "$SALES_CSV" > "$TMP_DIR/sales.csv"
sed 's/,/./g' "$STOCK_CSV" | iconv -f WINDOWS-1251 -t UTF-8 > "$TMP_DIR/stock.csv" 2>/dev/null || sed 's/,/./g' "$STOCK_CSV" > "$TMP_DIR/stock.csv"
echo "  OK: $(wc -l < $TMP_DIR/sales.csv) / $(wc -l < $TMP_DIR/stock.csv) строк"

# ШАГ 2: ВСЁ В ОДНОЙ ТРАНЗАКЦИИ
echo "[2/4] Загрузка в БД..."
sudo -u "$DB_USER" psql -d "$DB_NAME" <<SQL
BEGIN;

-- Временные таблицы (названия универсальные)
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

-- Загрузка CSV
\copy temp_sales FROM '$TMP_DIR/sales.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'UTF8');
\copy temp_stock FROM '$TMP_DIR/stock.csv' WITH (FORMAT csv, DELIMITER ';', HEADER true, ENCODING 'UTF8');

SELECT 'ЗАГРУЖЕНО:' AS info, 'Продажи' AS tbl, COUNT(*)::TEXT FROM temp_sales
UNION ALL SELECT '', 'Остатки', COUNT(*)::TEXT FROM temp_stock
UNION ALL SELECT '', 'Компаний', COUNT(DISTINCT client_code)::TEXT FROM temp_sales;

-- Снимаем ограничения
ALTER TABLE documents DROP CONSTRAINT IF EXISTS documents_total_amount_check;
ALTER TABLE sales_lines DROP CONSTRAINT IF EXISTS sales_lines_amount_check;

-- 🔥 ОТКЛЮЧАЕМ ТРИГГЕР (чтобы удаление не зависало)
ALTER TABLE sales_lines DISABLE TRIGGER trg_sales_lines_activity;

-- Очистка старых данных за ВЫБРАННЫЙ ГОД
DELETE FROM sales_lines WHERE document_id IN (SELECT id FROM documents WHERE EXTRACT(YEAR FROM invoice_date)=$TARGET_YEAR);
DELETE FROM documents WHERE EXTRACT(YEAR FROM invoice_date)=$TARGET_YEAR;
DELETE FROM client_year_activity WHERE sales_year=$TARGET_YEAR;

-- Клиенты
INSERT INTO clients (code, name, ipn, okpo_code)
SELECT DISTINCT client_code, client_name, client_ipn, client_okpo
FROM temp_sales WHERE client_code IS NOT NULL AND client_code != '0'
ON CONFLICT (code) DO UPDATE SET name=EXCLUDED.name, ipn=COALESCE(NULLIF(EXCLUDED.ipn,''), clients.ipn),
    okpo_code=COALESCE(NULLIF(EXCLUDED.okpo_code,''), clients.okpo_code), updated_at=CURRENT_TIMESTAMP;

-- Товары из остатков
INSERT INTO products (code, name, in_stock_balance)
SELECT DISTINCT product_code, product_name, in_stock_balance
FROM temp_stock WHERE product_code IS NOT NULL AND product_code != '0'
ON CONFLICT (code) DO UPDATE SET name=EXCLUDED.name, in_stock_balance=EXCLUDED.in_stock_balance, updated_at=CURRENT_TIMESTAMP;

-- Товары из продаж (новые)
INSERT INTO products (code, name, in_stock_balance)
SELECT DISTINCT product_code, product_name, 0 FROM temp_sales 
WHERE product_code IS NOT NULL AND product_code != '0' AND product_code NOT IN (SELECT code FROM products)
ON CONFLICT (code) DO NOTHING;

-- Документы
INSERT INTO documents (client_code, invoice_date, doc_number, total_amount)
SELECT client_code, doc_date, doc_number, SUM(amount)
FROM temp_sales WHERE client_code IS NOT NULL AND client_code!='0' AND doc_number IS NOT NULL
GROUP BY client_code, doc_date, doc_number;

-- Строки продаж
INSERT INTO sales_lines (document_id, product_code, quantity, amount)
SELECT d.id, t.product_code, t.quantity, t.amount
FROM temp_sales t JOIN documents d ON d.client_code=t.client_code AND d.invoice_date=t.doc_date AND d.doc_number=t.doc_number
WHERE t.product_code IS NOT NULL AND t.product_code!='0';

-- 🔥 ВКЛЮЧАЕМ ТРИГГЕР ОБРАТНО
ALTER TABLE sales_lines ENABLE TRIGGER trg_sales_lines_activity;

SELECT 'ИТОГО:' AS info, 'Документов' AS tbl, COUNT(*)::TEXT FROM documents WHERE EXTRACT(YEAR FROM invoice_date)=$TARGET_YEAR
UNION ALL SELECT '', 'Строк', COUNT(*)::TEXT FROM sales_lines sl JOIN documents d ON sl.document_id=d.id WHERE EXTRACT(YEAR FROM d.invoice_date)=$TARGET_YEAR;

COMMIT;
SQL
echo "  OK"

# ШАГ 3: Аналитика и синхронизация
echo "[3/4] Пересчёт аналитики и синхронизация за $TARGET_YEAR..."
sudo -u "$DB_USER" psql -d "$DB_NAME" <<SQL
-- Пересчитываем активность за целевой год
SELECT calculate_client_year_activity($TARGET_YEAR);

-- Синхронизируем is_active из client_year_active
UPDATE client_year_activity cya
SET is_active = TRUE, is_manual = TRUE
FROM client_year_active cyaa
WHERE cya.client_code = cyaa.client_code 
  AND cya.sales_year = $TARGET_YEAR AND cyaa.sales_year = $TARGET_YEAR 
  AND cyaa.is_active = TRUE AND cya.is_active = FALSE;

-- Отключаем нецелевые компании (is_manual = FALSE, is_active = FALSE)
UPDATE client_year_activity 
SET is_active = FALSE, is_manual = FALSE
WHERE sales_year = $TARGET_YEAR 
  AND client_code NOT IN (SELECT client_code FROM client_year_active WHERE sales_year = $TARGET_YEAR AND is_active = TRUE);

SELECT 'Активных:' AS s, COUNT(*) FROM client_year_activity WHERE sales_year=$TARGET_YEAR AND is_active=TRUE;
SQL
echo "  OK"

# ШАГ 4: Проверка ABC
echo "[4/4] Проверка ABC-анализа за $TARGET_YEAR..."
sudo -u "$DB_USER" psql -d "$DB_NAME" -c "SELECT * FROM get_abc_groups($TARGET_YEAR, 2.9);"
echo "  OK"

# Очистка
rm -rf "$TMP_DIR"
echo ""
echo "✅ ЗАГРУЗКА $TARGET_YEAR ЗАВЕРШЕНА!"
echo "Проверь: http://localhost:5000/analytics?token=utsk$TARGET_YEAR"
