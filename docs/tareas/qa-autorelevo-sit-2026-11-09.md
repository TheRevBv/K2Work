# QA autorelevo SIT — 9 nov 2026

Pruebas Playwright en `micrositio-autorelevo-real/autorelevo-e2e/src/qa/` contra el despliegue `micrositio-autorelevo-web-2` (morfeo-dev) y el admin `micrositio-autorelevo-2-dot-morfeo-dev-321917.ue.r.appspot.com/admin/`.

## Cómo correr

```
BASE_URL=https://micrositio-autorelevo-web-2-dot-morfeo-dev-321917.ue.r.appspot.com/autorelevo/ \
API_FROM=https://micrositio-autorelevo-web-dot-morfeo-dev-321917.ue.r.appspot.com \
API_TO=https://micrositio-autorelevo-web-2-dot-morfeo-dev-321917.ue.r.appspot.com \
POLIZA=Q250027051 NUM_ASEGURADO=2016019796 \
npx playwright test -c autorelevo-e2e qa/ --project=chromium --workers=1
```

- El OTP se lee de `web_service_log` (`name='SMS_TRANSACTION'`, texto en `request_`) con `bin/k2-sql dev`.
- La sesión se guarda en `autorelevo-e2e/.auth/sesion-qa.json` (gitignored): las siguientes corridas no mandan SMS. Bórrala si cambia el folio.
- `API_FROM/API_TO` existen porque `environment.staging.ts` trae `k2ApiUrl` del servicio viejo (`web-dot`), no de `web-2`.
- Datos: folio K2-658 (Q250027051 / MA26I002156), autorizado en dev.

## Resultado por bug

| Bug | Resultado | Causa / fix |
|---|---|---|
| BUG-87293BEC timer | Reproducido en `web-2` | El build desplegado no llama `startCountdown()` en `resend()`; el fix ya está en `5a24e6e` (en HEAD). Solo falta desplegar. |
| BUG-90FD668C sucursales | Pendiente de redespliegue | `sucursal.component.ts` tragaba el error (`error: () => {}`) y el spinner quedaba infinito. Fix: estado cargando/error/vacío con Reintentar. |
| BUG-435440F4 fecha/hora | Pendiente de redespliegue | `iconSuffix` de calendario/reloj se encimaba con el selector nativo de date/time. Fix: se quitaron. |
| BUG-52C30DF7 Regresar | Pendiente de redespliegue | `back()` iba a `/estado`, que redirige otra vez a sucursal. Fix: confirmación y `auth.logout()`. |
| BUG-17B5AEBA guardar 2 veces | No se reproduce en dev | 2º guardado con la misma decisión: 200, 4 documentos, estatus sin cambio. |

## Hallazgos nuevos

1. K2 exigía `dias_solicitados` al crear el ticket → 400 desde el micrositio. Según el PRD los días salen de las fechas de recolección/devolución en la reservación (máx. 20). Fix en K2: `dias_solicitados` opcional; sin él se reserva un evento de 0 días (mantiene validación de vigencia, folio activo y días restantes) y `settle` lo ajusta con `total_dias_uso_vehiculo` que el micrositio ya manda al reservar. El admin sigue mandando sus días.
1b. Catálogo dev alineado al PRD (`datos/qa-autorelevo-sit-2026-11-09/catalogo-documentos-segun-prd.sql`): desactivados 22 y 23 (Volante en pérdida total/parcial) y 13, 14, 24 en detención legal (queda 25 como declaración legal). Replicar en test/prod. Resumen del PRD en `docs/proyectos/micrositio-autorelevo/prd.md`.
2. Error de K2 `{error:{error,detail}}` se mostraba como "[object Object]". Fix en `captura-info.component.ts`.
3. K2: al autorizar, el comentario sobrescribía `razon_estatus` (el admin lo usa como nombre del motivo y redirige a "seleccione motivo" si está vacío). Fix en `_aplicar_autorizacion_servicio`: al aprobar conserva el nombre del motivo; al rechazar guarda el comentario (lo lee el micrositio como motivo de rechazo).
4. Admin: la autorización no rehidrataba la decisión guardada al entrar desde la lista. Fix: `patchValue` cuando llega el ticket (`authorization-data-form.component.ts`).
5. Build viejo del micrositio en `web-2`: no manda `datos_titular` ni `ubicacion_titular` (0 apariciones en el JS), así que K2 tomó el titular de Chubb y dejó la ubicación vacía; tampoco mapea `Servicio autorizado` ni reinicia el timer. Se corrige redesplegando el código actual. (`dev.k2web.online` despacha al servicio `micrositio-autorelevo`; no es la causa).
6. K2: `DATE_TODAY = datetime.now(...)` se evaluaba una sola vez al arrancar la instancia, así que todos los `audit_*_at` de autorelevo guardaban la hora de arranque. Fix: `datetime.now(timezone.utc)` en cada escritura (data manager, service, events manager, report manager, documents manager; se quitó `Constants.DATE_TODAY`).
7. Seguridad (sin fix): `/auth/login` devuelve teléfono y correo completos antes del OTP; el upload por `hash_id` no pide token.

## Corrida 9 nov 15:30 (servicio `micrositio-autorelevo-web` dev, build `main-O7BDW74F`, K2 `micrositio-autorelevo-2`)

| Bug | Resultado | Evidencia |
|---|---|---|
| BUG-87293BEC | PASA: tras reenviar, 5:00 → 4:50 | `autorelevo-e2e/test-output/qa/BUG-87293BEC/` |
| BUG-435440F4 | PASA: fecha inicio/fin y hora completas, un solo ícono nativo | `.../BUG-435440F4/fechas-hora.png` |
| BUG-52C30DF7 | PASA: confirma, borra `ar_session` y vuelve a la bienvenida | `.../BUG-52C30DF7/tras-regresar.png` |
| BUG-90FD668C | PASA tras corregir `deploy/server.js` (http-proxy-middleware ^2.0.6 ignoraba `on: { proxyReq }` y no mandaba `X-Api-Key`; ahora `onProxyReq`/`onError`) y la llave de AVASA (estaba mal transcrita). | `.../BUG-90FD668C/sucursales.png` |
| BUG-17B5AEBA | No se reproduce en dev | — |

Notas: el servicio `micrositio-autorelevo-web-2` hacía proxy de `/autorelevo/*` a `dev.k2web.online` (build viejo); se usa `micrositio-autorelevo-web`. Chubb SIT `Policy/Validate` estuvo caído (500.30) ~14:39-15:15 y sigue intermitente. Folio de prueba: 658.

Pendiente QA/test: desplegar el `server.js` corregido en morfeo-test y actualizar el secreto `avasa-api-key` de morfeo-test con la llave vigente.

## Validación de la llave AVASA en test

- Rastreo local: `sucursal.component.ts:293` → `AvAsaApiService.getSucursales` → `getLocations` (`avasa-api.service.ts:43`) → `/avasa/2.0/locations/` → proxy `deploy/server.js:77` → `AVASA_TARGET`, con `X-Api-Key` inyectado en servidor.
- Consulta de lectura para probar el despliegue: `GET https://micrositio-autorelevo-web-dot-morfeo-test.ue.r.appspot.com/avasa/2.0/locations/?country=MX&search=MONTERREY`. Esperar HTTP 200 con JSON de sucursales, no HTML del frontend. No requiere crear una reservación ni consultar la BD.
- El código local prioriza `AVASA_API_KEY` sobre Secret Manager (`avasa-api-key`, versión `latest` del proyecto de ejecución). La llave se lee al arrancar: actualizar el secreto no refresca las instancias existentes. Confirmar `AVASA_TARGET=https://apitest.avasa.com.mx` en test.
- Un resultado correcto valida la credencial cargada, pero no identifica por sí solo que sea la nueva: verificar la fuente efectiva y el arranque posterior a la actualización.
- Esta revisión comprobó código y bitácora; no ejecutó la petición contra test ni verificó sus secretos/despliegue actual.

## Sesión 10 nov — handoff para revisar con Codex

Repos y ramas: K2-Full-Portal `CDSEBAU-57-Fix-QA-SIT-Autorelevo` (fixes A y B en commit `cc0bd193`), micrositio-autorelevo-real `CDSEBAU-39-Fix-QA-SIT`.
Servicios dev (`morfeo-dev-321917`): admin+API K2 con fixes → `micrositio-autorelevo-2-dot-…`; micrositio web → `micrositio-autorelevo-web`, cuyo proxy `/k2portal` (`K2_PORTAL_TARGET` en `deploy/app.dev.yaml` local, fuera de git) apunta a `default/micrositio-autorelevo`, que NO tiene `cc0bd193`.

### Estado rápido
| # | Tema | Estado |
|---|---|---|
| A | Admin no avanza de Autorización a Asignación | Fix en `cc0bd193`; falta probar desplegado |
| B | "No se pudo determinar la vigencia" con póliza sin inciso | Fix en `cc0bd193`; no probado: Chubb UAT caído y el web no usa `-2` |
| C | Chubb UAT falla (siniestro 400, token 502) | Externo; reintentar |
| D | Admin lista folios borrados (`active_record=0`) | Abierto, sin fix |
| E | Folios cancelados muestran "Continuar" en vez de "Mostrar detalle" | Abierto, sin revisar |
| F | TypeError al recargar `steps` (store no persiste) | Abierto, cosmético |
| G | Dos campos "Motivo" confusos en Autorización | UX, propuesta de texto |

### A. Admin no avanza de Autorización a Asignación (folio 658)
- Síntoma: guardar con "Sí" muestra "Exito al guardar datos" pero se queda en Autorización; al recargar el radio Sí/No sale vacío.
- BD dev correcta: boleta 661 con `evaluador_aprobo_servicio=1`, servicio "Servicio autorizado" (hoy el 658 está Finalizado).
- Causa: `apiserver/ix/boletas_informativas/auto_relevo/api/utils/related_models.py` es la lista blanca de `serialize_servicio(include_all=False)` y no tenía `evaluador_aprobo_servicio` ni `motivo_evaluacion_servicio`. La API no los devuelve → `authorization-data-form` no rehidrata el radio y `steps.validateAuthorizationData` (`typeof … === 'boolean'`) falla → `steps` deja `redirectUrl` en Autorización.
- Fix: agregar ambos campos (2 líneas).
- Revisar con Codex: que nada consuma esos campos esperando su ausencia; `redirectUrl` de `steps.component.ts` nunca se limpia y compite con el `navigate` de cada formulario (`authorization-data-form.component.ts:59-67`).
- Prueba: desplegar `-2`, abrir 658 (o un folio nuevo) desde la lista → radio en "Sí" → Guardar → debe ir a `/steps/assignment`.

### B. "No se pudo determinar la vigencia de la póliza… [HTTP 400]" (póliza `BE|43027807`, siniestro `156156163244`)
- Flujo: `create_ticket` → `_get_vigencia` → Chubb por siniestro (`typeSearch=9`) y, si no trae `FinVigencia`/`FechaFinVigencia`, por póliza (`typeSearch=3`) con `_fetch_chubb` → `validate_and_get_count` lanza 400 si `vigencia_fin` es None (`auto_relevo_events_manager.py:67`).
- Causa: `_fetch_chubb` armaba `NumeroInciso = poliza.split('|')[-1]`; con `BE|43027807` mandaba 43027807 como inciso.
- Fix: `clave, numero, inciso = self._parse_policy_parts(poliza)` y `NumeroInciso: inciso or ""`.
- Revisar con Codex: qué acepta `assistancechubb/sales?typeSearch=3` sin inciso (vacío, omitido o "1"); el micrositio manda la póliza sin inciso al crear (`search-event` sí usa `BE|43027807|1`).
- Automatización: `micrositio-autorelevo-real/autorelevo-e2e/src/qa/vigencia-sin-inciso.spec.ts` (redirige `/k2portal` a `-2` vía `API_FROM/API_TO`; falta `NUM_ASEGURADO`; no se ha corrido; deja un folio en dev si pasa).

### C. Logs GCP del error de Ale (10 nov 11:11 CST)
- `micrositio-autorelevo-web`: `POST /k2portal/.../auto-relevo/tickets` → 400.
- K2 `default/micrositio-autorelevo` (código distinto al local: `permitir_vigencia_vencida=con_siniestro`):
  - por siniestro: `claims.gruas/Grua/bienafectado` → 400 "Could not find stored procedure ''";
  - por póliza: `ChubbPolicy.get_token` → 502.
- Conclusión: falla de Chubb UAT; el fix de B no habría cambiado el resultado. Mensaje para Ale ya enviado.
- Para que el web use los fixes: `K2_PORTAL_TARGET=https://micrositio-autorelevo-2-dot-morfeo-dev-321917.ue.r.appspot.com` y `.\deploy.ps1 dev`, o desplegar `cc0bd193` en `default/micrositio-autorelevo`.

### D–G. Pendientes sin fix
- D: `list_tickets` del admin no filtra `ServicioAutoRelevo.active_record` (el 652 borrado aparecía como abierto).
- E: en la lista del admin, folios Cancelados muestran "Continuar"; Finalizados "Mostrar detalle".
- F: al recargar en `/steps/*` el store está vacío, `steps.ngOnInit` hace `return` antes de `initForm` y `[formGroup]="actionForm"` (línea 587, `extra_hours`/`others_costs`) lanza 3 TypeError. No bloquea.
- G: etiqueta "Motivo de no aprobación" y placeholder "Explica por qué no se aprobó el servicio…".

### Limpieza de datos dev (10 nov)
- 156 folios abiertos (no Finalizado/Cancelado/No autorizado, `active_record=1`) → `Cancelado` con `datos/qa-autorelevo-sit-2026-11-09/cancelar-folios-abiertos.sql`. Ninguno tenía evento activo en `autorelevo_event`, no se tocaron conteos.
- Folio 652 (`active_record=0`, "En revisión de documentación") → `Cancelado` a mano.
- Resultado: 0 folios abiertos en dev. Motivo: folios con errores bloqueaban nuevas solicitudes en pólizas de prueba.
