# Estado del micrositio Autorelevo

## 2026-11-09 — Preparación de prueba AVASA en test

- Procedimiento de lectura y rastreo documentados en `../../tareas/qa-autorelevo-sit-2026-11-09.md`, sección «Validación de la llave AVASA en test».
- Pendiente ejecutar contra test. El servidor local carga la llave al arrancar y prioriza `AVASA_API_KEY` sobre Secret Manager; un 200 con sucursales valida la credencial efectiva, pero su identidad requiere comprobar configuración y actualización de instancias.

Fuentes: `Autorelevo_Contexto_y_Prompt_Codex.md` (22 sep 2026), `micrositio-autorelevo/docs/REANALISIS-2026-09-24.md` y memorias del proyecto. Las afirmaciones de las notas son lo documentado por esas fuentes, no una verificación nueva.

## Hecho

- Contexto y prompt para Codex redactados a partir del PRD (22 sep 2026).
- Cascarón Fase 2 en `micrositio-autorelevo`: login/OTP, cuatro motivos, siniestro condicional, captura reactiva, validación de PNG/PDF/DOCX hasta 10 MB, espera, estado y corrección, con mock y datos ficticios. Escenarios, supuestos y brechas F1 a F9 documentados en su README.
- Reanálisis del 24 sep 2026: según ese documento, el flujo principal funcionaba de punta a punta en local contra la base `morfeo_dev_db` (login y OTP, selección de servicio y captura, creación del ticket con motivo, carga por `hash_id`, rechazo por documento desde el admin y corrección sobre el mismo ticket).
- Respaldos de cancelación y cierre de folios en `micrositio-autorelevo/docs/` (fechas 25 y 28 sep 2026) y en `micrositio-autorelevo-real/docs/` (5 oct 2026).

## Decisiones

- El PRD define requisitos de negocio; las notas técnicas, la implementación prevista; el código, la fuente de verdad. Las diferencias se registran, no se resuelven por intuición.
- Cancelado no es lo mismo que Rechazado (cancelación por inactividad a 15 días).
- Distinguir rechazo documental (`comentario_validacion`) de autorización "no aprobado" (`razon_estatus`); por confirmar en código.
- Al 25 sep 2026 el equipo planea dejar de usar el admin de K2 para Autorelevo: los folios no se generan desde ahí y el micrositio es el punto de entrada. El botón "Continuar" de la pantalla de motivo de rechazo hacia `/solicitud/captura` es el flujo previsto, no un defecto. Prioridad: backend y micrositio; admin con baja prioridad salvo petición.
- El usuario y credenciales de prueba para obtener token del API están en el `.env` del apiserver (ver skill `k2-autorelevo`); no se registran aquí.

## Pendientes

Según el reanálisis del 24 sep 2026:

- Integridad en K2: cada folio nace con documentos de todos los motivos (27 en lugar de 4); reintentos crean folios duplicados; no hay regla de duplicado.
- Reglas del PRD sin implementar en K2: estatus globales de revisión, archivos DOCX y límite de 10 MB, recálculo de estatus al volver a subir, recordatorios cada tercer día y cancelación a 15 días.
- Pantallas que no siguen el Figma: "Estado de tu solicitud" y la pantalla intermedia de rechazo.

Según el contexto:

- Confirmar IDs K2 de los cuatro tipos de servicio y cómo se crea el ticket de avería mecánica sin siniestro.
- Definir la regla de duplicado para avería mecánica y la validación de las 72 h del diagnóstico.
- Confirmar el nombre real del estatus de documentación incompleta y qué estatus faltan en K2.
- Verificar `mapearFolio` (posible bug que guarda el ID de boleta) y `numReservacion` nunca poblado.
- Hallazgo reportado: credenciales de servicio en `environment.ts` del frontend; evaluar mover a backend/BFF y rotar si están activas.
- TBD del PRD: perfiles de operador en K2 y SLA de APIs.

## 2026-10-30 — Prueba E2E de OTP por correo (dev, versión micrositio-autorelevo-2)
- Póliza SIT BI99038410, inciso 1, asegurado 14164455 (plan PLUS; obtenido con `Policy/Detail` de Chubb SIT).
- Flujo `/api/autorelevo/auth/login` → `otp/send` (canal email) → `otp/validate` (`codigo`) OK; JWT emitido.
- `OTP_TEST_EMAIL`/`OTP_TEST_PHONE` se toman del `.env` del apiserver, que sube con el deploy (`.gcloudignore` no lo excluye).

## 2026-11-03 — Error de login en test (CORS), hipótesis sin confirmar
- Reporte: en `micrositio-autorelevo-web-dot-morfeo-test`, `login` falla por CORS con "Error al conectar con el servidor".
- `environment.test.ts` apunta al mismo host, así que con esa configuración no debería haber CORS: el build desplegado probablemente es otro (`staging` → `-web-dot-morfeo-dev`; sin reemplazo → `micrositio-autorelevo-dot-morfeo-dev`; `production` → `-web-dot-morfeo-prod`).
- `staging-autorelevo` parece descartado: la URL no trae `/autorelevo/`. `app.py` no permite orígenes `appspot.com` en CORS.
- Falta confirmar: Request URL del `login`, comando de build, y destino del proxy en `deploy/server.js` y el yaml de test (no están en el repo local).
- Confirmado 2026-11-03 con la consola del navegador: el front de test llama a `micrositio-autorelevo-web-dot-morfeo-prod.../api/autorelevo/auth/login`; el preflight falla sin `Access-Control-Allow-Origin` y el POST da `ERR_FAILED`. Es consistente con un build `production` (el default de `project.json`) desplegado en test. Falta confirmar comando de build y proxy/yaml de test. No agregar el dominio de QA al CORS: abriría el front de test contra prod.
- 2026-11-03: script `datos/CDSEBAU-39/desplegar-micrositio-dev.ps1` para desplegar a morfeo-dev desde la VDI; sin probar y con la ruta de dist por confirmar contra `deploy/server.js`.
- 2026-11-03: bundle público de `micrositio-autorelevo-web-dot-morfeo-test` revisado: contiene `-web-dot-morfeo-prod` y `api.avasa.com.mx`, con `<base href="/">`. `joshua.morinsalazar@chubb.com` no tiene `appengine.services.list` en morfeo-test, así que sigue sin verse quién desplegó ni cuándo.
- 2026-11-03: Cloud Logging de morfeo-test (solo lectura): 3 `CreateVersion` de `micrositio-autorelevo-web` el 2026-10-30 con cuenta personal de Alejandra Almaguer y versión autogenerada; la última, `20261030t085450`, sirve hoy. Sin peticiones a `/api/autorelevo/auth/login` en test en 7 días. Falta confirmar el comando de build con ella.
- 2026-11-03: ordenadas las carpetas: se trabaja con ramas en `micrositio-autorelevo` (ver skill `k2-autorelevo` y `README.md` de este proyecto).
