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
- **Nunca crear worktrees** (`git worktree add`, `EnterWorktree`, `isolation: "worktree"` en agentes) ni copias del repo: saturan el disco. Se trabaja en el checkout único de cada repo y se cambia de contexto con `git switch`.
- Ramas nuevas siempre desde `dev` actualizado: `git fetch origin && git switch -c <rama> origin/dev`.

## Cambiar de rama con cambios sin commitear

Autorizado sin preguntar (es local y reversible):

1. Guardar el trabajo de la rama actual:
   - poco o experimental → `git stash push -u -m "<rama>: <qué es>"`;
   - avance real → commit local `wip: <qué es>` (sin push; luego se rehace con `--amend` o `reset --soft`).
2. Registrarlo en `K2Work/docs/bitacora-ramas.md` (una línea por cambio: fecha, repo, rama, `stash@{n}`/hash, qué quedó pendiente).
3. `git switch` a la otra rama (o crearla desde `origin/dev`).
4. Al volver: `git stash pop` o deshacer el `wip`, y marcar la línea de la bitácora como retomada.
