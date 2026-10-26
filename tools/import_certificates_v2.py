"""
Импорт сертификатов v2 → product_certificates.
- Читает date/certificates_v2.csv (UTF-8, без BOM).
- Фильтрует: только те, у кого физически есть PDF в date/sertf/.
- Извлекает doc_1c_number из product_info.
- ON CONFLICT (cert_number, file_name) DO NOTHING.
"""
import csv
import os
import re
import sys
from datetime import datetime
import psycopg2
from psycopg2.extras import execute_values

CSV_FILE = '/home/serg/Documents/SQL_postgresql/Intelligent_Sales/date/certificates_v2.csv'
CERTS_FOLDER = '/home/serg/Documents/SQL_postgresql/Intelligent_Sales/date/sertf'
DB_CONFIG = {
    'host': 'localhost',
    'database': 'bd_intelligent_sales',
    'user': 'postgres',
    'password': 'root',
}


def parse_date(s):
    if not s:
        return None
    s = str(s).strip()
    for fmt in ('%Y-%m-%d', '%d.%m.%Y', '%d/%m/%Y'):
        try:
            return datetime.strptime(s, fmt).date()
        except ValueError:
            continue
    return None


def extract_doc_1c(product_info):
    """'Звіт виробництва за зміну ЮГ000000200 від ...' → 'ЮГ000000200'"""
    if not product_info:
        return None
    m = re.search(r'([А-ЯІЇЄҐ]{2,3}\d{6,})', str(product_info), re.UNICODE)
    return m.group(1) if m else None


def main():
    print('═' * 70)
    print('📥 Импорт сертификатов v2')
    print('═' * 70)

    if not os.path.exists(CSV_FILE):
        print(f'❌ CSV: {CSV_FILE}')
        sys.exit(1)
    if not os.path.exists(CERTS_FOLDER):
        print(f'❌ PDF: {CERTS_FOLDER}')
        sys.exit(1)

    rows = []
    errors = []
    missing = []
    with_1c = 0

    with open(CSV_FILE, 'r', encoding='utf-8-sig', newline='') as f:
        reader = csv.DictReader(f, delimiter=';')
        for i, row in enumerate(reader, start=2):
            try:
                cert_number = (row.get('cert_number') or '').strip()
                file_name = (row.get('cert_filename') or '').strip()
                if not cert_number or not file_name:
                    errors.append(f'Строка {i}: пустой cert_number/file_name')
                    continue

                pdf_path = os.path.join(CERTS_FOLDER, file_name)
                if not os.path.exists(pdf_path):
                    missing.append(file_name)
                    continue

                product_info = (row.get('product_info') or '').strip() or None
                doc_1c = extract_doc_1c(product_info)
                if doc_1c:
                    with_1c += 1

                rows.append((
                    cert_number,
                    (row.get('doc_number') or '').strip() or None,
                    parse_date(row.get('date', '')),
                    file_name,
                    f'/static/certs/{file_name}',
                    product_info,
                    doc_1c,
                    (row.get('organization') or '').strip() or None,
                ))
            except Exception as e:
                errors.append(f'Строка {i}: {e}')

    print(f'📊 Прочитано: {len(rows)}')
    print(f'⚠️  Ошибок: {len(errors)}')
    print(f'❌ PDF не найдено: {len(missing)}')
    print(f'🔗 С 1С-номером: {with_1c}')

    if not rows:
        print('❌ Нечего импортировать')
        sys.exit(1)

    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()

    cur.execute('TRUNCATE TABLE product_certificate_links, product_certificates RESTART IDENTITY CASCADE')
    conn.commit()
    print('   🗑️  Очищено')

    insert_sql = """
        INSERT INTO product_certificates
            (cert_number, doc_number, cert_date, file_name, file_path,
             product_info, doc_1c_number, organization)
        VALUES %s
        ON CONFLICT (cert_number, file_name) DO NOTHING
    """

    try:
        execute_values(cur, insert_sql, rows, page_size=100)
        conn.commit()
    except Exception as e:
        conn.rollback()
        print(f'   ❌ Ошибка: {e}')
        sys.exit(1)

    cur.execute('SELECT COUNT(*) FROM product_certificates')
    total = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM product_certificates WHERE doc_1c_number IS NOT NULL")
    n_1c = cur.fetchone()[0]
    cur.execute("SELECT MIN(cert_date), MAX(cert_date) FROM product_certificates")
    mn, mx = cur.fetchone()

    print()
    print('═' * 70)
    print('📊 ИТОГИ')
    print('═' * 70)
    print(f'Всего в БД:      {total}')
    print(f'С 1С-номером:    {n_1c}')
    print(f'Даты:            {mn} — {mx}')

    cur.close()
    conn.close()
    print('\n✅ Импорт завершён!')


if __name__ == '__main__':
    main()
