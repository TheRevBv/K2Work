-- Uso: bin/k2-sql dev -f datos/ajuste-movil-vale-grua-fotos/verificar.sql
SET @case_id = 67017;

SELECT f.id, f.file_kind, f.provider_id, f.voucher_number, f.batch_id, f.expected_count, f.sequence, f.batch_closed_at,
       f.size_bytes, f.sha256, a.dirname, a.filename, a.attachment_type
FROM ajuste_movil_file f
JOIN attachment a ON a.id = f.attachment_id
WHERE f.case_id = @case_id
ORDER BY f.id DESC;

SELECT id, action, status, timestamp, LEFT(response, 200) AS response
FROM web_service_log_ajuste_movil
WHERE case_number = @case_id
ORDER BY id DESC
LIMIT 20;

SELECT id, ticket_type, comment, created_time
FROM assistance_ticket
WHERE case_id = @case_id AND ticket_type = 9
ORDER BY id DESC
LIMIT 5;
