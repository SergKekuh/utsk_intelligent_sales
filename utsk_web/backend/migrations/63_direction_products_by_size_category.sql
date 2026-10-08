-- ============================================================
-- МИГРАЦИЯ 63: product_category в get_direction_products_by_size
-- Дата: 2026-10-07
-- ЦЕЛЬ: Добавить поле product_category (round/prof/welded/sheet)
--       для вкладки «Продукти за розмірами» на /direction-detail.
-- ВАЖНО: лист парсится отдельно (т.к. в parse_pipe_attributes он возвращает NULL).
-- РИСК: низкий (только новая колонка в RETURNS TABLE).
-- ============================================================

-- БЭКАП
CREATE TABLE IF NOT EXISTS backup_functions_20261007_direction_products AS
SELECT proname, pg_get_functiondef(oid) AS definition, now() AS backup_at
FROM pg_proc
WHERE proname = 'get_direction_products_by_size';

-- ═══════════════════════════════════════════════════════════
-- ПАТЧ get_direction_products_by_size
-- ═══════════════════════════════════════════════════════════

DROP FUNCTION IF EXISTS public.get_direction_products_by_size(integer, integer);

CREATE OR REPLACE FUNCTION public.get_direction_products_by_size(
    p_direction_id integer,
    p_year integer DEFAULT 2026
)
RETURNS TABLE(
    product_code character varying,
    product_name character varying,
    diameter numeric,
    wall numeric,
    is_prof boolean,
    prof_w numeric,
    prof_h numeric,
    product_category varchar,    -- НОВОЕ: round / prof / welded / sheet
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
        -- Для листа — diameter = NULL, для круглых — diameter
        CASE
            WHEN p.name ~* 'лист|ДСТУ 8540|ГОСТ 19903|ЛСТ' THEN NULL
            ELSE pa.diameter::numeric
        END AS diameter,
        -- Для листа — wall = толщина, для остальных — pa.wall
        CASE
            WHEN p.name ~* 'лист|ДСТУ 8540|ГОСТ 19903|ЛСТ' THEN (
                COALESCE(
                    replace((regexp_match(p.name, '(\d+(?:[.,]\d+)?)\s*[xх×*]\s*(\d+(?:[.,]\d+)?)\s*[xх×*]\s*(\d+(?:[.,]\d+)?)'))[1], ',', '.')::numeric,
                    replace((regexp_match(p.name, '(?i)(?:б-|б\s+|г/к\s*|лист\s+)(\d+(?:[.,]\d+)?)\s*(?:мм)?'))[1], ',', '.')::numeric,
                    replace((regexp_match(p.name, '(\d+(?:[.,]\d+)?)\s*[xх×*]\s*(\d+(?:[.,]\d+)?)'))[1], ',', '.')::numeric
                )
            )
            ELSE pa.wall::numeric
        END AS wall,
        -- Для листа is_prof = TRUE (условно), чтобы попадал в расчёт
        CASE
            WHEN p.name ~* 'лист|ДСТУ 8540|ГОСТ 19903|ЛСТ' THEN TRUE
            ELSE pa.is_prof::boolean
        END AS is_prof,
        -- Для листа — prof_w = ширина раскроя
        CASE
            WHEN p.name ~* 'лист|ДСТУ 8540|ГОСТ 19903|ЛСТ' THEN (
                COALESCE(
                    replace((regexp_match(p.name, '(\d+(?:[.,]\d+)?)\s*[xх×*]\s*(\d+(?:[.,]\d+)?)\s*[xх×*]\s*(\d+(?:[.,]\d+)?)'))[2], ',', '.')::numeric,
                    replace((regexp_match(p.name, '(\d+(?:[.,]\d+)?)\s*[xх×*]\s*(\d+(?:[.,]\d+)?)'))[2], ',', '.')::numeric,
                    1500::numeric
                )
            )
            ELSE pa.prof_w::numeric
        END AS prof_w,
        -- Для листа — prof_h = длина раскроя
        CASE
            WHEN p.name ~* 'лист|ДСТУ 8540|ГОСТ 19903|ЛСТ' THEN (
                COALESCE(
                    replace((regexp_match(p.name, '(\d+(?:[.,]\d+)?)\s*[xх×*]\s*(\d+(?:[.,]\d+)?)\s*[xх×*]\s*(\d+(?:[.,]\d+)?)'))[3], ',', '.')::numeric,
                    6000::numeric
                )
            )
            ELSE pa.prof_h::numeric
        END AS prof_h,
        -- product_category
        CASE
            WHEN p.name ~* 'лист|ДСТУ 8540|ГОСТ 19903|ЛСТ' THEN 'sheet'
            WHEN p.name ~* 'сварн|электросварн|електрозварн|ГОСТ 10704|ГОСТ 10705|ГОСТ 20295' THEN 'welded'
            WHEN pa.is_prof = TRUE THEN 'prof'
            WHEN pa.is_prof = FALSE AND pa.diameter IS NOT NULL THEN 'round'
            ELSE NULL
        END::varchar AS product_category,
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
         OR p.name ~* 'лист|ДСТУ 8540|ГОСТ 19903|ЛСТ'  -- лист пропускаем отдельно
      )
    GROUP BY
        p.code, p.name,
        pa.diameter, pa.wall, pa.is_prof, pa.prof_w, pa.prof_h
    ORDER BY total_rev DESC;
END;
$function$;

COMMENT ON FUNCTION get_direction_products_by_size(integer, integer) IS
'Продукты отрасли по типоразмерам с категоризацией (round, prof, welded, sheet)';
