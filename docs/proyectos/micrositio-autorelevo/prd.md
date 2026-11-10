# PRD Micrositio AutoRelevo

Fuente: Confluence CDS1, página 1198587907 "PRD Micrositio AutoRelevo", versión 16 (Danna Dominguez, 29/09/2026). Resumen fiel del PRD seguido de cómo lo implementan K2 y el micrositio. Si el PRD cambia, actualizar esta página.

## Alcance (sección 1)

| Funcionalidad | Requerimiento | Fecha |
|---|---|---|
| Ingreso por autoservicio | Identificación por número de asegurado / póliza / inciso, registro de contacto y carga de documentos en el micrositio | Oct 2026 |
| Validación documental | Único punto de intervención humana: aprobar/rechazar documentos en K2 | Oct 2026 |
| Comprobante de reservación | Comprobante de reserva del auto relevo | Oct 2026 |
| Estatus y seguimiento | Estatus visibles en el micrositio y notificaciones automáticas | Oct 2026 |
| Cierre de folio | Igual que hoy, en K2 | Oct 2026 |
| Gestión documental | Resguardo de documentos | — |

## Requerimientos funcionales (sección 3)

### Inicio de sesión y tipo de servicio
- Captura póliza, inciso y número de asegurado (sin siniestro en este paso).
- Tras el OTP se elige tipo de servicio. Pérdida total, pérdida parcial y detención legal piden número de siniestro en una pantalla aparte; avería mecánica no.

### Verificación OTP
- Se envía por SMS al teléfono registrado o por correo. Vigencia 5 min.
- Código incorrecto: mensaje "Código OTP incorrecto".
- "Enviar otro OTP" se habilita cuando pasan los 5 min del código enviado.

### Identificación y folio
- La API de pólizas valida identidad.
- Si el servicio requiere siniestro, se valida que exista para la póliza.
- Si ya hay una solicitud en proceso para el mismo siniestro/póliza/inciso, se bloquea.
- Al iniciar se asigna folio.

### Contacto y documentos
- Se muestran los datos de la póliza: nombre, correo, domicilio (estado, municipio, CP). Se reconoce el plan.
- Documentos obligatorios, máx. 10 MB, .png / .pdf / .docx:

| Servicio | Documentos |
|---|---|
| Pérdida total | Identificación oficial vigente, licencia de conducir vigente, carátula de la póliza |
| Pérdida parcial | Identificación oficial vigente, licencia de conducir vigente, carátula de la póliza |
| Detención legal | Identificación oficial vigente, licencia de conducir vigente, declaración legal |
| Avería mecánica | Identificación oficial vigente, licencia de conducir vigente, diagnóstico del taller (máximo 72 h de diagnosticado), carátula de la póliza |

- No se continúa sin datos y documentos completos.

### Auto Relevo en el menú de K2
- Lista de folios del micrositio con estatus "en revisión de documentación", siniestro, estatus y detalle. Filtros por columna.

### Validación por operador
- El operador aprueba o rechaza cada documento; acceso controlado por roles.
- Todo aprobado → estatus "documentación completa en espera de autorización" + notificación SMS/correo.
- Algún rechazo → "documentación incompleta o no aprobada".

### Autorización
- Respuesta esperada en 72 h; se registra en la sección "Autorización" de K2 como hoy.
- Resultado (aprobado / no aprobado) notificado por correo o SMS.

### Reservación con la agencia
- Ya autorizado, el asegurado elige sucursal, fecha y hora de recolección y devolución, y modelo.
- **Días: máximo 20 por asegurado; no se acepta si selecciona más de 20.** Los días solicitados salen de las fechas de recolección/devolución, no de un campo aparte.
- Categorías AVASA: Plus → C y D; Plus Premium → F, G, L, T, L4, L5, P4.
- Plus sin disponibilidad en C/D → cascada F, G, L, T, L4, L5, P4. Sin ninguna → pedir cambiar fecha.
- Plus Premium sin disponibilidad → pedir cambiar fecha.
- Se guarda el servicio y se recibe el código de reservación de AVASA.
- Boleta informativa: folio, vehículo, motivo, número de reservación y próximos pasos; descargable en PDF y enviada por correo.

### Entrega del vehículo
- Fecha, sucursal y requisitos (identificación, tarjeta de crédito/débito, licencia). Número de contrato.

### Cierre y facturación
- Al reportarse el regreso de la unidad, el folio se cierra solo con el cierre estándar de K2. Encuesta NPS como hoy.
- Datos: días utilizados y costo por día (capturados en K2; ver fuera de alcance).

### Duplicados
- No se crea folio si ya hay uno activo para el mismo siniestro.

### Estatus
- Existentes en K2: Pendiente, Documentos entregados, Vehículo entregado, Finalizado.
- A crear: en revisión de documentación, documentación completa en espera de autorización, documentación incompleta o errónea, servicio autorizado.
- "Consultar estatus" en el micrositio (póliza, inciso, asegurado + OTP). Línea de tiempo de 4 etapas: Solicitud recibida, Documentos en revisión, Solicitud aprobada, Vehículo asignado. Detalle por documento con motivo de rechazo; con vehículo asignado: unidad, agencia, entrega y devolución.

### Notificaciones
- Todo cambio de estatus por correo y SMS.
- Pendiente de acción del asegurado: recordatorio cada tercer día. Sin avance en 15 días naturales → se cancela el folio.

## Fuera de alcance (sección 4)
- Integración con Siniestros.
- Cambios que haga AVASA después de la reservación.
- Conexión con SAP.
- Sucursales por proximidad (no está en la API de AVASA).
- Escalamiento si Siniestros no responde en 72 h (posible fase 2).
- Reporte automático de días reales usados y costo por día al regreso de la unidad.

## No funcionales (sección 5)
- Documentos en repositorio seguro con control de acceso.
- Disponibilidad 24/7, responsivo.
- Integraciones con AVASA/Hertz por API.
- Log de todo cambio de estatus, notificación y decisión.

## Cómo se implementa (estado al 9 nov 2026)

| Tema | Implementación |
|---|---|
| Teléfono y correo del OTP | Vienen del API de pólizas de Chubb (`insured.phoneNumber` / `insured.email`, `apiserver/ix/api/endpoints/autorelevo_auth.py`); K2 no los guarda. En ambientes no prod, `OTP_TEST_PHONE` / `OTP_TEST_EMAIL` redirigen el envío. Si la póliza no tiene ninguno, el login responde 422 antes del override. |
| Datos capturados en el micrositio | Se guardan en `datos_titular` / `ubicaciones_titular` del ticket, no en la póliza. |
| Días de renta | El micrositio crea el ticket sin `dias_solicitados`; K2 aparta un evento de 0 días (valida vigencia, folio activo y días restantes) y al reservar `settle` lo ajusta con `total_dias_uso_vehiculo` calculado de las fechas. El admin sí captura días al crear. Tope de 20 en la pantalla de fechas del micrositio. |
| Días utilizados al cierre | Los captura el operador en K2 (`total_dias_uso_vehiculo`); `events_manager.finish` descuenta los reales. |
| Catálogo de documentos | `documentos_requeridos` por `motivo_servicio_id`; activos en dev alineados al PRD con `datos/qa-autorelevo-sit-2026-11-09/catalogo-documentos-segun-prd.sql` (se desactivaron Volante de admisión en pérdida total/parcial y detención legal, carátula y "número de siniestro y detención legal" en detención legal; la declaración legal es el id 25). Falta replicar en test/prod. |
| Avería: diagnóstico | El nombre en catálogo dice "arriba de 72 hrs"; el PRD dice "máximo 72 horas". Validar el texto con negocio. |
