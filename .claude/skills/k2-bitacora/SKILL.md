---
name: k2-bitacora
description: Llena la bitácora diaria de CDS en Obsidian (Trabajo/Cds/Mensuales/Tareas <Mes> <Año>.md) con actividades y horas que suman 8 h por día y su proyecto del Time Tracker. Usar cuando el usuario pide "llena/actualiza mi bitácora", "qué hice hoy/ayer" o ponerle tiempos a las tareas.
---

# Bitácora diaria CDS

Archivo: `~/Documentos/ObsidianVault/Trabajo/Cds/Mensuales/Tareas <Mes> <Año>.md` (ej. `Tareas Octubre 2026.md`). Si el mes no existe, crearlo.

## Formato

    5 de octubre
    - (1 h) [BAU] Se atiende daily de canales y ahio
    - (3 h) [BAU: Documentación] Se actualiza version de catalogos de siniestros
    - (4 h) [2026_58P_MicrositioAutorelevo] Se sube ajuste de autorelevo con revision de hash ids

- Encabezado `<día> de <mes>` en minúsculas, línea en blanco entre días.
- Viñetas impersonales ("Se revisa", "Se corrige", "Se atiende"), cortas.
- `(N h)` al inicio, múltiplos de 0.5; **cada día suma exactamente 8 h**.
- Tras las horas, el proyecto del CDS Time Tracker entre corchetes: `[CODIGO]`, `[BAU]` o `[BAU: <actividad>]`.
  Si es estimado, tomarlo de la línea `- Time Tracker:` de `docs/tareas/<rama>.md` o de lo ya capturado en el portal
  (`bin/k2-timetracker proyectos`); lista y endpoints en `docs/proyectos/cds-timetracker.md`. Avisar al usuario cuáles se estimaron.
- Solo días hábiles salvo indicación contraria.
- No reescribir días ya llenos, ni los antiguos sin horas, salvo petición.

## Fuentes de actividades

1. Lo que dicte el usuario (dailies, weeklies, reuniones, revisiones: no aparecen en git).
2. `docs/tareas/*.md` con secciones fechadas y su fecha de modificación.
3. Commits propios del día: `git -C ../K2-Full-Portal log --since=<día> --until=<día+1> --author="$(git -C ../K2-Full-Portal config user.name)" --format='%ad %s' --date=iso` (ídem micrositio).

## Reparto de horas

- Referencia: dailies 0.5–1 h, weekly/reunión 1–1.5 h, fix con prueba 2.5–3.5 h, análisis/rastreo 2–2.5 h, PR/CDM/documentación 1–2 h.
- Ajustar para cerrar en 8 h.

## Al terminar

1. Ejecutar `bin/k2-bitacora-check "<archivo>"`; debe salir 0.
2. Mostrar tabla día → horas e indicar qué se dedujo sin evidencia para que el usuario lo confirme.
3. Ofrecer subirlo al CDS Time Tracker: `bin/k2-timetracker --date <día>` (dry-run) y, con confirmación del usuario, `--apply`.
