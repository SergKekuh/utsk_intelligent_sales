BEGIN;

-- ═══════════════════════════════════════════════════════════
-- Таблица сертификатов
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS product_certificates (
    id              SERIAL PRIMARY KEY,
    cert_number     VARCHAR(100) NOT NULL,
    doc_number      VARCHAR(50),
    cert_date       DATE,
    file_name       VARCHAR(255) NOT NULL,
    file_path       VARCHAR(500),
    product_info    TEXT,
    doc_1c_number   VARCHAR(50),
    organization    VARCHAR(255),
    product_code    VARCHAR(50),
    created_at      TIMESTAMP DEFAULT NOW(),
    CONSTRAINT uq_cert_number_file UNIQUE (cert_number, file_name)
);

CREATE INDEX IF NOT EXISTS idx_certs_cert_number 
    ON product_certificates(cert_number);
CREATE INDEX IF NOT EXISTS idx_certs_cert_date 
    ON product_certificates(cert_date);
CREATE INDEX IF NOT EXISTS idx_certs_product_code 
    ON product_certificates(product_code);
CREATE INDEX IF NOT EXISTS idx_certs_doc_1c 
    ON product_certificates(doc_1c_number);
CREATE INDEX IF NOT EXISTS idx_certs_product_info 
    ON product_certificates(product_info) WHERE product_info IS NOT NULL;

-- ═══════════════════════════════════════════════════════════
-- Таблица связи сертификат ↔ товар (many-to-many)
-- ═══════════════════════════════════════════════════════════
CREATE TABLE IF NOT EXISTS product_certificate_links (
    id              SERIAL PRIMARY KEY,
    product_code    VARCHAR(50) NOT NULL,
    certificate_id  INTEGER NOT NULL REFERENCES product_certificates(id) ON DELETE CASCADE,
    link_type       VARCHAR(50) DEFAULT 'doc_number_match',
    created_at      TIMESTAMP DEFAULT NOW(),
    CONSTRAINT uq_link_product_cert UNIQUE (product_code, certificate_id)
);

CREATE INDEX IF NOT EXISTS idx_links_product_code 
    ON product_certificate_links(product_code);
CREATE INDEX IF NOT EXISTS idx_links_cert_id 
    ON product_certificate_links(certificate_id);

COMMIT;
