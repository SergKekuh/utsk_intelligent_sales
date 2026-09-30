-- Артефакт 4: Классификация по корзине
CREATE OR REPLACE FUNCTION public.classify_clients_by_basket(p_overwrite_manual boolean DEFAULT false)
 RETURNS TABLE(updated_count bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_count BIGINT;
BEGIN
    WITH client_baskets AS (
        SELECT 
            d.client_code,
            SUM(sl.amount) AS total_revenue,
            SUM(sl.amount) FILTER (WHERE pa.is_prof) AS prof_revenue,
            SUM(sl.amount) FILTER (WHERE NOT pa.is_prof AND pa.diameter >= 57) AS heavy_round_revenue,
            SUM(sl.amount) FILTER (WHERE p.name ILIKE '%ВГП%') AS vgp_revenue,
            SUM(sl.amount) FILTER (WHERE p.name ~* '(арматура|круг |квадрат |лист |кутник|швелер)') AS general_metal_revenue
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON sl.product_code = p.code
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) pa
        WHERE EXTRACT(YEAR FROM d.invoice_date) >= 2024
        GROUP BY d.client_code
        HAVING SUM(sl.amount) > 0
    ),
    basket_classified AS (
        SELECT 
            client_code,
            CASE
                WHEN COALESCE(vgp_revenue, 0) > total_revenue * 0.4 THEN 4 -- ЖКХ
                WHEN COALESCE(prof_revenue, 0) > total_revenue * 0.6 THEN 10 -- Металлоконструкции (проф труба > 60%)
                WHEN COALESCE(heavy_round_revenue, 0) > total_revenue * 0.6 THEN 11 -- Машиностроение (круглая > 60%)
                WHEN COALESCE(general_metal_revenue, 0) > total_revenue * 0.4 THEN 6 -- Трейдер
                WHEN COALESCE(prof_revenue, 0) > total_revenue * 0.3 AND COALESCE(heavy_round_revenue, 0) > total_revenue * 0.3 THEN 3 -- Промышленность
                ELSE 9
            END AS new_dir_id,
            0.60 AS new_conf
        FROM client_baskets
    ),
    upd AS (
        UPDATE clients c
        SET activity_direction_id = bc.new_dir_id,
            direction_confidence = bc.new_conf
        FROM basket_classified bc
        WHERE c.code = bc.client_code
          AND c.activity_direction_id = 9
          AND bc.new_dir_id <> 9
          AND (p_overwrite_manual = TRUE OR is_direction_manual = FALSE OR is_direction_manual IS NULL)
          AND (c.direction_confidence IS NULL OR c.direction_confidence < 1.0)
        RETURNING c.code
    )
    SELECT COUNT(*) INTO v_count FROM upd;

    RETURN QUERY SELECT v_count;
END;
$function$;
