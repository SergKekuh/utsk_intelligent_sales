# 📊 Миграция сертификатов: итоговая сводка

**Дата завершения:** 2026-10-26  
**Промты:** №77 (аудит) → №80 (импорт) → №81 (связка) → №82 (сверка) → №83 (legacy_verified) → №84 (API) → №85 (фронт) → №86 (архив)

## 1. Данные
| Таблица | Записей | Назначение |
|---|---|---|
| `certs_registry` | 4 733 | Сертификаты 1С (Linux-путь, pdf_exists) |
| `product_sales_registry` | 20 004 | Строки продаж 2026 (9 мес.) |
| `cert_product_links` | 10 428 | Many-to-many связи cert ↔ sale |
| `product_certificates_archive` | 2 163 | Архив старых сертификатов |
| `product_certificate_links_archive` | 13 545 | Архив старых `doc_number_match` (с `is_deprecated`) |

## 2. Качество связей
| link_type | cnt | verified |
|---|---|---|
| exact_document | 77 | 77 |
| legacy_verified | 4 763 | 4 763 |
| fuzzy_document | 5 588 | 0 |
| **Итого** | **10 428** | **4 840 (46.4%)** |

## 3. PDF
- `pdf_exists=true`: 2 165
- `pdf_exists=false`: 2 568 → `date/missing_pdfs.txt`
- При дозагрузке: `python backend/scripts/rescan_pdfs.py`

## 4. API
- `GET /api/certificates` — список (обратная совместимость)
- `GET /api/certificates/{filename}` — 200 / 410 (file_missing) / 404
- `GET /api/certificates/by-product/{code}`
- `GET /api/certificates/by-doc/{doc_number}`

## 5. Фронтенд
- `size-detail.html`: кнопка «PDF» → 200; «PDF відсутній» → toast.

## 6. Baseline 7/7 (не двигался)
1823 / 878 / 32337 / 8931 / 74953 / 4593 / 964295456.86

## 7. Что дальше
1. Дозагрузка PDF 2023–2025 в `date/sertf/` → `rescan_pdfs.py`.
2. Постепенное повышение `fuzzy_document → legacy_verified` (если появятся новые `product_code`-связи из 1С).
3. UI-фильтр «показать только сертификаты с PDF» (опционально, Промт №88).
