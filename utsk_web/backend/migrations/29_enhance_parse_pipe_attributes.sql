-- ============================================================
-- 29_enhance_parse_pipe_attributes.sql
-- УСИЛЕНИЕ parse_pipe_attributes
-- Логика: если 3 числа через x → профильная (квадрат/прямоугольник)
--          если 2 числа → круглая (если нет явного «проф» в названии)
-- НЕ ЛОМАЕМ существующие вызовы — только улучшаем определение
-- ============================================================

CREATE OR REPLACE FUNCTION parse_pipe_attributes(p_name VARCHAR)
RETURNS TABLE(
    diameter NUMERIC,
    wall NUMERIC,
    prof_w NUMERIC,
    prof_h NUMERIC,
    is_prof BOOLEAN,
    standard VARCHAR,
    weight_m NUMERIC
)
LANGUAGE plpgsql IMMUTABLE AS $$
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
$$;

COMMENT ON FUNCTION parse_pipe_attributes(VARCHAR) IS 
    'Парсер названий труб. 3 числа → профиль, 2 числа + «проф» → профиль, 2 числа → круглая.';
