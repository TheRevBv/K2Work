---
name: k2-cdm
description: Formalización Chubb Delivery Model (CDM) de un ticket K2 - genera los .docx DIS, CLL, PRUEBAS y Manual Técnico y redacta los 3 correos de Solicitud de Aprobación (Diseño, Construcción, Checklist). Usar cuando el usuario pide "documentación CDM", "formalizar", "DIS/CLL/PRUEBAS", "correos de aprobación" o va a liberar un ticket.
---

# Formalización CDM

Va después del PR: `k2-ticket` → `k2-rastrear` → fix → `k2-qa` → `k2-git` (PR) → **`k2-cdm`**.

Formatos de documentos y correos: `formatos.md`. Restricciones de wordcraft: `notas-generacion-docs.md` (leer antes de generar).

## Datos de entrada

Pedir solo lo que falte; el resto sale de K2Work y del repo:

| Dato | Fuente |
|---|---|
| ID `<AÑO>_OM-<PROY>_R<NN>` | usuario |
| Clave Jira, historia, objetivo, PRD | `docs/tareas/<rama>.md` |
| Definiciones | `rag/glosario.md` |
| Enlace, título y rama del PR | GitHub Enterprise `https://nausp-aapp0001.aceins.com/Mexico-IT/K2-full-portal/pull/<N>` (sin acceso desde aquí: pedir número/captura). Texto del enlace: `<título> · Pull Request #<N> · Mexico-IT/K2-full-portal` |
| Archivos cambiados | `git diff --stat <base>...<rama>` en K2-Full-Portal |
| Scripts SQL y orden | `datos/<ticket>/` → `sql.zip` |
| Escenarios y capturas E2E | `k2-qa` (colección Bruno en `datos/<ticket>/bruno/`): matriz en `docs/tareas/<rama>/matriz-qa.md`, capturas numeradas en `datos/<ticket>/`. Copiarlas a `<carpeta>/src/` e insertarlas en PRUEBAS.md como párrafo `IMG: captura.png` (cdm_docx.py las incrusta; `![]()` no funciona con wordcraft). Captura de la bitácora con Playwright: `table:has-text("<texto de un comentario>")`, una navegación a la vez. Sin capturas → `[PENDIENTE]` y sugerir correr `k2-qa` |
| Versión GCP a liberar y de rollback | Nombre de versión de App Engine en morfeo-dev (`<version>-dot-morfeo-dev-321917.ue.r.appspot.com`); ej. flujo WhatsApp/Blip → `blip`. Rollback = versión activa anterior: preguntar al usuario |
| Solicitante, fecha límite | usuario (default: Victor de la Paz; fecha = hoy + 1 día hábil) |

## Generar

1. Carpeta de salida `~/Documentos/wordcraft/cdm/<ID>/` (fuera de wordcraft no se puede escribir).
2. Escribir cada documento en Markdown en `<carpeta>/src/` siguiendo `formatos.md` y convertir con `wordcraft-cli convert src/X.md <ID>_X.docx` (no requiere el MCP). Salidas: `<ID>_DIS.docx`, `<ID>_CLL.docx`, `<ID>_PRUEBAS.docx`, `ManualTecnico-<NOMBRE>.docx`, más `diagrama.png` y `sql.zip` si aplican. Después aplicar el formato Chubb (portada con logo, índice, encabezado, pie con versión de formato y página, encabezado de tablas negro o verde en DIS):
   `uv run -q --with python-docx .claude/skills/k2-cdm/cdm_docx.py <docx> --tipo DIS|CLL|PRUEBAS|MANUAL --id <ID>`
   El .md empieza con `# <Título>` y `**<ID>** · <proyecto>`; sin línea final de versión (la pone el pie). Logo: `~/Documentos/wordcraft/cdm/plantillas/logo-chubb.png` (copia en `.claude/skills/k2-cdm/logo-chubb.png`). Revisar con `wordcraft-cli render <docx> <scratchpad>/x.png --page N`.
3. Secciones sin contenido: "N/A" en DIS, "No Aplica" en CLL. No inventar datos: si falta uno, dejar `[PENDIENTE: …]` y listarlo.
4. Correos en `~/Documentos/wordcraft/cdm/<ID>/correos.md`: asunto, Para, CC, adjuntos y cuerpo de DIS, CON y CLL, listos para pegar en Outlook. Los envía el usuario.

## Orden de envío

DIS primero (diseño aprobado por Hector) → CON (solo a Hector, con PR y pruebas) → CLL (a QA). Si rechazan, se reenvía subiendo `SolicitudDeAprobacion<NN>`; un cambio de alcance sube `R<NN>`.

## Cierre

Anotar en `docs/tareas/<rama>.md` el ID CDM, la ruta de los documentos y el estado de cada aprobación.
