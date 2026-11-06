# Spec: importador genérico de archivos a tabla (K2 apiserver)

- Fecha: 2026-10-26 · Repo: K2-Full-Portal (`apiserver`) · Rama propuesta: `feat-autorelevo-reporte-avasa`
- Primer caso: Reporte AVASA de contratos cerrados → `autorelevo_contrato_renta` (Días Renta, Total del contrato, Voucher Total).

## Objetivo

Subir un `.xlsx` o `.csv` con un layout conocido y guardarlo en su tabla de forma segura, validada, idempotente y auditada. Agregar un layout nuevo debe ser declarar un objeto en código, sin tocar el motor.

## Fuera de alcance

- Procesamiento asíncrono (GCS + Cloud Tasks). Se agrega por layout cuando uno supere ~50k filas.
- Layouts configurables desde BD o UI.
- Pantalla en el admin Angular (se prueba vía API/Bruno).
- Migraciones alembic: los cambios de esquema van como scripts SQL con su rollback en `K2Work/datos/feat-autorelevo-reporte-avasa/`.

## Decisiones

| Tema | Decisión | Motivo |
|---|---|---|
| Ejecución | Endpoint en apiserver | Permite cargas recurrentes sin desarrollo |
| Procesamiento | Síncrono, una transacción, upsert en lotes de 500 | Sin hilos en memoria: el patrón de `form_response_import/task.py` (cola por proceso + hilos daemon) pierde trabajos con `--max-requests` y el autoescalado de App Engine |
| Layouts | Declarativos en código (registro) | El cliente solo elige una clave; tabla, columnas y llave salen de código revisado |
| Resultado | Todo o nada | No hay importaciones parciales que reconciliar |

## Componentes (`ix/apps/importador/`)

| Archivo | Responsabilidad | Depende de |
|---|---|---|
| `layouts.py` | `ImportColumn(header, field, kind, required)`, `ImportLayout(key, model, upsert_key, columns, roles, max_bytes, max_rows)` y registro `LAYOUTS` | modelos |
| `parsers.py` | Valida extensión y bytes mágicos, protege contra zip bomb, lee xlsx (`read_only`, `data_only`) o csv UTF-8; normaliza encabezados; produce `(numero_fila, dict)` | openpyxl, csv |
| `validators.py` | Convierte celdas por `kind` (`text`, `decimal`, `int`, `date`); acumula `RowError(fila, columna, valor, mensaje)`; detecta llaves duplicadas en el archivo | — |
| `services.py` | `ImportService.importar(layout, filename, data, user_id) -> ImportResult` | lo anterior + sesión SQLAlchemy |
| `endpoints.py` | `POST /importador/<layout_key>` y `GET /importador/layouts` | `wrappers`, `config` |
| `definitions.py` | `API_URI_BASE`, mensajes y límites globales | — |

Normalización de encabezados: quitar `\xad` y espacios repetidos, pasar a minúsculas y quitar acentos (`unicodedata` NFKD). Si un encabezado aparece repetido (AVASA trae `Contract Number` dos veces), se toma la primera aparición.

Modelo nuevo `AutorelevoContratoRenta` junto a los modelos de autorelevo (`boletas_informativas/auto_relevo/api/auto_relevo_boleta/auto_relevo_boleta_models.py`), con los campos de la tabla y las columnas `audit_*` y `active_record`.

Layout AVASA:

| Encabezado (normalizado) | Campo | Tipo | Obligatorio |
|---|---|---|---|
| contract number | `contract_number` | text | sí (llave) |
| numero de reserva | `numero_reserva` | text | no |
| numero de siniestro o folio | `siniestro_folio` | text | no |
| dias renta | `dias_renta` | decimal | sí |
| total del contrato | `total_contrato` | decimal | sí |
| voucher total | `voucher_total` | decimal | sí |

Roles: `ADMIN`, `SUPERVISOR`. Límites: 5 MB y 20,000 filas. Las filas sin `Contract Number` y sin ningún otro valor se ignoran como filas vacías; si tienen otros datos, son error.

## Flujo

1. El endpoint valida token (`@wrappers.auth`), que el layout exista (404 si no) y el rol del usuario contra `layout.roles` (403).
2. Revisa que venga `file`, su tamaño contra `max_bytes` (lee como máximo `max_bytes + 1`), la extensión y los bytes mágicos.
3. Parser: tope de tamaño descomprimido (50 MB) y luego lectura en streaming.
4. Se valida el archivo completo. Si hay errores se responde 400 y no se escribe nada.
5. `INSERT … ON DUPLICATE KEY UPDATE` (SQLAlchemy Core, dialecto MySQL) en lotes de 500 y un solo commit. En inserción llena `audit_created_by`; en actualización, `audit_updated_by`.
6. Log de auditoría: usuario, layout, nombre de archivo, SHA-256, filas, insertados y actualizados. Nunca el contenido de las filas.
7. Respuesta `{success, data: {layout, total, insertados, actualizados}, error}`.

## Seguridad

- No se arma SQL con strings y el cliente nunca elige tabla ni columnas.
- Se valida por bytes mágicos, no por Content-Type. Hay límites de tamaño, de filas y de descompresión.
- Se agrega `defusedxml` a `requirements.txt` (hoy no está); openpyxl lo usa en automático contra XXE y bombas de entidades.
- `data_only=True` (sin fórmulas). En CSV, los textos que empiezan con `=`, `+`, `-` o `@` son error.
- Las columnas fuera del layout (nombres, placas) se descartan y no llegan a BD ni a logs.
- Errores de BD: rollback, 500 genérico al cliente y el detalle solo al log.

## Errores

| Caso | HTTP |
|---|---|
| Sin archivo, extensión o bytes inválidos, archivo dañado | 400 |
| Excede `max_bytes` | 413 |
| Excede `max_rows` o el tope de descompresión | 400 |
| Faltan columnas obligatorias | 400 con la lista |
| Errores de fila o llave duplicada en el archivo | 400 con `errores` (máximo 100) y `total_errores` |
| Sin token / rol no permitido / layout inexistente | 401 / 403 / 404 |
| Error de BD | 500 genérico y rollback |

## Esquema (SQL, sin alembic)

- `01-crear-tabla.sql` / `01-rollback.sql`: ya aplicados en dev el 2026-10-26.
- `03-auditoria.sql` / `03-rollback.sql`: agregan o quitan `audit_created_at`, `audit_updated_at`, `audit_deleted_at`, `audit_created_by` (NULL, porque la carga inicial no tiene usuario), `audit_updated_by`, `audit_deleted_by` y `active_record`, igual que `costos_autorelevo`.

## Pruebas

`pytest` no está en `requirements.txt`; se usa el runner que ya ocupan `ix/tests/` (se confirma al implementar).

- Unitarias: normalización (`Di\xadas Renta`), conversión por tipo, duplicados, filas vacías, límites, bytes mágicos falsos, zip bomb sintética e inyección de fórmula en CSV.
- Servicio contra MySQL local o dev con rollback: primera carga, recarga idempotente (0 insertados) y una fila mala que no escribe nada.
- Endpoint: 401, 403, 404, 413 y caso feliz.
- Aceptación en dev con el Excel real: 4,404 filas, suma `total_contrato` = 56,801,820.67 y suma `voucher_total` = 53,474,699.88.
- Colección Bruno con datos sintéticos.

## Escalabilidad

Lectura en streaming y lotes de 500. AVASA tarda segundos. `max_rows` evita ocupar un hilo gthread o la RAM de una `F4_1G`. Si un layout crece, se le agrega `modo="async"` y la firma de `ImportService.importar` no cambia.
