### trg_ab_tests_upd ON ab_tests

- **Таблица:** `ab_tests`
- **Функция:** `update_updated_at_column`

```sql
CREATE TRIGGER trg_ab_tests_upd BEFORE UPDATE ON public.ab_tests FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
```

**Определение функции триггера:**
```sql
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
```

---

### trg_activity_directions_upd ON activity_directions

- **Таблица:** `activity_directions`
- **Функция:** `update_updated_at_column`

```sql
CREATE TRIGGER trg_activity_directions_upd BEFORE UPDATE ON public.activity_directions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
```

**Определение функции триггера:**
```sql
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
```

---

### trg_clients_sync_direction ON clients

- **Таблица:** `clients`
- **Функция:** `trg_sync_clients_direction`

```sql
CREATE TRIGGER trg_clients_sync_direction BEFORE INSERT OR UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION trg_sync_clients_direction()
```

**Определение функции триггера:**
```sql
CREATE OR REPLACE FUNCTION public.trg_sync_clients_direction()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF NEW.direction_id IS DISTINCT FROM OLD.direction_id AND (NEW.activity_direction_id IS NOT DISTINCT FROM OLD.activity_direction_id) THEN
        NEW.activity_direction_id := NEW.direction_id;
    ELSIF NEW.activity_direction_id IS DISTINCT FROM OLD.activity_direction_id THEN
        NEW.direction_id := NEW.activity_direction_id;
    END IF;
    RETURN NEW;
END;
$function$
```

---

### trg_clients_upd ON clients

- **Таблица:** `clients`
- **Функция:** `update_updated_at_column`

```sql
CREATE TRIGGER trg_clients_upd BEFORE UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
```

**Определение функции триггера:**
```sql
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
```

---

### trg_log_status_change ON clients

- **Таблица:** `clients`
- **Функция:** `log_status_change`

```sql
CREATE TRIGGER trg_log_status_change BEFORE UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION log_status_change()
```

**Определение функции триггера:**
```sql
CREATE OR REPLACE FUNCTION public.log_status_change()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF (OLD.current_status_id IS DISTINCT FROM NEW.current_status_id) THEN
        INSERT INTO status_change_log (client_code, old_status_id, new_status_id, changed_by, change_reason)
        VALUES (NEW.code, OLD.current_status_id, NEW.current_status_id, 'SYSTEM', 'Автоматический пересчет');
        NEW.status_history = COALESCE(NEW.status_history, '[]'::jsonb) || jsonb_build_object('date', CURRENT_TIMESTAMP, 'old_status', OLD.current_status_id, 'new_status', NEW.current_status_id);
    END IF;
    RETURN NEW;
END;
$function$
```

---

### trg_penalize_rejection ON manager_rejections_log

- **Таблица:** `manager_rejections_log`
- **Функция:** `penalize_rejected_product`

```sql
CREATE TRIGGER trg_penalize_rejection AFTER INSERT ON public.manager_rejections_log FOR EACH ROW EXECUTE FUNCTION penalize_rejected_product()
```

**Определение функции триггера:**
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

---

### trg_product_scoring_upd ON product_scoring

- **Таблица:** `product_scoring`
- **Функция:** `update_updated_at_column`

```sql
CREATE TRIGGER trg_product_scoring_upd BEFORE UPDATE ON public.product_scoring FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
```

**Определение функции триггера:**
```sql
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
```

---

### trg_products_upd ON products

- **Таблица:** `products`
- **Функция:** `update_updated_at_column`

```sql
CREATE TRIGGER trg_products_upd BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
```

**Определение функции триггера:**
```sql
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
```

---

### trg_sales_lines_activity ON sales_lines

- **Таблица:** `sales_lines`
- **Функция:** `trg_update_client_activity`

```sql
CREATE TRIGGER trg_sales_lines_activity AFTER INSERT OR DELETE OR UPDATE ON public.sales_lines FOR EACH ROW EXECUTE FUNCTION trg_update_client_activity()
```

**Определение функции триггера:**
```sql
CREATE OR REPLACE FUNCTION public.trg_update_client_activity()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_year INTEGER;
    v_client_code VARCHAR;
    v_doc_id INTEGER;
BEGIN
    -- Определяем ID документа (защита от DELETE)
    IF (TG_OP = 'DELETE') THEN
        v_doc_id := OLD.document_id;
    ELSE
        v_doc_id := NEW.document_id;
    END IF;

    -- Если документа нет, выходим
    IF v_doc_id IS NULL THEN RETURN NULL; END IF;

    -- Находим год и клиента
    SELECT EXTRACT(YEAR FROM invoice_date)::INTEGER, client_code 
    INTO v_year, v_client_code
    FROM documents WHERE id = v_doc_id;
    
    -- Вызываем точечный пересчет
    IF FOUND THEN
        PERFORM calculate_client_year_activity(v_year, v_client_code);
    END IF;
    
    RETURN NULL;
END;
$function$
```

---

### trg_status_rules_upd ON status_rules

- **Таблица:** `status_rules`
- **Функция:** `update_updated_at_column`

```sql
CREATE TRIGGER trg_status_rules_upd BEFORE UPDATE ON public.status_rules FOR EACH ROW EXECUTE FUNCTION update_updated_at_column()
```

**Определение функции триггера:**
```sql
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$function$
```

---

