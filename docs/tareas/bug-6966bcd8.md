# BUG-6966BCD8 — "Consultar estatus" termina en crear solicitud (micrositio)

Reabierto 1x (12 nov 2026). Reporta Ian Téllez; asignado a Jeffrey Mikel.

## Causa
No era código: la liga Dev (`micrositio-autorelevo-web`) seguía sirviendo `20261110t150319` (10 nov),
anterior al fix de intención de Hector (`ebfcab5`, 11 nov: `auth.intencion` en `sessionStorage.ar_intencion`,
`?flujo=estatus` desde bienvenida/guard, OTP no manda a `/solicitud` en consulta).

## Resolución (13 nov 2026)
- Deploy de `dev` (`fc40e11`) como `20261113t130345` y promovido al 100 %.
- e2e `autorelevo-e2e/src/qa/consultar-estatus.spec.ts` contra Dev con BI99038410 / 14164455 / inciso 1:
  pasa; termina en "Seguimiento de solicitud" (folio K2-44), sin pasar por `/solicitud/*`.
- `deploy.ps1` sin `-Promote` deja la versión sin tráfico; la URL por versión no sirve por HTTPS (67 > 63 caracteres).
