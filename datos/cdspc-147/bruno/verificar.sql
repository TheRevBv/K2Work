-- bin/k2-sql dev -e "$(cat datos/cdspc-147/bruno/verificar.sql)"; cambiar 0 por el case_id devuelto
SELECT id, ticket_type, program_type, created_time, comment FROM assistance_ticket WHERE case_id = 0 ORDER BY id;
