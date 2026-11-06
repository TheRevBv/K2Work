---
name: k2-ticket
description: Documenta un ticket/requerimiento de K2 o CDS (correos, capturas, chats, scripts) en K2Work/docs/tareas. Usar cuando el usuario pasa datos de un ticket, capturas de Jira/Teams/correo o pide "documenta/anexa esto".
---

# Documentar un ticket

Un archivo por rama: `docs/tareas/<NombreDeRama>.md` y carpeta `docs/tareas/<NombreDeRama>/` para evidencias.

## Al recibir material

1. Copiar capturas a la carpeta de evidencias con nombre numerado y descriptivo (`01-requerimiento.png`, `02-pantalla-error.png`).
2. Transcribir lo relevante en el `.md`; no depender solo de la imagen.
3. Si el material trae credenciales o datos personales de clientes, omitirlos o anonimizarlos.

## Estructura del `.md`

    # <Título del ticket>
    - Rama: <rama> · Repo: <K2-Full-Portal | micrositio-autorelevo>
    ## Requerimiento
    ## Hallazgos            (fechados: 2026-10-12: …)
    ## Cambios             (archivos tocados, una línea por archivo)
    ## Pruebas             (enlaza datos/<ticket>/ y la matriz QA)
    ## Pendientes

## Cierre

Si se descubre algo reutilizable (término, archivo clave, regla de negocio) agregarlo a `rag/glosario.md` o `rag/indice-archivos.md`.
