-- ============================================================
-- МИГРАЦИЯ 55: get_direction_products_by_size — добавить prof_w, prof_h
-- Дата: 2026-10-05
--
-- ЦЕЛЬ: 1. Разделить круглые и профильные трубы (в WHERE пропускать оба типа).
--       2. Прокинуть prof_w, prof_h до фронта.
--       3. Исправить геометрию профильных (не сливать 200×150 и 200×100).
--
-- ПРИЧИНА: Сейчас WHERE pa.diameter IS NOT NULL отсекает профильные
--          (у них diameter = NULL, а есть prof_w × prof_h).
--
-- РИСК: низкий (только добавляем поля в RETURNS TABLE + расширяем WHERE).
-- ОТКАТ: DROP FUNCTION + восстановить из бэкапа
--        backup_functions_20261005_products_by_size.
-- ============================================================

-- БЭКАП
CREATE TABLE IF NOT EXISTS backup_functions_20261005_products_by_size AS
SELECT proname, pg_get_functiondef(oid) AS definition, now() AS backup_at
FROM pg_proc
WHERE proname = 'get_direction_products_by_size';

-- ПЕРЕСОЗДАТЬ ФУНКЦИЮ
DROP FUNCTION IF EXISTS public.get_direction_products_by_size(integer, integer);

CREATE OR REPLACE FUNCTION public.get_direction_products_by_size(
    p_direction_id integer,
    p_year integer DEFAULT 2026
)
RETURNS TABLE(
    product_code varchar,
    product_name varchar,
    diameter numeric,
    wall numeric,
    is_prof boolean,
    prof_w numeric,        -- НОВОЕ
    prof_h numeric,        -- НОВОЕ
    total_quantity numeric,
    total_revenue numeric,
    clients_count bigint,
    invoices_count bigint,
    avg_price numeric
)
LANGUAGE plpgsql
STABLE
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        p.code::varchar,
        p.name::varchar,
        pa.diameter::numeric,
        pa.wall::numeric,
        pa.is_prof::boolean,
        pa.prof_w::numeric,     -- НОВОЕ
        pa.prof_h::numeric,     -- НОВОЕ
        COALESCE(SUM(sl.quantity), 0)::numeric AS total_qty,
        COALESCE(SUM(sl.amount), 0)::numeric AS total_rev,
        COUNT(DISTINCT d.client_code)::bigint AS cli_cnt,
        COUNT(DISTINCT d.id)::bigint AS inv_cnt,
        ROUND(COALESCE(SUM(sl.amount), 0) / NULLIF(SUM(sl.quantity), 0), 2)::numeric AS avg_price
    FROM clients c
    JOIN documents d ON d.client_code = c.code AND EXTRACT(YEAR FROM d.invoice_date) = p_year
    JOIN sales_lines sl ON sl.document_id = d.id
    JOIN products p ON p.code = sl.product_code AND p.is_service = FALSE
    CROSS JOIN LATERAL parse_pipe_attributes(p.name) pa
    WHERE c.activity_direction_id = p_direction_id
      AND c.code NOT IN ('9653', '11230', '8814')
      AND (
            pa.diameter IS NOT NULL
         OR (pa.prof_w IS NOT NULL AND pa.prof_h IS NOT NULL)
      )
    GROUP BY p.code, p.name, pa.diameter, pa.wall, pa.is_prof, pa.prof_w, pa.prof_h
    ORDER BY total_rev DESC;
END;
$function$;

-- ПРОВЕРКА
SELECT
    'OK' AS status,
    pg_get_function_result(oid) AS result
FROM pg_proc
WHERE proname = 'get_direction_products_by_size';
