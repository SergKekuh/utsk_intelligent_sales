BEGIN;
CREATE TABLE IF NOT EXISTS product_similarities (
    id BIGSERIAL PRIMARY KEY,
    source_product_code VARCHAR(50) NOT NULL REFERENCES products(code) ON DELETE CASCADE,
    similar_product_code VARCHAR(50) NOT NULL REFERENCES products(code) ON DELETE CASCADE,
    similarity_score DECIMAL(5,2) DEFAULT 0,
    match_type VARCHAR(50) NOT NULL,
    source_diameter NUMERIC(10,2), source_wall NUMERIC(10,2),
    similar_diameter NUMERIC(10,2), similar_wall NUMERIC(10,2),
    UNIQUE(source_product_code, similar_product_code)
);
COMMIT;
