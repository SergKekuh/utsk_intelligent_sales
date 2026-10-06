-- Migration 54: Backfill direction_source and patch classification functions
-- Author: Antigravity
-- Date: 2026-10-05

-- 1. Patch classify_clients_directions to ensure direction_source is set
CREATE OR REPLACE FUNCTION public.classify_clients_directions(p_overwrite_manual boolean DEFAULT false)
 RETURNS TABLE(updated_count bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_count BIGINT;
BEGIN
    WITH classified AS (
        SELECT 
            c.code,
            CASE
                WHEN c.name ~* '(агро|аграр|ферм|сгп|сг |зерн|элеватор|елеватор|урожай|сад |птиц|дір|жон дір|кукурудз|насін)' THEN 1
                WHEN c.name ~* '(буд|строит|монтаж|кровл|бетон|девелоп|покров|фасад|покрів|архітек|інжинір)' THEN 2
                WHEN c.name ~* '(кріплен|метиз|конструкт|болт|гайк|сітк|дрот|перфор)' THEN 10
                WHEN c.name ~* '(маш|метмаш|турбо|агрегат|станум|гідравлік|обладнан|механік|верстат|вагов|ваги)' THEN 11
                WHEN c.name ~* '(енерг|електр|світл|кабель|трансформатор|генератор|солар)' THEN 12
                WHEN c.name ~* '(авто|трак|мотор|сто |шиномонтаж|автомоб|еверласт|причеп|вагон)' THEN 13
                WHEN c.name ~* '(транс|логіст|доставк|карго|перевез|експедиц)' THEN 14
                WHEN c.name ~* '(завод| з-д|пром|нафт|газ|фабр|індустр|трубоізол|насос|котел|комбінат|хім|полімер)' THEN 3
                WHEN c.name ~* '(водоканал|жкг|жкх|тепло|комун| кп | крп |водовідвід|водопостач|жек|осбб|ліфт|газопостач)' THEN 4
                WHEN c.name ~* '(дорож|автодор|шлях|міст |мост|асфальт|автошлях)' THEN 5
                WHEN c.name ~* '(виробничо-комерц|производственно-коммерч|вкф|вир-торг|твк|втп|нвп|пнвп)' THEN 8
                WHEN c.name ~* '(метбаза|металлопрокат|база стал|сталь груп|металл|метал|трейд|дистриб|сбыт|склад|торг|постач| тк | тд |прокат|сталеніт|інтерстил|оксімет|є прокат|пайп|стіл|метпроф|юнимет|ютмк|метаст|сплав|арк-групп|базис|арматура|фітинг)' THEN 6
                WHEN c.name ~* '(держ|міськ|район|управлін|лікарн|школ|універ|ритейл|маркет|супермаркет)' THEN 15
                WHEN c.name ~* '(фоп|флп| чл|фізична особа|підприємець)' OR (length(c.edrpou) = 10 AND c.edrpou ~ '^[0-9]+$') THEN 7
                WHEN c.name ~* '(пружин|пруж|технік|техник|нво|нвп|нвф|інтерконструкц|станк|станок|редуктор|насосн)' THEN 11
                WHEN c.name ~* '(нафт|нефт|оіл|ойл|oil|енерджі|енерго|полімер|хім|хим)' THEN 3
                WHEN c.name ~* '(стал|стил|steel|імпекс|импекс|impex|холд|ресурс|континент|преміум)' THEN 6
                ELSE COALESCE(c.activity_direction_id, 9)
            END AS new_dir_id,
            CASE
                WHEN c.name ~* '(агро|аграр|ферм|сгп|сг |зерн|элеватор|елеватор|урожай|сад |птиц|дір|жон дір|кукурудз|насін|буд|строит|монтаж|кровл|бетон|девелоп|покров|фасад|покрів|архітек|інжинір|кріплен|метиз|конструкт|болт|гайк|сітк|дрот|перфор|маш|метмаш|турбо|агрегат|станум|гідравлік|обладнан|механік|верстат|вагов|ваги|енерг|електр|світл|кабель|трансформатор|генератор|солар|авто|трак|мотор|сто |шиномонтаж|автомоб|еверласт|причеп|вагон|транс|логіст|доставк|карго|перевез|експедиц|завод| з-д|пром|нафт|газ|фабр|індустр|трубоізол|насос|котел|комбінат|хім|полімер|водоканал|жкг|жкх|тепло|комун| кп | крп |водовідвід|водопостач|жек|осбб|ліфт|газопостач|дорож|автодор|шлях|міст |мост|асфальт|автошлях|виробничо-комерц|производственно-коммерч|вкф|вир-торг|твк|втп|нвп|пнвп|метбаза|металлопрокат|база стал|сталь груп|металл|метал|трейд|дистриб|сбыт|склад|торг|постач| тк | тд |прокат|сталеніт|інтерстил|оксімет|є прокат|держ|міськ|район|управлін|лікарн|школ|універ|ритейл|маркет|супермаркет|фоп|флп| чл|фізична особа|підприємець)' OR (length(c.edrpou) = 10 AND c.edrpou ~ '^[0-9]+$')
                THEN 0.85
                WHEN c.name ~* '(пружин|пруж|технік|техник|нво|нвп|нвф|інтерконструкц|станк|станок|редуктор|насосн)' THEN 0.65
                WHEN c.name ~* '(нафт|нефт|оіл|ойл|oil|енерджі|енерго|полімер|хім|хим)' THEN 0.65
                WHEN c.name ~* '(стал|стил|steel|імпекс|импекс|impex|холд|ресурс|континент|преміум)' THEN 0.65
                ELSE 0.50
            END AS new_conf
        FROM clients c
        WHERE (p_overwrite_manual = TRUE OR c.is_direction_manual = FALSE OR c.is_direction_manual IS NULL)
    ),
    upd AS (
        UPDATE clients c
        SET activity_direction_id = cl.new_dir_id,
            direction_confidence = GREATEST(
                COALESCE(c.direction_confidence, 0),
                cl.new_conf
            ),
            direction_source = 'auto_name'
        FROM classified cl
        WHERE c.code = cl.code
          AND (
              (c.activity_direction_id IS DISTINCT FROM cl.new_dir_id AND cl.new_conf >= COALESCE(c.direction_confidence, 0))
              OR ((c.direction_source IS NULL OR c.direction_source = 'unknown') AND cl.new_dir_id != 9)
          )
        RETURNING c.code
    )
    SELECT COUNT(*) INTO v_count FROM upd;

    RETURN QUERY SELECT v_count;
END;
$function$;

-- 2. Patch classify_clients_by_basket
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
            BOOL_OR(p.name ILIKE '%порізка%' OR p.name ILIKE '%резка%') AS has_porezka,
            (c.name ~* '(трейд|торг|постач|снаб|дистриб|метбаза|сталь|металл|пайп|стіл|метпроф|юнимет|ютмк)') AS trader_pattern
        FROM clients c
        JOIN documents d ON d.client_code = c.code
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON sl.product_code = p.code
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE c.activity_direction_id = 9
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
                WHEN heavy_round_share > 0.80
                     AND NOT trader_pattern
                     AND (has_steel OR has_hardware)
                THEN 11
                WHEN heavy_round_share > 0.50
                     AND has_porezka
                     AND NOT trader_pattern
                THEN 11
                WHEN heavy_round_share > 0.70
                     AND NOT trader_pattern
                THEN 3
                ELSE 9
            END AS new_dir_id,
            CASE
                WHEN vgp_share > 0.60 AND NOT trader_pattern THEN 0.70
                WHEN prof_share > 0.60 AND NOT trader_pattern THEN 0.70
                WHEN heavy_round_share > 0.80 AND NOT trader_pattern AND (has_steel OR has_hardware) THEN 0.75
                WHEN heavy_round_share > 0.50
                     AND has_porezka AND NOT trader_pattern THEN 0.70
                WHEN heavy_round_share > 0.70 AND NOT trader_pattern THEN 0.65
                ELSE NULL  
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
            direction_source = 'basket'
        FROM classified cl
        WHERE c.code = cl.code
          AND cl.new_conf IS NOT NULL
          AND cl.new_dir_id != 9
          AND c.activity_direction_id IS DISTINCT FROM cl.new_dir_id
          AND cl.new_conf >= COALESCE(c.direction_confidence, 0)
        RETURNING c.code
    )
    SELECT COUNT(*) INTO v_count FROM upd;

    RETURN QUERY SELECT v_count;
END;
$function$;

-- 3. Backfill direction_source
-- Step 1: Clients with confidence = 1.00 and NULL source -> manual
UPDATE clients
SET direction_source = 'manual'
WHERE direction_source IS NULL
  AND direction_confidence = 1.00;

-- Step 2: Clients with classified direction (activity_direction_id != 9, 16) and NULL source -> auto_name
UPDATE clients
SET direction_source = 'auto_name'
WHERE direction_source IS NULL
  AND activity_direction_id NOT IN (9, 16);

-- Step 3: Clients with unclassified direction (activity_direction_id IN (9, 16)) and NULL source -> unknown
UPDATE clients
SET direction_source = 'unknown'
WHERE direction_source IS NULL
  AND activity_direction_id IN (9, 16);
