# CDSPC-147 — "Programado: {fechaCita}" en bitácora

- Jira: https://chubbservicios.atlassian.net/browse/CDSPC-147 (épica CDSPC-50 · OM-R26-121 Mejoras Grúas 2.0)
- Asignado: Hector Barcenas · Reporta: Mariana Canas
- Rama: `feat/cdspc-147-programado-bitacora` (desde `dev` en `c0a23518`)
- Time Tracker: `2026_62R_MejorasGruas2.0` (supuesto por la épica; en el portal sale finalizado, confirmar) · claves: CDSPC-147, programado, Chubb SIT

## Requerimiento

Como operador, al programar una cita de grúa desde WhatsApp quiero que se guarde en la bitácora la etiqueta
"Programado: {fechaCita}" para tener el registro.

## Contexto (reunión con Isai Ramírez / Alejandra Almaguer)

- "Mejoras grúas para WA" solo lo aplicaron Blip y Telasist; falta el lado de K2.
- Listado de gestiones (`/admin/assistance/cases`): ya aparece "Programado: dd-mm-aaaa hh:mm" en algunas tarjetas, pero no en todas
  las programadas por WA (caso #1484260 sí lo muestra).
- Bitácora (`/admin/assistance/cases/<id>/tickets/1`): ejemplo caso #1484304, evento tipo **Programado** con comentario
  "Programado para coordinación. GRUA PROGRAMADA PARA MAÑANA 13-10-26 A LAS 10:00 A.M.".
- Hay migración en curso: front a Angular 20 y back a Python 3.14. En `dev` local: `admin` sigue en Angular 14 (`@angular/core ^14.0.6`),
  backend ya `runtime: python314`, Flask 3.1.3, SQLAlchemy 2.0.51. Falta traer el código actualizado desde la VDI.

## Pendiente

- [x] Traer código actualizado de la VDI (Angular 20): `dev` en `cf95bb9d` = snapshot de `Mexico-IT/K2-full-portal` origin/dev `cee7e3022`
      (vía `git archive` + 7z). Front `@angular/core ^20.3.19`, TS 5.9. Rama del ticket rebaseada encima.
- [x] `k2-rastrear` (ver Hallazgos).
- [ ] Confirmar con Blip qué campos mandan para grúa programada (¿`programado`/`fecha_programada` como en hogar?).
- [ ] Reproducir con `k2-sql` en dev (falta `~/.config/k2work/db.dev.env`): tickets `ticket_type=11` de casos creados por chat.

## Hallazgos

### Front: cuándo se pinta "Programado:"
- `admin/src/app/components/assistances/assistance-cases/assistance-cases.component.ts:964-993`: pone `isprogrammed=true` y
  `fechaprogramada = serviceInfo.datetime + hourTimeZone` solo si el caso está abierto y el último ticket "de texto de servicio" es
  `ticket_type 11` (PROGRAMMED → `serviceInfo.text == 'Programmed'`).
- Plantillas: `assistance-cases.component.html:561,737` (operador), `:1396` (despachador, además exige `programmed_datetime` = fecha futura),
  `assistance-case-card/assistance-case-card.component.html:87`.
- Datos: `GET /assistancecases?check_ticket_type=true&case_ids=…` → `apiserver/ix/api/endpoints/assistancecases.py:398-470`
  (último ticket por servicio entre PROGRAMMED, CONNECTION, REIMBURSE y cancelados).

### Back: quién crea el ticket PROGRAMMED (11)
- `apiserver/ix/svc/assistanceticket.py` `create_new_assistance_ticket`:
  - `ticket_type == PROGRAMMED` (≈1905): ticket manual; `datetime` = fecha recibida, comentario `"{AssistanceProgrammingType.name}. {comentario}"`
    → así sale "Programado para coordinación. GRUA PROGRAMADA PARA…" del caso #1484304 (lo capturó un operador).
  - Al asignar servicio con `programmed == 1` + `programdate` (+ `program_type`) (≈1950-1990): crea además un ticket PROGRAMMED
    con `comment = AssistanceProgrammingType.name` y notificación programada.
- WA grúa: `POST /v2/wa/create_ticket` (`apiserver/ix/whatsApp/endpoints/ticket_creation.py:33`) → `assistance_case_svc.create_initial_case_ticket`
  (`svc/assistancecase.py:308`). El schema `schema_whats_app_assistancecase` (`whatsApp/schemas/schemas.py:2`) **no tiene**
  `programado`/`fecha_programada` ni `programmed`/`programdate`, así que un caso de grúa por WA nunca genera ticket 11 → no aparece "Programado:".
  El validador usa `purge_unknown=True` (`api/wrappers.py:454`): aunque Blip ya los mande, se descartan sin error.
- WA hogar sí: `create_home_assistance_case` (`whatsApp/utils/utils.py:2324`) guarda `programado`/`fecha_programada` en
  `non_auto_assistance_case` y `assistance_case_telasist_link`, pero tampoco crea ticket 11.

### Evidencia en BD dev (2026-10-15)
- `assistance_programming_type`: 10 Programado para coordinación, 20 seguimiento, 25 no se puede asignar proveedor,
  30 confirmación de cita, 35 no se puede facturar, 40 reembolso, 50 cliente no contesta, 60 re-coordinación, 70 excedente, 80 VoBo comercial.
- Casos por chat (`assistance_ticket.comment LIKE 'Boleta creada por chat%'`): 1981; solo 2 tienen ticket 11 (10522, 10527, de 2024,
  capturados a mano por el usuario 1674).
- Hogar: 454 `non_auto_assistance_case.programmed=1` con `fecha_programada`, **0** tickets 11 → no se ve "Programado:" ni en bitácora.
- `web_service_log_blip`: 290 requests con `programado`/`fecha_programada` (formato `'2026-09-24T15:00:00'`, sin zona), **todos de hogar**
  (servicio 444). Grúa/vial (138 requests con `ticket.latitude`, último 2026-10-08): ninguno trae fecha/cita/programado.
  Ejemplo vial: `{ClaveId, PolizaId, NumeroInciso, phone, country_phone_code, ticket:{service_id:332, latitude, longitude, comment}, latitude, longitude}`.

- Prueba de grúa programada en Bot QA (2026-10-02 10:22, fecha elegida 2026-10-02 16:00): caso **67026**, póliza M6 99007763,
  log `web_service_log_blip.id=4705` sin fecha. **Ojo:** el log se escribe con `g.json = validator.document` (`api/wrappers.py:488`),
  ya purgado por `purge_unknown=True` → los campos que no estén en el schema nunca se ven en el log.
- Versión App Engine `blip` (12-oct, rev interna `93315314`): `ticket_creation.py` igual a dev; `schemas.py` solo agrega
  `entidad/municipio/colonia/calle/entreCalles` al webhook de Telasist. `fechaCita` existe solo en el webhook de Telasist hogar
  (`svc/telasist/telasist_home_webhook_processor.py`), no en `/v2/wa/create_ticket`.

### Hipótesis de fix (pendiente de confirmar campos con Blip)
Aceptar `programado`/`fecha_programada` en `/v2/wa/create_ticket` y, si `programado == "SI"`, mapear a `ticket.programmed=1`,
`programdate`, `program_type` para que `create_new_assistance_ticket` cree el ticket PROGRAMMED con comentario `"Programado: {fecha}"`.
Revisar el flujo hermano de hogar.

## Implementación (commit `9475091b`, 2026-10-16)

- `whatsApp/schemas/schemas.py`: `scheduled_service_schema` (`programado`, `fecha_programada`) compartido por el schema de grúa y el de hogar.
- `whatsApp/utils/utils.py` `set_scheduled_ticket`: si `programado == "SI"` y hay fecha → `programmed=1`, `programdate`, `program_type=COORDINATION (10)`,
  `program_comment="Programado: dd-mm-aaaa HH:MM"`. Se llama en `create_ticket_from_wa` (rama vehicular).
- `svc/assistanceticket.py`: el ticket PROGRAMMED usa `program_comment` si viene; si no, el nombre del tipo.
- `models/assistance_programming_type.py`: `COORDINATION = 10`.
- Efecto lateral: hogar por `/v2/wa/create_ticket` ya no pierde `programado`/`fecha_programada` en la validación.
- Patch para VDI: `docs/tareas/patches/cdspc-147-programado-grua-wa.patch` → en la VDI: `git checkout -b feat/cdspc-147-programado-bitacora origin/dev` y `git am <patch>`.

## Pruebas

- Unitaria (sin BD): schema conserva los campos; `SI`+fecha llena el ticket; `NO` o sin fecha no cambia nada. OK.
- Colección Bruno: `datos/cdspc-147/bruno/` (3 casos) + `verificar.sql`.
- E2E local contra dev bloqueado: desde 2026-10-15 Chubb SIT (`Policy/SubstituteExp`) responde 200 "Ok" con `Marca`/`Tipo`/`Poliza` null para
  todas las pólizas (0 completas vs 57 vacías en `web_service_log`), y `get_car_model_id` truena con `None.strip()` → 500 antes del código nuevo.
  Pendiente repetir cuando Chubb SIT regrese datos.

## Formalización CDM

- ID: `2026_OM-P25-033_R01` (proyecto OM-P25-033 · AHIO - F2; el prefijo de año 2026 es supuesto).
- Documentos y correos: `~/Documentos/wordcraft/cdm/2026_OM-P25-033_R01/` (DIS, CLL, PRUEBAS, ManualTecnico, `correos.md`).
- PR: https://nausp-aapp0001.aceins.com/Mexico-IT/K2-full-portal/pull/139 (rama `CDSEBAU-147-CDSPC-Gruas-Programadas`, 6 archivos, incluye `.gitignore`). Versión GCP a liberar: `blip`.
- Versión GCP de rollback: en blanco (aún no se sabe cuál estará en preprod).
- Pendiente: capturas E2E para PRUEBAS. 2026-10-19: Chubb SIT `Policy/SubstituteExp` sigue respondiendo 200 "Ok" con Poliza/Marca/Tipo/Modelo null (ej. BE 43132157 inciso 1).
- Aprobaciones: DIS pendiente de envío · CON pendiente · CLL pendiente.

## E2E 2026-10-19 (SubstituteExp simulado)

- Matriz: `docs/tareas/feat-cdspc-147-programado-bitacora/matriz-qa.md`. Casos 67607 (programada), 67609 (no programada), 67608 (SI sin fecha) en dev.
- Simulación: cambio temporal en `ix/tools/services/chubb_policy.py` (`K2_MOCK_SUBSTITUTEEXP`), revertido. El chequeo "La poliza tiene casos abiertos" depende de la póliza simulada: variar `Poliza` en el mock y en el request por caso.
- **Hallazgo — hora desfasada 6 h:** `fecha_programada` llega en hora local sin zona (`2026-10-20T16:00:00`) y se guarda tal cual en `assistance_ticket.created_time`, que el resto del sistema maneja en UTC. El front resta 6 h: bitácora y listado muestran "20 Oct 10:00 AM" / "Programado: 20-10-2026 10:00" mientras el comentario dice 16:00. Fix propuesto: convertir `fecha_programada` de America/Mexico_City a UTC en `set_scheduled_ticket` antes de asignar `programdate` (el comentario conserva la hora local). Confirmar si el ticket PROGRAMMED manual (operador) ya manda UTC.
- Verificado el flujo manual: el admin manda `datetime`/`programdate` como `Date` de JS (ISO UTC) y el back lo guarda tal cual → `created_time` del ticket 11 en UTC (caso 66004: "a las 22 hrs" del 31-jul → `2026-08-01 04:13`). Hogar no se ve afectado: usa `non_auto_assistance_case.fecha_programada` en hora local y Telasist le agrega `-0600`.
- Fix aplicado (sin commit): `set_scheduled_ticket` convierte `fecha_programada` de `config.K2_TIMEZONE` a UTC para `programdate`; el comentario conserva la hora local. Prueba sin BD: 16:00 → 22:00 UTC, 21:30 → 03:30 UTC del día siguiente, NO / sin fecha sin cambios. OK.
- 2026-10-19: el usuario commiteó y subió el fix y redesplegó `blip` en dev. Re-prueba con Bruno contra blip con Chubb SIT real (SubstituteExp ya responde): caso 67613 (KD 39002312), ticket 11 en `2026-10-20 22:00:00` UTC, bitácora "20 Oct 04:00 PM" y comentario "Programado: 20-10-2026 16:00". OK. PRUEBAS del CDM actualizado con este caso.

## JSON real de Blip (correo María Varela, 2026-10-21)

- Blip manda los campos **dentro de `ticket`** y con otro nombre: `ticket.programado = "SI"`, `ticket.fechaYhora = "2026-10-22T14:30:00-06:00"` (con zona).
- La implementación actual espera `programado`/`fecha_programada` en la raíz → con este payload no se crea el ticket 11. Además el subschema
  `ticket` no los declara y `purge_unknown=True` los borra antes de llegar a `set_scheduled_ticket`. Caso 1493152 se creó sin programado.
- Ajuste aplicado (2026-10-21, sin commit): declarar `programado`/`fechaYhora` en el subschema `ticket` de `schema_whats_app_assistancecase` y leerlos de `data["ticket"]`
  respetando el offset (`datetime.fromisoformat`, y solo si viene sin zona localizar con `K2_TIMEZONE`). Actualizar colección Bruno.
  - `schemas.py`: subschema `ticket` acepta `programado` y `fechaYhora`. La raíz conserva `programado`/`fecha_programada` (hogar y compatibilidad).
  - `set_scheduled_ticket`: prioriza `ticket.programado`/`ticket.fechaYhora`; si no, la raíz. `datetime.fromisoformat` respeta el offset; sin zona asume `K2_TIMEZONE`.
    Comentario en hora local. Prueba sin BD con el payload del correo: `programdate=2026-10-22T20:30:00`, "Programado: 22-10-2026 14:30"; NO / sin fecha no cambian nada; raíz legacy OK; `Z` OK.
  - Bruno regenerado en formato OpenCollection (Bruno 4.2.1) con `bin/k2-bruno datos/cdspc-147/bruno/spec.json --force`: 5 casos (Blip, NO, SI sin fecha, sin zona, raíz legacy) contra `blip`.
  - Pendiente: desplegar en `blip` y correr la colección; actualizar patch/PR 139 y PRUEBAS del CDM.

## 2026-10-22 — póliza QA y mini patch
- Chubb SIT volvió a responder con datos completos (`MORFEO_GET_SALE_CHUBB` en `web_service_log`).
  Pólizas vigentes sin casos en dev para el bot QA: **MF 46112617 inciso 1** (Chevrolet Aveo 2017, vence 17/Sep/2031) y **GQ 46101104 inciso 1** (Chevrolet Aveo 2026, vence 22/Sep/2031).
- Mini patch (sin commit, sobre `b7ea4496`): `docs/tareas/patches/cdspc-147-ticket-programado-fechaYhora.patch` → en la VDI `git apply <patch>`.
- 2026-10-22: se cerró en dev el caso 67678 (status 1→2, `UPDATE assistance_case SET status=2`) para liberar GQ 46101104; bloqueaba con 'La poliza tiene casos abiertos'.
