"""
Промт №80: импорт CSV в product_sales_registry / certs_registry.
- cert_path_original берётся из CSV (уже Linux).
- cert_path_linux = cert_path_original; страховка: если Windows-путь —
  собираем из CERT_BASE_LINUX + cert_filename.
- Проверка os.path.isfile() -> pdf_exists + missing_pdfs.txt.
- Существующие таблицы НЕ трогаются. Одна транзакция.
"""
import csv
import os
import sys
from pathlib import Path
import psycopg2

# ---------- КОНФИГ ----------
DB_DSN        = os.getenv("DB_DSN", "dbname=bd_intelligent_sales user=postgres password=root host=localhost")
CERT_BASE_LINUX = "/home/serg/Documents/SQL_postgresql/Intelligent_Sales/date/sertf"
CSV_SALES     = Path("date/product_sales_clean.csv")
CSV_CERT      = Path("date/sertifycat_clean.csv")
MISSING_OUT   = Path("date/missing_pdfs.txt")


def read_csv(path: Path, expected_nf: int, required: list[str]):
    with path.open("r", encoding="utf-8", newline="") as f:
        reader = csv.reader(f, delimiter=";", quoting=csv.QUOTE_MINIMAL)
        header = next(reader)
        for col in required:
            if col not in header:
                raise SystemExit(f"❌ {path.name}: нет колонки {col}. Заголовок: {header}")
        rows = []
        for i, row in enumerate(reader, start=2):
            if len(row) != expected_nf:
                raise SystemExit(f"❌ {path.name}: строка {i} — {len(row)} полей, ожидали {expected_nf}")
            rows.append(row)
        return header, rows


def normalize_cert_path(path_orig: str, fname: str) -> tuple[str, str]:
    """(cert_path_original, cert_path_linux).
    Linux — оставляем; Windows — собираем из fname + CERT_BASE_LINUX (страховка).
    """
    p = (path_orig or "").strip()
    if p.startswith("/"):
        return p, p
    return p, f"{CERT_BASE_LINUX}/{fname}"


def main() -> int:
    if not CSV_SALES.exists() or not CSV_CERT.exists():
        print(f"❌ Нет CSV: {CSV_SALES} / {CSV_CERT}")
        return 1
    if not os.path.isdir(CERT_BASE_LINUX):
        print(f"❌ Каталог PDF на VM не существует: {CERT_BASE_LINUX}")
        return 1

    _, sales = read_csv(CSV_SALES, 5,
        ["product_code", "product_name", "doc_number", "quantity", "amount"])
    _, certs = read_csv(CSV_CERT, 6,
        ["date", "doc_number", "cert_number", "cert_filename", "cert_path_original", "organization"])
    print(f"📥 Прочитано: sales={len(sales)}, certs={len(certs)}")

    # ---------- ПУТИ + PDF ----------
    cert_rows, missing = [], []
    n_windows_fallback = 0
    for date_s, doc, cnum, fname, path_orig, org in certs:
        path_orig_norm, linux_path = normalize_cert_path(path_orig, fname)
        if not path_orig_norm.startswith("/"):
            n_windows_fallback += 1
        exists = os.path.isfile(linux_path)
        if not exists:
            missing.append((cnum, fname, linux_path))
        cert_rows.append((date_s, doc, cnum, fname, path_orig_norm, linux_path, org, exists))

    n_found = len(cert_rows) - len(missing)
    print(f"🔎 PDF найдено: {n_found} / {len(cert_rows)}; отсутствует: {len(missing)}")
    if n_windows_fallback:
        print(f"⚠️  Windows-путей в CSV (fallback): {n_windows_fallback}")
    if missing:
        with MISSING_OUT.open("w", encoding="utf-8", newline="") as f:
            w = csv.writer(f, delimiter=";", lineterminator="\n")
            w.writerow(["cert_number", "cert_filename", "cert_path_linux"])
            w.writerows(missing)
        print(f"   ➜ {MISSING_OUT}")

    # ---------- ИМПОРТ ----------
    conn = psycopg2.connect(DB_DSN)
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute("TRUNCATE product_sales_registry RESTART IDENTITY;")
                cur.execute("TRUNCATE certs_registry RESTART IDENTITY;")

                cur.executemany(
                    "INSERT INTO product_sales_registry"
                    "(product_code,product_name,doc_number,quantity,amount) "
                    "VALUES (%s,%s,%s,%s,%s)", sales)
                cur.executemany(
                    "INSERT INTO certs_registry"
                    "(cert_date,doc_number,cert_number,cert_filename,"
                    "cert_path_original,cert_path_linux,organization,pdf_exists) "
                    "VALUES (%s,%s,%s,%s,%s,%s,%s,%s)", cert_rows)

                # --- проверки внутри транзакции ---
                cur.execute("SELECT COUNT(*) FROM product_sales_registry;")
                n_s = cur.fetchone()[0]
                cur.execute("SELECT COUNT(*) FROM certs_registry;")
                n_c = cur.fetchone()[0]
                cur.execute("SELECT COUNT(*) FROM certs_registry WHERE pdf_exists;")
                n_pdf = cur.fetchone()[0]
                cur.execute("SELECT ROUND(SUM(amount),2), ROUND(SUM(quantity),3) FROM product_sales_registry;")
                s_amt, s_qty = cur.fetchone()

                s_amt_csv = round(sum(float(r[4]) for r in sales), 2)
                s_qty_csv = round(sum(float(r[3]) for r in sales), 3)

                if (n_s, n_c) != (len(sales), len(certs)):
                    raise RuntimeError(f"❌ Счётчики: sales {n_s}/{len(sales)}, certs {n_c}/{len(certs)}")
                if round(float(s_amt), 2) != s_amt_csv:
                    raise RuntimeError(f"❌ amount: БД {s_amt} vs CSV {s_amt_csv}")
                if round(float(s_qty), 3) != s_qty_csv:
                    raise RuntimeError(f"❌ quantity: БД {s_qty} vs CSV {s_qty_csv}")
                if n_pdf != n_found:
                    raise RuntimeError(f"❌ pdf_exists {n_pdf} != найдено {n_found}")
                cur.execute("SELECT COUNT(*) FROM certs_registry WHERE cert_path_linux NOT LIKE '/%';")
                if cur.fetchone()[0]:
                    raise RuntimeError("❌ cert_path_linux без ведущего '/'")

                # --- контроль неизменности СТАРЫХ таблиц ---
                cur.execute("SELECT COUNT(*) FROM product_certificates;")
                pc = cur.fetchone()[0]
                cur.execute("SELECT COUNT(*) FROM product_certificate_links;")
                pcl = cur.fetchone()[0]
                if (pc, pcl) != (2163, 13545):
                    raise RuntimeError(f"❌ Старые таблицы изменились: pc={pc} pcl={pcl} (ожидали 2163/13545)")

                print(f"✅ В транзакции: sales={n_s}, certs={n_c}, pdf_exists={n_pdf}")
                print(f"   amount:   {s_amt} (CSV {s_amt_csv})")
                print(f"   quantity: {s_qty} (CSV {s_qty_csv})")
                print(f"   старые не тронуты: pc={pc}, pcl={pcl}")
        print("✅ COMMIT выполнен.")
    except Exception as e:
        conn.rollback()
        print(f"❌ ROLLBACK: {e}")
        return 2
    finally:
        conn.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
