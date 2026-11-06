# Autorelevo: cargar Reporte AVASA de contratos cerrados (Chubb_CDS)
- Rama: feat/autorelevo-reporte-avasa (desde origin/dev cf95bb9d) · Repo: K2-Full-Portal (apiserver) + micrositio-autorelevo

## Requerimiento
Guardar la información del reporte "Reporte AVASA Contratos Cerrados Chubb_CDS" (renta de autos de AVASA para Chubb) y usarla en el módulo de autorelevo. Por ahora solo se piden las columnas marcadas en amarillo (captura `feat-autorelevo-reporte-avasa/01-requerimiento-columnas-amarillas.png`):

- **Días Renta** (col. D)
- **Total del contrato** (col. K)
- **Voucher Total** (col. O)

Archivo fuente: `~/Descargas/Reporte AVASA Contratos Cerrados Chubb_CDS.7z` → un `.xlsx`. No se copia a K2Work porque trae datos personales (nombre del asegurado, placas).

## Hallazgos
2026-10-26:
- Una hoja ("Reporte de Contratos Cerrados C"), 4,406 filas de datos, 37 columnas. `Contract Number` aparece dos veces (cols. A y P).
- Columnas: Contract Number, Número de Siniestro o Folio, KM Traveled, Días Renta, TK Con Inclusiones, Cargos Adicionales, Daños del Contrato, Cargo Delivery, Cargo Combustible, IVA, Total del contrato, Voucher Renta, Voucher Adicionales, Voucher IVA, Voucher Total, STATUS, Numero de Reserva, Fecha Creación Reserva, Categoría Reservada/Rentada, Placa, Brand, Year, Model, First/Last Name, Pick up/Drop Off (fecha, hora, sucursal), CDP ID/NAME, Odom Out/In.
- El encabezado "Días Renta" trae un guion suave oculto (`Di\xadas Renta`): normalizar encabezados al importar.
- **Solo 310 de 4,404 filas traen `Número de Siniestro o Folio`** (ej. `GA25C01534`). Las demás solo tienen `Contract Number` y `Numero de Reserva`.
- Montos: Total del contrato = renta + cargos + IVA; Voucher Total = lo que cubre el voucher (puede ser 0). La diferencia sería lo que paga el asegurado (por confirmar).
- En K2 (apiserver) y en el micrositio no existe hoy ningún campo de días de renta, contrato AVASA ni voucher de renta. `numReservacion` del micrositio nunca se puebla (ver `docs/proyectos/micrositio-autorelevo/estado.md`): candidato para enlazar con `Numero de Reserva`.

- Decisión del usuario: **sin migración alembic**; solo scripts SQL de aplicación y rollback.
- K2 no tiene un importador genérico de xlsx a tabla. Lo que existe: `ix/tools/utils/xlsx.py` (funciones por caso con xlrd; xlrd 2.x ya no lee `.xlsx`), `ix/apps/csv/csv_service.py` (`CSVProcessor` con estrategias, solo CSV y deduplica por `code_clean` fijo) y `ix/apps/form_response_import`. Por eso la carga se genera fuera de K2 con un script de K2Work.
- Tablas de autorelevo en dev: `autorelevo_sinister` (`numero_siniestro`), `costos_autorelevo` (costos por `boleta_informativa_id`: días adicionales, horas de espera, subtotal, impuestos, total), `servicios_auto_relevo`. Todas `utf8_general_ci`. `costos_autorelevo` son costos del servicio en K2, no el contrato de AVASA: tabla aparte.
- Los 301 siniestros distintos del reporte no aparecen en `autorelevo_sinister` de dev (lo esperado, dev trae datos de prueba).
- Control del reporte: 4,404 contratos únicos; suma Total del contrato 56,801,820.67; suma Voucher Total 53,474,699.88.

## Cambios
- `datos/feat-autorelevo-reporte-avasa/01-crear-tabla.sql` / `01-rollback.sql`: crea / borra `autorelevo_contrato_renta`.
- `datos/feat-autorelevo-reporte-avasa/generar_carga.py`: genera `02-carga.sql` (INSERT … ON DUPLICATE KEY UPDATE en lotes de 500, idempotente por `contract_number`) y `02-rollback.sql` (DELETE por contrato). Solo exporta llaves y columnas pedidas, sin nombres ni placas.

- K2-Full-Portal, 11 commits locales sin push (cf95bb9d..593448a5), 19 archivos, +1144:
  - `apiserver/ix/apps/importador/` (definitions, errors, parsers, validators, layouts, services, endpoints): importador genérico síncrono.
  - `auto_relevo_boleta_models.py`: modelo `AutorelevoContratoRenta` (`audit_created_by` nullable solo aquí).
  - `ix/app.py`: registro de `POST /api/importador/<layout>` y `GET /api/importador/layouts`.
  - `requirements.txt`: `defusedxml==0.7.1`.
  - `ix/tests/importador/`: 90 pruebas.
- `datos/feat-autorelevo-reporte-avasa/03-auditoria.sql` / `03-rollback.sql`: columnas audit_* (aplicado en dev).

## Pruebas
- 2026-10-26: `pytest ix/tests/importador -q` → 90 passed (venv `~/.venvs/k2`). Las pruebas de servicio usan dev con rollback; conteo `ZZ%` en dev = 0.
- 2026-10-26 aceptación (Task 7) con el Excel real vía endpoint en dev: primera corrida 400 por la fila `REPORT TOTAL`; se agregó la fila de totales como control (commit `c26eb0a4`, 104 pruebas). Segunda corrida: 200, `total 4404, insertados 0, actualizados 4404`. Dev: 4,404 filas, 309 con siniestro, Días Renta 73,514, Total 56,801,820.67, Voucher 53,474,699.88 (igual a la fila de totales del Excel), `audit_updated_by` en las 4,404.
- Colección Bruno `datos/feat-autorelevo-reporte-avasa/bruno/` (archivos sintéticos `ZZB*` en `archivos/`): 12/13 OK contra el apiserver local. Falla solo *Sin rol* por falta de `K2_USER_SIN_ROL`/`K2_PASS_SIN_ROL` en `~/.config/k2work/bruno/k2.env`. El caso feliz escribe en dev; se limpió con `limpiar.sql` (ZZ% = 0).
- `bin/k2-bruno` ahora soporta cuerpos multipart (`form` en el spec) y corrige `defaults.body: null`; `tests/test-k2-bruno.sh` 14/14.
- Cada tarea pasó revisión de spec + calidad y la rama una revisión final; todos los hallazgos Important se corrigieron.
- 2026-10-26: `01-crear-tabla.sql` y `02-carga.sql` aplicados en dev con `--commit` (autorizado). Resultado: 4,404 filas, 309 con siniestro, suma total 56,801,820.67, suma voucher 53,474,699.88 (igual al Excel). Recarga idempotente: sigue en 4,404.
- (histórico) `bin/k2-sql` bloquea DDL sin `--commit` (también `CREATE TEMPORARY TABLE`); falta autorización para crear la tabla en dev.

## Diseño del importador genérico
- Spec: `feat-autorelevo-reporte-avasa/spec-importador.md` · Plan: `feat-autorelevo-reporte-avasa/plan-importador.md` (2026-10-26).
- Decisiones: endpoint en apiserver; síncrono, una transacción, lotes de 500; layouts declarativos en código; todo o nada.
- Riesgo del patrón actual `form_response_import/task.py`: cola en memoria + hilos daemon por worker gunicorn; pierde trabajos con `--max-requests` y el autoescalado.

## Decisiones tomadas durante la implementación
- Los errores de archivo dañado, tipos estrictos, total_errores y límites de columna se corrigieron aunque el código del plan fuera literal: manda el spec (un archivo malo nunca da 500).
- Rechazo de prefijos de fórmula (= + - @ tab CR) en columnas de texto de xlsx y csv. Un texto legítimo que empiece con "-" se rechaza.
- Llaves duplicadas comparadas sin distinguir mayúsculas (la collation de MySQL es ci).
- `fecha_carga` conserva la fecha de la primera carga; la de la última actualización está en `audit_updated_at`.
- Límite de tamaño por endpoint (`Content-Length` + envoltura del `wsgi.input` para chunked); sin `MAX_CONTENT_LENGTH` global.
- `AuditEntity` no se tocó; `audit_created_by` es nullable solo en este modelo por la carga inicial por SQL.
- Fila de totales: el layout AVASA exige la fila `REPORT TOTAL`; sus sumas (Días Renta, Total, Voucher) deben cuadrar al centavo con las filas cargadas o el archivo se rechaza. Riesgo: si AVASA manda montos con más de 2 decimales, el redondeo por fila podría dar un falso "no cuadran".
- Pendientes conscientes: kind `int` no valida rango INT (AVASA no lo usa); si algún día se configura `MAX_CONTENT_LENGTH` global en Werkzeug 3, revisar la envoltura `_EntradaLimitada`; la coma decimal europea se lee como miles.

## Pendientes
- 2026-10-27: venv `~/.venvs/k2` recreado con Python 3.14 (runtime `python314` de App Engine) y `requirements.txt` + `pytest` + `setuptools` (por `distutils` en `ix/tools/utils/functions.py`): Flask 3.1.3, Werkzeug 3.1.8, SQLAlchemy 2.0.51, mysqlclient 2.2.8 → `pytest ix/tests/importador` 104 passed (requiere proxy `mysql-dev`). El venv anterior (3.10) quedó en `~/.venvs/k2-py310`.
- Probar el 403 real: agregar un usuario sin rol admin/supervisor como `K2_USER_SIN_ROL` y `K2_PASS_SIN_ROL` en `~/.config/k2work/bruno/k2.env` y correr la carpeta *Sin rol*.
- Push y PR con `k2-git` (12 commits locales, sin push).
- Formato de error para el front: `{"error": {"data": [...], "detail": ..., "total_errores": N}}`.
- Confirmar la llave de cruce con el folio de autorelevo: ¿`Número de Siniestro o Folio`, `Numero de Reserva` o `Contract Number`? Con siniestro solo cruzan 310 filas.
- Confirmar si es carga única (script/migración) o recurrente (endpoint de importación de xlsx en el admin).
- Confirmar dónde se muestran/usan los 3 campos en autorelevo (pantalla de estado, cálculo, validación).
- Propuesta: tabla nueva (p. ej. `autorelevo_contrato_renta`: contract_number, numero_reserva, siniestro_folio, dias_renta, total_contrato, voucher_total, fecha_carga) + migración alembic + script de importación idempotente por `contract_number`.

## 2026-10-27 — Refactor de estructura (patch para VDI)

- Se reorganizó el código después de la revisión estructural: `utils.py` (`es_vacio`, `celda`, `redondear`), `conversores.py`, `totales.py`, `schemas.py` (dataclasses + `TipoColumna` enum), `mensajes.py`, `layouts/` (registro en `__init__.py` y el layout en `avasa.py`).
- `EntradaLimitada` pasó a `ix/tools/utils/http_limits.py` y `normalizar_encabezado` a `ix/tools/utils/string_helpers.py`. `ImportError_` se renombró a `ImportacionError`.
- `/code-review` contra `dev` no encontró errores. Siguen pendientes de decidir: el estilo de `ImportService` (solo staticmethods) y el idioma de los nombres (inglés o español).
- Pytest: 104 passed. El patch es `datos/feat-autorelevo-reporte-avasa/autorelevo-refactor-estructura.patch` (git diff contra HEAD, LF). Los cambios no están commiteados en la rama local.
- Decisión del usuario: nombres en inglés en todo el módulo y `ImportService` sin cambios (solo staticmethods; se conserva el método `importar`).
  - Archivos: `converters.py`, `totals.py`, `messages.py`. Clases: `ImportFileError`, `TotalRow(header, marker, fields)`, `ColumnType`, `LimitedInput`. Funciones: `read_file`, `map_columns`, `validate_rows`, `get_layout`, `normalize_header`, `import_file`, `list_layouts`.
  - El JSON de respuesta no cambia (`fila`, `columna`, `valor`, `mensaje`, `insertados`, `total_errores`…): `RowError.to_dict` mapea a las llaves en español.
  - Pytest 104 passed. Patches: `autorelevo-refactor-ingles-completo.patch` (contra el commit único) y `autorelevo-refactor-ingles-incremental.patch` (sobre `autorelevo-refactor-estructura.patch`).
- VDI (Mexico-IT/K2-full-portal): un push que actualiza una rama ya existente lo rechaza el ruleset de organización `EnforceGitleaks` (GH013, "Required status check Gitleaks Secret Scanning is expected"), aunque gitleaks no encuentre fugas. Crear una rama nueva sí pasa. El refactor se subió como `CDSEBAU-57-CDSPLAT-Micrositio-Reporte-Avasa-v2` (commit 83edbb58); el PR va contra `dev` desde esa rama.

## 2026-10-28 — Botón de carga en el admin (front)

- En la lista de boletas de Auto Relevo (`relevo-car/list`) hay un botón **Cargar reporte AVASA**, visible solo para `admin`/`supervisor` (los mismos roles del layout; el backend sigue validando y responde 403).
- Reutiliza `components/upload-file-modal` (`.xlsx,.csv`, 5 MB). `RelevoService.importAvasaReport` hace `POST importador/avasa_contratos` con el campo `file` (`execPostFormData`).
- Éxito: SweetAlert con total/nuevos/actualizados. 400 con errores por fila: `p-dialog` con tabla Fila/Columna/Valor leído/Mensaje y "Mostrando N de total_errores". Otros (403, 413): `fireErrorMessage` con `detail` o el string de `error`.
- Sin NgRx: es un comando puntual sin estado compartido. Lo nuevo usa signals (`showUploadModal`, `importError`); el resto del componente se dejó igual.
- Modal compartido: "Max 10 MB" pasó a `Max {{size}} MB files are allowed` con `maxFileSizeMB()` (reembolsos sigue viendo 10). Clave propia "Value read" porque "Value" en es.json es "Factor".
- Archivos: `relevo_import.model.ts` (nuevo), `relevo.service.ts`, `list.component.{ts,html}`, `upload-file-modal.component.html`, `i18n/{es,en}.json`.
- Verificación: `ng build --configuration development` OK (con stub temporal de `environments.generated.ts`, que en local no existe; se borró). Falta probar en navegador contra el apiserver local.
- Spec `relevo-car/list/list.component.spec.ts` (5 casos: roles, éxito, errores por fila, detail, 403 en texto): 5/5 en ChromiumHeadless.
  - Cómo correrla: `CHROMIUM_BIN=~/.cache/ms-playwright/chromium-1248/chrome-linux64/chrome npx ng test --watch=false --browsers=ChromiumHeadless --ts-config=<tsconfig que extienda tsconfig.spec.json e incluya solo la spec> --include=<spec>`, con el stub temporal de `environments.generated.ts`.
  - `ng test` completo no compila hoy por `tests/dynamicFormObfuscation.spec.ts:104` (TS2540, `showClientName` es read-only). Es ajeno a esta rama.
- Commit local `3492b3cd` (sin push): `feat(autorelevo): carga del reporte AVASA desde la lista de boletas`. Patch para la VDI: `datos/feat-autorelevo-reporte-avasa/autorelevo-front-carga-avasa.patch` (`git format-patch -1`; se aplica con `git am`).

## 2026-10-29 — Rama consolidada en la VDI
- Rama `CDSEBAU-57-CDSPLAT-Micrositio-Autorelevo-v2` (recreada, HEAD `375fd4744`): parte de `CDSEBAU-35-Autorelevo-Micro-Rechazos` hasta `f23f445a0`, más los 4 commits (importador, refactor, front AVASA, dispatcher temporal de Héctor), merge de `origin/dev` (`c42a5bc79`) y merge de la rama de Donovan (`709163199` flujo de aprobación/rechazo). Push como rama nueva: gitleaks sin hallazgos.
- La primera `-v2` (`4bee456e4`, sin dev ni Donovan) se cerró y se borró desde el PR; también desaparecieron del remoto `…-Reporte-Avasa` y `…-Reporte-Avasa-v2`.
- Patch aplicado en la VDI con conflicto en `es.json` (claves de AHIO al final): se resolvió conservando ambas.
- GH013 (`EnforceGitleaks`) bloquea actualizar ramas existentes; crear una rama nueva (o recrear una borrada con el mismo nombre) sí pasa.
- Pendiente: decidir con Donovan/Héctor qué pasa con `CDSEBAU-35-Autorelevo-Micro-Rechazos` (sigue con sus 2 commits).

## 2026-10-29 — CLL v2 (CDM)
- ID `2026_OM-P26-117_R01` (mismo de la v1, Historial 2.0.0). Docs en `~/Documentos/wordcraft/cdm/2026_OM-P26-117_R01/`: `_CLL.docx`, `sql.zip` (Creacion_Micrositio_v2.sql: tabla `autorelevo_contrato_renta` + auditoría + columnas de Donovan en `boleta_informativa`; Contingencia_Micrositio_v2.sql).
- Cubre K2 PR #164 y Micrositio PR #7 (CDSEBAU-39-Autorelevo-v2). Pendiente: versión GAE v2 y confirmar lista de archivos con el código actualizado. El CLL lo anexa el usuario.
- 2026-10-30: con el código v2 (`~/Descargas/v2-export/`, tar del admin y del micrositio) confirmé que la carga AVASA está igual en la v2 y que el admin incluye los campos `evaluador_aprobo_servicio`/`motivo_evaluacion_servicio`. Generados `_PRUEBAS.docx`, `ManualTecnico-MICROSITIO_AUTORELEVO_V2.docx` y `correos.md` (CON y CLL, SolicitudDeAprobacion02). Pendientes: evidencia de Donovan, captura del micrositio en /autorelevo.
- Versión GCP a liberar: micrositio-autorelevo.
- 2026-10-30: ramas locales v2 creadas (K2 2325fcdc, micrositio CDSEBAU-39-Autorelevo-v2).

- 2026-10-30: build de ramas locales v2. Admin (`node run-angular.js production` con variables de Firebase/Google falsas, el `environments.generated.ts` se borró después) compila. Apiserver: `compileall` OK y `pytest ix/tests/importador` 104 passed (venv `~/.venvs/k2`). Micrositio no compila: la v2 importa `@chubb/ui-components` (librería interna de Chubb, 23 archivos) que no está en el `package.json` local ni instalable fuera de la VDI.
- 2026-11-03: `_PRUEBAS.docx` regenerado con 2 capturas del admin (botón "Cargar reporte AVASA" y diálogo "Subir archivo"). Siguen pendientes: usuario sin rol en Bruno, evidencia de Donovan, captura del micrositio en /autorelevo.
- 2026-11-03: `_PRUEBAS.docx` regenerado con 2 capturas del admin (botón "Cargar reporte AVASA" y diálogo "Subir archivo"). Siguen pendientes: usuario sin rol en Bruno, evidencia de Donovan, captura del micrositio en /autorelevo.
- 2026-11-03: generado `_DIS.docx` (src/DIS.md) y correo DIS en `correos.md`; antes se había marcado como no aplica por el DDD 2026_CDS-BAUOM-P26-126_R01. Aprobación DIS: sin enviar.
- 2026-11-03: `Creacion_Micrositio_v2.sql` unificado (auditoría dentro del CREATE TABLE); `sql.zip` y `_CLL.docx` regenerados.
