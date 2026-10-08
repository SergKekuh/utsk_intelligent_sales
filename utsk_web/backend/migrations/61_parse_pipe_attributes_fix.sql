-- ============================================================
-- МИГРАЦИЯ 61: Патч parse_pipe_attributes
-- Дата: 2026-10-07
-- ЦЕЛЬ:
--   1. Чёрный список нон-труб (хомут, стяжк, плівк, лист, шкаф, ...).
--   2. Физические правила: wall < diameter, wall <= 80 (круглые), wall <= 25 (профиль), A,B <= 500.
-- РИСК: средний (парсер используется во многих аналитических функциях).
-- ОТКАТ: Восстановить из backup_functions_20261007_parser
-- ============================================================

-- БЭКАП
CREATE TABLE IF NOT EXISTS backup_functions_20261007_parser AS
SELECT proname, pg_get_functiondef(oid) AS definition, now() AS backup_at
FROM pg_proc
WHERE proname = 'parse_pipe_attributes';

-- ═══════════════════════════════════════════════════════════
-- ПАТЧ parse_pipe_attributes
-- ═══════════════════════════════════════════════════════════
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
    -- Инициализация NULL
    diameter := NULL;
    wall := NULL;
    prof_w := NULL;
    prof_h := NULL;
    is_prof := FALSE;
    standard := NULL;
    weight_m := NULL;

    -- ═══ 1. ЧЁРНЫЙ СПИСОК НОН-ТРУБ ═══
    IF p_name ~* 'хомут|стяжк|плівк|пленк|плита|плит[аы]|болт|шкаф|шафа|калькулятор|ролет|тур[ыиа]|osb|кабельн|самокл|папір|папер|кабел|дюбел|анкер|цвях|шуруп|саморіз|гайк|шайб|кутник|смуга|арматур|катанк|дріт|дрот|сітк|сетк|лист' THEN
        RETURN NEXT;
        RETURN;
    END IF;

    -- ═══ 2. СТАНДАРТ ═══
    standard := substring(p_name from '(ГОСТ\s*\d+[-\s]*\d*|ДСТУ\s*\d+[:\d]*|GB/T\s*\d+[:\d]*|EN\s*\d+[-\d]*)');

    -- ═══ 3. ПАТТЕРН 3 ЧИСЕЛ (профиль A×B×S) ═══
    dims3 := regexp_match(p_name, '(\d+(?:[.,]\d+)?)\s*[xх×]\s*(\d+(?:[.,]\d+)?)\s*[xх×]\s*(\d+(?:[.,]\d+)?)');

    -- ═══ 4. ПАТТЕРН 2 ЧИСЕЛ ═══
    dims2 := regexp_match(p_name, '(\d+(?:[.,]\d+)?)\s*[xх×]\s*(\d+(?:[.,]\d+)?)');

    IF dims3 IS NOT NULL THEN
        v_n1 := REPLACE(dims3[1], ',', '.')::NUMERIC;
        v_n2 := REPLACE(dims3[2], ',', '.')::NUMERIC;
        v_n3 := REPLACE(dims3[3], ',', '.')::NUMERIC;

        -- ФИЗ. ПРАВИЛО: wall <= 25 для профиля
        IF v_n3 IS NULL OR v_n3 <= 0 OR v_n3 > 25 THEN
            RETURN NEXT;
            RETURN;
        END IF;

        -- ФИЗ. ПРАВИЛО: A, B <= 500 (разумный предел профиля)
        IF v_n1 > 500 OR v_n2 > 500 THEN
            RETURN NEXT;
            RETURN;
        END IF;

        is_prof := TRUE;
        prof_w := v_n1;
        prof_h := v_n2;
        wall := v_n3;
        diameter := GREATEST(v_n1, v_n2);
    ELSIF dims2 IS NOT NULL THEN
        v_n1 := REPLACE(dims2[1], ',', '.')::NUMERIC;
        v_n2 := REPLACE(dims2[2], ',', '.')::NUMERIC;

        IF p_name ~* 'проф|profile|квадрат|прямокут|прямоугольн' THEN
            -- Профильная без явной стенки
            IF v_n1 > 500 OR v_n2 > 500 THEN
                RETURN NEXT;
                RETURN;
            END IF;
            is_prof := TRUE;
            prof_w := v_n1;
            prof_h := v_n2;
            wall := NULL;
            diameter := GREATEST(v_n1, v_n2);
        ELSE
            -- Круглая: D×S
            -- ФИЗ. ПРАВИЛА:
            --   wall < diameter
            --   wall <= 80
            --   diameter >= 5 (минимум)
            IF v_n1 < 5 OR v_n2 <= 0 OR v_n2 >= v_n1 OR v_n2 > 80 THEN
                RETURN NEXT;
                RETURN;
            END IF;

            is_prof := FALSE;
            diameter := v_n1;
            wall := v_n2;
        END IF;
    ELSE
        -- Не распарсили — возвращаем NULL
        RETURN NEXT;
        RETURN;
    END IF;

    -- ═══ 5. ВЕС МЕТРА (для круглых) ═══
    IF NOT is_prof AND diameter IS NOT NULL AND wall IS NOT NULL THEN
        weight_m := ROUND((PI() * (diameter - wall) * wall * 7850 / 1000000)::NUMERIC, 3);
    END IF;

    RETURN NEXT;
END;
$function$;

COMMENT ON FUNCTION public.parse_pipe_attributes(character varying) IS
'Парсер параметров труб (диаметр/сечение/стенка) с черным списком нон-труб и физическими проверками геометрии.';
