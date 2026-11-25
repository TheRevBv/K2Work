# CDSEBAU-57-Autorelevo-integrado

- Repo: K2-Full-Portal, rama `CDSEBAU-57-Autorelevo-integrado`
- Time Tracker: 2026_58P_MicrositioAutorelevo
- Matriz QA: [matriz-qa.md](CDSEBAU-57-Autorelevo-integrado/matriz-qa.md)

## 23 nov 2026 — Reporte QA (Ian Téllez, Teams "Pruebas Micrositio Autorelevo")

1. El correo para cargar documentación y el de "documento rechazado" son el mismo.
2. La liga de carga sigue mostrando que la documentación se cargó exitosamente.

### Hallazgos

- **Correo:** ambos salen de `POST /v1/boleta-informativa/auto-relevo/servicios/<id>/enviar` → `AutoRelevoNotificationsService.envio_mail` (`notifications_manager.py`), siempre con `template/autorelevo_mail.html` y asunto "CHECK LIST- AUTO RELEVO…". No existe plantilla de rechazo.
  El PRD (`docs/proyectos/micrositio-autorelevo/prd.md`) no define correo de rechazo; solo "Todo cambio de estatus por correo y SMS" (l. 83) y "Algún rechazo → documentación incompleta" (l. 52). Es feature: pendiente que negocio defina texto y destino del botón (micrositio o liga K2). Si se hace: en `envio_mail` usar plantilla nueva cuando `has_rejected_documents(servicio_id)`.
- **Liga:** `AutoRelevoFilesService.get_documents` (`upload_file_manager.py:280`) responde 400 "Todos los documentos ya han sido cargados" si todo `estatus_archivo == completado`. Rechazar solo cambia `estatus_validacion`; el archivo queda `completado`. **Bug.**

### Fix (liga)

Commit `91005644 fix(autorelevo): permitir recargar documentos rechazados desde la liga pública`.
`_procesar_documentos` reporta `Pendiente` el documento con `estatus_validacion == 'Rechazado'`. Patch: `datos/CDSEBAU-57/0001-fix-autorelevo-permitir-recargar-documentos-rechazad.patch`.

```diff
--- a/apiserver/ix/boletas_informativas/auto_relevo/api/auto_relevo_boleta/upload_file_manager.py
+++ b/apiserver/ix/boletas_informativas/auto_relevo/api/auto_relevo_boleta/upload_file_manager.py
@@ -358,7 +358,8 @@ class AutoRelevoFilesService:
                 estatus_archivo = "Pendiente"
                 hash_id_documento = None
             else:
-                estatus_archivo = documento_archivo.estatus_archivo.name if documento_archivo else "Pendiente"
+                rechazado = documento_validacion.estatus_validacion == "Rechazado"
+                estatus_archivo = documento_archivo.estatus_archivo.name if documento_archivo and not rechazado else "Pendiente"
                 hash_id_documento = documento_validacion.hash_id
 
             resultado.append({
```

Pendiente: desplegar en dev y que QA reprueba; respuesta enviada a Ian con ambos puntos.

## 2026-11-24 — BUG-0FCE5E2C reabierto (no llega correo de servicio autorizado)

- Causa: el admin (`authorization-data-form.component.ts`) autoriza con `PUT /auto-relevo/tickets/<id>` → `update_ticket`, que aplica `_aplicar_autorizacion_servicio` pero no mandaba correo. El aviso de 5ca828bc solo estaba en `POST /tickets/<id>/autorizacion`, que el admin no usa.
- Evidencia GCP (morfeo-dev, versión `micrositio-autorelevo`): prueba de Ian el 24 nov a las 15:19–15:33 UTC sobre el ticket 674, solo con `PUT /tickets/674` y `POST /tickets/674/cierre`, sin `/autorizacion` y sin logs de aviso.
- Fix: helper `_avisar_si_autorizado(servicio, estatus_previo)` llamado tras el commit en `update_ticket` y `registrar_autorizacion`. Test `test_avisa_al_autorizar_desde_el_admin` (falla sin el fix; 5/5 pasan con él).
- Bruno: `bruno/Autorelevo/Servicio autorizado (CDSEBAU-57)/7 Autorizar desde admin PUT (envía correo).yml`.

## 2026-11-24 — Folio No autorizado y orden de pasos

Decisiones del usuario: el "No" es definitivo; el folio queda en "No autorizado" (no "Cancelado") y el asegurado puede abrir una solicitud nueva; el orden de pasos se valida en admin y backend; el micrositio muestra el motivo al iniciar sesión; el e2e crea folios en dev con la póliza Q2|50027051.

### Caso A — "No autorizado" cierra el folio
- K2 `auto_relevo_boleta_service.py`: `_aplicar_autorizacion_servicio` llama `_sync_event_status` (libera evento y conteo); `_validate_folio_editable` bloquea `update_ticket` y `update_ticket_status` en `ESTATUS_BLOQUEADOS` (Cancelado, No autorizado); el cierre rechaza todo `ESTATUS_SIN_RECALCULO`.
- Admin `list.component`: `isClosed()` → "Ver detalle" para Finalizado/Cancelado/No autorizado.
- Micrositio: bloque "Motivo de no autorización" en `estado-solicitud`; en el login (`otp.component`), si no hay folio abierto y el último es "No autorizado", se muestra en `/estado` con "Nueva solicitud" (`K2ApiService.buscarUltimoNoAutorizado`).
- Tests: `ix/tests/auto_relevo/test_folio_no_autorizado.py`.

### Caso B — no saltar pasos
- Admin: `steps/relevo-steps.ts` (`pasoPermitido`, `pasoActual`, `pasoRelevoGuard` en las 6 rutas hijas); `goTo*` avisa "Paso no disponible". Asignación/seguimiento exigen autorización en "Sí". Spec `relevo-steps.spec.ts` (no corre hoy: `ng test` falla por `tests/dynamicFormObfuscation.spec.ts`, ajeno).
- Backend: `_validate_orden_pasos` + `ESTATUS_POR_PASO` / `CAMPOS_*_POR_PASO` en `constants.py`. Autorización requiere documentación completa (o todos los docs aprobados, para folios viejos); asignación requiere autorizado; seguimiento requiere vehículo entregado. Solo cuentan los campos del vehículo que cambian (el admin reenvía `VehiculoAsignado` completo).
- Tests: `ix/tests/auto_relevo/test_orden_pasos.py`. Suite autorelevo: 45 pasan, 2 fallan preexistentes (`test_tickets_abiertos`, fixture).

### E2E
- Bruno `bruno/Autorelevo/Flujo folio E2E (CDSEBAU-57)/` (13 requests, Run folder). Requiere el backend desplegado en la versión `micrositio-autorelevo` y que la póliza no tenga folio abierto (si no, 409).
