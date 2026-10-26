BEGIN;
ALTER TABLE product_certificates 
  ADD COLUMN IF NOT EXISTS product_info TEXT,
  ADD COLUMN IF NOT EXISTS doc_1c_number VARCHAR(50);

ALTER TABLE product_certificate_links
  ADD COLUMN IF NOT EXISTS link_type VARCHAR(50) DEFAULT 'doc_number_match';

CREATE INDEX IF NOT EXISTS idx_certs_product_info 
  ON product_certificates(product_info) WHERE product_info IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_certs_doc_1c 
  ON product_certificates(doc_1c_number);

TRUNCATE TABLE product_certificate_links;
TRUNCATE TABLE product_certificates RESTART IDENTITY CASCADE;
COMMIT;
