-- Catálogo documentos_requeridos alineado al PRD Micrositio AutoRelevo v16 (Confluence CDS1, 29/09/2026).
-- Pérdida total / parcial: identificación, licencia, carátula.
-- Detención legal: identificación, licencia, declaración legal (id 25). El número de siniestro se captura en su propia pantalla.
-- Avería mecánica: identificación, licencia, diagnóstico del taller, carátula (ya coincide).
UPDATE documentos_requeridos SET active_record = 0 WHERE id IN (22, 23) AND nombre_documento = 'Volante de admision';
UPDATE documentos_requeridos SET active_record = 0 WHERE id IN (13, 14, 24) AND motivo_servicio_id = 3;
SELECT m.nombre motivo, d.id, d.nombre_documento FROM documentos_requeridos d JOIN motivo_servicio m ON m.id = d.motivo_servicio_id
 WHERE d.active_record = 1 AND m.id IN (1, 2, 3, 4) ORDER BY m.id, d.id;
