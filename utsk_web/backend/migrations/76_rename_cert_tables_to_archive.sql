BEGIN;

-- Проверка на всякий случай: если таблицы уже переименованы — выходим без ошибки
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema='public' AND table_name='product_certificates')
     AND NOT EXISTS (SELECT 1 FROM information_schema.tables
                     WHERE table_schema='public' AND table_name='product_certificates_archive')
  THEN
    ALTER TABLE public.product_certificates RENAME TO product_certificates_archive;
  END IF;

  IF EXISTS (SELECT 1 FROM information_schema.tables
             WHERE table_schema='public' AND table_name='product_certificate_links')
     AND NOT EXISTS (SELECT 1 FROM information_schema.tables
                     WHERE table_schema='public' AND table_name='product_certificate_links_archive')
  THEN
    ALTER TABLE public.product_certificate_links RENAME TO product_certificate_links_archive;
  END IF;
END $$;

COMMIT;
