CREATE TABLE IF NOT EXISTS classification_audit_log (
    id BIGSERIAL PRIMARY KEY,
    client_code VARCHAR(50) NOT NULL,
    client_name VARCHAR(500),
    changed_at TIMESTAMP DEFAULT NOW(),
    old_direction_id INT,
    new_direction_id INT,
    old_confidence NUMERIC(3,2),
    new_confidence NUMERIC(3,2),
    old_source VARCHAR(20),
    new_source VARCHAR(20),
    change_reason VARCHAR(50),
    changed_by VARCHAR(100),
    notes TEXT
);

CREATE OR REPLACE FUNCTION revert_classification_change(audit_id BIGINT)
RETURNS TABLE (success BOOLEAN, client_code VARCHAR, message TEXT) AS $$
DECLARE
    rec RECORD;
BEGIN
    SELECT * INTO rec FROM classification_audit_log WHERE id = audit_id;
    IF NOT FOUND THEN
        RETURN QUERY SELECT FALSE, ''::VARCHAR, 'Audit record not found'::TEXT;
        RETURN;
    END IF;

    UPDATE clients
    SET activity_direction_id = rec.old_direction_id,
        direction_confidence = rec.old_confidence,
        direction_source = 'revert',
        is_direction_manual = TRUE
    WHERE code = rec.client_code;

    INSERT INTO classification_audit_log (
        client_code, client_name, old_direction_id, new_direction_id,
        old_confidence, new_confidence, old_source, new_source, change_reason, changed_by
    ) VALUES (
        rec.client_code, rec.client_name, rec.new_direction_id, rec.old_direction_id,
        rec.new_confidence, rec.old_confidence, rec.new_source, 'revert', 'revert', 'admin'
    );

    RETURN QUERY SELECT TRUE, rec.client_code, 'Reverted successfully'::TEXT;
END;
$$ LANGUAGE plpgsql;
