# AGENTS.md — K2Work

Instrucciones para cualquier agente de IA que trabaje en el proyecto **K2** (CDS) y en el **micrositio de autorelevo**.
K2Work es el espacio de apoyo; el código vive en los repos y no se mezcla con este.

## Proyectos

| Proyecto | Ruta | Stack |
|---|---|---|
| K2-Full-Portal | `../K2-Full-Portal` | `admin/` Angular · `apiserver/` Flask 3.1 + SQLAlchemy 2.0 + MySQL (`mysql+pymysql`), alembic en `apiserver/migrations`, App Engine |
| micrositio-autorelevo | `../micrositio-autorelevo-real` | micrositio de autorelevo para siniestros (ver `docs/proyectos/micrositio-autorelevo/`) |

El backend NO es FastAPI: es Flask. Rutas con `@wrappers.api_resource` en `apiserver/ix/api/endpoints` y por dominio en `apiserver/ix/apps`, `whatsApp`, `vps`…; servicios en `svc`, modelos en `models` (ver `docs/arquitectura.md`).

## Reglas para agentes

1. Sin `commit`, `push` ni PR sin confirmación explícita del usuario. Nunca `Co-Authored-By` ni `Claude-Session` en commits o PRs.
2. Sin comentarios narrativos en el código (`FIX C1: antes…`, `Ahora se…`). Solo JSDoc/docstrings útiles o aclaración de una regla no obvia. El porqué de un cambio va en la respuesta al usuario.
3. Sin credenciales ni datos sensibles en K2Work. Las conexiones de BD viven en `~/.config/k2work/db.<perfil>.env`.
4. Solo BD `local` y `dev`. `test` y `prod` están bloqueados. Lo que modifica datos corre con ROLLBACK salvo `--commit` confirmado por el usuario.
5. Antes de proponer un fix, rastrear el flujo completo (skill `k2-rastrear`).
6. Documentar hallazgos en `docs/tareas/<rama>.md`; lo reutilizable en `rag/`.
7. Responder en español.

## Flujo de un ticket

`k2-ticket` → `k2-rastrear` → `k2-bd` (reproducir con SQL) → fix mínimo → `k2-git` → `k2-qa`.
Bitácora diaria: `k2-bitacora`.

## Mapa de K2Work

| Carpeta | Contenido |
|---|---|
| `docs/` | `arquitectura.md`, `modulos/`, `tareas/`, `proyectos/` |
| `rag/` | glosario e índice de archivos |
| `practicas/` | convenciones |
| `skills/` | índice de skills (código en `.claude/skills/`) |
| `datos/` | scripts SQL y salidas por ticket |
| `bin/` | `k2-sql`, `k2-bruno`, `k2-bitacora-check`, `k2-bitacora-hook`, `k2-timetracker` |
| `bruno/` | colecciones Bruno generales (Blip, Chubb SIT, Telasist); credenciales en `~/.config/k2work/bruno/` |
| `tests/` | pruebas de los scripts de `bin/` |
