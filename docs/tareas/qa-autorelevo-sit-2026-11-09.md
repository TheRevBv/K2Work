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
| B | "No se pudo determinar la vigencia" con póliza sin inciso | Fix en `cc0bd193`; prueba e2e corregida; pendiente correrla con Chubb UAT arriba |
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
- Automatización: `micrositio-autorelevo-real/autorelevo-e2e/src/qa/vigencia-sin-inciso.spec.ts`, ya corregida. El OTP se lee de `web_service_log` en dev (`sesion.ts`), así que no hace falta apuntar a `-2` para el login. Exige `CONFIRMAR_CREAR_FOLIO_DEV=1`, `POLIZA`, `INCISO`, `NUM_ASEGURADO`, `SINIESTRO` y `BASE_URL`; crea un folio en dev.

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

### Continuación Codex — automatización B (10 nov)

- Ramas verificadas: micrositio `CDSEBAU-39-Fix-QA-SIT`; backend `CDSEBAU-57-Fix-QA-SIT-Autorelevo`. El spec de B ya existía sin seguimiento en Git; se completó sin commit.
- Rastreo: `captura-info.component.ts:onSubmit` construye `prefijo|numero`; `k2-api.service.ts:crearTicket` envía `poliza` y `sinister_chubb_id`; `_get_vigencia` consulta siniestro y después póliza; `_fetch_chubb` usa `_parse_policy_parts` y envía inciso vacío cuando falta. El cambio de `cc0bd193` corrige el payload, pero no confirma el contrato externo de Chubb.
- Spec: exige datos explícitos, limita destino al backend dev `-2`, calcula `API_FROM` con el origen (sin duplicar `/autorelevo/`), desactiva reintentos, usa un PDF válido y comprueba póliza sin inciso, siniestro, respuesta 2xx, ID de servicio y navegación a `/solicitud/espera` después de subir documentos.
- Evidencia automática: adjunto `resultado-creacion` con HTTP, ID de servicio y destino. Sin cuerpos completos, tokens ni capturas de datos personales. Los datos de la captura facilitada por el usuario se usan solo en la sesión, no se copian aquí.
- Verificación: TypeScript pasó; Playwright descubre un caso; corrida sin confirmación se detuvo en `beforeAll`, antes del navegador, como se esperaba. No equivale a una corrida E2E aprobada.
- Pendiente: ejecutar integración con autorización de creación y disponibilidad de Chubb. Un éxito E2E no prueba necesariamente el fallback por póliza si Chubb ya entrega vigencia por siniestro. Confirmar aparte qué acepta `typeSearch=3` sin inciso.

Comando desde el repositorio del micrositio, con variables de datos definidas en la terminal y creación autorizada:

```bash
BASE_URL=https://micrositio-autorelevo-web-dot-morfeo-dev-321917.ue.r.appspot.com/ \
CONFIRMAR_CREAR_FOLIO_DEV=1 \
npx playwright test -c autorelevo-e2e qa/vigencia-sin-inciso \
  --project=chromium --workers=1 --reporter=line
```

Requiere `POLIZA`, `INCISO`, `NUM_ASEGURADO`, `SINIESTRO`. No repetir automáticamente si se creó un folio y falló la carga de documentos; consultar el ID registrado antes de otra ejecución.

Revisión estática adicional (sin fixes ni validación desplegada): A incluye los campos en `related_models.py`; `steps` todavía conserva `redirectUrl` entre emisiones. D: ni `list_tickets` ni `_apply_filters` filtran `ServicioAutoRelevo.active_record`. E: la plantilla solo distingue `Finalizado`; `Cancelado` cae en Continuar. F: `ngOnInit` sale antes de `initForm` cuando falta el ticket. A y D–F siguen pendientes de QA funcional.

### Contactos en login — reporte adicional 10 nov

- Capturas del usuario: `Policy/Detail` muestra teléfono/correo dentro de `responseData.insured`, pero el login responde 422. Las capturas usan números de póliza distintos: al login le falta un dígito respecto de la consulta Bruno. No constituyen todavía una reproducción con la misma entrada.
- Rastreo local: `login.component.ts` → `auth.service.ts:login` envía el número sin recortarlo → `autorelevo_auth.py:autorelevo_login` normaliza espacios/mayúsculas → `AutorelevoPolicyService.get_policy_detail` consulta `Policy/Detail` con ese mismo número → extrae `responseData.insured.phoneNumber` y `.email`. El 422 se emite cuando ambos están vacíos, antes de generar el contexto OTP.
- El código local reconoce las claves mostradas en las capturas. Pendiente repetir con exactamente la misma póliza/asegurado/inciso y confirmar el backend efectivo del proxy web; no hay evidencia suficiente para cambiar el mapeo. Una respuesta sin `responseData` útil también puede terminar en el mensaje de contactos ausentes; distinguirla de una póliza válida sin contactos requiere revisar la respuesta real del servicio.

- Confirmación posterior del usuario (captura 10 nov, 12:04): después de corregir el número de póliza, el login avanzó a `/verificacion/canal`, devolvió ambos contactos y mostró SMS/correo. Este caso no reproduce un defecto de extracción de contactos; el fallo anterior correspondía a una entrada distinta. Evidencia visual del usuario, no corrida automatizada. No confirma envío/validación OTP ni creación del folio de B.

### Consulta directa GCP — 10 nov, ~12:08 CST

- Consulta de solo lectura en `morfeo-dev-321917`, logs App Engine desde 16:00 UTC (10:00 CST). POST con rutas `auto-relevo`, `document` o `upload`: último intento de creación a las 17:11:15 UTC (11:11 CST), HTTP 400 en web y `default`, trace `b73677e17d25c45edcf80401883695da`. Los únicos POST posteriores encontrados fueron cierres de folios, HTTP 200.
- Logs de aplicación 17:11:16–19 UTC confirman `bienafectado` / `Could not find stored procedure`, fallo 502 al obtener token y finalmente «No se pudo determinar» la vigencia. El error ocurre al crear ticket, antes de subir documentos.
- No se encontraron POST posteriores de creación/carga en esa consulta; esto no prueba recuperación. Codex todavía no reprodujo el flujo mediante E2E. No se guardaron cuerpos ni datos de asegurados.

### Sync del apiserver desplegado y flag de 48 h — 10 nov

- El código de `micrositio-autorelevo-2` (K2 `default`, 10:42 CST) **no era el de la rama local**. Se bajó desde `deployment.files` de `gcloud app versions describe` (GCS `staging.morfeo-dev-321917.appspot.com`, objetos por SHA1): de 2099 archivos, 811 solo diferían por CRLF y 8 tenían contenido distinto; 3 existían solo en GCP.
- Lo que faltaba en local: validación de 48 h del siniestro (422 `Siniestro reciente`), `FechaReporteSiniestro` en `assistancechubb.py`, `permitir_vigencia_vencida` con siniestro, folio abierto por póliza (409 + `?abierto=1`), `release()` al cancelar/no autorizar y `search-event?solo_venta`. Tests en `apiserver/ix/tests/auto_relevo/`.
- Rama `CDSEBAU-57-Sync-Autorelevo-GCP` → merge fast-forward a `CDSEBAU-57-Fix-QA-SIT-Autorelevo` (commits `f4038e5e` y `b0e86b89`).
- Flag: `AUTORELEVO_MIN_HORAS_SINIESTRO` (default 48; dev `0`, test/prod `48`). Con `0` no se consulta Chubb solo para la fecha de reporte.
- Verificación: `py_compile` OK; tests de `test_tickets_abiertos.py` → 20 pasan, 2 fallan (`test_folio_cancelado_o_no_autorizado_libera_evento` usa `g.s()` y no pide el fixture `app_context` de `ix/tests/conftest.py:308`). Es un hueco del test importado, no del código de producto.

### Nuevas capturas y cambio de destino web — 10 nov

- Logs dev verificados: 12:08 y 12:17 CST, `default` versión `micrositio-autorelevo`, creación HTTP 400 por vigencia, con errores de procedimiento Chubb y obtención de token. A las 13:02–13:03 CST, `default` versión `release-12-nov`, tres creaciones HTTP 400 por «Debe indicar los días de renta». Son errores distintos previos a la carga de archivos.
- Código local: `validate_and_get_count` permite `dias=None`, pero rechaza días presentes inválidos; `create_ticket` pasa `payload.get("dias_solicitados")`. El micrositio no envía días al crear. No agregar días ficticios como solución.
- El usuario informa que ya apuntó el web a K2 `-2` para pruebas. El cambio es posterior a los intentos anteriores; falta validar una solicitud nueva contra ese destino. No atribuir los errores de `release-12-nov` al código de `-2`.

### Normalización de la póliza en el micrositio — 10 nov

- El payload de `POST /tickets` llegaba como `"poliza": " Q|250027051"`: el login guardaba en sesión lo tecleado sin limpiar y los cinco puntos que armaban `PREFIJO|NUMERO` partían del valor crudo. `_parse_policy_parts` en K2 recibía prefijo `" Q"` y número `"250027051"`, que no coincide con el `Q2|50027051` de Chubb.
- Fix en rama `CDSEBAU-39-Fix-QA-SIT`: helper `core/utils/poliza.ts` (`normalizarPoliza` deja solo `[A-Z0-9]` y `polizaK2` arma `PREFIJO|NUMERO`). Se normaliza al iniciar sesión, al restaurar `sessionStorage` y en los cinco usos (`captura-info` ×2, `num-siniestro`, `otp`, `estado-solicitud`).
- Verificación: `tsc -p autorelevo/tsconfig.app.json --noEmit` y `tsc -p autorelevo-e2e/tsconfig.json --noEmit` sin errores; los seis archivos tocados entran en el programa de compilación.
- Sigue pendiente: el web de test apunta a un backend de test con el código viejo, así que el 400 de «días de renta» solo desaparece al desplegar `CDSEBAU-57-Fix-QA-SIT-Autorelevo`.

### Columna «Motivo» vacía en el listado del admin — 10 nov

- El listado (`relevo-car/list.component.html:157`) pintaba `BoletaInformativa.motivo_activacion_servicio`, texto que solo escribe el operador al guardar el motivo (`reason-data-form.component.ts:136`). Los folios recién creados salían «No seleccionado» aunque `motivo_servicio_id` sí venía en el payload. En dev: 11 de 12 boletas traen el id; solo la 654 (creada desde el admin) lo tiene `NULL`.
- Fix (commit `b4c7c81b`): relación `BoletaInformativa.motivo_servicio` (`lazy='joined'`), `MotivoServicio` en `related_models.py` y en `serialize_servicio`, y en el admin un respaldo `motivo_activacion_servicio || MotivoServicio?.nombre`. Se mantiene la prioridad del texto del operador, así que reportes y folios ya procesados no cambian.
- Verificación: `py_compile`, mapper de SQLAlchemy (`lazy=joined`), `test_tickets_abiertos.py` 20/22 (los 2 fallos previos) y `ng build --configuration development` sin errores.
- Requiere redesplegar apiserver **y** admin en dev: el nombre del catálogo lo arma el backend.
