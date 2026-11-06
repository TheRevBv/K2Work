# Ajuste Móvil: vale de grúa y fotos del siniestro

Propuesta de dos endpoints para Ajuste Móvil: recibir el vale de grúa y recibir varias fotos del siniestro. Documento CDM en `~/Documentos/wordcraft/cdm/ajuste-movil-vale-grua/`.

## Estado actual de K2 (análisis 20/10/2026)

Rutas relativas a `apiserver/ix/`.

### Autenticación
- Los usuarios de servicio entran por `POST /api/auth/token` (`api/endpoints/auth.py:116`).
- El JWT es HS256 con vigencia de 12 h y solo lleva `identity`: no tiene `aud`, `jti` ni roles. No hay refresh ni revocación.
- `@wrappers.api_resource` no autentica. La autenticación la hace `@wrappers.auth` (`api/wrappers.py:578`) y la autorización `@wrappers.only_for` (`:621`), que deja pasar siempre a ADMIN.
- No hay rol propio por usuario de servicio. Los endpoints `/v2/wa/*` aceptan roles de operador.
- No hay rate limiting (tampoco en el login), ni `MAX_CONTENT_LENGTH`, ni API key o mTLS.
- Hay HMAC con `compare_digest` solo en OFAC (`ofac/utils/decorators.py:25`); sirve como patrón.

### Log
- `create_log_in_table` (`whatsApp/utils/utils.py:302`) guarda `str(data)` completo, así que no debe recibir el base64.

### Archivos
- Modelos `Attachment` (`models/attachment.py`) y `AssistanceCaseAttachment` (tabla `assistance_case_attachment`). Tipos útiles: `TYPE_SINISTER` y `TYPE_DOCUMENTS_EVIDENCE = 57`.
- Funciones en `tools/storage/storage.py`: `upload_file` (privado), `generate_signed_url` y `delete_file_by_url`.
- `files.upload` traga el error 413, así que su validación de tamaño no sirve. `/file_manager/upload/` recibe `bucket_name` del cliente. Ninguno de los dos se debe reutilizar.
- No hay validación por magic bytes ni antimalware en ningún punto.
- Bitácora del caso: `create_new_assistance_ticket` con `ticket_type=COMMENT` (`svc/assistanceticket.py:910`).
- Instancias de prod: F4_1G con 2 workers × 4 threads. Límites de App Engine: request de 32 MB y 60 s.

## Decisiones (20/10/2026)

- Las fotos se reciben por lote: abrir el lote, enviar una foto por request en multipart y cerrar el lote. Máximo 20 fotos por lote y 10 MB por foto; el lote expira a las 24 h.
- El vale pasa de base64 a multipart y reutiliza `attachment` y `assistance_case_attachment`. Se agregan dos tablas: el lote de fotos y el detalle de archivos (`sha256`, proveedor, folio).
- Seguridad Fase 1 en los dos endpoints: rol dedicado, rate limit, validación por magic bytes, re-codificación con Pillow, validación del PDF y log sin el contenido.
- Seguridad Fase 2: HMAC (se quitó de Fase 1 por decisión del 20/10), token de vida corta, ClamAV, URLs firmadas y mTLS o Cloud Armor.
- Documento: `Propuesta-AjusteMovil-ValeGrua-Fotos.docx/.pdf`, con fuente en `src/Propuesta.md`.

## Implementación (20/10/2026)

Rama: `feat/ajuste-movil-vale-grua-fotos`, creada desde `origin/dev`. Todavía sin commits. También trae `deploy-w-secrets.ps1` copiado de `feat/ajuste-movil-volante`.

### Código
- `ix/apps/ajuste_movil/endpoints.py` tiene las 4 rutas bajo `/api/v2/ajuste-movil/cases/<case_id>/` y el decorador `only_ajuste_movil`. Ese decorador exige el nombre "Ajuste Movil" y el rol `ajuste_movil_service`, y no deja pasar a ADMIN.
- `ix/apps/ajuste_movil/services.py`:
  - Valida que el caso exista y que lo haya creado el usuario de servicio. Para el vale, valida que tenga proveedor asignado y que no tenga ya un vale.
  - Rate limit: 60 archivos por minuto por usuario.
  - Guarda en `attachment` y `assistance_case_attachment` (tipos 58 y 59) y en `ajuste_movil_file`.
  - Deja comentario en la bitácora (ticket COMMENT) y registra en `web_service_log_ajuste_movil` sin el contenido del archivo.
- `ix/apps/ajuste_movil/file_validation.py`:
  - Magic bytes y tope de 10 MB.
  - Re-codifica las imágenes con Pillow: quita EXIF y lo que venga después de los píxeles, y limita los píxeles.
  - En el PDF busca `/JavaScript`, `/OpenAction` y similares.
- `ix/models/ajuste_movil_file.py` define `AjusteMovilPhotoBatch` y `AjusteMovilFile`.
- `apiserver/sql/ajuste_movil_archivos.sql` crea las 2 tablas, el rol y la asignación del rol al usuario "Ajuste Movil".
- Pruebas: `ix/tests/ajuste_movil/test_file_validation.py`, 17 OK.

### Bruno
- Colección en `datos/ajuste-movil-vale-grua-fotos/bruno`, con 19 requests en orden. El login guarda el token y "Lote - abrir" guarda `batchId`.
- Hay que capturar el secreto `password` del usuario Ajuste Movil en el entorno.
- Casos en dev:
  - 67017: de Ajuste Móvil, con proveedor 14.
  - 67588: de Ajuste Móvil, sin proveedor.
  - 67621: de otro usuario.
- Verificación: `datos/ajuste-movil-vale-grua-fotos/verificar.sql`.

### Pendiente
- Rate limit en `/auth/token`: no está, porque toca el login general.
- Antes de probar hay que correr el SQL en la BD local.
- La validación del PDF es por texto: un PDF con object streams comprimidos podría ocultar `/JS`. Para la Fase 2 está ClamAV (o pikepdf).

## Cambio de diseño (20/10): una sola tabla nueva

- Se eliminó `ajuste_movil_photo_batch`. El archivo vive en `attachment` + `assistance_case_attachment`; el detalle (sha256, proveedor, vale, lote) en `ajuste_movil_file`.
- El lote es un UUID que genera Ajuste Móvil. Nace con la primera foto (`PUT .../photo-batches/<uuid>/photos/<n>` con `expected_count` en el form) y vence 24 h después de ella.
- `POST .../photo-batches/<uuid>/close` valida que estén todas y marca `batch_closed_at` en las filas del lote.
- Se quitó el endpoint `POST .../photo-batches` (abrir lote).
