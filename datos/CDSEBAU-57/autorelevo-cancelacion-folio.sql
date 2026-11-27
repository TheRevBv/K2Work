-- Cancelación de folios de AutoRelevo con motivo y submotivo.
-- El código desplegado en default/micrositio-autorelevo (morfeo-dev, 2026-11-26) ya mapea estas
-- tablas y columnas; sin ellas, GET /auto-relevo/tickets responde 500 (Unknown column cancel_reason_id).
-- Definición tomada de auto_relevo_boleta_models.py de esa versión.

CREATE TABLE IF NOT EXISTS autorelevo_cancel_reason (
  id INT NOT NULL AUTO_INCREMENT,
  nombre VARCHAR(255) NOT NULL,
  audit_created_at DATETIME NOT NULL,
  audit_updated_at DATETIME NULL,
  audit_deleted_at DATETIME NULL,
  audit_created_by INT NOT NULL,
  audit_updated_by INT NULL,
  audit_deleted_by INT NULL,
  active_record TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_autorelevo_cancel_reason_nombre (nombre),
  CONSTRAINT fk_autorelevo_cancel_reason_created_by FOREIGN KEY (audit_created_by) REFERENCES user_ (id),
  CONSTRAINT fk_autorelevo_cancel_reason_updated_by FOREIGN KEY (audit_updated_by) REFERENCES user_ (id),
  CONSTRAINT fk_autorelevo_cancel_reason_deleted_by FOREIGN KEY (audit_deleted_by) REFERENCES user_ (id)
);

CREATE TABLE IF NOT EXISTS autorelevo_cancel_subreason (
  id INT NOT NULL AUTO_INCREMENT,
  cancel_reason_id INT NOT NULL,
  nombre VARCHAR(255) NOT NULL,
  audit_created_at DATETIME NOT NULL,
  audit_updated_at DATETIME NULL,
  audit_deleted_at DATETIME NULL,
  audit_created_by INT NOT NULL,
  audit_updated_by INT NULL,
  audit_deleted_by INT NULL,
  active_record TINYINT(1) NOT NULL DEFAULT 1,
  PRIMARY KEY (id),
  UNIQUE KEY uq_autorelevo_cancel_subreason (cancel_reason_id, nombre),
  CONSTRAINT fk_autorelevo_cancel_subreason_reason FOREIGN KEY (cancel_reason_id) REFERENCES autorelevo_cancel_reason (id),
  CONSTRAINT fk_autorelevo_cancel_subreason_created_by FOREIGN KEY (audit_created_by) REFERENCES user_ (id),
  CONSTRAINT fk_autorelevo_cancel_subreason_updated_by FOREIGN KEY (audit_updated_by) REFERENCES user_ (id),
  CONSTRAINT fk_autorelevo_cancel_subreason_deleted_by FOREIGN KEY (audit_deleted_by) REFERENCES user_ (id)
);

ALTER TABLE servicios_auto_relevo
  ADD COLUMN cancel_reason_id INT NULL AFTER razon_estatus,
  ADD COLUMN cancel_subreason_id INT NULL AFTER cancel_reason_id,
  ADD COLUMN comentarios_cancelacion TEXT NULL AFTER cancel_subreason_id,
  ADD CONSTRAINT fk_servicios_auto_relevo_cancel_reason FOREIGN KEY (cancel_reason_id) REFERENCES autorelevo_cancel_reason (id),
  ADD CONSTRAINT fk_servicios_auto_relevo_cancel_subreason FOREIGN KEY (cancel_subreason_id) REFERENCES autorelevo_cancel_subreason (id);

-- Rollback:
-- ALTER TABLE servicios_auto_relevo
--   DROP FOREIGN KEY fk_servicios_auto_relevo_cancel_subreason,
--   DROP FOREIGN KEY fk_servicios_auto_relevo_cancel_reason,
--   DROP COLUMN comentarios_cancelacion,
--   DROP COLUMN cancel_subreason_id,
--   DROP COLUMN cancel_reason_id;
-- DROP TABLE autorelevo_cancel_subreason;
-- DROP TABLE autorelevo_cancel_reason;
