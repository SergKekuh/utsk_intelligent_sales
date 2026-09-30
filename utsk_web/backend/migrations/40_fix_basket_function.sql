CREATE OR REPLACE FUNCTION public.classify_clients_by_basket()
 RETURNS TABLE(updated_count bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_count BIGINT;
BEGIN
    WITH candidates AS (
        SELECT 
            c.code,
            c.name,
            c.direction_confidence,
            COALESCE(SUM(sl.amount) FILTER (
                WHERE ppa.is_prof = FALSE 
                  AND ppa.diameter BETWEEN 15 AND 100
                  AND ppa.wall BETWEEN 2.5 AND 5
                  AND (p.name ILIKE '%ВГП%' OR p.name ILIKE '%водогаз%')
            ), 0) / NULLIF(SUM(sl.amount), 0) AS vgp_share,
            COALESCE(SUM(sl.amount) FILTER (
                WHERE ppa.is_prof = FALSE 
                  AND ppa.diameter >= 100
                  AND ppa.wall >= 8
            ), 0) / NULLIF(SUM(sl.amount), 0) AS heavy_round_share,
            COUNT(DISTINCT CASE 
                WHEN ppa.is_prof = FALSE AND ppa.diameter >= 100 AND ppa.wall >= 8 
                THEN ppa.diameter::TEXT || 'x' || ppa.wall::TEXT 
            END) AS heavy_sizes_count,
            COALESCE(SUM(sl.amount) FILTER (WHERE ppa.is_prof = TRUE), 0) 
                / NULLIF(SUM(sl.amount), 0) AS prof_share,
            BOOL_OR(p.name ILIKE '%лист%' OR p.name ILIKE '%круг%' OR p.name ILIKE '%швелер%' OR p.name ILIKE '%балк%') AS has_steel,
            BOOL_OR(p.name ILIKE '%болт%' OR p.name ILIKE '%гайк%' OR p.name ILIKE '%шайб%' OR p.name ILIKE '%метиз%') AS has_hardware,
            (c.name ~* '(трейд|торг|постач|снаб|дистриб|метбаза|сталь|металл|пайп|стіл|метпроф|юнимет|ютмк)') AS trader_pattern
        FROM clients c
        JOIN documents d ON d.client_code = c.code
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON sl.product_code = p.code
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE c.activity_direction_id = 9  -- ✅ Только группа 9
          AND c.is_active_current = TRUE
          AND c.is_direction_manual = FALSE
          AND c.code NOT IN ('9653', '11230', '8814')
          AND EXTRACT(YEAR FROM d.invoice_date) BETWEEN 2024 AND 2026
          AND COALESCE(p.is_service, FALSE) = FALSE
        GROUP BY c.code, c.name, c.direction_confidence
        HAVING SUM(sl.amount) > 0
    ),
    classified AS (
        SELECT 
            code,
            CASE
                WHEN vgp_share > 0.60 AND NOT trader_pattern THEN 4
                WHEN prof_share > 0.60 AND NOT trader_pattern THEN 10
                WHEN heavy_round_share > 0.70 
                     AND heavy_sizes_count >= 3
                     AND NOT trader_pattern
                     AND (has_steel OR has_hardware)
                THEN 11
                WHEN heavy_round_share > 0.70 
                     AND NOT trader_pattern
                THEN 3
                ELSE 9
            END AS new_dir_id,
            CASE
                WHEN vgp_share > 0.60 AND NOT trader_pattern THEN 0.70
                WHEN prof_share > 0.60 AND NOT trader_pattern THEN 0.70
                WHEN heavy_round_share > 0.70 AND heavy_sizes_count >= 3 
                     AND NOT trader_pattern AND (has_steel OR has_hardware) THEN 0.75
                WHEN heavy_round_share > 0.70 AND NOT trader_pattern THEN 0.65
                ELSE NULL  -- Не менять
            END AS new_conf
        FROM candidates
    ),
    upd AS (
        UPDATE clients c
        SET activity_direction_id = cl.new_dir_id,
            direction_confidence = GREATEST(
                COALESCE(c.direction_confidence, 0),
                cl.new_conf
            ),
            direction_source = COALESCE(c.direction_source, 'basket')
        FROM classified cl
        WHERE c.code = cl.code
          AND cl.new_conf IS NOT NULL
          AND cl.new_dir_id != 9  -- ✅ Не трогаем тех, кто остаётся в 9
          AND c.activity_direction_id IS DISTINCT FROM cl.new_dir_id
          AND cl.new_conf >= COALESCE(c.direction_confidence, 0)
        RETURNING c.code
    )
    SELECT COUNT(*) INTO v_count FROM upd;

    RETURN QUERY SELECT v_count;
END;
$function$;
