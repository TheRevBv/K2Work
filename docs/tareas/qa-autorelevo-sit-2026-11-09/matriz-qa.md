# Matriz QA — autorelevo SIT

| Caso | Pasos | Esperado | Resultado | Evidencia |
|---|---|---|---|---|
| B: descubrimiento | Playwright `--list --reporter=line` | Un caso Chromium | ok | Salida de sesión: 1 test in 1 file |
| B: tipado | `tsc --noEmit -p autorelevo-e2e/tsconfig.json` | Sin errores | ok | Salida de sesión: código 0 |
| B: sin autorización | Ejecutar sin `CONFIRMAR_CREAR_FOLIO_DEV` | Detener antes del navegador | ok | Fallo esperado en beforeAll |
| B: creación sin inciso | Ejecutar spec con datos SIT y autorización | Payload sin inciso, 2xx, ID, pantalla espera | ok (manual, 10 nov 14:59 CST) | `POST /tickets` → 200, 1188 B; pantalla «¡Recibimos tu solicitud!» con folio **K2-659**; BD `servicios_auto_relevo` 659: póliza `50027051`, prefijo `Q2`, siniestro `MA26I002156`, estatus «En revisión de documentación»; `autorelevo_event` 2 `reservado` con `numero_eventos` 0 |
| B: contrato Chubb | Consultar fallback typeSearch=3 sin inciso | Vigencia de póliza correcta | pendiente | Falta el flujo de avería mecánica (sin siniestro, `solo_venta`) |
| B: folio abierto | Repetir solicitud con la misma póliza mientras 659 siga abierto | 409 con folio y estatus | pendiente | Consecuencia del nuevo 409; probar en la UI |
| A: autorización | Abrir folio y guardar Sí | Radio rehidratado y Asignación | pendiente | Revisión estática solamente |
| D: folio inactivo | Consultar lista admin | Excluir active_record=0 | pendiente | Sin fix |
| E: cancelado | Consultar lista admin | Mostrar detalle | pendiente | Sin fix |
| F: recarga | Recargar steps sin store | Sin TypeError | pendiente | Sin fix |
