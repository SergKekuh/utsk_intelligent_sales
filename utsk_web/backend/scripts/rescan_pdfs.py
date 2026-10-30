"""
Промт №83: рескан PDF в date/sertf.
- Обновляет pdf_exists в certs_registry по факту os.path.isfile.
- Перегенерирует missing_pdfs.txt.
- НЕ трогает cert_path_linux (путь уже правильный из CSV).
- Идемпотентен: можно запускать сколько угодно раз.
"""
import csv
import os
import sys
from pathlib import Path
import psycopg2

DB_DSN       = os.getenv("DB_DSN", "dbname=bd_intelligent_sales user=postgres host=localhost password=root")
CERT_BASE    = "/home/serg/Documents/SQL_postgresql/Intelligent_Sales/date/sertf"
MISSING_OUT  = Path("date/missing_pdfs.txt")

def main() -> int:
    if not os.path.isdir(CERT_BASE):
        print(f"❌ Каталог PDF не существует: {CERT_BASE}")
        return 1

    conn = psycopg2.connect(DB_DSN)
    try:
        with conn, conn.cursor() as cur:
            # Берём все сертификаты: id, cert_number, cert_filename, pdf_exists
            cur.execute("SELECT id, cert_number, cert_filename, pdf_exists FROM certs_registry;")
            certs = cur.fetchall()
            print(f"📥 Сертификатов в реестре: {len(certs)}")

            became_true  = []  # id, которые были false → стали true
            became_false = []  # id, которые были true → стали false (файл удалили)
            still_missing = []

            for cid, cnum, fname, current_flag in certs:
                path = f"{CERT_BASE}/{fname}"
                actual = os.path.isfile(path)
                if actual and not current_flag:
                    became_true.append(cid)
                elif not actual and current_flag:
                    became_false.append(cid)
                if not actual:
                    still_missing.append((cnum, fname, path))

            # Обновляем только те, у кого фактическое состояние изменилось
            if became_true:
                cur.execute("UPDATE certs_registry SET pdf_exists = TRUE WHERE id = ANY(%s);",
                            (became_true,))
                print(f"✅ Стало pdf_exists=true:  {len(became_true)}")
            if became_false:
                cur.execute("UPDATE certs_registry SET pdf_exists = FALSE WHERE id = ANY(%s);",
                            (became_false,))
                print(f"⚠️  Стало pdf_exists=false: {len(became_false)} (файл удалён/перемещён)")

            if not became_true and not became_false:
                print("ℹ️  Изменений нет: все флаги pdf_exists соответствуют диску.")

            # Итоги
            cur.execute("""
                SELECT
                  (SELECT COUNT(*) FROM certs_registry)                            AS total,
                  (SELECT COUNT(*) FROM certs_registry WHERE pdf_exists)           AS exists_true,
                  (SELECT COUNT(*) FROM certs_registry WHERE NOT pdf_exists)       AS exists_false;
            """)
            total, exists_true, exists_false = cur.fetchone()
            print(f"📊 Итого: total={total} / pdf_exists=true={exists_true} / false={exists_false}")

            # missing_pdfs.txt (все, кого нет на диске)
            with MISSING_OUT.open("w", encoding="utf-8", newline="") as f:
                w = csv.writer(f, delimiter=";", lineterminator="\n")
                w.writerow(["cert_number", "cert_filename", "cert_path_linux"])
                w.writerows(still_missing)
            print(f"   ➜ {MISSING_OUT} ({len(still_missing)} строк)")

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
