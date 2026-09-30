CREATE OR REPLACE FUNCTION public.classify_clients_directions(p_overwrite_manual boolean DEFAULT false)
 RETURNS TABLE(updated_count bigint)
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_count BIGINT;
BEGIN
    WITH classified AS (
        SELECT 
            code,
            CASE
                WHEN name ~* '(агро|аграр|ферм|сгп|сг |зерн|элеватор|елеватор|урожай|сад |птиц|дір|жон дір|кукурудз|насін|комбайн|трактор|сеялк|сівалк|борон|культиватор|жатка|обприскув|удобрен|комбикорм|корм|птахо|свино|молочн|фермер|агрохолдинг)' THEN 1
                WHEN name ~* '(буд|строит|монтаж|кровл|бетон|девелоп|покров|фасад|покрів|архітек|інжинір|генподряд|подрядчик|забудовник|жбк|залізобетон|фундамент|свая|паля|розчин|цегла|цемент|плитка|ремонт)' THEN 2
                WHEN name ~* '(кріплен|метиз|конструкт|болт|гайк|сітк|дрот|перфор|металоконструкц|зварн|зварюв|кузн|кован|ковальств|ґрат|ворота|паркан|огорож|навіс|ангар)' THEN 10
                WHEN name ~* '(маш|метмаш|турбо|агрегат|станум|гідравлік|обладнан|механік|верстат|вагов|ваги|машинобуд|станкобуд|приладобуд|конвеєр|редуктор|насос|компресор|вентиляц|пневмат|гідравл|арматура|фітинг|фитинг|пружин)' THEN 11
                WHEN name ~* '(енерг|електр|світл|кабель|трансформатор|генератор|солар|електростанц|генерац|сонячн|вітров|соняч|відновлюв|кабельн|підстанц)' THEN 12
                WHEN name ~* '(авто|трак|мотор|сто |шиномонтаж|автомоб|еверласт|причеп|вагон|автосервіс|автосалон|авторемонт|автотранспорт|вантажівк|напівприч|автокран|спецтехнік)' THEN 13
                WHEN name ~* '(транс|логіст|доставк|карго|перевез|експедиц|логістичн|транспортн|перевізн|експедитор|складськ|вантажоперев|кур''єр|поштамт)' THEN 14
                WHEN name ~* '(завод| з-д|пром|нафт|газ|фабр|індустр|трубоізол|насос|котел|комбінат|хім|полімер|металург|ливар|прокат|штампов|кузнеч|термич|гальваніч|фарбув|нафтохім|технолодж)' THEN 3
                WHEN name ~* '(водоканал|жкг|жкх|тепло|комун| кп | крп |водовідвід|водопостач|жек|осбб|ліфт|газопостач|водопровід|водовідведенн|каналізац|тепломереж|теплопостач|енергопостач|обленерго|облгаз)' THEN 4
                WHEN name ~* '(дорож|автодор|шлях|міст |мост|асфальт|автошлях|дорстрой|дорожн|шляхобуд|бруківк|тротуар|мостобуд|дорожньо)' THEN 5
                WHEN name ~* '(виробничо-комерц|производственно-коммерч|вкф|вир-торг|твк|втп|нвп|пнвп)' THEN 8
                WHEN name ~* '(метбаза|металлопрокат|база стал|сталь груп|металл|метал|трейд|дистриб|сбыт|склад|торг|постач| тк | тд |прокат|сталеніт|інтерстил|оксімет|є прокат|торгов|торгово|снаб|оптов|роздрібн|маркет|супермаркет|гіпермаркет|магазин|склад-магазин|пайп|сталь|стіл|метпроф|юнимет|ютмк|метаст|сплав|арк-групп|базис|базис гк)' THEN 6
                WHEN name ~* '(держ|міськ|район|управлін|лікарн|школ|універ|ритейл|маркет|супермаркет)' THEN 15
                WHEN name ~* '(фоп|флп| чл|фізична особа|підприємець)' OR (length(edrpou) = 10 AND edrpou ~ '^[0-9]+$') THEN 7
                ELSE 9
            END AS new_dir_id,
            CASE WHEN name ~* '(агро|буд|кріпл|маш|енерг|авто|транс|завод|водоканал|дорож|виробничо|метбаза|держ|фоп)' OR (length(edrpou) = 10 AND edrpou ~ '^[0-9]+$') THEN 0.85 ELSE 0.70 END AS new_conf
        FROM clients
        WHERE (p_overwrite_manual = TRUE OR is_direction_manual = FALSE OR is_direction_manual IS NULL)
    ),
    upd AS (
        UPDATE clients c
        SET activity_direction_id = cl.new_dir_id,
            direction_confidence = cl.new_conf
        FROM classified cl
        WHERE c.code = cl.code
          AND (c.activity_direction_id IS DISTINCT FROM cl.new_dir_id OR c.activity_direction_id IS NULL)
        RETURNING c.code
    )
    SELECT COUNT(*) INTO v_count FROM upd;

    RETURN QUERY SELECT v_count;
END;
$function$;

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
            SUM(sl.amount) FILTER (WHERE NOT pa.is_prof AND pa.diameter < 57) AS light_round_revenue,
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
                WHEN COALESCE(heavy_round_revenue, 0) > total_revenue * 0.5 THEN 11 -- Машиностроение (часто берут толстостенные трубы)
                WHEN COALESCE(prof_revenue, 0) > total_revenue * 0.5 THEN 10 -- Металлоконструкции (профильная труба)
                WHEN COALESCE(general_metal_revenue, 0) > total_revenue * 0.4 THEN 6 -- Трейдер
                WHEN COALESCE(prof_revenue, 0) > total_revenue * 0.25 AND COALESCE(heavy_round_revenue, 0) > total_revenue * 0.25 THEN 3 -- Промышленность
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
        RETURNING c.code
    )
    SELECT COUNT(*) INTO v_count FROM upd;

    RETURN QUERY SELECT v_count;
END;
$function$;

SELECT * FROM classify_clients_directions();
SELECT * FROM classify_clients_by_basket();

SELECT 
    ad.id, ad.name,
    COUNT(c.code) FILTER (WHERE c.is_active_current = TRUE) AS active_clients
FROM activity_directions ad
LEFT JOIN clients c ON c.activity_direction_id = ad.id
GROUP BY ad.id, ad.name
ORDER BY active_clients DESC;
