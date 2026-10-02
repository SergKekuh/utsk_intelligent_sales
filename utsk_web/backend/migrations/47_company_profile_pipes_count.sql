-- ============================================================
-- МИГРАЦИЯ 47: get_company_profile_pipes_count
-- Дата: 2026-10-01
--
-- ЦЕЛЬ: количество профильных труб (квадратных + прямоугольных)
--   в каталоге компании.
--   Используется для блока 2 на карточке клиента.
--
-- ЛОГИКА:
--   - Все позиции в products, у которых parse_pipe_attributes.is_prof = TRUE.
--   - Только товары (is_service = FALSE).
--   - Число одинаково для всех клиентов.
--
-- РИСК: низкий (только добавление новой функции).
-- ОТКАТ: DROP FUNCTION get_company_profile_pipes_count();
-- ============================================================

DROP FUNCTION IF EXISTS get_company_profile_pipes_count();

CREATE OR REPLACE FUNCTION get_company_profile_pipes_count()
RETURNS BIGINT
LANGUAGE SQL
STABLE
AS $$
    SELECT COUNT(*)::BIGINT
    FROM products p
    CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
    WHERE COALESCE(p.is_service, FALSE) = FALSE
      AND ppa.is_prof = TRUE
      AND ppa.prof_w IS NOT NULL
      AND ppa.prof_h IS NOT NULL;
$$;

COMMENT ON FUNCTION get_company_profile_pipes_count() IS
'Количество профильных труб (квадратных + прямоугольных) в каталоге компании.';
