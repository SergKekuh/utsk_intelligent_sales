"""
Промт №82: сверка старых product_certificate_links с новыми cert_product_links.
1. Обогащение: если старая связь (doc_number + product_code) ведёт к
   cert_sale-паре, которой нет в cert_product_links — добавить её с
   link_type='legacy_verified', is_verified=true, source='legacy'.
2. Разметка: старые связи, которые НЕ подтверждены новыми — is_deprecated=true.
   НЕ удаляем.
3. Итог: печать распределения.
"""
import json
import os
import sys
import psycopg2

DB_DSN = os.getenv("DB_DSN", "dbname=bd_intelligent_sales user=postgres host=localhost password=root")

def main() -> int:
    conn = psycopg2.connect(DB_DSN)
    try:
        with conn:
            with conn.cursor() as cur:
                # --- 1. ОБОГАЩЕНИЕ: старые связи, которых нет в новых ---
                cur.execute("""
                    SELECT DISTINCT cr.id, psr.id, cr.doc_number, psr.product_code
                    FROM product_certificate_links pcl
                    JOIN product_certificates pc ON pcl.certificate_id = pc.id
                    JOIN certs_registry cr       ON pc.cert_number = cr.cert_number
                    JOIN product_sales_registry psr
                      ON  psr.doc_number = cr.doc_number
                     AND ltrim(psr.product_code,'0') = pcl.product_code
                    WHERE NOT EXISTS (
                      SELECT 1 FROM cert_product_links cpl
                      WHERE cpl.cert_id = cr.id AND cpl.sale_id = psr.id
                    );
                """)
                to_enrich = cur.fetchall()
                print(f"💡 К обогащению из старых связей: {len(to_enrich)}")

                enrich_rows = []
                for cert_id, sale_id, doc, pcode in to_enrich:
                    enrich_rows.append((
                        cert_id, sale_id, "legacy_verified", True,
                        json.dumps({"doc_number": doc, "product_code": pcode,
                                    "source": "product_certificate_links",
                                    "level": 3}, ensure_ascii=False)
                    ))
                if enrich_rows:
                    cur.executemany(
                        "INSERT INTO cert_product_links"
                        "(cert_id, sale_id, link_type, is_verified, match_details) "
                        "VALUES (%s,%s,%s,%s,%s) "
                        "ON CONFLICT (cert_id, sale_id) DO NOTHING",
                        enrich_rows)
                    print(f"✅ Добавлено legacy_verified: {len(enrich_rows)}")

                # --- 2. РАЗМЕТКА: старые связи, не подтверждённые новыми ---
                # ВАЖНО: сначала фиксируем «снимок» подтверждённых старых id,
                # потом ставим is_deprecated = NOT in (подтверждённые).
                cur.execute("""
                    WITH confirmed AS (
                      SELECT DISTINCT pcl.id
                      FROM product_certificate_links pcl
                      JOIN product_certificates pc ON pcl.certificate_id = pc.id
                      JOIN certs_registry cr       ON pc.cert_number = cr.cert_number
                      JOIN product_sales_registry psr
                        ON  psr.doc_number = cr.doc_number
                       AND ltrim(psr.product_code,'0') = pcl.product_code
                      JOIN cert_product_links cpl
                        ON  cpl.cert_id = cr.id AND cpl.sale_id = psr.id
                    )
                    UPDATE product_certificate_links pcl
                    SET is_deprecated = NOT EXISTS (
                      SELECT 1 FROM confirmed c WHERE c.id = pcl.id
                    );
                """)
                dep = cur.rowcount
                print(f"🏷️  Разметка is_deprecated: обработано {dep}")

                # --- 3. ИТОГИ ---
                cur.execute("""
                    SELECT is_deprecated, COUNT(*)
                    FROM product_certificate_links
                    GROUP BY is_deprecated ORDER BY is_deprecated;
                """)
                print("📋 product_certificate_links:")
                for dep_flag, cnt in cur.fetchall():
                    label = "deprecated" if dep_flag else "actual"
                    print(f"   {label:10s} = {cnt}")

                cur.execute("""
                    SELECT link_type,
                           COUNT(*) AS total,
                           SUM(CASE WHEN is_verified THEN 1 ELSE 0 END) AS verified
                    FROM cert_product_links
                    GROUP BY link_type ORDER BY link_type;
                """)
                print("📊 cert_product_links:")
                for lt, cnt, ver in cur.fetchall():
                    print(f"   {lt:15s} total={cnt:5d} verified={ver}")

        print("✅ COMMIT.")
    except Exception as e:
        conn.rollback()
        print(f"❌ ROLLBACK: {e}")
        return 2
    finally:
        conn.close()
    return 0

if __name__ == "__main__":
    sys.exit(main())
