# Matriz QA — BUG-0FCE5E2C correo de servicio autorizado (dev)

Commit: `5ca828bc fix(autorelevo): notificar al asegurado cuando se autoriza su servicio`.
Disparo: `POST /v1/boleta-informativa/auto-relevo/tickets/<id>/autorizacion` cuando el estatus pasa a "Servicio autorizado".
Asunto: `AUTO RELEVO - Servicio autorizado`; link `https://micrositio-autorelevo-web-dot-morfeo-dev-321917.ue.r.appspot.com/autorelevo/`.

| # | Caso | Pasos | Esperado | Resultado | Evidencia |
|---|------|-------|----------|-----------|-----------|
| 1 | Feliz | Folio nuevo con correo propio → subir docs → "Documentación completa en espera de autorización" → Autorizar | Llega correo "Servicio autorizado" con nombre, siniestro, póliza y link | pendiente | |
| 2 | Link | Abrir el link del correo | Abre el micrositio de dev y permite iniciar la reserva | pendiente | |
| 3 | No autorizar | Otro folio → rechazar con comentario | Estatus "No autorizado", sin correo de autorizado | pendiente | |
| 4 | Re-autorizar | Volver a autorizar el folio del caso 1 | No llega un segundo correo (solo en la transición) | pendiente | |
| 5 | Sin correo | Folio sin correo de titular → autorizar | Autoriza sin error; log `sin correo para aviso` | pendiente | |
| 6 | Regresión | Al pasar a documentación completa | Sigue llegando "Documentación aprobada" | pendiente | |
| 7 | Regresión | Autorización tardía (Vehículo entregado sin decisión) | No cambia estatus, no envía correo | pendiente | |

Bruno: `bruno/Autorelevo/` (carpeta "Servicio autorizado (CDSEBAU-57)") (casos 1, 3, 4 y validaciones).
