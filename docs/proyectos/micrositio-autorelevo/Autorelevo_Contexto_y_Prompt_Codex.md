# Micrositio Autorelevo — análisis contextual y prompt para Codex

Fecha: 22 de septiembre de 2026. Responsable: Joshua.

## 1. Alcance y nivel de evidencia

Este análisis se basa en las 18 capturas compartidas (configuración de environment, fragmentos de CLAUDE.md y docs/NOTAS-ARQUITECTURA-CODEX.md) y en el **PRD de Confluence "PRD Micrositio AutoRelevo"** (espacio CDS1, página 1198587907, última modificación 10 sep 2026). No se ha inspeccionado el repositorio ni ejecutado la aplicación. Las descripciones técnicas son lo documentado, no una certificación del comportamiento actual.

Jerarquía de fuentes: **el PRD define requisitos de negocio y criterios de aceptación**; las notas técnicas describen la implementación prevista; el código es la fuente de verdad de lo implementado. Cuando difieran, registrar la diferencia; no resolverla por intuición.

El objetivo es usar Codex con el código de K2 disponible fuera de la VDI para investigar contratos y apoyar los cambios del micrositio. Tener K2 no implica disponer también del código del micrositio: si falta este último, Codex podrá analizar el backend y preparar cambios propuestos, pero no afirmar que implementó o verificó el frontend.

| Responsable | Alcance comunicado |
|---|---|
| Joshua | Solicitud rechazada; Upload document; revisión de los flujos de pérdida parcial, pérdida total, detención legal y avería mecánica |
| Donovan | Reservación de vehículo |

La lista original sitúa Upload document bajo Solicitud rechazada. Debe priorizarse su relación con la corrección de documentos rechazados y revisar la carga inicial como dependencia, sin asumir que se pidió rediseñar toda la carga documental.

## 2. Requisitos del PRD relevantes para Joshua

Fecha proyectada de todas las funcionalidades: octubre 2026.

### 2.1 Inicio de sesión, OTP y siniestro

- Login con **póliza, inciso y número de asegurado**. No se pide número de siniestro en este paso.
- OTP automático por SMS o correo. Vigencia **5 minutos**. Error exacto: **"Código OTP incorrecto"**. La opción **"Enviar otro OTP"** se habilita cuando expiran los 5 minutos.
- Tras OTP, selector de tipo de servicio.
- **Pérdida total, pérdida parcial y detención legal**: pantalla adicional para capturar número de siniestro; el sistema valida que exista un siniestro para esa póliza.
- **Avería mecánica**: no se solicita número de siniestro.
- La validación de identidad usa la API de pólizas.
- Al iniciar, el asegurado obtiene un folio.

### 2.2 Duplicados

Se bloquea el registro si ya existe una solicitud de auto relevo activa para el mismo siniestro/póliza/inciso. Pendiente: definir la regla de duplicado para avería mecánica (no tiene siniestro).

### 2.3 Registro de contacto y carga documental

- Se muestran datos de póliza: nombre, correo, domicilio (estado, municipio/alcaldía, código postal) y **tipo de plan** (Plus / Plus Premium).
- Documentos obligatorios; **máximo 10 MB por archivo**; formatos **.png, .pdf, .docx**.
- No se permite continuar sin datos y documentación completos.

| Servicio | Documentos requeridos (PRD) |
|---|---|
| Pérdida total | Identificación oficial vigente, licencia vigente, carátula de póliza |
| Pérdida parcial | Identificación oficial vigente, licencia vigente, carátula de póliza |
| Detención legal | Identificación oficial vigente, licencia vigente, declaración legal |
| Avería mecánica | Identificación oficial vigente, licencia vigente, diagnóstico del taller (**mínimo 72 h desde el diagnóstico**), carátula de póliza |

Pendiente: cómo se valida la regla de 72 h (¿fecha capturada? ¿validación manual del operador?).

### 2.4 Validación por operador y rechazo

- Único punto manual del flujo. El operador aprueba o rechaza **cada documento** en K2, con comentario de rechazo; acceso por roles.
- Todos aprobados → estatus **"documentación completa en espera de autorización"** + notificación.
- Algún documento rechazado → estatus **"documentación incompleta o no aprobada"** (en otro punto del PRD: "incompleta o errónea"; confirmar nombre real).
- Mismo flujo de aprobación que el Autorelevo actual de K2.
- Autorización: respuesta esperada en 72 h, registrada en la sección "Autorización" de K2; resultado **aprobado / no aprobado**, notificado por correo o SMS. Este "no aprobado" es el candidato a **rechazo global** (razon_estatus), distinto del rechazo documental (comentario_validacion). Confirmar en código.

### 2.5 Estatus

- K2 visible hoy: Pendiente, Documentos entregados, Vehículo entregado, Finalizado.
- Deben agregarse (crear si no existen): **en revisión de documentación**, **documentación completa en espera de autorización**, **documentación incompleta o errónea**, **servicio autorizado**.
- Consulta de estatus desde el menú "Consultar estatus": póliza + inciso + número de asegurado + OTP.
- Línea de tiempo con 4 etapas para el asegurado: **Solicitud recibida → Documentos en revisión → Solicitud aprobada → Vehículo asignado**.
- Detalle por documento con resultado (aprobado/rechazado) **y motivo de rechazo**.
- Con vehículo asignado: unidad, agencia, fecha de entrega y devolución.

Diferencia a registrar: las notas técnicas listan "Autorizado" y "Cancelado"; el PRD no los menciona entre los estatus visibles. El PRD sí define cancelación automática (ver 2.6), lo que confirma que **Cancelado ≠ Rechazado**.

### 2.6 Notificaciones, recordatorios y cancelación

- Todo cambio de estatus se notifica por correo y SMS.
- Si el folio está pendiente de acción del asegurado (no carga documentos o no coordina el servicio): **recordatorio cada tercer día**.
- **Sin avance en 15 días naturales → cancelación del folio.** Aplica a documentos rechazados sin corrección.
- Todo cambio de estatus, notificación y decisión debe quedar en log.

### 2.7 Frontera con Donovan (reservación, para contexto)

20 días máximos de servicio; categorías AVASA por plan (Plus: C, D, con cascada F, G, L, T, L4, L5, P4; Plus Premium: F, G, L, T, L4, L5, P4 sin cascada); boleta con folio, vehículo, motivo, número de reservación y próximos pasos, descargable en PDF y enviada por correo. El tipo de plan se identifica en la captura (lado de Joshua) y lo consume la reservación: dependencia compartida.

### 2.8 Fuera de alcance y no funcionales

Fuera de alcance: integración con Siniestros, cambios de AVASA posteriores a la reserva, SAP, sucursales por proximidad, escalamiento por 72 h, reporte automático de días/costo. No funcionales: almacenamiento documental seguro con control de acceso, 24/7, responsivo móvil/escritorio, integraciones por API, log de auditoría. TBD: perfiles de operador en K2; SLA de APIs.

## 3. Producto y arquitectura documentada

Recorrido documentado: bienvenida, validación de póliza, canal de verificación, OTP, selección de servicio, captura, creación o consulta de ticket, carga documental y consulta de estado. Desde el estado puede derivar a documentos rechazados/motivo o a selección de sucursal y vehículo, boleta y confirmación.

| Elemento | Versión o mecanismo documentado |
|---|---|
| Angular | 20, componentes standalone, formularios reactivos |
| Nx | 21.4.0; app autorelevo y proyecto autorelevo-e2e |
| TypeScript | 5.8 |
| Estado | Angular Signals, sin NgRx |
| Asincronía | RxJS y HttpClient |
| UI | ChubbUI 4.0.21 |
| Pruebas | Jest y Playwright |
| Node | 20.20.2 recomendado; las notas reportan problemas de @swc/core y Nx con Node 25 |

Verificar versiones reales en package.json, lockfile y .nvmrc antes de instalar. No actualizar dependencias como parte incidental. Los paquetes @chubb/* proceden del registry privado Nexus Chubb configurado en .npmrc. Si no está accesible fuera de VDI, registrar la limitación y continuar el análisis estático; no sustituir silenciosamente componentes corporativos.

### Separación de responsabilidades

- autorelevo/src/app/features/: pantallas, presentación, navegación y validación de interacción.
- autorelevo/src/app/core/services/: sesión, estado compartido y adaptadores de API.
- autorelevo/src/app/core/models/index.ts: modelos internos.
- core/guards/: acceso a rutas.
- core/interceptors/: transporte HTTP, autenticación y mocks.
- shared/components/: UI reutilizable sin lógica de negocio.
- autorelevo/src/environments/: configuración por ambiente.
- autorelevo/src/styles.scss: estilos globales y overrides ChubbUI.
- autorelevo-e2e/: pruebas Playwright.
- docs/ y docs/prototypes/: documentación y referencias funcionales.

No duplicar reglas de negocio entre pantallas. No importar una pantalla en otra para compartir estado. Las respuestas externas deben convertirse a modelos internos en los servicios API.

## 4. Rutas y pantallas

| Ruta | Componente documentado | Acceso |
|---|---|---|
| / | BienvenidaComponent | Público |
| /auth/login | LoginComponent | Público |
| /auth/otp | OtpComponent | Público |
| /verificacion/canal | CanalVerificacionComponent | Público |
| /solicitud/servicio | SeleccionServicioComponent | authGuard |
| /solicitud/captura | CapturaInfoComponent | authGuard |
| /solicitud/espera | EnEsperaComponent | authGuard |
| /solicitud/vehiculo | SeleccionVehiculoComponent | authGuard |
| /solicitud/boleta | BoletaInformativaComponent | authGuard |
| /solicitud/aprobada | SolicitudAprobadaComponent | authGuard |
| /estado | EstadoSolicitudComponent | authGuard |
| /estado/rechazada | DocsRechazadasComponent | authGuard |
| /estado/rechazo-motivo | MotivoRechazoComponent | authGuard |
| /estado/sucursal | SucursalComponent | authGuard |

app.routes.ts utiliza loadComponent. Para Joshua son prioritarias /estado, /estado/rechazada y /estado/rechazo-motivo; servicio, captura y espera alimentan esos estados. Verificar si existe la pantalla condicional de número de siniestro exigida por el PRD (2.1) o si se captura dentro de /solicitud/captura.

## 5. Estado, modelos y autenticación

AuthService es dueño de la sesión: signal privado con lectura readonly, persistencia sessionStorage bajo ar_session, sesión temporal tras login, JWT real tras validateOtp e isAuthenticated como computed usado por el guard. Logout limpia sesión y vuelve a /. Verificar que la sesión temporal no habilite rutas protegidas. Los componentes consumen AuthService, no leen storage directamente. Contrastar vigencia, reenvío y mensaje de OTP con el PRD (2.1).

SolicitudService administra número de siniestro, motivo, folio/ticket, sucursal, vehículo y boleta; expone estado readonly/computed y métodos setServicio, setFolio, setSucursal, setVehiculo, setBoleta, updateEstatus y reset. Actualizaciones inmutables. Investigar qué sobrevive a una recarga y cómo se recupera el ticket del backend. El número de siniestro debe ser opcional para avería mecánica.

Modelos documentados: MotivoSolicitud (cuatro motivos), Folio, DocumentoRequerido, Vehiculo, Sucursal y Boleta. EstatusSolicitud contiene en_revision, rechazado, aprobado y vehiculo_asignado. No asumir correspondencia directa con estados K2 ni con las 4 etapas de la línea de tiempo del PRD; construir un mapeo explícito. Falta en los modelos documentados el tipo de plan (Plus / Plus Premium).

Integraciones:

1. K2 Backend/Morfeo: sesión del asegurado y OTP; POST /auth/login, /auth/otp/send, /auth/otp/validate y /auth/otp/resend bajo la base configurada.
2. K2 Portal: tickets, boletas, documentos y validaciones. JWT diferente, POST /api/auth/token y caché shareReplay(1).
3. AVASA: ubicaciones, tarifas, vehículos y reservaciones.

El interceptor debe seleccionar credenciales por destino. Revisar expiración, invalidación, reintentos y exclusión del endpoint de token para evitar recursión. No enviar tokens de un sistema a otro.

El proxy /k2portal (autorelevo/proxy.conf.json) apunta al portal de desarrollo y elimina el prefijo; secure:false por certificado autofirmado de desarrollo. No trasladar esa excepción a producción ni asumir que el proxy de ng serve existe en el despliegue.

## 6. Contratos K2 que requieren especial atención

### Identificadores distintos

```typescript
{
  ServicioAutoRelevo: { id, estatus_servicio, razon_estatus },
  BoletaInformativa: { id, folio_servicio, fecha_solicitud },
  DocumentosValidacion: [
    { id, nombre_documento, hash_id, estatus_validacion, comentario_validacion }
  ],
  DatosTitular: { nombre_completo, telefono_contacto, correo_electronico }
}
```

Esquema ilustrativo, no interfaz completa.

- ServicioAutoRelevo.id: identificador para GET /tickets/{id}.
- BoletaInformativa.id: identificador de boleta; no sustituye al anterior.
- Folio.id debe conservar ServicioAutoRelevo.id.
- hash_id identifica el destino documental de carga; no sustituye a los anteriores.
- Aclarar cuál es el "folio" que ve el asegurado según el PRD (¿folio_servicio?).

CLAUDE.md señala un posible bug donde mapearFolio guarda el ID de boleta. Verificar la implementación actual antes de declarar que persiste.

### Operaciones documentadas de K2ApiService

getK2Token, invalidateK2Token, crearTicket, buscarTicketActivo, obtenerTicket, enviarNotificacion, subirDocumento, guardarReservacion y mapearFolio. Confirmar que existen.

crearTicket recibe siniestroChubbId, póliza y tipoServicioId (POST /tickets). Verificar cómo se crea sin siniestro para avería mecánica. obtenerTicket: GET /tickets/{ServicioAutoRelevo.id}. subirDocumento: PUT multipart con hash_id. URL, campo multipart, límites (PRD: 10 MB; .png/.pdf/.docx) y respuestas deben extraerse del backend; comprobar si el backend aplica esos límites o solo el frontend.

K2 espera la póliza como PREFIJO|NUMERO (dos primeros caracteres = prefijo). Verificar y evitar duplicar el separador.

buscarTicketActivo es el candidato a implementar la regla de duplicados del PRD (2.2); verificar sus criterios.

### Secuencia documental

K2 puede devolver DocumentosValidacion vacío tras crear el ticket; los hash_id aparecen después de enviarNotificacion y una nueva consulta.

Auditar: creación/recuperación → generación de documentos/notificación → nueva consulta → carga por hash_id → actualización del estado. No confundir respuesta vacía con ausencia de requisitos. No ejecutar notificaciones repetidamente al renderizar o reintentar sin verificar idempotencia: envía correo (y el PRD exige log de cada notificación).

Investigar reutilización, expiración y regeneración de hash para documentos rechazados, y la transición tras una nueva carga.

## 7. Cuatro tipos de servicio

| Servicio | Motivo interno | Siniestro | Documentos adicionales a INE y licencia | ID K2 |
|---|---|---|---|---|
| Pérdida parcial | perdida_parcial | Obligatorio y validado | Carátula de póliza | Pendiente de verificar |
| Pérdida total | perdida_total | Obligatorio y validado | Carátula de póliza | Pendiente de verificar |
| Detención legal | detencion_legal | Obligatorio y validado | Declaración legal | Pendiente de verificar |
| Avería mecánica | averia_mecanica | No se solicita | Diagnóstico del taller (≥72 h) y carátula de póliza | Pendiente de verificar |

Documentos confirmados por PRD y notas; contrastar con catálogos y validaciones del backend. No inventar IDs 1–4. CLAUDE.md reporta tipo_servicio_id fijo en 1: comprobar si persiste y trazar el mapeo.

La revisión por tipo abarca selección, captura de siniestro condicional, validaciones, payload, documentos, consulta, rechazo y reenvío.

## 8. Rechazo de solicitud y de documentos

El PRD confirma dos niveles: rechazo **documental** (por documento, con comentario, estatus "documentación incompleta…") y resultado de **autorización** aprobado/no aprobado. razon_estatus y comentario_validacion probablemente corresponden a cada uno; confirmarlo en código.

Investigar:

- Códigos reales de "documentación incompleta/errónea" y "no aprobado"; si existen o deben crearse.
- Cómo decide /estado la ruta siguiente y cómo mapea a la línea de tiempo de 4 etapas.
- Si MotivoRechazoComponent recibe motivo global, por documento o agregación (el PRD pide motivo por documento).
- Si mapearFolio conserva comentarios, estados y hashes.
- Varios documentos rechazados con comentarios diferentes.
- Qué documentos pueden reemplazarse y cuáles aprobados se conservan.
- Qué estado retorna K2 tras la corrección (esperado por PRD: volver a "en revisión de documentación") y qué acción lo dispara.
- Comentarios vacíos sin inventar una causa.
- Si un "no aprobado" en autorización permite reintentar o es terminal.
- Relación con recordatorios cada tercer día y cancelación a 15 días.

No equiparar Cancelado con Rechazado: el PRD define cancelación por inactividad.

## 9. Frontera con Donovan y AVASA

AvAsaApiService documenta getLocations, getRates, crearReservacion, consultarReservacion y adaptadores getSucursales/getVehiculos. Modelos AvAsa* se convierten a internos antes de la UI.

numReservacion pertenece a AVASA. CLAUDE.md lo reporta nunca poblado; guardarReservacion sincronizaría AVASA con K2. Comprobar y coordinar con Donovan. El tipo de plan (captura) y el estatus "servicio autorizado" (rechazo/aprobación) son las entradas que Joshua entrega a la reservación.

Joshua preserva el paso hacia la reservación y los modelos compartidos; no implementa la reservación.

## 10. Particularidades ChubbUI

- Preferir componentes corporativos existentes.
- Algunos inputs requieren enums, p. ej. CbProgressTrackerSpacingVariant.COMFORTABLE (útil para la línea de tiempo de 4 etapas).
- cb-select-tile con FormsModule, ngModel y selected=false; confirmar firma en la versión instalada.
- CbButtonDirective usa clases Tailwind no generadas automáticamente; conservar overrides de styles.scss.
- El MCP ChubbUI (@chubb/ui-mcp-server) usa rutas Windows no portables. .mcp.json y /mcp son de Claude Code; no asumir que Codex los carga. Se puede analizar leyendo tipos y exports locales.

## 11. Credenciales y configuración

Una captura muestra credenciales de servicio en environment.ts; se omiten sus valores. Un environment de Angular se entrega al navegador; usar .env en build no los vuelve secretos. Registrar el hallazgo, evaluar mover la autenticación privilegiada a backend/BFF y rotar si están activas. No propagar credenciales a prompts, logs, pruebas o documentación. El PRD exige almacenamiento documental seguro con control de acceso, lo que refuerza el hallazgo. No autoriza un rediseño de autenticación sin análisis de impacto.

## 12. Orden sugerido de trabajo y verificación

1. Identificar repositorios, ramas y cambios existentes (la captura muestra CDSEBAU-39-rechazados); preservar trabajo ajeno.
2. Leer instrucciones locales, documentación y este documento (incluido el resumen del PRD).
3. Rastrear rutas, contratos, IDs, catálogos y estados en K2; contrastar con el micrositio si está disponible.
4. Confirmar ID de servicio en consultas, mapeo de tipo de servicio y creación sin siniestro.
5. Resolver secuencia de hashes/carga y distinción rechazo documental / no aprobado.
6. Validar los cuatro recorridos contra el PRD y la frontera hacia reservación.
7. Proponer cambios pequeños por capa y pruebas de comportamiento.

Pruebas prioritarias: IDs de servicio y boleta diferentes; cuatro motivos con IDs verificados; siniestro condicional; documentos inicialmente vacíos y posterior disponibilidad; límites 10 MB y formatos; múltiples rechazos; carga fallida sin marcar éxito; corrección de un documento conservando otros; retorno a revisión; mapeo a 4 etapas; duplicado bloqueado; recarga y recuperación del ticket; sesión y OTP expirados; tokens por destino; errores backend sin convertirlos en éxito vacío.

```bash
nvm use 20.20.2
npx nx serve autorelevo
npx nx build autorelevo
npx nx lint autorelevo
npx nx test autorelevo
npx nx e2e autorelevo-e2e
```

Antes de instalar, revisar lockfile, gestor y acceso al registry. Evitar correos, cargas reales, tickets y reservaciones en producción. Un mock verde demuestra comportamiento frente a ese mock, no integración real.

## 13. Cascarón local solicitado

Crear un proyecto independiente en `~/github/personal/micrositio-autorelevo`. Resolver y mostrar la ruta absoluta; si existe, inspeccionar y conservar su contenido.

Objetivo: reproducir los flujos de Joshua con contratos tipados y mocks locales. Angular 20, Nx 21.4, TypeScript 5.8, standalone, Signals, formularios reactivos, Jest, Playwright, Node 20.20.2 (si son compatibles e instalables).

Estructura mínima:

- Aplicación `autorelevo` y proyecto `autorelevo-e2e`.
- Capas `features/`, `shared/`, `core/models/`, `core/services/`, `core/guards/`, `core/interceptors/`, `environments/`.
- Rutas: login (póliza/inciso/número de asegurado), OTP, selección de servicio, captura condicional de siniestro, captura/carga, espera, estado (línea de tiempo de 4 etapas), solicitud rechazada, motivo de rechazo y corrección de documentos.
- Modelos internos: cuatro motivos, tipo de plan, folio/ticket, documentos, estatus, datos del titular.
- `AuthService`, `SolicitudService` y puerto/adaptador K2 con implementación mock.
- Validaciones del PRD: 10 MB, .png/.pdf/.docx, documentos por servicio, siniestro condicional, OTP 5 min con reenvío, duplicado.
- Fixtures para los cuatro servicios y escenarios: en revisión, documentación completa, uno o varios documentos rechazados, corrección, servicio autorizado, no aprobado, duplicado y cancelado por inactividad.
- README con instalación, ejecución, pruebas, alcance, decisiones, limitaciones y trazabilidad a criterios del PRD.
- `.env.example` solo si una herramienta lo necesita, con valores ficticios.

Sin código corporativo de K2, credenciales, URLs privadas, paquetes privados, datos de asegurados ni datos de ambientes reales. Si `@chubb/*` no está disponible, crear adaptadores neutrales con punto de sustitución documentado.

Contratos como interfaces y puertos. Mocks deterministas que distingan `ServicioAutoRelevo.id`, `BoletaInformativa.id` y `hash_id`. Generación de documentos como transición explícita; notificación simulada idempotente.

Git local en rama de trabajo, `.gitignore` para `dist/`, `.angular/`, `.nx/cache/`, `node_modules/`, entornos locales y resultados de pruebas. Sin remotos ni publicación.

Primero el diagnóstico de K2; después el cascarón con contratos comprobados, marcando supuestos.

## 14. Prompt listo para pegar en Codex

Copia el bloque y adjunta este documento. Inicia Codex donde esté K2; si también tienes el micrositio, proporciona ambas rutas locales reales. No uses las rutas Windows de las capturas.

```text
Actúa como analista técnico senior de Angular, TypeScript y backend Flask. Ayúdame con el proyecto Micrositio Autorelevo de Chubb México. Soy Joshua. Lee el archivo Autorelevo_Contexto_y_Prompt_Codex.md que acompaña este prompt; su sección 2 resume el PRD oficial y es la referencia de requisitos de negocio.

Mi alcance es Solicitud Rechazada, Upload document asociado y revisión integral de los cuatro tipos de servicio: pérdida parcial, pérdida total, detención legal y avería mecánica. Donovan se encarga de reservación de vehículo. Respeta esa frontera y documenta dependencias compartidas (tipo de plan, estatus autorizado, numReservacion).

Además, crea un cascarón independiente del micrositio en `~/github/personal/micrositio-autorelevo`. Resuelve y muestra primero la ruta absoluta. Si ya existe, inspecciona y conserva su contenido.

Tengo código de K2 fuera de la VDI. Primero determina qué repositorios están realmente disponibles. Si falta el micrositio, analiza K2 y entrega contratos y propuestas; no inventes su implementación ni afirmes haberlo probado. Si falta una ruta necesaria, pídemela después del análisis posible.

PRIMERA FASE: DIAGNÓSTICO DE K2 SIN MODIFICAR SU CÓDIGO.

1. Lee AGENTS.md, README, CLAUDE.md y docs/NOTAS-ARQUITECTURA-CODEX.md si existen. Verifica git status, rama y diferencias. No borres, resetees ni sobrescribas trabajo. Sin commits, pushes, despliegues ni llamadas que creen tickets, manden correos o hagan reservaciones.
2. Separa: hecho comprobado en código, requisito del PRD, afirmación documental, hipótesis y pendiente. Cita archivo, símbolo y líneas.
3. En K2 busca apiserver/ix/boletas_informativas/autorelevo/ y admin/src/app/app-modules/relevo-car/ (o localízalos por símbolos). Revisa blueprints, modelos, validadores, serializadores, catálogos, semillas/migraciones y consumidores del portal.
4. Reconstruye contratos de crear, buscar (duplicados) y consultar tickets; generación de documentos y notificación; carga/reemplazo por hash_id; validación por operador; autorización; transición tras corrección; recordatorios y cancelación a 15 días. Extrae método, ruta, autenticación, campos, tipos, respuesta, errores y efectos secundarios. Ejemplos sintéticos sin datos personales ni secretos.
5. Comprueba ServicioAutoRelevo.id frente a BoletaInformativa.id y hash_id; el ID de GET /tickets/{id}; qué folio ve el asegurado. Si existe el micrositio, revisa mapearFolio y Folio.id.
6. Encuentra los IDs reales de los cuatro tipos de servicio y su fuente, y cómo se crea un ticket de avería mecánica sin siniestro. No asumas valores.
7. Reconstruye documentos por tipo; compara backend, frontend y PRD (10 MB, .png/.pdf/.docx, diagnóstico ≥72 h). Verifica cuándo aparecen hash_id, regeneración/reutilización y cómo evitar notificaciones duplicadas.
8. Distingue razon_estatus de comentario_validacion. Construye tabla de estados reales K2 vs. estatus exigidos por el PRD (en revisión de documentación, documentación completa en espera de autorización, documentación incompleta o errónea, servicio autorizado), indicando cuáles faltan, y su mapeo a las 4 etapas visibles (Solicitud recibida, Documentos en revisión, Solicitud aprobada, Vehículo asignado). No equipares cancelación con rechazo.
9. Si está el micrositio, revisa versiones, app.routes.ts, core/models, AuthService (OTP 5 min, "Código OTP incorrecto", reenvío), SolicitudService, K2ApiService, interceptores, pantallas de estado/rechazo/carga y pruebas. Verifica bugs documentados sin asumir que siguen abiertos.
10. Conserva UI → estado/adaptadores → APIs. Respeta ChubbUI. No actualices dependencias. Sin registry o servicios corporativos, continúa con análisis estático y registra lo no validado.
11. No reproduzcas secretos. Señala credenciales de servicio en frontend si persisten. No confundas JWT del asegurado con JWT de K2 Portal.

ENTREGA:
A. Repositorios, ramas, versiones y limitaciones.
B. Mapa de arquitectura y archivos relevantes para Joshua.
C. Endpoints, contratos y efectos secundarios.
D. Matriz de cuatro servicios: motivo, ID K2, fuente, siniestro, campos, documentos y validaciones (backend / frontend / PRD).
E. Flujo de rechazo/corrección y tabla de estados, confirmado vs. desconocido vs. faltante respecto del PRD.
F. Defectos actuales priorizados con evidencia, incluidas brechas contra el PRD; distingue pendientes ya resueltos.
G. Plan de cambios por archivo/capa, dependencias con Donovan y criterios de aceptación trazados al PRD (marca como propuestos los que el PRD no cubre).
H. Pruebas necesarias y dudas de negocio sin resolver (incluye los TBD del PRD).

SEGUNDA FASE: CASCARÓN LOCAL.

Crea `~/github/personal/micrositio-autorelevo` con Angular 20, Nx 21.4, TypeScript 5.8, standalone, Signals, formularios reactivos, Jest y Playwright, Node 20.20.2. Si alguna versión no es compatible, presenta evidencia y usa la combinación mínima compatible.

Incluye `autorelevo`, `autorelevo-e2e`, features/core/shared, rutas del alcance de Joshua (incluida captura condicional de siniestro y línea de tiempo de 4 etapas), modelos internos (con tipo de plan), AuthService, SolicitudService, puerto/adaptador K2 mock y fixtures deterministas. Escenarios: cuatro motivos, en revisión, documentación completa, uno o varios documentos rechazados, corrección, autorizado, no aprobado, duplicado y cancelado. Valida 10 MB y formatos. Modela por separado ServicioAutoRelevo.id, BoletaInformativa.id y hash_id; generación de documentos explícita e idempotente.

README con comandos, decisiones, limitaciones y trazabilidad al PRD; .gitignore para dist, cachés, dependencias, entornos locales y resultados de pruebas. Solo datos y endpoints ficticios. Sin código corporativo, credenciales, URLs privadas, datos reales ni paquetes privados; si falta ChubbUI, adaptadores neutrales documentados.

Git solo local con rama descriptiva; sin remotos ni push. Ejecuta build, lint, pruebas unitarias y un e2e básico. Reporta comandos y resultados exactos y lo que no pudo ejecutarse.

En K2 la primera fase es solo lectura. Las modificaciones se limitan a `~/github/personal/micrositio-autorelevo`.
```
