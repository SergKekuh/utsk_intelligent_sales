"""
Промт №83 (подшаг 3.2): повышение fuzzy_document -> legacy_verified
там, где старая связь (is_deprecated=false) подтверждает пару.
- fuzzy_document: остаётся у не-подтверждённых.
- legacy_verified: новый link_type, is_verified=true.
- Идемпотентность: повторный запуск ничего не изменит (WHERE link_type='fuzzy_document').
"""
import json
import os
import sys
import psycopg2

DB_DSN = os.getenv("DB_DSN", "dbname=bd_intelligent_sales user=postgres host=localhost password=root")

def main() -> int:
    conn = psycopg2.connect(DB_DSN)
    try:
        with conn, conn.cursor() as cur:
            # Обновляем fuzzy -> legacy_verified, где старая связь подтверждает
            cur.execute("""
                UPDATE cert_product_links cpl
                SET link_type = 'legacy_verified',
                    is_verified = true,
                    match_details = match_details || jsonb_build_object(
                        'upgraded_from', 'fuzzy_document',
                        'source', 'product_certificate_links'
                    )
                WHERE cpl.link_type = 'fuzzy_document'
                  AND EXISTS (
                    SELECT 1
                    FROM product_certificate_links pcl
                    JOIN product_certificates pc ON pcl.certificate_id = pc.id
                    JOIN certs_registry cr       ON pc.cert_number = cr.cert_number
                    JOIN product_sales_registry psr ON psr.id = cpl.sale_id
                    WHERE cr.id = cpl.cert_id
                      AND psr.doc_number = cr.doc_number
                      AND ltrim(psr.product_code,'0') = pcl.product_code
                      AND pcl.is_deprecated = false
                  );
            """)
            print(f"✅ Повышено fuzzy -> legacy_verified: {cur.rowcount}")

            # Итоги
            cur.execute("""
                SELECT link_type, COUNT(*),
                       SUM(CASE WHEN is_verified THEN 1 ELSE 0 END)
                FROM cert_product_links
                GROUP BY link_type ORDER BY link_type;
            """)
            print("📊 cert_product_links после повышения:")
            for lt, cnt, ver in cur.fetchall():
                print(f"   {lt:20s} total={cnt:5d} verified={ver}")
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
