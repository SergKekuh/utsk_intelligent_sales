UPDATE clients c
SET activity_direction_id = b.activity_direction_id,
    direction_confidence = b.direction_confidence
FROM clients_direction_backup_v4 b
WHERE c.code = b.code;
