# Модуль рекомендаций и допродаж (`recommendations`)

## 📌 Назначение и логика работы
Рекомендательная система UTSK Intelligent Sales предназначена для менеджеров по продажам. Она анализирует исторические покупки клиента, типоразмеры закупаемых труб, структуру закупок клиентов аналогичной отрасли и остатки на складе компании для предложения наиболее маржинальных и востребованных позиций.

### Файлы модуля
- **API Роутер:** `utsk_web/backend/app/api/products.py`
- **Фронтенд:**
  - `utsk_web/frontend/static/client-detail.html` (Блок умных рекомендаций и модальное окно drilldown)
  - `utsk_web/frontend/static/product-analytics.html` (Вкладка ML-рекомендаций)
- **Таблицы базы данных:**
  - `products` (каталог номенклатуры, остатки `in_stock_balance`, геометрические параметры)
  - `product_scoring` (скоринг популярности и весов товаров)
  - `product_cross_sells` (правила кросс-продаж и смежных позиций)
  - `manager_rejections_log` (журнал отклоненных менеджером позиций с триггером пенализации)

---

## ⚙️ Логика формирования рекомендаций (5 блоков приоритетов)
1. **Блок 1 (Приоритет 1 — История покупок):**
   - Товары и размеры, которые клиент регулярно покупал в 2024-2025 гг., но еще не заказывал или заказывал мало в 2026 году, при условии наличия свободного остатка на складе.
2. **Блок 2 (Приоритет 2 — Новинки и хиты отрасли):**
   - Позиции, пользующиеся высоким спросом у других компаний той же отрасли (`activity_direction_id`), которые данный клиент еще ни разу не покупал.
3. **Блок 3 (Приоритет 3 — Cross-sell / смежные размеры):**
   - Смежные типоразмеры труб (например, при покупке 76х3.5 рекомендация 76х4 или профильной трубы аналогичного сечения).
4. **Блок 4 (Приоритет 4 — Веб-активность):**
   - Позиции, просмотренные клиентом на сайте компании (из таблицы `website_behavior_log`).
5. **Блок 5 (Fallback — Топ склада):**
   - Высоколиквидные складские остатки с максимальным скорингом в `product_scoring`.

---

## 🛠 Ключевые SQL-функции

### 1. `get_recommendations_for_client(p_client_code TEXT)`
```sql
CREATE OR REPLACE FUNCTION public.get_recommendations_for_client(p_client_code text)
 RETURNS TABLE(code character varying, name character varying, in_stock numeric, purchase_count_total bigint, purchases_current_year bigint, revenue_current_year numeric, purchases_prev_year bigint, revenue_prev_year numeric, last_purchase_date date, pct_current_year numeric, pct_prev_year numeric, trend text, days_since_last integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    WITH client_total_current AS (
        SELECT COALESCE(SUM(sl.amount), 0) AS total_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE)
          AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
    ),
    client_total_prev AS (
        SELECT COALESCE(SUM(sl.amount), 0) AS total_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1
          AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
    ),
    product_stats AS (
        SELECT 
            p.code, 
            p.name, 
            COALESCE(p.in_stock_balance, 0)::NUMERIC as in_stock,
            COUNT(sl.id)::BIGINT as purchase_count_total,
            COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) THEN d.id END)::BIGINT as purchases_current_year,
            COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) THEN sl.amount ELSE 0 END), 0)::NUMERIC as revenue_current_year,
            COUNT(DISTINCT CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1 THEN d.id END)::BIGINT as purchases_prev_year,
            COALESCE(SUM(CASE WHEN EXTRACT(YEAR FROM d.invoice_date) = EXTRACT(YEAR FROM CURRENT_DATE) - 1 THEN sl.amount ELSE 0 END), 0)::NUMERIC as revenue_prev_year,
            MAX(d.invoice_date) as last_purchase_date
        FROM clients c
        JOIN documents d ON d.client_code = c.code
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON sl.product_code = p.code
        LEFT JOIN products pr ON sl.product_code = pr.code
        WHERE c.code = p_client_code 
          AND COALESCE(pr.is_service, FALSE) = FALSE AND sl.amount > 0
        GROUP BY p.code, p.name, p.in_stock_balance
        HAVING COUNT(sl.id) >= 2
    )
    SELECT 
        ps.code,
        ps.name,
        ps.in_stock,
        ps.purchase_count_total,
        ps.purchases_current_year,
        ps.revenue_current_year,
        ps.purchases_prev_year,
        ps.revenue_prev_year,
        ps.last_purchase_date,
        ROUND(ps.revenue_current_year / NULLIF((SELECT total_revenue FROM client_total_current), 0) * 100, 1)::NUMERIC as pct_current_year,
        ROUND(ps.revenue_prev_year / NULLIF((SELECT total_revenue FROM client_total_prev), 0) * 100, 1)::NUMERIC as pct_prev_year,
        (CASE 
            WHEN ps.purchases_current_year > ps.purchases_prev_year THEN '📈 Рост'
            WHEN ps.purchases_current_year < ps.purchases_prev_year THEN '📉 Спад'
            WHEN ps.purchases_current_year = ps.purchases_prev_year AND ps.purchases_current_year > 0 THEN '➡️ Стабильно'
            ELSE '🆕 Новый'
        END)::TEXT as trend,
        (CURRENT_DATE - ps.last_purchase_date::DATE)::INTEGER as days_since_last
    FROM product_stats ps
    ORDER BY ROUND(ps.revenue_current_year / NULLIF((SELECT total_revenue FROM client_total_current), 0) * 100, 1) DESC, ps.purchase_count_total DESC
    LIMIT 5;
END;
$function$
```

### 2. `get_recommendations_by_size(p_client_code TEXT, p_limit INT)`
```sql
CREATE OR REPLACE FUNCTION public.get_recommendations_by_size(p_client_code text, p_limit integer DEFAULT 5)
 RETURNS TABLE(size_key text, size_display text, pipe_type_ua text, display_name text, purchase_count_current bigint, revenue_current numeric, pct_of_client_total numeric, purchase_count_prev bigint, revenue_prev numeric, stock_balance_total numeric)
 LANGUAGE plpgsql
 STABLE
AS $function$
DECLARE
    v_year INT := EXTRACT(YEAR FROM CURRENT_DATE)::INT;
    v_total_revenue NUMERIC;
BEGIN
    -- 1. Общая товарная выручка клиента за текущий год (%)
    SELECT COALESCE(SUM(sl.amount), 0)
    INTO v_total_revenue
    FROM documents d
    JOIN sales_lines sl ON sl.document_id = d.id
    LEFT JOIN products pr ON sl.product_code = pr.code
    WHERE d.client_code = p_client_code
      AND EXTRACT(YEAR FROM d.invoice_date) = v_year
      AND COALESCE(pr.is_service, FALSE) = FALSE
      AND sl.amount > 0;

    -- 2. Основной запрос
    RETURN QUERY
    WITH parsed AS (
        SELECT 
            p.code AS product_code,
            COALESCE(p.in_stock_balance, 0)::NUMERIC AS stock,
            ppa.diameter,
            ppa.wall,
            ppa.prof_w,
            ppa.prof_h,
            ppa.is_prof,
            -- Формируем ключ размера
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                ELSE NULL
            END AS size_key,
            -- Отображаемый размер
            CASE 
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT || '×' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN ppa.prof_w::TEXT || '×' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN ppa.diameter::TEXT || '×' || ppa.wall::TEXT
                ELSE NULL
            END AS size_display,
            -- Тип трубы
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
    -- Остатки: сумма по уникальным product_code в разрезе размера
    stock_per_size AS (
        SELECT 
            par.size_key,
            SUM(par.stock) AS stock_total
        FROM parsed par
        WHERE par.size_key IS NOT NULL
        GROUP BY par.size_key
    ),
    -- Продажи клиента: разворачиваем на размеры
    exploded AS (
        SELECT 
            d.id AS doc_id,
            EXTRACT(YEAR FROM d.invoice_date)::INT AS yr,
            sl.amount,
            par.size_key,
            par.size_display,
            par.pipe_type_ua
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN parsed par ON par.product_code = sl.product_code
        WHERE d.client_code = p_client_code
          AND sl.amount > 0
          AND par.size_key IS NOT NULL
          AND EXTRACT(YEAR FROM d.invoice_date) BETWEEN (v_year - 1) AND v_year
    ),
    by_size AS (
        SELECT 
            e.size_key,
            MAX(e.size_display) AS size_display,
            MAX(e.pipe_type_ua) AS pipe_type_ua,
            COUNT(DISTINCT e.doc_id) FILTER (WHERE e.yr = v_year) AS purchase_count_current,
            COALESCE(SUM(e.amount) FILTER (WHERE e.yr = v_year), 0) AS revenue_current,
            COUNT(DISTINCT e.doc_id) FILTER (WHERE e.yr = v_year - 1) AS purchase_count_prev,
            COALESCE(SUM(e.amount) FILTER (WHERE e.yr = v_year - 1), 0) AS revenue_prev
        FROM exploded e
        GROUP BY e.size_key
    )
    SELECT 
        bs.size_key,
        bs.size_display,
        bs.pipe_type_ua,
        bs.pipe_type_ua || ' ' || bs.size_display AS display_name,
        bs.purchase_count_current,
        bs.revenue_current,
        ROUND(bs.revenue_current / NULLIF(v_total_revenue, 0) * 100, 1) AS pct_of_client_total,
        bs.purchase_count_prev,
        bs.revenue_prev,
        COALESCE(sps.stock_total, 0) AS stock_balance_total
    FROM by_size bs
    LEFT JOIN stock_per_size sps ON sps.size_key = bs.size_key
    WHERE bs.purchase_count_current > 0
    ORDER BY 
        bs.revenue_current DESC,
        bs.purchase_count_current DESC
    LIMIT p_limit;
END;
$function$
```

### 3. `get_recommendations_block2(p_direction_id INT, p_client_code TEXT)`
```sql
CREATE OR REPLACE FUNCTION public.get_recommendations_block2(p_direction_id integer, p_client_code text)
 RETURNS TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p.code, p.name, 'Новинка в вашем сегменте'::TEXT AS reason, 2 AS priority,
           COALESCE(p.in_stock_balance, 0)::NUMERIC AS in_stock, 0::INT AS purchase_count
    FROM products p
    WHERE p.anchor_direction_id = p_direction_id
      AND p.is_new_arrival = TRUE
      AND COALESCE(p.in_stock_balance, 0) > 0
      AND p.code NOT IN (
          SELECT sl2.product_code FROM sales_lines sl2
          JOIN documents d2 ON sl2.document_id = d2.id
          WHERE d2.client_code = p_client_code
      )
    ORDER BY p.in_stock_balance DESC
    LIMIT 5;
END;
$function$
```

### 4. `get_recommendations_block3(p_client_code TEXT)`
```sql
CREATE OR REPLACE FUNCTION public.get_recommendations_block3(p_client_code text)
 RETURNS TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p_related.code, p_related.name, 'С этим обычно берут'::TEXT AS reason, 3 AS priority,
           COALESCE(p_related.in_stock_balance, 0)::NUMERIC AS in_stock, 0::INT AS purchase_count
    FROM clients c
    JOIN documents d ON d.client_code = c.code
    JOIN sales_lines sl ON sl.document_id = d.id
    JOIN product_cross_sells pcs ON sl.product_code = pcs.main_product_code
    JOIN products p_related ON pcs.related_product_code = p_related.code
    WHERE c.code = p_client_code
      AND COALESCE(p_related.in_stock_balance, 0) > 0
      AND p_related.code NOT IN (
          SELECT sl2.product_code FROM sales_lines sl2
          JOIN documents d2 ON sl2.document_id = d2.id
          WHERE d2.client_code = p_client_code
      )
    GROUP BY p_related.code, p_related.name, p_related.in_stock_balance
    LIMIT 5;
END;
$function$
```

### 5. `get_recommendations_block4(p_client_code TEXT)`
```sql
CREATE OR REPLACE FUNCTION public.get_recommendations_block4(p_client_code text)
 RETURNS TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p.code, p.name, 'Вы недавно интересовались'::TEXT AS reason, 4 AS priority,
           COALESCE(p.in_stock_balance, 0)::NUMERIC AS in_stock, 0::INT AS purchase_count
    FROM website_behavior_log wbl
    JOIN products p ON wbl.product_code = p.code
    WHERE wbl.client_code = p_client_code
      AND wbl.timestamp >= CURRENT_TIMESTAMP - INTERVAL '7 days'
      AND COALESCE(p.in_stock_balance, 0) > 0
      AND p.code NOT IN (
          SELECT sl2.product_code FROM sales_lines sl2
          JOIN documents d2 ON sl2.document_id = d2.id
          WHERE d2.client_code = p_client_code
      )
    GROUP BY p.code, p.name, p.in_stock_balance
    ORDER BY MAX(wbl.timestamp) DESC
    LIMIT 5;
END;
$function$
```

### 6. `get_recommendations_fallback()`
```sql
CREATE OR REPLACE FUNCTION public.get_recommendations_fallback()
 RETURNS TABLE(code character varying, name character varying, reason text, priority integer, in_stock numeric, purchase_count integer)
 LANGUAGE plpgsql
 STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT p.code, p.name, 'Популярный товар'::TEXT AS reason, 99::INT AS priority,
           COALESCE(p.in_stock_balance, 0)::NUMERIC AS in_stock, 0::INT AS purchase_count
    FROM products p
    WHERE COALESCE(p.in_stock_balance, 0) > 0
    ORDER BY p.code
    LIMIT 5;
END;
$function$
```

---

## 🌐 Эндпоинты API
- `GET /api/recommendations/{client_code}` — классические пономенклатурные рекомендации.
- `GET /api/recommendations-by-size/{client_code}` — современные рекомендации, сгруппированные по типоразмеру трубы (`size_key`).
- `GET /api/client-products-by-size/{client_code}` — список всех размеров труб, закупавшихся клиентом.
- `GET /api/client-products-by-size/{client_code}/{size_key}` — модальный drilldown по конкретному размеру (секции «Купленные ранее» и «Доступные на складе аналоги»).

---

## 💡 Механизм обратной связи (Feedback Loop)
Если менеджер нажимает «Отклонить рекомендацию»:
1. Запрос уходит в `POST /api/recommendations/reject`.
2. Запись добавляется в `manager_rejections_log`.
3. Срабатывает триггер `trg_penalize_rejection`, вызывающий `penalize_rejected_product()`:
```sql
CREATE OR REPLACE FUNCTION public.penalize_rejected_product()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    INSERT INTO product_scoring (client_code, product_code, negative_reinforcement)
    VALUES (NEW.client_code, NEW.product_code, 3)
    ON CONFLICT (client_code, product_code) 
    DO UPDATE SET 
        negative_reinforcement = product_scoring.negative_reinforcement + 3,
        updated_at = CURRENT_TIMESTAMP;
    
    UPDATE product_scoring 
    SET is_blocked = TRUE, blocked_until = CURRENT_DATE + INTERVAL '30 days'
    WHERE client_code = NEW.client_code AND product_code = NEW.product_code AND current_weight < 0;
    
    RETURN NEW;
END;
$function$
```
4. Скоринг товара снижается, и он временно перестает предлагаться данному клиенту.
