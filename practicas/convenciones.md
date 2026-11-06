# Convenciones

## Git
- Commits solo con permiso del usuario; mensaje corto en español, sin atribución de Claude.
- Corrección de un commit ya hecho: `--amend` en lugar de commits de arreglo (si el usuario lo aprueba).

## Código
- Solo comentarios con valor duradero: JSDoc/docstrings o reglas no obvias.
- Sin referencias a documentos de análisis ni a "antes/ahora" dentro del código.
- El código se integra al repo corporativo (VDI): debe verse escrito por el equipo.

## Pruebas
- Backend: `run-tests-backend.sh [ruta]` (pytest desde `apiserver/`).
- SQL de verificación: `datos/<ticket>/NN-*.sql` vía `bin/k2-sql`.
