-- ============================================================
-- МИГРАЦИЯ 46: get_company_assortment_size
-- Дата: 2026-10-01
--
-- ЦЕЛЬ: общее число позиций в каталоге компании (products).
--   Используется для блока «Індекс Різоманіття» на карточке клиента.
--
-- ЛОГИКА (по решению Serg, 2026-10-01):
--   COUNT(*) FROM products — ВСЕ позиции каталога, включая услуги.
--   Число одинаково для всех клиентов. Это «обещание компании»:
--   «у нас N позиций — выбирайте».
--
-- ⚠️ Не путать с get_client_diversity_index (типоразмеры труб у клиента).
--
-- РИСК: низкий (только добавление новой функции).
-- ОТКАТ: DROP FUNCTION get_company_assortment_size();
-- ============================================================

DROP FUNCTION IF EXISTS get_company_assortment_size();

CREATE OR REPLACE FUNCTION get_company_assortment_size()
RETURNS BIGINT
LANGUAGE SQL
STABLE
AS $$
    SELECT COUNT(*)::BIGINT FROM products;
$$;

COMMENT ON FUNCTION get_company_assortment_size() IS
'Общее число позиций в каталоге компании (products). Для блока «Індекс Різоманіття».';
