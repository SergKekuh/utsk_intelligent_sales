BEGIN;

CREATE TABLE IF NOT EXISTS product_sales_registry (
    id              BIGSERIAL PRIMARY KEY,
    product_code    VARCHAR(20)   NOT NULL,
    product_name    VARCHAR(512)  NOT NULL,
    doc_number      VARCHAR(20)   NOT NULL,
    quantity        NUMERIC(12,3) NOT NULL DEFAULT 0,
    amount          NUMERIC(14,2) NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ   DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_psr_product_code ON product_sales_registry(product_code);
CREATE INDEX IF NOT EXISTS idx_psr_doc_number   ON product_sales_registry(doc_number);

CREATE TABLE IF NOT EXISTS certs_registry (
    id                  BIGSERIAL PRIMARY KEY,
    cert_date           DATE          NOT NULL,
    doc_number          VARCHAR(20)   NOT NULL,
    cert_number         VARCHAR(64)   NOT NULL,
    cert_filename       VARCHAR(128)  NOT NULL,
    cert_path_original  TEXT          NOT NULL,
    cert_path_linux     TEXT          NOT NULL,
    organization        VARCHAR(256),
    pdf_exists          BOOLEAN       DEFAULT FALSE,
    created_at          TIMESTAMPTZ   DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_cr_doc_number    ON certs_registry(doc_number);
CREATE INDEX IF NOT EXISTS idx_cr_cert_filename ON certs_registry(cert_filename);
CREATE INDEX IF NOT EXISTS idx_cr_cert_number   ON certs_registry(cert_number);

COMMIT;
