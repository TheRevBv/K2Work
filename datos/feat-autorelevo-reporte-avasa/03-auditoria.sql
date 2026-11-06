ALTER TABLE autorelevo_contrato_renta
    ADD COLUMN audit_created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN audit_updated_at DATETIME NULL ON UPDATE CURRENT_TIMESTAMP,
    ADD COLUMN audit_deleted_at DATETIME NULL,
    ADD COLUMN audit_created_by INT NULL,
    ADD COLUMN audit_updated_by INT NULL,
    ADD COLUMN audit_deleted_by INT NULL,
    ADD COLUMN active_record TINYINT(1) DEFAULT 1;
