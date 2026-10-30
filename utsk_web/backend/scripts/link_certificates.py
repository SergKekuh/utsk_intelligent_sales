"""
Промт №81: связка certs_registry ↔ product_sales_registry.
- Уровень 1: exact_document (1 cert + 1 product на накладную).
- Уровень 2: exact_match / fuzzy_document (по маркерам размер/сталь).
- Связь many-to-many. pdf_exists игнорируется.
- Старые doc_number_match НЕ трогаются.
"""
import json
import os
import re
import sys
import psycopg2

DB_DSN = os.getenv("DB_DSN", "dbname=bd_intelligent_sales user=postgres host=localhost password=root")

# Регулярки для маркеров
SIZE_RE   = re.compile(r'(\d{2,4})\s*[хx×]\s*(\d{2,4})', re.IGNORECASE)
THICK_RE  = re.compile(r'[хx×]\s*(\d{1,2})(?:\s|$)', re.IGNORECASE)
STEEL_RE  = re.compile(r'ст\s*(\d+(?:[гГ][2２]?[сС]?)?|09[гГ]2[сС])', re.IGNORECASE)

def extract_markers(name: str) -> dict:
    """Извлекает маркеры из имени товара или файла сертификата."""
    n = name or ''
    out = {"sizes": [], "steels": [], "raw": n}
    for m in SIZE_RE.finditer(n):
        a, b = m.group(1), m.group(2)
        out["sizes"].append(f"{a}x{b}")
    for m in STEEL_RE.finditer(n):
        out["steels"].append(m.group(1).lower())
    return out

def markers_overlap(p: dict, c: dict) -> tuple[bool, dict]:
    """Сравнивает маркеры. Возвращает (совпало, детали)."""
    sizes_ok = bool(set(p["sizes"]) & set(c["sizes"])) if p["sizes"] and c["sizes"] else False
    steels_ok = bool(set(p["steels"]) & set(c["steels"])) if p["steels"] and c["steels"] else False
    details = {
        "product_sizes": p["sizes"], "cert_sizes": c["sizes"],
        "product_steels": p["steels"], "cert_steels": c["steels"],
        "sizes_match": sizes_ok, "steels_match": steels_ok
    }
    # Совпадение = хотя бы один размер ИЛИ (если стали есть с обеих сторон) сталь
    ok = sizes_ok or steels_ok
    return ok, details

def main() -> int:
    conn = psycopg2.connect(DB_DSN)
    try:
        with conn:
            with conn.cursor() as cur:
                # Чистим таблицу связей (она новая)
                cur.execute("TRUNCATE cert_product_links RESTART IDENTITY;")

                # Загружаем сертификаты и продажи в память (4733 + 20004 — небольшие объёмы)
                cur.execute("SELECT id, doc_number, cert_number, cert_filename FROM certs_registry;")
                certs = cur.fetchall()
                cur.execute("SELECT id, product_code, product_name, doc_number FROM product_sales_registry;")
                sales = cur.fetchall()

                # Группируем по doc_number
                certs_by_doc = {}
                for cid, doc, cnum, fname in certs:
                    certs_by_doc.setdefault(doc, []).append(
                        {"id": cid, "cert_number": cnum, "cert_filename": fname})
                sales_by_doc = {}
                for sid, pcode, pname, doc in sales:
                    sales_by_doc.setdefault(doc, []).append(
                        {"id": sid, "product_code": pcode, "product_name": pname})

                # Пересечение документов
                common_docs = set(certs_by_doc) & set(sales_by_doc)
                print(f"📊 Документов с обеих сторон: {len(common_docs)}")

                links = []  # (cert_id, sale_id, link_type, is_verified, match_details_json)

                for doc in common_docs:
                    cs = certs_by_doc[doc]
                    ss = sales_by_doc[doc]

                    # УРОВЕНЬ 1: 1 сертификат + 1 товар → exact_document
                    if len(cs) == 1 and len(ss) == 1:
                        c, s = cs[0], ss[0]
                        links.append((
                            c["id"], s["id"], "exact_document", True,
                            json.dumps({"doc_number": doc, "level": 1}, ensure_ascii=False)
                        ))
                        continue

                    # УРОВЕНЬ 2: несколько → по маркерам
                    for c in cs:
                        c_mark = extract_markers(c["cert_filename"])
                        for s in ss:
                            p_mark = extract_markers(s["product_name"])
                            ok, details = markers_overlap(p_mark, c_mark)
                            link_type = "exact_match" if ok else "fuzzy_document"
                            is_verified = bool(ok)
                            links.append((
                                c["id"], s["id"], link_type, is_verified,
                                json.dumps({"doc_number": doc, "level": 2, **details},
                                           ensure_ascii=False)
                            ))

                print(f"🔗 Связей к вставке: {len(links)}")
                cur.executemany(
                    "INSERT INTO cert_product_links"
                    "(cert_id, sale_id, link_type, is_verified, match_details) "
                    "VALUES (%s,%s,%s,%s,%s)", links)

                # Проверки
                cur.execute("SELECT link_type, COUNT(*), SUM(CASE WHEN is_verified THEN 1 ELSE 0 END) "
                            "FROM cert_product_links GROUP BY link_type ORDER BY link_type;")
                print("✅ Распределение связей:")
                for lt, cnt, ver in cur.fetchall():
                    print(f"   {lt:15s} total={cnt:5d} verified={ver}")
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
