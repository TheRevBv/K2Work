# CDSEBAU-39 — rama limpia para Gitleaks (micrositio autorelevo)

**Fecha:** 2026-10-26 · Repo corporativo `Mexico-IT/Micrositio-Autorelevo` (solo accesible desde la VDI).

## Problema
PR #5 (`CDSEBAU-39-autorelevo-3` → `dev`, 37 commits) bloqueado por Gitleaks: 23 hallazgos en el **historial** (la punta ya estaba limpia).

## Solución
- Rama `CDSEBAU-39-autorelevo-clean` desde `origin/dev` + `merge --squash` de `-3` → 1 commit.
- Fuera del repo: `.chubb-ui-mcp-cache/`; `.gitignore` con `.bmad-core/`, `.prodigy/`, `.chubb-ui-mcp-cache/`, `environment.local.ts`.
- `CLAUDE.md:105` → `k2PortalPassword: process.env.K2_PORTAL_PASSWORD`.
- PR #6 abierto. Queda 1 hallazgo `xml-password` (falso positivo: `deploy/server.js:97`, `k2Password` viene de Secret Manager) → `/whitelist`.

## Aprendizajes
- Gitleaks del servidor usa reglas corporativas (`xml-password`) que el gitleaks local no trae: local limpio ≠ servidor limpio.
- El hook de push está en warn-only; el bloqueo real es el comentario del bot en el PR.
- `stash -u` no guarda archivos ignorados; si `dev` no los versiona, respaldarlos fuera del repo antes del `switch`.

## Pendientes
- Aprobación de whitelist por DevSecOps (Jira).
- Cerrar PR #5 (avisar a Donovan/Hector) y borrar rama remota `-3` tras merge.
- Rotar credenciales expuestas en el historial de `-3`.
- En la VDI: `git switch CDSEBAU-39-autorelevo-3` + `git stash pop` (stash@{0}).

Script de referencia: `datos/CDSEBAU-39/rama-limpia-gitleaks.sh`.

## BUG-9A55E506 — Envío sin documentación (SIT, Alta)
- Causa: en `captura-info.component.ts` el botón «Enviar solicitud» solo se deshabilitaba con `loading()`; `onSubmit` no validaba documentos.
- Fix (micrositio-autorelevo-real, rama dev, sin commit): getter `documentosCompletos` (todos los documentos con `estado === 'subido'`), deshabilita el botón y `onSubmit` corta con mensaje.
- Verificado local 2026-11-05 (Playwright, rama verify/bug-9a55e506 = dev + shims infra/local-v2, motivo pérdida total): sin documentos → botón deshabilitado; 2/3 → deshabilitado; 3/3 → habilitado; quitar uno → deshabilitado. No se probó el envío real a K2 (sesión simulada, sin OTP).

## BUG-08E2E353 — «K2 no generó hash_id» al enviar con documentos (SIT, Media)
- Logs morfeo-test: el micrositio SIT reenvía /k2portal al K2 de **dev** (servicio 648, póliza CE|50001692, siniestro MA26G001851). `POST /servicios/648/enviar` 200 y `GET /tickets/648` 200 a las 20:12, 20:22 y 20:53 UTC.
- BD dev: el 648 sí tiene hash_id en sus documentos.
- Causa: en dev `default` el 100% del tráfico va a la versión `test-maps` (hector.barcenas1, 2026-10-26, revisión 7e469722, que no está en el clon local). Su `serialize_servicio` no incluye `"hash_id"` en `DocumentosValidacion`, así que el micrositio nunca recibe el hash.
- Código correcto: rama CDSEBAU-57-CDSPLAT-Micrositio-Autorelevo-v2 (commit 2325fcdc agrega `"hash_id": doc.hash_id`). Solución: desplegar el backend con ese cambio, o mover el tráfico a una versión que lo tenga. No es cambio del micrositio.
