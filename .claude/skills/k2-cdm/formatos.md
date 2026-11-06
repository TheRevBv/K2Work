# Formatos CDM (Chubb Delivery Model)

ID de producto: `<AÑO>_OM-<PROY>_R<NN>` (ej. `2026_OM-P26-076_R01`). Archivos: `<ID>_<TIPO>.docx`.

Elementos comunes de los .docx:
- Portada: logo CHUBB (arriba izq.), título grande + ID debajo.
- Encabezado de página: `<ID>` / `<Título del doc>` con línea inferior.
- Pie: `Versión Documento: #.##.##` (solo CLL) · `Versión Formato: <x.xx.xx>` · número de página · "Documento confidencial Chubb".
- Página 2: Tabla de Contenido.
- Cierre: Historial del Documento (tabla Versión | Autor | Solicitante | Descripción | Fecha) e Historial del Formato ("Consultar Historial de Formato en: Administración de Formatos", enlace).
- Autor: Manuel Fernando Silva Encinas · Solicitante: Victor de la Paz (confirmar por ticket).

## DIS — Diseño Detallado (Versión Formato 3.00.01, fuente serif)

1. Objetivo del Documento — texto fijo:
   "El objetivo del documento es establecer la propuesta de solución detallada aplicable solo al proyecto. presentar diseñadores y desarrolladores información correspondiente a la modificación y creación de artefactos que den respuestas a las necesidades planteadas en las historias de usuario incluidos en el proyecto."
2. Definiciones, Acrónimos y Abreviaciones — tabla con encabezado verde: Nombre | Función | TipoObjeto (puede ir vacía).
3. Antecedentes — N/A por defecto. Luego "Referencia".
4. Diseño Detallado
   - Historias de Usuario — tabla 2 columnas: clave Jira (ej. CDSEBAU-44) | título en negritas + descripción.
   - Diseño de Métodos API — N/A o detalle.
   - Diseño de Seguridad — N/A o detalle.
   - Permisos aplicación — N/A o detalle.
   - Parámetros de Configuración de aplicación — N/A o detalle.
5. Objetos Detallados (puede ir vacío).
6. Historial del Documento — v1.00.00, "Versión Inicial".
7. Historial del Formato.

## CLL — Checklist de Liberación (Versión Formato 4.00.01, fuente sans)

1. Objetivo del Documento — problema de negocio (1 párrafo).
2. Definiciones, Acrónimos y Abreviaciones — tabla Término | Descripción (encabezado negro).
3. Referencias — `PR: <título PR · Pull Request #N · Mexico-IT/K2-full-portal>` (enlace) y `PRD: <página Confluence>` (enlace, cursiva).
4. Detalle de las Actividades de Liberación — párrafos resumen + tabla Requerimiento | Detalle (decisiones/criterios CA-xx).
   - Verificar Requisitos.
   - Respaldar Información, Objetos, Archivos, Formas de Impresión — N/A.
   - Ambiente resaltado en amarillo: `Morfeo-Test | Morfeo-Prod`.
   - Liberación de Archivos de Bases de Datos — tabla Nombre | Pasos | Base de datos (ej. `sql.zip`; orden de scripts `00_create table.sql` → marcas/submarcas → vehículos; QA: `vehicle_catalog_dev`, UAT: `vehicle_catalog_prod`).
   - Liberación de Ejecutables de la Aplicación — tabla Archivo | Archivos Contenidos (tipo: Archivo Python, Servicio / Python (nuevo), Repositorio / Python, Estrategia / Python…) | Descripción. Debajo, resaltados: `Branch: <rama>` y `Versión GCP liberar: <versión>`.
   - Configuración de Recursos en Servidores, Registro de Windows, Componentes, Archivos Web, Formas de Impresión, Instalador — "No Aplica".
5. Plan de Contingencia
   - Scripts de Base de Datos — No Aplica (o scripts de rollback).
   - Información, Objetos, Archivos, Formas de Impresión, Ejecutables — texto fijo "Copiar la versión de los objetos… sección 2 de este documento." + `Versión GCP liberar: <versión anterior>` (rollback).
   - Restauración de Recursos de Servidores / Registro de Windows / Componentes / Archivo Web / Formas de Impresión — No Aplica.
6. Historial del Documento — v1.0.0.
7. Historial del Formato.

## Correos de solicitud de aprobación

Asunto: `<ID> - <FASE>_SolicitudDeAprobacion<NN>`. Etiqueta: Yellow Data - LATAM.
Cuerpo: `SOLICITUD DE APROBACIÓN - <FASE LARGA>`, Productos de Trabajo, lista, Ruta, Aprobaciones Solicitadas, Fecha límite `[MM/DD/AAAA]`, Comentarios.

| Fase | Para | CC | Adjuntos | Aprueba | Particular |
|---|---|---|---|---|---|
| DIS (DISEÑO) | Barcenas Hector, Almaguer Alejandra, Lopez Geovanni | De La Paz Victor Hugo, ITCDS_QA | `<ID>_DIS.docx` | @Barcenas, Hector | Lista de 8 productos con Requerido (verde) / No aplica (rojo): Componentes Involucrados, Diseño General, Diseño Detallado, Diagrama de Entidad Relación, Especificaciones Técnicas, Diagramas de Secuencia, Prototipo, Revisión de documentos de Diseño por Peer. Ruta vacía. Comentarios = resumen del cambio. |
| CON (CONSTRUCCIÓN) | Barcenas Hector | De La Paz Victor Hugo | `<ID>_CLL.docx`, `<ID>_PRUEBAS.docx`, `diagrama.png`, `ManualTecnico-<NOMBRE>.docx`, `sql.zip` | @Barcenas, Hector | Lista: componente (ej. API K2). Ruta = enlace al PR. Comentarios "Solicitud de aprobación". Sección "Pruebas de Construcción" con lista de pruebas. |
| CLL (CHECKLIST) | Barcenas Hector, Almaguer Alejandra, Lopez Geovanni | De La Paz Victor Hugo, ITCDS_QA | `<ID>_CLL.docx`, `sql.zip` | @ITCDS_QA | Lista: `<ID>CLL`. Sin Ruta. Comentarios "Solicitud de aprobación". |



## PRUEBAS — Evidencia de pruebas (`<ID>_PRUEBAS.docx`)

Mismo esqueleto (portada, encabezado, pie). Cuerpo: una sección por escenario con título en negritas (ej. "Pruebas con vehículo eléctrico") seguido de capturas de la evidencia (bitácora del caso en K2: fecha, usuario, acción, proveedor, comentario — p. ej. tipo de servicio enviado a AHIO, costo adicional por aditamento, respuestas del cuestionario). Escenarios = casos `ok` de `docs/tareas/<rama>/matriz-qa.md`; capturas desde la carpeta del ticket.

## Manual Técnico (`ManualTecnico-<NOMBRE>.docx`)

Sin formato fijo capturado. Estructura libre: objetivo, arquitectura/flujo (`diagrama.png`), modelo de datos (tablas nuevas), endpoints/servicios tocados, configuración y despliegue.
