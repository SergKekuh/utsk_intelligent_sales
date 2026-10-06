# Уроки проекта Intelligent Sales

---

## Урок 28. Родственные SQL-функции должны отдавать симметричные поля

**Дата:** 2026-10-05  
**Контекст:** Промт №18 (финал) → Промт №19  

**Симптом:** `get_profile_pipes_sizes` отдаёт `size_display`, а `get_profile_pipes_sizes_yoy` — нет. Фронт компенсирует через JS-fallback `formatSizeDisplay()`.  

**Причина:** функции писались в разное время, `yoy` группирует только по `size_key` и теряет `prof_w/prof_h/wall` внутри CTE.  

**Урок:** Если `get_A` и `get_B` работают с одной сущностью — обе должны отдавать **все производные поля**, даже если фронт умеет fallback. Асимметрия — технический долг, который повторится.  

**Фикс:** патчить через `pg_get_functiondef` → `CREATE OR REPLACE`, добавить поле и в `RETURNS TABLE`, и в `SELECT`, и в API-маппинг.  

**Проверка:**
```bash
curl -s ".../sizes?..." | python3 -c "...print(sorted(keys))"
curl -s ".../sizes-yoy?..." | python3 -c "...print(sorted(keys))"
# Оба списка должны содержать 'size_display'
```

---

## Урок 29. Заполнение метаданных (direction_source) при неизменных ключевых полях

**Дата:** 2026-10-05  
**Контекст:** Промт №22 (Миграция 54)  

**Симптом:** 541 активный клиент (1496 всего) имел `direction_source = NULL`, при этом `activity_direction_id` и `direction_confidence` были заполнены. В карточке клиента отображался бейдж «❓ Не визначено».  

**Причина:** В миграции 41 было выполнено `UPDATE clients SET direction_source = NULL;`, затем запущена `classify_clients_directions(FALSE)`. Но условие внутри функции:
```sql
WHERE c.code = cl.code
  AND c.activity_direction_id IS DISTINCT FROM cl.new_dir_id
```
пропускало всех клиентов, чья отрасль уже совпадала с результатом regex (так как была предварительно восстановлена из бэкапа). В результате `direction_source` так и остался `NULL`.  

**Урок:** При обновлении сопутствующих метаданных (source, timestamp, author) условие `UPDATE` должно учитывать случаи, когда ключевое поле не изменилось, но метаданные отсутствуют:
```sql
WHERE c.code = cl.code
  AND (
      (c.activity_direction_id IS DISTINCT FROM cl.new_dir_id AND cl.new_conf >= COALESCE(c.direction_confidence, 0))
      OR ((c.direction_source IS NULL OR c.direction_source = 'unknown') AND cl.new_dir_id != 9)
  )
```

**Фикс:** Миграция 54 выполнила бэкфилл:
1. `confidence = 1.00` → `'manual'` (36 клиентов)
2. `activity_direction_id NOT IN (9, 16)` → `'auto_name'` (713 клиентов)
3. `activity_direction_id IN (9, 16)` → `'unknown'` (747 клиентов)
И пропатчила `classify_clients_directions` и `classify_clients_by_basket` для будущих запусков.


---

## Урок 30. Не отсекать сущности по частичным атрибутам и разделять геометрию при группировке

**Дата:** 2026-10-05  
**Контекст:** Промт №25 (Миграция 55)

**Симптом:** Во вкладке «Продукты по размерам» страницы отрасли (`direction-detail.html`) отображались только круглые трубы. Профильные трубы полностью отсутствовали, хотя в отрасли «Трейдер» их 201 позиция. Кроме того, профильные трубы разного сечения (например, 200×150 и 200×100) сливались бы в одну строку по псевдо-диаметру 200 (`GREATEST`).

**Причина:**
1. Функция `parse_pipe_attributes()` для профильных труб возвращает `prof_w` и `prof_h`, оставляя `diameter = NULL`.
2. Функция `get_direction_products_by_size` содержала фильтр `WHERE pa.diameter IS NOT NULL`, который молча отсекал 100% профильных труб.
3. В группировке использовался только `pa.diameter`, из-за чего терялась ширина и высота профиля (`prof_w`, `prof_h`).

**Урок:**
- Фильтрация по атрибуту конкретного типа изделия (`pa.diameter IS NOT NULL`) в универсальных функциях приводит к бесследной потере других категорий. Фильтр должен допускать все валидные типы: `WHERE pa.diameter IS NOT NULL OR (pa.prof_w IS NOT NULL AND pa.prof_h IS NOT NULL)`.
- Нельзя сжимать 2D-геометрию (A×B) в скаляр `GREATEST(A, B)` для экономии колонок в таблице: разные изделия склеиваются, искажая аналитику продаж.
- Для совместимости API-роутов с разным именованием в URL (единственное vs множественное число: `/direction/...` и `/directions/...`) использовать множественные декораторы FastAPI `@router.get(...)`.

**Фикс:** Миграция 55:
- Расширила `RETURNS TABLE` функции `get_direction_products_by_size` полями `prof_w numeric, prof_h numeric`.
- Расширила `WHERE` и `GROUP BY` для поддержки сечений профильных труб.
- Добавила алиас-роут в `directions.py`.
- На фронтенде добавлен тумблер `[🟢 Круглі] [🟦 Профільні]` с раздельной отрисовкой матриц `Ø × t` и `A×B × t`.

---

## Урок 31. Массовая украинизация — от аудита к финишу + локализация БД

**Дата:** 2026-10-06  
**Контекст:** Промты №26–43

**Симптом:** Двуязычный UI. Плюс — **статусы в БД** (`status_rules.status_name`) на русском и **использовались в логике** 10 функций (`calculate_client_status`, `update_client_analytics`, `get_funnel_data`, `get_client_status_2025`, `get_top_clients_80pct` и др.).

**Урок:**
- **Порядок критичен:** СНАЧАЛА функции (привязка к `id`), ПОТОМ `UPDATE status_rules`.
- **Функции, которые ищут по тексту** — патчить на поиск по `id`. Это **устраняет** зависимость от локализации.
- **`get_top_clients_80pct`** — большая функция. Патч через `pg_get_functiondef` + `sed` + `CREATE OR REPLACE`.
- **Стадии воронки** (`'Разові (1)'`, `'Повторні (2-3)'` и т.д.) — **тоже в SQL**, не только в UI.
- **`toLocaleString('ru-RU')` → `'uk-UA'`**, месяцы — через массив.
- **Таблица может называться не так, как ожидаешь** (`statuses` vs `status_rules`).
- **Проверка после миграции:** `SELECT calculate_client_status('4501')` — не NULL.

**Фикс:** миграция 57 (10 функций + UPDATE), патчи `clients.py` + `index.html`. Baseline неизменен.

**Метрика:** ~16 часов, 32 страницы, +4 урока.
