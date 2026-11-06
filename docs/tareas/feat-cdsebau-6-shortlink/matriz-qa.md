# Matriz QA — CDSEBAU-6 ShortLink (feat/cdsebau-6-shortlink)

Rama desde `origin/dev`. Prueba: dominio esperado `<SHORT_URL_DOMAIN o SYSTEM_URL>/s/<código de 7>`.
Colección Bruno: `datos/cdsebau-6/bruno/` (casos 1-4, corrida 23/10 contra apiserver local de la rama con BD dev, 5/5 ok).
Verificar BD con `bin/k2-sql dev -f datos/cdsebau-6/01-short-links-recientes.sql`.

| # | Caso | Pasos / SQL | Esperado | Resultado | Evidencia |
|---|------|-------------|----------|-----------|-----------|
| 1 | Generar link (feliz) | `POST /api/shortlink/test` `{target_url}` | Regresa `short_url` con `/s/<7 chars>`; fila nueva en short_links (case_id NULL) | ok | `evidencias/bruno-qa-01-generar-link.png` (`dev.k2web.online/s/xIO60rZ`) |
| 2 | Redirección | `GET /s/<code>` del caso 1 | 302 a target_url | ok | `evidencias/bruno-qa-02-redireccion.png` |
| 3 | Código inexistente | `GET /s/XXXXXXX` | 302 a SYSTEM_URL, sin error 500 | ok | `evidencias/bruno-qa-03-codigo-inexistente.png` (local: SYSTEM_URL = dev.k2web.online) |
| 4 | Sin target_url | `POST /api/shortlink/test` `{}` | 400 "target_url es requerido" | ok | `evidencias/bruno-qa-04-sin-target_url.png` |
| 5 | SMS solicitud de ubicación | `POST /v1/auto_gen_assist/location-request/create-location-request` con communication_method=sms | SMS con link corto propio; fila en short_links | pendiente | |
| 6 | Correo/SMS de ubicación (location_client) | Flujo de solicitud de ubicación al cliente desde un caso | payload url acortada con /s/; abre la página de ubicación | pendiente | |
| 7 | SMS al proveedor con ubicación | Asignar proveedor a un caso con lat/long (assistanceticket) | Link /s/ redirige a Google Maps; short_links.case_id = caso | pendiente | 01-short-links-recientes.sql |
| 8 | Link NPS boletas informativas | Enviar boleta informativa NPS | Link /s/ abre `/public/nps-form?...`; case_id del caso | pendiente | |
| 9 | Link de encuesta | Envío de encuesta (tools/utils/survey.py) | Link /s/ con case_id del caso | pendiente | |
| 10 | Unicidad de código | `datos/cdsebau-6/02-codigo-duplicado.sql` | 0 filas | ok | 0 filas en dev (23/10) |
| 11 | Regresión: sin llamadas a Cuttly | `grep -rn cuttly_svc apiserver/ix` | Sin resultados | ok | grep sin coincidencias en la rama |
| 12 | Regresión: arranque del apiserver | Levantar apiserver / py_compile de los 7 archivos | Arranca sin ImportError | ok (py_compile) | falta arranque real |
