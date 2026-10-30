BEGIN;

CREATE TABLE IF NOT EXISTS cert_product_links (
    id                  BIGSERIAL PRIMARY KEY,
    cert_id             BIGINT NOT NULL REFERENCES certs_registry(id)          ON DELETE CASCADE,
    sale_id             BIGINT NOT NULL REFERENCES product_sales_registry(id)  ON DELETE CASCADE,
    link_type           VARCHAR(20) NOT NULL,   -- 'exact_document' | 'exact_match' | 'fuzzy_document'
    is_verified         BOOLEAN DEFAULT FALSE,
    match_details       JSONB,                  -- подробности матчинга (для аудита)
    created_at          TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (cert_id, sale_id)
);
CREATE INDEX IF NOT EXISTS idx_cpl_cert_id  ON cert_product_links(cert_id);
CREATE INDEX IF NOT EXISTS idx_cpl_sale_id  ON cert_product_links(sale_id);
CREATE INDEX IF NOT EXISTS idx_cpl_link_type ON cert_product_links(link_type);

COMMIT;
