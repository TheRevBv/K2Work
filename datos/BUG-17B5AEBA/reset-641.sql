-- Ticket 641 (boleta 644): regresa a "entrega de documentos" con el motivo actual (Pérdida Parcial).
UPDATE servicios_auto_relevo SET estatus_servicio = 'Pendiente', razon_estatus = 'Pérdida Parcial' WHERE id = 641;
UPDATE boleta_informativa SET fecha_recepcion_documentos = NULL, fecha_autorizacion_siniestro = NULL,
  fecha_asignacion_auto = NULL, fecha_entrega_vehiculo = NULL, evaluador_aprobo_servicio = NULL,
  motivo_evaluacion_servicio = NULL, tiempo_autorizacion_valuacion = NULL
WHERE id = 644;
-- Documentos del motivo anterior (Pérdida Total) y sus archivos: baja lógica.
UPDATE documentos_archivos a JOIN documentos_validacion v ON v.id = a.documento_validacion_id
SET a.active_record = 0, a.audit_deleted_at = NOW() WHERE v.servicio_id = 641 AND v.id IN (15224, 15225, 15226, 15227);
UPDATE documentos_validacion SET active_record = 0, audit_deleted_at = NOW() WHERE servicio_id = 641 AND id IN (15224, 15225, 15226, 15227);
-- Vehículo asignado (paso posterior): baja lógica.
UPDATE vehiculos_asignados SET active_record = 0, audit_deleted_at = NOW() WHERE id = 1223 AND boleta_informativa_id = 644;

SELECT s.id, s.estatus_servicio, s.razon_estatus, b.motivo_servicio_id, b.fecha_recepcion_documentos, b.fecha_entrega_vehiculo, b.evaluador_aprobo_servicio
FROM servicios_auto_relevo s JOIN boleta_informativa b ON b.id = s.boleta_informativa_id WHERE s.id = 641;
SELECT id, documento_requerido_id, estatus_validacion, active_record FROM documentos_validacion WHERE servicio_id = 641;
SELECT id, active_record FROM vehiculos_asignados WHERE boleta_informativa_id = 644;
