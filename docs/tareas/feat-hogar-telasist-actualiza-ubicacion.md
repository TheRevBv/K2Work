# feat/hogar-telasist-actualiza-ubicacion

Webhook `POST /api/v2/telasist/home-assistance-status` ahora actualiza la ubicación del caso
(calle, colonia, entidad, municipio, entre calles) cuando Telasist envía `entidad`, `municipio`,
`colonia`, `calle`, `entreCalles`. Código: `svc/telasist/telasist_home_webhook_processor.py::_update_case_address`.

## Auth
- `@wrappers.auth` + `validate_webhook_jwt`: el JWT debe ser de `BaseConfig.TELASIST_WEBHOOK_EMAIL`
  (`telasist.hogar@chubbservicios.com`). Un token de otro usuario devuelve 401.
- Login: `POST /api/auth/token`.

## QA
Colección Bruno: `~/Código/personal/collections_bruno/K2 Telasist Hogar` (README con el orden).
Verificación: `GET /api/assistancecases/<id>` y comentario "Ubicación actualizada desde Telasist" en tickets.

## CDM
- ID 2026_OM-P25-033_R01 (compartido con CDSPC-147), envío 02. PR #104 `CDSEBAU-374-Hogar-Actualiza-Ubicacion` → `D4PLATFORM-48814-backup`.
- Documentos: `~/Documentos/wordcraft/cdm/2026_OM-P25-033_R01/telasist-hogar/`.
- Pendiente: versión GCP / rollback, capturas E2E en PRUEBAS. DIS / CON / CLL: sin enviar.
