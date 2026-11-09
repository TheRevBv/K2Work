-- Ticket 652 duplicado de 653 (siniestro KA26I000590): baja lógica del ticket y sus documentos.
UPDATE documentos_archivos a JOIN documentos_validacion v ON v.id = a.documento_validacion_id
SET a.active_record = 0, a.audit_deleted_at = NOW() WHERE v.servicio_id = 652;
UPDATE documentos_validacion SET active_record = 0, audit_deleted_at = NOW() WHERE servicio_id = 652;
UPDATE servicios_auto_relevo SET active_record = 0, audit_deleted_at = NOW() WHERE id = 652;
SELECT id, estatus_servicio, active_record FROM servicios_auto_relevo WHERE id IN (652, 653);
SELECT servicio_id, SUM(active_record) activos FROM documentos_validacion WHERE servicio_id IN (652, 653) GROUP BY servicio_id;
