# CDSEBAU-57-Autorelevo-integrado

- Repo: K2-Full-Portal, rama `CDSEBAU-57-Autorelevo-integrado`
- Time Tracker: 2026_58P_MicrositioAutorelevo
- Matriz QA: [matriz-qa.md](CDSEBAU-57-Autorelevo-integrado/matriz-qa.md)

## 23 nov 2026 — Reporte QA (Ian Téllez, Teams "Pruebas Micrositio Autorelevo")

1. El correo para cargar documentación y el de "documento rechazado" son el mismo.
2. La liga de carga sigue mostrando que la documentación se cargó exitosamente.

### Hallazgos

- **Correo:** ambos salen de `POST /v1/boleta-informativa/auto-relevo/servicios/<id>/enviar` → `AutoRelevoNotificationsService.envio_mail` (`notifications_manager.py`), siempre con `template/autorelevo_mail.html` y asunto "CHECK LIST- AUTO RELEVO…". No existe plantilla de rechazo.
  El PRD (`docs/proyectos/micrositio-autorelevo/prd.md`) no define correo de rechazo; solo "Todo cambio de estatus por correo y SMS" (l. 83) y "Algún rechazo → documentación incompleta" (l. 52). Es feature: pendiente que negocio defina texto y destino del botón (micrositio o liga K2). Si se hace: en `envio_mail` usar plantilla nueva cuando `has_rejected_documents(servicio_id)`.
- **Liga:** `AutoRelevoFilesService.get_documents` (`upload_file_manager.py:280`) responde 400 "Todos los documentos ya han sido cargados" si todo `estatus_archivo == completado`. Rechazar solo cambia `estatus_validacion`; el archivo queda `completado`. **Bug.**

### Fix (liga)

Commit `91005644 fix(autorelevo): permitir recargar documentos rechazados desde la liga pública`.
`_procesar_documentos` reporta `Pendiente` el documento con `estatus_validacion == 'Rechazado'`. Patch: `datos/CDSEBAU-57/0001-fix-autorelevo-permitir-recargar-documentos-rechazad.patch`.

```diff
--- a/apiserver/ix/boletas_informativas/auto_relevo/api/auto_relevo_boleta/upload_file_manager.py
+++ b/apiserver/ix/boletas_informativas/auto_relevo/api/auto_relevo_boleta/upload_file_manager.py
@@ -358,7 +358,8 @@ class AutoRelevoFilesService:
                 estatus_archivo = "Pendiente"
                 hash_id_documento = None
             else:
-                estatus_archivo = documento_archivo.estatus_archivo.name if documento_archivo else "Pendiente"
+                rechazado = documento_validacion.estatus_validacion == "Rechazado"
+                estatus_archivo = documento_archivo.estatus_archivo.name if documento_archivo and not rechazado else "Pendiente"
                 hash_id_documento = documento_validacion.hash_id
 
             resultado.append({
```

Pendiente: desplegar en dev y que QA reprueba; respuesta enviada a Ian con ambos puntos.
