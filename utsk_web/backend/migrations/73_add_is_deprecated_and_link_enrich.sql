BEGIN;

-- 1. Колонка is_deprecated для старых связей (по умолчанию FALSE = не тронуты)
ALTER TABLE product_certificate_links
  ADD COLUMN IF NOT EXISTS is_deprecated BOOLEAN DEFAULT FALSE;

-- 2. Новый тип связи для «восстановленных из старых»
--    (в cert_product_links уже VARCHAR(20), менять не нужно;
--     в match_details сохраним source='legacy')

COMMIT;
