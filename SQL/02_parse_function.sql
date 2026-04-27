CREATE OR REPLACE FUNCTION parse_pipe_attributes(p_name VARCHAR)
RETURNS TABLE(
    diameter NUMERIC, wall NUMERIC, prof_w NUMERIC, prof_h NUMERIC,
    is_prof BOOLEAN, standard VARCHAR, weight_m NUMERIC
) AS $$
DECLARE
    dims TEXT[];
BEGIN
    standard := substring(p_name from '(ГОСТ\s*\d+[-\s]*\d*|ДСТУ\s*\d+[:\d]*|GB/T\s*\d+[:\d]*|EN\s*\d+[-\d]*)');
    
    IF p_name ~* 'проф|profile' THEN
        is_prof := TRUE;
        dims := regexp_matches(p_name, '(\d+(?:\.\d+)?)\s*[xх×]\s*(\d+(?:\.\d+)?)\s*[xх×]\s*(\d+(?:\.\d+)?)');
        IF dims IS NOT NULL THEN
            prof_w := dims[1]::NUMERIC;
            prof_h := dims[2]::NUMERIC;
            wall := dims[3]::NUMERIC;
            diameter := GREATEST(prof_w, prof_h);
        END IF;
    ELSE
        is_prof := FALSE;
        dims := regexp_matches(p_name, '(\d+(?:\.\d+)?)\s*[xх×]\s*(\d+(?:\.\d+)?)');
        IF dims IS NOT NULL THEN
            diameter := dims[1]::NUMERIC;
            wall := dims[2]::NUMERIC;
        END IF;
    END IF;
    
    IF diameter IS NOT NULL AND wall IS NOT NULL AND NOT is_prof THEN
        weight_m := ROUND((PI() * (diameter - wall) * wall * 7850 / 1000000)::NUMERIC, 3);
    END IF;
    
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql;
