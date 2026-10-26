"""
Нормализация date/certificates_v2.csv (in-place).
- Читает всё в память (utf-8-sig, BOM снимается).
- Нормализует даты → YYYY-MM-DD.
- Добавляет .pdf если нет.
- Пустые product_info → ''.
- Пишет обратно (utf-8 БЕЗ BOM, '\n', разделитель ';').
- Бэкап оригинала: certificates_v2.csv.bak
"""
import csv
import os
import shutil
from datetime import datetime

CSV = '/home/serg/Documents/SQL_postgresql/Intelligent_Sales/date/certificates_v2.csv'
BAK = CSV + '.bak'


def parse_date(s):
    if not s:
        return ''
    s = str(s).strip()
    for fmt in ('%Y-%m-%d', '%d.%m.%Y', '%d/%m/%Y'):
        try:
            return datetime.strptime(s, fmt).strftime('%Y-%m-%d')
        except ValueError:
            continue
    return ''


def fix_filename(fn, cert_number):
    if not fn:
        fn = str(cert_number or '')
    fn = fn.strip()
    if fn and not fn.lower().endswith('.pdf'):
        fn += '.pdf'
    return fn


def main():
    if not os.path.exists(CSV):
        print(f'❌ Не найден: {CSV}')
        return

    # Бэкап
    if not os.path.exists(BAK):
        shutil.copy2(CSV, BAK)
        print(f'💾 Бэкап: {BAK}')

    # Чтение в память
    rows = []
    errors = []
    with open(CSV, 'r', encoding='utf-8-sig', newline='') as f:
        reader = csv.DictReader(f, delimiter=';')
        for i, row in enumerate(reader, start=2):
            cert_number = (row.get('cert_number') or '').strip()
            if not cert_number:
                errors.append(f'Строка {i}: пустой cert_number')
                continue
            rows.append({
                'date':          parse_date(row.get('date', '')),
                'doc_number':    (row.get('doc_number') or '').strip(),
                'cert_number':   cert_number,
                'cert_filename': fix_filename(row.get('cert_filename'), cert_number),
                'product_info':  (row.get('product_info') or '').strip(),
                'organization':  (row.get('organization') or '').strip(),
            })

    # Запись обратно
    with open(CSV, 'w', encoding='utf-8', newline='') as f:
        writer = csv.DictWriter(f, fieldnames=[
            'date', 'doc_number', 'cert_number',
            'cert_filename', 'product_info', 'organization'
        ], delimiter=';', lineterminator='\n')
        writer.writeheader()
        writer.writerows(rows)

    print(f'✅ Нормализовано: {len(rows)}')
    print(f'⚠️  Пропущено: {len(errors)}')
    print(f'📄 Файл: {CSV}')


if __name__ == '__main__':
    main()
