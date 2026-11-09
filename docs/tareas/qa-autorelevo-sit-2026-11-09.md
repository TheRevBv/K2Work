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

1. Micrositio no mandaba `dias_solicitados` → K2 400. Fix: campo "Días de renta" en captura (`captura-info.component.ts`, `k2-api.service.ts`).
2. Error de K2 `{error:{error,detail}}` se mostraba como "[object Object]". Fix en `captura-info.component.ts`.
3. K2: al autorizar, el comentario sobrescribía `razon_estatus` (el admin lo usa como nombre del motivo y redirige a "seleccione motivo" si está vacío). Fix en `_aplicar_autorizacion_servicio`: al aprobar conserva el nombre del motivo; al rechazar guarda el comentario (lo lee el micrositio como motivo de rechazo).
4. Admin: la autorización no rehidrataba la decisión guardada al entrar desde la lista. Fix: `patchValue` cuando llega el ticket (`authorization-data-form.component.ts`).
5. Build viejo del micrositio en `web-2`: no manda `datos_titular` ni `ubicacion_titular` (0 apariciones en el JS), así que K2 tomó el titular de Chubb y dejó la ubicación vacía; tampoco mapea `Servicio autorizado` ni reinicia el timer. Se corrige redesplegando el código actual. (`dev.k2web.online` despacha al servicio `micrositio-autorelevo`; no es la causa).
6. K2: `DATE_TODAY = datetime.now(...)` se evaluaba una sola vez al arrancar la instancia, así que todos los `audit_*_at` de autorelevo guardaban la hora de arranque. Fix: `datetime.now(timezone.utc)` en cada escritura (data manager, service, events manager, report manager, documents manager; se quitó `Constants.DATE_TODAY`).
7. Seguridad (sin fix): `/auth/login` devuelve teléfono y correo completos antes del OTP; el upload por `hash_id` no pide token.
