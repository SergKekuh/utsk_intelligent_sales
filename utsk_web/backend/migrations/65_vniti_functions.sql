-- ============================================================
-- МИГРАЦИЯ 65: SQL-функции методики ВНИТИ
-- ============================================================

-- ─── 1. vniti_calc_contact_radius ───
CREATE OR REPLACE FUNCTION public.vniti_calc_contact_radius(
    p_a NUMERIC, p_b NUMERIC, p_s NUMERIC, p_k10 NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql IMMUTABLE
AS $function$
DECLARE
    v_c9 NUMERIC;
    v_arg NUMERIC;
    v_theta NUMERIC;
BEGIN
    v_c9 := (p_a + p_b) / 3.1415;
    v_arg := 0.5 / (p_s * (1.0 / p_k10 - 1.0 / v_c9));
    v_theta := ATAN(v_arg) * 180.0 / 3.1415;
    RETURN ROUND((2.35 - 0.007 * v_theta) * p_k10 / 1.72, 3);
END;
$function$;

-- ─── 2. vniti_calc_billet_diameter ───
CREATE OR REPLACE FUNCTION public.vniti_calc_billet_diameter(
    p_a NUMERIC, p_b NUMERIC, p_s NUMERIC, p_r_calc NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql IMMUTABLE
AS $function$
DECLARE
    v_c9 NUMERIC;
    v_first NUMERIC;
    v_second NUMERIC;
BEGIN
    v_c9 := (p_a + p_b) / 3.1415;
    v_first := SQRT((1.0 / p_r_calc - 1.0 / v_c9) * p_s) * 3.0 * p_s;
    v_second := 2.0 * (p_a + p_b) - 1.72 * p_r_calc;
    RETURN ROUND((v_first + v_second) / 3.1415, 2);
END;
$function$;

-- ─── 3. vniti_calc_k ───
CREATE OR REPLACE FUNCTION public.vniti_calc_k(
    p_diameter NUMERIC, p_a NUMERIC, p_b NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql IMMUTABLE
AS $function$
BEGIN
    RETURN ROUND(p_diameter / ((p_a + p_b) / 2.0), 4);
END;
$function$;

-- ─── 4. vniti_get_k_range ───
CREATE OR REPLACE FUNCTION public.vniti_get_k_range(p_s NUMERIC)
RETURNS TABLE(k_min NUMERIC, k_max NUMERIC, r_min_coef NUMERIC, r_max_coef NUMERIC)
LANGUAGE sql STABLE
AS $function$
    SELECT k_min, k_max, r_min_coef, r_max_coef
    FROM tu_coefficients
    WHERE p_s > t_min AND p_s <= t_max
    ORDER BY t_min DESC LIMIT 1;
$function$;

-- ─── 5. vniti_round_production_radius ───
CREATE OR REPLACE FUNCTION public.vniti_round_production_radius(
    p_r_calc NUMERIC, p_s NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql IMMUTABLE
AS $function$
DECLARE
    v_r_max_tu NUMERIC;
    v_k_range RECORD;
BEGIN
    SELECT * INTO v_k_range FROM vniti_get_k_range(p_s);
    v_r_max_tu := v_k_range.r_max_coef * p_s;
    IF p_r_calc <= v_r_max_tu THEN
        RETURN FLOOR(p_r_calc * 2) / 2.0;
    ELSE
        RETURN FLOOR(v_r_max_tu * 2) / 2.0;
    END IF;
END;
$function$;

-- ─── 6. vniti_calc_section_properties ───
CREATE OR REPLACE FUNCTION public.vniti_calc_section_properties(
    p_h NUMERIC, p_b NUMERIC, p_t NUMERIC
)
RETURNS TABLE(
    area_cm2 NUMERIC, weight_m NUMERIC,
    ix_cm4 NUMERIC, iy_cm4 NUMERIC,
    wx_cm3 NUMERIC, wy_cm3 NUMERIC,
    wpl_x_cm3 NUMERIC, wpl_y_cm3 NUMERIC,
    ix_rad_cm NUMERIC, iy_rad_cm NUMERIC,
    ik_cm4 NUMERIC, wk_cm3 NUMERIC
)
LANGUAGE plpgsql IMMUTABLE
AS $function$
DECLARE
    v_a NUMERIC;
    v_ix NUMERIC;
    v_iy NUMERIC;
    v_wx NUMERIC;
    v_wy NUMERIC;
BEGIN
    v_a := (2.0 * p_t * (p_h + p_b - 2.0 * p_t)) / 100.0;
    v_ix := (p_b * POWER(p_h, 3) - (p_b - 2*p_t) * POWER(p_h - 2*p_t, 3)) / (12.0 * 10000.0);
    v_iy := (p_h * POWER(p_b, 3) - (p_h - 2*p_t) * POWER(p_b - 2*p_t, 3)) / (12.0 * 10000.0);
    v_wx := v_ix / (p_h / 20.0);
    v_wy := v_iy / (p_b / 20.0);
    RETURN QUERY SELECT
        ROUND(v_a, 3), ROUND(v_a * 0.785, 3),
        ROUND(v_ix, 3), ROUND(v_iy, 3),
        ROUND(v_wx, 3), ROUND(v_wy, 3),
        ROUND(v_wx * 1.18, 3), ROUND(v_wy * 1.18, 3),
        ROUND(SQRT(v_ix / v_a), 3), ROUND(SQRT(v_iy / v_a), 3),
        ROUND(2.0 * v_ix * v_iy / NULLIF(v_ix + v_iy, 0), 3),
        ROUND(1.2 * LEAST(v_wx, v_wy), 3);
END;
$function$;

-- ─── 7. vniti_enumerate_profiles ───
CREATE OR REPLACE FUNCTION public.vniti_enumerate_profiles(
    p_diameter NUMERIC,
    p_wall NUMERIC,
    p_k10 NUMERIC DEFAULT 22,
    p_shape VARCHAR DEFAULT 'square',
    p_step_mm NUMERIC DEFAULT 1.0,
    p_max_aspect NUMERIC DEFAULT 4.0,
    p_limit INTEGER DEFAULT 50
)
RETURNS TABLE(
    a NUMERIC, b NUMERIC, r_calc NUMERIC, r_prod NUMERIC,
    k_real NUMERIC, k_min NUMERIC, k_max NUMERIC,
    fits_tu BOOLEAN, delta_diameter NUMERIC
)
LANGUAGE plpgsql STABLE
AS $function$
DECLARE
    v_k_range RECORD;
    v_a NUMERIC;
    v_b NUMERIC;
    v_count INTEGER := 0;
BEGIN
    SELECT * INTO v_k_range FROM vniti_get_k_range(p_wall);
    IF v_k_range IS NULL THEN RETURN; END IF;
    
    v_a := 20;
    WHILE v_a <= 400 AND v_count < p_limit LOOP
        IF p_shape = 'square' THEN
            v_b := v_a;
            IF vniti_calc_k(p_diameter, v_a, v_b) BETWEEN v_k_range.k_min AND v_k_range.k_max THEN
                RETURN QUERY SELECT
                    v_a, v_b,
                    vniti_calc_contact_radius(v_a, v_b, p_wall, p_k10),
                    vniti_round_production_radius(vniti_calc_contact_radius(v_a, v_b, p_wall, p_k10), p_wall),
                    vniti_calc_k(p_diameter, v_a, v_b),
                    v_k_range.k_min, v_k_range.k_max, TRUE,
                    ROUND(p_diameter - vniti_calc_billet_diameter(v_a, v_b, p_wall, vniti_calc_contact_radius(v_a, v_b, p_wall, p_k10)), 2);
                v_count := v_count + 1;
            END IF;
            v_a := v_a + p_step_mm;
        ELSE
            v_b := 20;
            WHILE v_b < v_a AND v_count < p_limit LOOP
                IF v_a / v_b <= p_max_aspect THEN
                    IF vniti_calc_k(p_diameter, v_a, v_b) BETWEEN v_k_range.k_min AND v_k_range.k_max THEN
                        RETURN QUERY SELECT
                            v_a, v_b,
                            vniti_calc_contact_radius(v_a, v_b, p_wall, p_k10),
                            vniti_round_production_radius(vniti_calc_contact_radius(v_a, v_b, p_wall, p_k10), p_wall),
                            vniti_calc_k(p_diameter, v_a, v_b),
                            v_k_range.k_min, v_k_range.k_max, TRUE,
                            ROUND(p_diameter - vniti_calc_billet_diameter(v_a, v_b, p_wall, vniti_calc_contact_radius(v_a, v_b, p_wall, p_k10)), 2);
                        v_count := v_count + 1;
                    END IF;
                END IF;
                v_b := v_b + p_step_mm;
            END LOOP;
            v_a := v_a + p_step_mm;
        END IF;
    END LOOP;
END;
$function$;

-- ПРОВЕРКА
SELECT 'Migration 65 applied' AS status;
