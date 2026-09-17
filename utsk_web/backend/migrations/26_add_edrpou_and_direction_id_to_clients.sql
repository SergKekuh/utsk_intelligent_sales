-- ============================================================
-- Migration 26: Add edrpou and direction_id to clients table
-- UTSK Intelligent Sales
-- ============================================================

-- 1. Add edrpou column and backfill from okpo_code
ALTER TABLE clients ADD COLUMN IF NOT EXISTS edrpou VARCHAR(20);
UPDATE clients SET edrpou = okpo_code WHERE edrpou IS NULL;
CREATE INDEX IF NOT EXISTS idx_clients_edrpou ON clients(edrpou);

-- 2. Add direction_id column and backfill from activity_direction_id
ALTER TABLE clients ADD COLUMN IF NOT EXISTS direction_id INT REFERENCES activity_directions(id) ON DELETE SET NULL;
UPDATE clients SET direction_id = activity_direction_id WHERE direction_id IS NULL;
CREATE INDEX IF NOT EXISTS idx_clients_direction_id ON clients(direction_id);
CREATE INDEX IF NOT EXISTS idx_clients_activity_direction_id ON clients(activity_direction_id);

-- 3. Trigger to keep activity_direction_id and direction_id synchronized
CREATE OR REPLACE FUNCTION trg_sync_clients_direction()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.direction_id IS DISTINCT FROM OLD.direction_id AND (NEW.activity_direction_id IS NOT DISTINCT FROM OLD.activity_direction_id) THEN
        NEW.activity_direction_id := NEW.direction_id;
    ELSIF NEW.activity_direction_id IS DISTINCT FROM OLD.activity_direction_id THEN
        NEW.direction_id := NEW.activity_direction_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_clients_sync_direction ON clients;
CREATE TRIGGER trg_clients_sync_direction
BEFORE INSERT OR UPDATE ON clients
FOR EACH ROW
EXECUTE FUNCTION trg_sync_clients_direction();

COMMENT ON COLUMN clients.edrpou IS 'Код ЄДРПОУ підприємства (синхронізовано з okpo_code)';
COMMENT ON COLUMN clients.direction_id IS 'ID галузі діяльності (синхронізовано з activity_direction_id)';
