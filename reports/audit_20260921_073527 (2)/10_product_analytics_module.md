# Модуль продуктовой аналитики (`product-analytics`)

## 📌 Назначение
Модуль обеспечивает детальный анализ номенклатуры металлопроката, парсинг технических характеристик труб из наименований 1С, агрегацию по типоразмерам и drilldown-аналитику остатков.

### Файлы модуля
- **Страница:** `utsk_web/frontend/static/product-analytics.html` (параметр `?code={client_code}`)
- **API Роутер:** `utsk_web/backend/app/api/products.py`
- **Вспомогательные SQL-скрипты:** `utsk_web/sql/01_get_all_sizes_for_client.sql`, `utsk_web/sql/02_get_products_by_size_drilldown.sql`

---

## 📐 Алгоритм парсинга параметров труб (`parse_pipe_attributes`)
Функция нормализует текстовые названия номенклатуры 1С и извлекает физические атрибуты:
```sql
CREATE OR REPLACE FUNCTION public.parse_pipe_attributes(p_name character varying)
 RETURNS TABLE(diameter numeric, wall numeric, prof_w numeric, prof_h numeric, is_prof boolean, standard character varying, weight_m numeric)
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE
    dims3 TEXT[];
    dims2 TEXT[];
    v_n1 NUMERIC;
    v_n2 NUMERIC;
    v_n3 NUMERIC;
BEGIN
    -- 1. Извлечение стандарта
    standard := substring(p_name from '(ГОСТ\s*\d+[-\s]*\d*|ДСТУ\s*\d+[:\d]*|GB/T\s*\d+[:\d]*|EN\s*\d+[-\d]*)');

    -- 2. Ищем паттерн 3 чисел (профиль: A×B×S)
    dims3 := regexp_match(p_name, '(\d+(?:[.,]\d+)?)\s*[xх×]\s*(\d+(?:[.,]\d+)?)\s*[xх×]\s*(\d+(?:[.,]\d+)?)');
    -- 3. Ищем паттерн 2 чисел (круглая: D×S или профиль A×B)
    dims2 := regexp_match(p_name, '(\d+(?:[.,]\d+)?)\s*[xх×]\s*(\d+(?:[.,]\d+)?)');

    -- Замена запятой на точку (для locale)
    IF dims3 IS NOT NULL THEN
        v_n1 := REPLACE(dims3[1], ',', '.')::NUMERIC;
        v_n2 := REPLACE(dims3[2], ',', '.')::NUMERIC;
        v_n3 := REPLACE(dims3[3], ',', '.')::NUMERIC;
        
        -- ТРИ ЧИСЛА → всегда профильная
        is_prof := TRUE;
        prof_w := v_n1;
        prof_h := v_n2;
        wall := v_n3;
        diameter := GREATEST(v_n1, v_n2);
    ELSIF dims2 IS NOT NULL THEN
        v_n1 := REPLACE(dims2[1], ',', '.')::NUMERIC;
        v_n2 := REPLACE(dims2[2], ',', '.')::NUMERIC;
        
        -- ДВА ЧИСЛА → проверяем контекст
        IF p_name ~* 'проф|profile|квадрат|прямоугольн' THEN
            -- Профильная, но без явной стенки
            is_prof := TRUE;
            prof_w := v_n1;
            prof_h := v_n2;
            wall := NULL;
            diameter := GREATEST(v_n1, v_n2);
        ELSE
            -- Круглая: D×S
            is_prof := FALSE;
            diameter := v_n1;
            wall := v_n2;
        END IF;
    ELSE
        -- Не смогли распарсить
        is_prof := FALSE;
        RETURN NEXT;
        RETURN;
    END IF;

    -- 4. Вес метра для круглых труб
    IF NOT is_prof AND diameter IS NOT NULL AND wall IS NOT NULL THEN
        weight_m := ROUND((PI() * (diameter - wall) * wall * 7850 / 1000000)::NUMERIC, 3);
    END IF;

    RETURN NEXT;
END;
$function$
```

### Формат ключей типоразмеров (`size_key`):
- **Круглые трубы (Round):** `round_DxS` (например: `round_76x3.5`, `round_159x6`, `round_219x8`)
- **Квадратные трубы (Profile Square):** `prof_AxAxS` (например: `prof_40x40x3`, `prof_80x80x4`)
- **Прямоугольные трубы (Profile Rectangular):** `prof_AxBxS` (например: `prof_40x80x3`, `prof_60x120x4`)

---

## ⚙️ SQL-функции продуктовой аналитики

### 1. `get_all_sizes_for_client(p_client_code TEXT, p_year INT)`
```sql
CREATE OR REPLACE FUNCTION public.get_all_sizes_for_client(p_client_code text, p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer)
 RETURNS TABLE(size_key text, size_display text, pipe_type text, pipe_type_ua text, display_name text, purchase_count bigint, revenue numeric, pct_of_client_total numeric, stock_balance_total numeric, products_count integer, has_stock boolean)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_total_revenue NUMERIC;
BEGIN
    -- Общая выручка клиента за год
    SELECT COALESCE(SUM(sl.amount), 0)
    INTO v_total_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.client_code = p_client_code
      AND EXTRACT(YEAR FROM d.invoice_date) = p_year
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    RETURN QUERY
    WITH parsed AS (
        SELECT 
            p.code AS product_code,
            COALESCE(p.in_stock_balance, 0)::NUMERIC AS stock,
            ppa.diameter, ppa.wall, ppa.prof_w, ppa.prof_h, ppa.is_prof,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                ELSE NULL
            END AS size_key,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT || '×' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.diameter::TEXT || '×' || ppa.wall::TEXT
                ELSE NULL
            END AS size_display,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w = ppa.prof_h THEN 'square'
                WHEN ppa.is_prof AND ppa.prof_w <> ppa.prof_h THEN 'rect'
                WHEN NOT ppa.is_prof THEN 'round'
                ELSE NULL
            END AS pipe_type,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w = ppa.prof_h THEN 'Квадратная труба'
                WHEN ppa.is_prof AND ppa.prof_w <> ppa.prof_h THEN 'Прямоугольная труба'
                WHEN NOT ppa.is_prof THEN 'Круглая труба'
                ELSE NULL
            END AS pipe_type_ua
        FROM products p
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE COALESCE(p.is_service, FALSE) = FALSE
    ),
    stock_per_size AS (
        SELECT 
            par.size_key,
            SUM(par.stock) AS stock_total,
            COUNT(*) AS products_count,
            BOOL_OR(par.stock > 0) AS has_stock
        FROM parsed par
        WHERE par.size_key IS NOT NULL
        GROUP BY par.size_key
    ),
    exploded AS (
        SELECT 
            d.id AS doc_id,
            sl.amount,
            par.size_key,
            par.size_display,
            par.pipe_type,
            par.pipe_type_ua,
            par.product_code
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN parsed par ON par.product_code = sl.product_code
        WHERE d.client_code = p_client_code
          AND sl.amount > 0
          AND par.size_key IS NOT NULL
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    ),
    by_size AS (
        SELECT 
            e.size_key,
            MAX(e.size_display) AS size_display,
            MAX(e.pipe_type) AS pipe_type,
            MAX(e.pipe_type_ua) AS pipe_type_ua,
            COUNT(DISTINCT e.doc_id) AS purchase_count,
            SUM(e.amount) AS revenue,
            COUNT(DISTINCT e.product_code) AS products_count_client
        FROM exploded e
        GROUP BY e.size_key
    )
    SELECT 
        bs.size_key,
        bs.size_display,
        bs.pipe_type,
        bs.pipe_type_ua,
        bs.pipe_type_ua || ' ' || bs.size_display AS display_name,
        bs.purchase_count,
        bs.revenue,
        ROUND(bs.revenue / NULLIF(v_total_revenue, 0) * 100, 2) AS pct_of_client_total,
        COALESCE(sps.stock_total, 0) AS stock_balance_total,
        COALESCE(sps.products_count, 0)::INT AS products_count,
        COALESCE(sps.has_stock, FALSE) AS has_stock
    FROM by_size bs
    LEFT JOIN stock_per_size sps ON sps.size_key = bs.size_key
    ORDER BY bs.revenue DESC;
END;
$function$
```

### 2. `get_products_by_size_for_client(p_client_code TEXT, p_size_key TEXT, p_year INT)`
```sql
CREATE OR REPLACE FUNCTION public.get_products_by_size_for_client(p_client_code text, p_size_key text, p_year integer DEFAULT (EXTRACT(year FROM CURRENT_DATE))::integer)
 RETURNS TABLE(product_code text, product_name text, standard text, is_purchased boolean, purchase_count bigint, quantity numeric, revenue numeric, last_purchase_date date, days_since_last integer, stock_balance numeric, is_prof boolean, size_display text)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH matching_products AS (
        SELECT 
            p.code::TEXT AS product_code,
            p.name::TEXT AS product_name,
            GREATEST(COALESCE(p.in_stock_balance, 0)::NUMERIC, 0) AS stock_balance,
            ppa.standard::TEXT AS standard,
            ppa.is_prof,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT || '×' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.diameter::TEXT || '×' || ppa.wall::TEXT
                ELSE NULL
            END AS size_display,
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                ELSE NULL
            END AS size_key
        FROM products p
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE COALESCE(p.is_service, FALSE) = FALSE
    ),
    client_purchases AS (
        SELECT 
            sl.product_code::TEXT AS product_code,
            COUNT(DISTINCT d.id) AS purchase_count,
            SUM(sl.quantity) AS quantity,
            SUM(sl.amount) AS revenue,
            MAX(d.invoice_date) AS last_purchase_date
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
        GROUP BY sl.product_code
    )
    SELECT 
        mp.product_code,
        mp.product_name,
        mp.standard,
        (cp.product_code IS NOT NULL) AS is_purchased,
        COALESCE(cp.purchase_count, 0) AS purchase_count,
        COALESCE(cp.quantity, 0) AS quantity,
        COALESCE(cp.revenue, 0) AS revenue,
        cp.last_purchase_date,
        CASE 
            WHEN cp.last_purchase_date IS NOT NULL 
            THEN (CURRENT_DATE - cp.last_purchase_date::DATE)::INT
            ELSE NULL
        END AS days_since_last,
        mp.stock_balance,
        mp.is_prof,
        mp.size_display
    FROM matching_products mp
    LEFT JOIN client_purchases cp ON cp.product_code = mp.product_code
    WHERE mp.size_key = p_size_key
      AND (
          cp.product_code IS NOT NULL
          OR mp.stock_balance > 0
      )
    ORDER BY 
        (cp.product_code IS NOT NULL) DESC,
        COALESCE(cp.revenue, 0) DESC,
        mp.stock_balance DESC,
        mp.product_code;
END;
$function$
```

---

## 📊 Статистика типоразмеров в базе данных
- **Всего товаров в каталоге (`products`):** 4450
- **Круглых труб:** 4059
- **Профильных труб:** 391
- **Уникальных типоразмеров (`size_key`):** 1172
  - Круглых размеров: 886
  - Профильных размеров: 286
  - Нераспарсенные позиции (фитинги, арматура, фланцы, сопутствующие материалы): 1089

---

## 🚀 Вкладки интерфейса `product-analytics.html`
1. **📏 Все размеры труб (Drill-down):**
   - Таблица: Типоразмер, Тип трубы, Количество покупок, Выручка 2026, Доля в закупках клиента (%), Остаток на складе, Число позиций на складе.
   - Клик по строке открывает модальное окно с разделами «Куплено клиентом» и «Доступно на складе».
2. **📊 ABC-анализ номенклатуры:**
   - Распределение номенклатурных позиций по классам A, B, C по выручке.
3. **📈 Динамика 2026 vs 2025:**
   - Сравнение объемов закупок год-к-году с выявлением растущих и падающих позиций.
4. **🤖 ML-Рекомендации:**
   - Вкладка предиктивных рекомендаций.
   - **Текущая проблема (Задача 5.2):** На данной вкладке позиции отображаются по отдельным кодам товаров 1С, а не агрегированы по `size_key`, что приводит к дублированию однотипных позиций разных длин и ГОСТов.
