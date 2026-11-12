-- Verifica un folio de colisión creado con la colección Bruno.
-- Uso: bin/k2-sql dev -f datos/collision-no-concesionados/bruno/verificar.sql  (cambiar @case_id)
SET @case_id = 0;

SELECT c.id, c.provider_type, c.caneinsite, c.destination_type, s.applicant_type,
       c.state_id, c.state_district_id
FROM assistance_case c
JOIN sinister s ON s.id = c.sinister_id
WHERE c.id = @case_id;

SELECT t.id, t.ticket_type, t.service_id, t.provider_id, t.created_time, LEFT(t.comment, 120) comment
FROM assistance_ticket t
WHERE t.case_id = @case_id
ORDER BY t.id;

-- Con fila y ahio_service_id = viajó a Qonect; sin fila = asignación manual / Geocercas.
SELECT a.id, a.ahio_service_id, a.requires_manual_assignment, a.reassign_reason
FROM assistance_case_ahio a
WHERE a.case_id = @case_id;

SELECT e.value1, e.comment1, e.value2, e.comment2
FROM case_extra_service e
WHERE e.case_id = @case_id;
