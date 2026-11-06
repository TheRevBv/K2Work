ALTER TABLE autorelevo_contrato_renta
    DROP COLUMN audit_created_at, DROP COLUMN audit_updated_at, DROP COLUMN audit_deleted_at,
    DROP COLUMN audit_created_by, DROP COLUMN audit_updated_by, DROP COLUMN audit_deleted_by,
    DROP COLUMN active_record;
