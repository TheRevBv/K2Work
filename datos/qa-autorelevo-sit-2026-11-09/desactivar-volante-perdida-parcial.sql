-- PRD Micrositio AutoRelevo v16: Pérdida parcial requiere identificación, licencia y carátula.
-- "Volante de admision" (id 23, motivo 2) no está en el PRD: se desactiva del catálogo.
SELECT id, nombre_documento, motivo_servicio_id, obligatorio, active_record FROM documentos_requeridos WHERE id = 23;
UPDATE documentos_requeridos SET active_record = 0 WHERE id = 23 AND motivo_servicio_id = 2;
SELECT id, nombre_documento, active_record FROM documentos_requeridos WHERE motivo_servicio_id = 2;
