# Эталонные базовые метрики (Baseline Metrics)

> [!IMPORTANT]
> Данные контрольные суммы получены прямыми SQL-запросами к базе данных `bd_intelligent_sales` на дату **2026-09-21**. После применения любых новых миграций, скриптов или правок функций эти цифры должны строго сохраняться!

---

## 🎯 Контрольные эталонные значения

```yaml
clients:
  total: 1754
  active_current: 729
  with_direction: 1754
  with_direction_non_mixed: 798
  with_ipn: 1322
  with_okpo: 1397

documents:
  total: 29179
  year_2024: 11574
  year_2025: 11832
  year_2026: 5773

sales_lines:
  total: 67584

products:
  total: 4450
  service: 0
  goods: 4450
  profile: 391
  round: 4059
  in_stock: 2594

unique_sizes:
  total: 1172
  round: 886
  profile: 286

revenue_total:
  year_2024: 904781175.38
  year_2025: 1054790600.24
  year_2026: 563407633.09

revenue_goods_2026:
  total: 563416633.09
```

---

## 🧪 Скрипт валидации эталонных метрик

Для проверки базы данных после миграций выполните:
```bash
PGPASSWORD=root psql -h localhost -U postgres -d bd_intelligent_sales -c "
SELECT 
    (SELECT count(*) FROM clients) AS clients_total,
    (SELECT count(*) FROM clients WHERE is_active_current = TRUE) AS clients_active_current,
    (SELECT count(*) FROM clients WHERE activity_direction_id IS NOT NULL) AS clients_with_direction,
    (SELECT count(*) FROM clients WHERE ipn IS NOT NULL AND trim(ipn) != '') AS clients_with_ipn,
    (SELECT count(*) FROM clients WHERE (edrpou IS NOT NULL AND trim(edrpou) != '') OR (okpo_code IS NOT NULL AND trim(okpo_code) != '')) AS clients_with_okpo,
    (SELECT count(*) FROM documents) AS documents_total,
    (SELECT count(*) FROM documents WHERE EXTRACT(YEAR FROM invoice_date) = 2024) AS doc_2024,
    (SELECT count(*) FROM documents WHERE EXTRACT(YEAR FROM invoice_date) = 2025) AS doc_2025,
    (SELECT count(*) FROM documents WHERE EXTRACT(YEAR FROM invoice_date) = 2026) AS doc_2026,
    (SELECT count(*) FROM sales_lines) AS sales_lines_total,
    (SELECT count(*) FROM products) AS products_total,
    (SELECT count(*) FROM products WHERE is_service = TRUE) AS products_service,
    (SELECT count(*) FROM products WHERE COALESCE(is_service, FALSE) = FALSE) AS products_goods;
"
```
