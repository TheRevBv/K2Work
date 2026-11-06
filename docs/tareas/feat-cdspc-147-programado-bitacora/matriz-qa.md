# Matriz QA — CDSPC-147

Ambiente: backend local contra BD dev, SubstituteExp simulado (respuesta real de M9 39590099, `web_service_log.id=9414`), bitácora en admin dev (`blip`). Colección: `datos/cdspc-147/bruno/`.

| # | Caso | Pasos / SQL | Esperado | Resultado | Evidencia |
|---|------|-------------|----------|-----------|-----------|
| 1 | Grúa programada (SI + fecha) | `1 Grua programada.bru` → caso 67607 | Ticket 11, program_type 10, "Programado: 20-10-2026 16:00"; etiqueta en listado | ok | `datos/cdspc-147/01-bitacora-programada-67607.png`, `01b-listado-programado-67607.png` |
| 2 | Grúa no programada (NO) | `2 Grua no programada.bru` (póliza M9 39590147) → caso 67609 | Sin ticket 11; flujo normal a Qonect | ok | `datos/cdspc-147/02-bitacora-no-programada-67609.png` |
| 3 | SI sin fecha | `3 Grua SI sin fecha.bru` (póliza M9 39702552) → caso 67608 | Sin ticket 11; flujo normal a Qonect | ok | `datos/cdspc-147/03-bitacora-si-sin-fecha-67608.png` |
| 4 | BD | `bin/k2-sql dev` sobre `assistance_ticket` de 67607-67609 | Solo 67607 tiene ticket 11 | ok | `datos/cdspc-147/04-verificar-tickets.txt` |
| 5 | Hora mostrada del evento Programado | Bitácora de 67607 (antes del fix) | Fecha del evento = 16:00 | falla | Se muestra 10:00 (ver Hallazgos) |
| 7 | Re-prueba con fix UTC en blip dev, Chubb real | `1 Grua programada.bru` con baseUrl blip y póliza KD 39002312 → caso 67613 | Ticket 11 en `2026-10-20 22:00:00` UTC; bitácora 20 Oct 04:00 PM y comentario 16:00 | ok | `datos/cdspc-147/05-bitacora-programada-utc-67613.png`, `05-verificar-utc-67613.txt` |
| 6 | Unitarias (schema / set_scheduled_ticket) | pruebas sin BD | SI+fecha llena ticket; NO o sin fecha no cambia | ok | `docs/tareas/feat-cdspc-147-programado-bitacora.md` |
