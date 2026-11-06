# feat/remove-cuttly-usage — ShortLink propio (reemplazo de Cuttly)

- Commit: d25b24a6 (Joshua Morin, 2026-08-07); `api/endpoints/shortlink.py` llegó vía snapshot 6d68eea4.
- Tabla `short_links` ya existe en dev; script de creación en el CDM (sql.zip).
- Ruta pública `GET /s/<code>`; variable opcional `SHORT_URL_DOMAIN` (fallback `SYSTEM_URL`).
- Ojo: `POST /api/shortlink/test` está marcado como TEMP ("borrar tras validar").

## CDM
- ID: 2026_OM-P25-033_R01 (compartido con CDSPC-147 y Telasist, mismo despliegue). Versión 1.0.2 en el CLL consolidado.
- Docs: `~/Documentos/wordcraft/cdm/2026_OM-P25-033_R01/shortlink/` (SolicitudDeAprobacion03).
- Jira: CDSEBAU-6. Pendiente: PR, versión GCP (PROD/QA) y rollback, evidencias.
- Aprobaciones: DIS — / CON — / CLL —

## Rama nueva (22/10/2026)
`feat/remove-cuttly-usage` salía de `develop` (45 commits ajenos a dev). Se creó `feat/cdsebau-6-shortlink` desde `origin/dev`
(worktree `../K2-Full-Portal-shortlink`). dev ya tenía svc/endpoint/modelo/config/survey de ShortLink; la rama solo cambia 7 archivos.
Matriz: `docs/tareas/feat-cdsebau-6-shortlink/matriz-qa.md`.

## QA en Bruno (23/10/2026)

- Colección `datos/cdsebau-6/bruno/` (spec.json, generada con `bin/k2-bruno`), corrida con `npx @usebruno/cli` contra el apiserver local de la rama (venv `env/` en el worktree, Python 3.14 + setuptools por `distutils`). Su `.env` apunta a la BD dev. Resultado: 5/5 ok.
- Capturas en `datos/cdsebau-6/evidencias/bruno-qa-0{1..4}-*.png`. Se generan desde el JSON del CLI; el reporte HTML de Bruno no se guarda porque incrusta el body del login y el token.
- Bug encontrado y corregido: `models/short_link.py` tenía `default=datetime.now(timezone.utc)`, que se evalúa al importar y deja el mismo `created_at` en todas las filas. Ahora es `default=lambda: datetime.now(timezone.utc)`. La rama ya cambia 8 archivos.
- Los códigos usan `secrets.token_urlsafe`, así que pueden llevar `-` y `_`.
- `SHORT_URL_DOMAIN` no existe en GCP: no está en Secret Manager ni en los envVariables de App Engine (default, qa, uat). Se usa `SYSTEM_URL`: dev `ahio-test-dot-morfeo-dev-321917...` (default), `https://qa.k2web.online` y `https://uat.k2web.online`. El comentario del endpoint de prueba menciona `cds.k2web.online` como dominio esperado.
- `bin/k2-bruno` admite ahora `"followRedirects": false` por request.
