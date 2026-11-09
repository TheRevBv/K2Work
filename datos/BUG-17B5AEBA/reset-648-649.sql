UPDATE boleta_informativa b JOIN servicios_auto_relevo s ON s.boleta_informativa_id = b.id
SET b.evaluador_aprobo_servicio = NULL, b.motivo_evaluacion_servicio = NULL, b.fecha_autorizacion_siniestro = NULL
WHERE s.id IN (648, 649);
UPDATE servicios_auto_relevo SET estatus_servicio = 'Documentación completa en espera de autorización', razon_estatus = NULL WHERE id IN (648, 649);
SELECT s.id, s.estatus_servicio, s.razon_estatus, b.evaluador_aprobo_servicio, b.fecha_autorizacion_siniestro
FROM servicios_auto_relevo s JOIN boleta_informativa b ON b.id = s.boleta_informativa_id WHERE s.id IN (648, 649);
