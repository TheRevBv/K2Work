@AGENTS.md

## Específico de Claude Code

- Responde en español.
- Para leer el código agrega los repos como directorios de trabajo (`/add-dir ../K2-Full-Portal`).
- El shell es fish: usa rutas entre comillas en globs (`--include='*.py'`).
- Para SQL usa `bin/k2-sql`; nunca conectes a mano a una base ni leas los `.env` de los repos.
- Al terminar una investigación, actualiza `docs/tareas/<rama>.md` y, si descubres algo reutilizable, `rag/glosario.md` o `rag/indice-archivos.md`.
- Comandos que requieren `sudo` o login interactivo: pídele al usuario que los ejecute con `! <comando>`.
