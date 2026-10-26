"""
Связь сертификатов с продуктами через doc_1c_number → documents.doc_number.
⚠️ Семантика спорна: product_info содержит приходные/производственные документы,
   а documents.doc_number — расходные накладные. Формат совпадает, но это разные документы.
   Поэтому в product_certificate_links проставляется link_type = 'doc_number_match'.
"""
import psycopg2
from psycopg2.extras import execute_values

DB_CONFIG = {
    'host': 'localhost',
    'database': 'bd_intelligent_sales',
    'user': 'postgres',
    'password': 'root',
}


def main():
    print('═' * 70)
    print('🔗 Связь сертификатов с продуктами (doc_number, link_type=doc_number_match)')
    print('═' * 70)

    conn = psycopg2.connect(**DB_CONFIG)
    cur = conn.cursor()

    # Проверка колонки
    cur.execute("""
        SELECT COUNT(*) FROM information_schema.columns
        WHERE table_name = 'documents' AND column_name = 'doc_number'
    """)
    if cur.fetchone()[0] == 0:
        print('❌ documents.doc_number не найдена — пропускаем')
        cur.close()
        conn.close()
        return

    # Поиск связей (порядок колонок: product_code, certificate_id, link_type)
    cur.execute("""
        SELECT DISTINCT sl.product_code, pc.id, 'doc_number_match'
        FROM product_certificates pc
        JOIN documents d ON d.doc_number = pc.doc_1c_number
        JOIN sales_lines sl ON sl.document_id = d.id
        WHERE pc.doc_1c_number IS NOT NULL
          AND sl.product_code IS NOT NULL
    """)
    links = cur.fetchall()
    print(f'Найдено связей (product_code ↔ certificate_id): {len(links)}')

    if not links:
        cur.close()
        conn.close()
        return

    # Очистка и вставка
    cur.execute('TRUNCATE TABLE product_certificate_links RESTART IDENTITY')

    insert_sql = """
        INSERT INTO product_certificate_links (product_code, certificate_id, link_type)
        VALUES %s
        ON CONFLICT (product_code, certificate_id) DO NOTHING
    """
    try:
        execute_values(cur, insert_sql, links, page_size=100)
        conn.commit()
    except Exception as e:
        conn.rollback()
        print(f'❌ Ошибка: {e}')
        cur.close()
        conn.close()
        return

    # Обновить product_code (первая связь)
    cur.execute("""
        UPDATE product_certificates pc
        SET product_code = (
            SELECT pcl.product_code FROM product_certificate_links pcl
            WHERE pcl.certificate_id = pc.id LIMIT 1
        )
        WHERE product_code IS NULL
          AND EXISTS (
              SELECT 1 FROM product_certificate_links pcl
              WHERE pcl.certificate_id = pc.id
          )
    """)
    conn.commit()

    cur.execute('SELECT COUNT(*) FROM product_certificate_links')
    n_links = cur.fetchone()[0]
    cur.execute('SELECT COUNT(DISTINCT product_code) FROM product_certificate_links')
    n_distinct_prods = cur.fetchone()[0]
    cur.execute('SELECT COUNT(*) FROM product_certificates WHERE product_code IS NOT NULL')
    n_prod = cur.fetchone()[0]

    print()
    print('═' * 70)
    print('📊 ИТОГИ')
    print('═' * 70)
    print(f'Связей в product_certificate_links: {n_links}')
    print(f'Уникальных товаров со связями:      {n_distinct_prods}')
    print(f'Сертификатов с product_code:        {n_prod}')

    cur.close()
    conn.close()
    print('\n✅ Связь завершена!')


if __name__ == '__main__':
    main()
