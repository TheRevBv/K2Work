-- Cancela los folios de autorelevo que el micrositio considera abiertos
-- (estatus distinto de Finalizado, Cancelado y No autorizado). Ninguno tiene evento activo.
SELECT estatus_servicio, COUNT(*) total FROM servicios_auto_relevo
WHERE active_record = 1 AND estatus_servicio NOT IN ('Finalizado','Cancelado','No autorizado')
GROUP BY estatus_servicio;

UPDATE servicios_auto_relevo
SET estatus_servicio = 'Cancelado', audit_updated_at = UTC_TIMESTAMP()
WHERE active_record = 1 AND estatus_servicio NOT IN ('Finalizado','Cancelado','No autorizado');

SELECT ROW_COUNT() cancelados;
