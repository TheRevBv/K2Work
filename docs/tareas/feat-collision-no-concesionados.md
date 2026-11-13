# Colisión No Concesionados → Qonect (AHIO Fase 2)

## Contexto
- La regla de elegibilidad para mandar colisiones **no concesionadas** a Qonect solo existía en el `develop` del espejo personal (no existe en el repo corporativo).
- En la VDI (`origin/dev`, snapshot `cf95bb9d` del 15-oct) el servicio 391 estaba **comentado** en `apps/ahio/variables.py` y quedaba la marca `#QUITAR EN CAMBIOS NUEVOS DE CONCESIONADO` en `whatsApp/services/collision.py`.
- 11-nov, Héctor Bárcenas: lo que venga de colisión y se vaya por Qonect se manda con **`tipoServicio` = 2 (Siniestro)** según `ContratoInterfazAhioQonect` (1 Asistencia, 2 Siniestro, 3 Auxilio vial).

## Patches (`docs/tareas/patches/collision-no-concesionados/`)
Base: `cf95bb9d` (VDI dev). Rama local: `feat/collision-no-concesionados` en `K2-Full-Portal`.

| # | Origen | Contenido |
|---|---|---|
| 0001 | parte de `e474d4eb` | `qonect_eligibility.py` + `provider_type_eligibility.py` (no existían en la VDI) |
| 0002 | `29282033` | `collision_eligibility.py`, integración en `assistancecases.py`, `collision.py`, `AutomaticClosingProcess`, tests |
| 0003 | `8896420c` | `enums/maneuver_type.py` |
| 0004 | `92862d96` | Ventura elegible como destino hasta confirmación OPS/Redes |
| 0005 | `272222cb` | validaciones extra de cuestionario + tests |
| 0006 | nuevo | habilita servicio 391 en `variables.py` con `tipoServicio: 2`; ajusta test |
| 0007 | parte de `e474d4eb` | `svc/assistanceticket.py`: reemplaza `validate_send_qonect` por `is_eligible_for_automatic_qonect`. Sin esto las reglas de colisión nunca se ejecutaban |

Aplicado en la VDI (11-nov) sobre `origin/dev` 4b64a66df (PR #188) como rama `CDSEBAU-6-feat-collision-no-concesionados`: conflicto en 0005 (`assistanceticket.py`, se quedó la versión de dev: solo era un log) y en 0006 (`variables.py`, #188 borró el bloque comentado). Tras #188 hay que ajustar `tests/automatic_closing/test_validate_service_id.py` para simular `get_ahio_service_id` y `AhioService` en lugar de `AhioRepository`. El 0007 se generó después y falta aplicarlo en la VDI.

## Flujo (rastreo)
`POST /api/v2/wa/sinister/create_folio` (`whatsApp/endpoints/collision.py`) → `svc.create_assistance_case` (`whatsApp/services/collision.py`; `flow_type=collision` ⇒ `provider_type="No Concesionado"`, `caneinsite=False`; `ticket.trigger = requiere_maniobra or cdsservice`) → `create_new_assistance_ticket` (`svc/assistanceticket.py`, ticket ASSIGN_SERVICE) → `is_state_allowed` + `is_state_district_allowed` + `is_eligible_for_automatic_qonect` → worker AHIO → `servicio-propuesto` con `QONECT_SERVICE_CONFIG[391]`.
- `applicant_type` sale de la API de siniestros de Chubb, no del body.
- `POST /api/assistancetickets` tiene `purge_unknown=True` y su schema no trae `car_type`: por esa vía la regla de vehículo siempre bloquea (fail-closed).

## Colección Bruno
`datos/collision-no-concesionados/bruno/` (12 casos + login, host `local`), registrada en el workspace de Bruno. Verificación por folio: `verificar.sql`. Los siniestros por defecto (MA26K002923 Ajustador, 156156163244 Centro de Valuación) vienen de casos de dev ya usados: reemplazarlos por siniestros de Chubb SIT sin caso.

Notas del rebase:
- El `dev` local tiene CRLF y la VDI LF: se aplicó con `-Xignore-space-at-eol` y se normalizó a LF.
- Conflicto real en `questionnaire_validations.py`: se tomó la versión de `develop` (imports `g`/`m` a nivel módulo + rama `SERVICE_TRUCK_COLLISION`).
- Sin 0006 el apiserver truena con `ImportError: SERVICE_TRUCK_COLLISION` (constante comentada en la VDI).

## Verificación
- `git am` sobre `cf95bb9d` limpio; árbol idéntico a la rama.
- `pytest ix/tests/ahio ix/tests/automatic_closing`: 138 passed. 12 de `is_state_allowed`/`is_district_allowed` fallan por config faltante en el entorno local (`None.split`), igual sin la serie.

## Aplicar en la VDI
```powershell
git fetch origin
git checkout -b feat/collision-no-concesionados origin/dev
git am --3way <ruta>\collision-no-concesionados\*.patch
```
Si `origin/dev` avanzó y `git am` choca: `git am --show-current-patch=diff`, resolver, `git add`, `git am --continue`.

## Pendiente
- Validar en sandbox Qonect un servicio-propuesto de colisión con `tipoServicio: 2`.
- Confirmar con OPS/Redes la regla de Ventura (patch 0004).

## 13-nov: caso 67988 no viajó a Qonect (versión blip)
- El caso sí pasó la elegibilidad (`[AHIO] lanzando worker propose_service`). El worker falló con `Redis 127.0.0.1:6379 connection refused`.
- Causa: `secrets_loader` no carga ningún secreto porque `GOOGLE_APPLICATION_CREDENTIALS` apunta a `apiserver/ix/keys/morfeo-dev-321917-eb4e5b05c7d9.json`, que no viene en el bundle. Sin secretos, `REDIS_HOST` queda en `None`. Solución: redesplegar sin esa variable.
- Se quitaron los comentarios narrativos del código y de los tests de no concesionados. `ix/tests/ahio` y `ix/tests/automatic_closing`: 150 passed.
- Corrección (13-nov): la causa completa era un `.env` incluido en el bundle de blip. `load_secrets` no sobreescribe variables que ya existen, así que `REDIS_HOST` se quedaba local (el log decía `10 cargados, 77 ya existían`). Con el redeploy sin `.env` el log dice `87 cargados, 0 ya existían`.
- Prueba en blip: caso 67994 (siniestro MA25K004002, bien 1). Llegó a Qonect (`servicio-propuesto` 200). Respuesta: "No existen gruas que cumplan con el tiempo de calidad establecido". 67993 se creó antes del fix y falló por Redis.
- Prueba del fix 0009 en blip (deploy 16:49 UTC; el log dice `87 cargados, 0 ya existían`): caso 67995 (KA26H000489, bien 1) por WhatsApp con carga "Sí". No se lanzó el worker AHIO, así que el caso queda para asignación manual, que es lo correcto.
