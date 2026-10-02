CREATE OR REPLACE FUNCTION trg_clients_classification_audit_func()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.activity_direction_id IS DISTINCT FROM NEW.activity_direction_id) OR
       (OLD.direction_confidence IS DISTINCT FROM NEW.direction_confidence) OR
       (OLD.direction_source IS DISTINCT FROM NEW.direction_source) THEN
       
        INSERT INTO classification_audit_log (
            client_code, client_name, old_direction_id, new_direction_id,
            old_confidence, new_confidence, old_source, new_source,
            change_reason, changed_by
        ) VALUES (
            NEW.code, NEW.name, OLD.activity_direction_id, NEW.activity_direction_id,
            OLD.direction_confidence, NEW.direction_confidence, OLD.direction_source, NEW.direction_source,
            NEW.direction_source, 'system'
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_clients_classification_audit ON clients;
CREATE TRIGGER trg_clients_classification_audit
AFTER UPDATE ON clients
FOR EACH ROW
EXECUTE FUNCTION trg_clients_classification_audit_func();
