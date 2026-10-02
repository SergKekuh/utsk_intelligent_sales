-- ============================================================
-- МИГРАЦИЯ 43: get_client_diversity_index
-- Дата: 2026-10-01
--
-- ЦЕЛЬ: количество уникальных типоразмеров труб у клиента за год.
--   Используется для отображения «Індекс Різоманіття» на карточке клиента.
--
-- ЛОГИКА:
--   - Товарная выручка: is_service = FALSE
--   - Формула size_key — 1-в-1 из get_all_sizes_for_client
--   - Учитываются: круглые (round_DxS), профильные (prof_WxHxS)
--   - Не учитываются: ГОСТ, марка стали (только геометрия)
--
-- РИСК: низкий (только добавление новой функции).
-- ОТКАТ: DROP FUNCTION get_client_diversity_index(text, integer);
-- ============================================================

DROP FUNCTION IF EXISTS get_client_diversity_index(text, integer);

CREATE OR REPLACE FUNCTION get_client_diversity_index(
    p_client_code TEXT,
    p_year INTEGER DEFAULT 2026
)
RETURNS BIGINT
LANGUAGE SQL
STABLE
AS $$
    SELECT COUNT(DISTINCT size_key)::BIGINT
    FROM (
        SELECT
            CASE
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT || 'x' || ppa.wall::TEXT
                WHEN ppa.is_prof AND ppa.prof_w IS NOT NULL AND ppa.prof_h IS NOT NULL
                    THEN 'prof_' || ppa.prof_w::TEXT || 'x' || ppa.prof_h::TEXT
                WHEN NOT ppa.is_prof AND ppa.diameter IS NOT NULL AND ppa.wall IS NOT NULL
                    THEN 'round_' || ppa.diameter::TEXT || 'x' || ppa.wall::TEXT
                ELSE NULL
            END AS size_key
        FROM documents d
        JOIN sales_lines sl ON sl.document_id = d.id
        JOIN products p ON p.code = sl.product_code
        CROSS JOIN LATERAL parse_pipe_attributes(p.name) ppa
        WHERE d.client_code = p_client_code
          AND EXTRACT(YEAR FROM d.invoice_date) = p_year
          AND COALESCE(p.is_service, FALSE) = FALSE
          AND sl.amount > 0
    ) t
    WHERE size_key IS NOT NULL;
$$;

COMMENT ON FUNCTION get_client_diversity_index(text, integer) IS
'Количество уникальных типоразмеров труб у клиента за год (Індекс Різоманіття).';
