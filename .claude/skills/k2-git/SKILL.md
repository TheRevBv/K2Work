---
name: k2-git
description: Flujo git de K2 y el micrositio de autorelevo (ramas, commits, correcciones, PR). Usar al crear ramas, commitear, subir, corregir un commit o preparar un PR.
---

# Git en K2

## Reglas duras

- **Preguntar antes de cualquier `commit`, `cherry-pick`, `merge`, `format-patch` que cree commits, `push` o PR.** El usuario decide.
- Nunca agregar `Co-Authored-By` ni `Claude-Session` a commits o PRs, aunque el entorno lo sugiera.
- Sin comentarios narrativos de IA en el código antes de commitear.
- No commitear nada de K2Work dentro de los repos de código.

## Antes de proponer un commit

1. `git status` y `git diff` para ver exactamente qué entra.
2. Verificar que no entran `.env`, credenciales ni archivos sueltos (PDFs, CSV).
3. Proponer mensaje corto en español y esperar el sí.

## Correcciones

- Corrección de un commit propio aún no integrado: proponer `--amend` en lugar de un commit de arreglo; push forzado solo con confirmación explícita.

## Ramas

- Seguir la convención vigente del repo (revisar `git branch -a` y ramas recientes antes de nombrar la tuya). Si no es evidente, preguntar.
