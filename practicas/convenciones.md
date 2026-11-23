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

## Patches hacia la VDI
- Se publican en `datos/<ticket>/*.patch` (K2Work en GitHub) y se bajan del raw.
- En la VDI, `curl.exe` (schannel) falla con `CRYPT_E_NO_REVOCATION_CHECK (0x80092012)` porque el proxy corporativo no deja validar la revocación del certificado. Usar `--ssl-no-revoke` y nunca `-s` a secas (oculta el error):
  `curl.exe -L -f --ssl-no-revoke -o x.patch <raw-url>`
- Alternativa: `Invoke-WebRequest <raw-url> -OutFile x.patch`.
- Aplicar sin commit: `git apply --check x.patch` y luego `git apply x.patch` (si falla por CRLF: `--ignore-whitespace`).
- En la VDI las ramas pueden llevar prefijo de ticket (p. ej. `CDSEBAU-6-feat-collision-no-concesionados`); verificar la rama antes de aplicar.
