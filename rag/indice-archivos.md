# Índice de archivos

Rutas relativas a `../K2-Full-Portal` (K2).

| Qué buscas | Dónde |
|---|---|
| Entrada de la app (arranque local) | `apiserver/main.py` |
| Creación de la app Flask, CORS, registro de rutas, Swagger UI | `apiserver/ix/app.py` |
| Decorador de rutas `api_resource`, manejo de errores, filtros y paginación | `apiserver/ix/api/wrappers.py` |
| Esquemas de validación de requests | `apiserver/ix/api/schemas.py` |
| Endpoints REST generales (60 módulos) | `apiserver/ix/api/endpoints/` |
| Autenticación y login | `apiserver/ix/api/endpoints/auth.py`, `apiserver/ix/auth/jwt.py`, `apiserver/ix/tools/libraries/flask_jwt.py` |
| Configuración, roles y `API_ROOT` | `apiserver/ix/config/baseconfig.py`, `apiserver/ix/config/appconfig.py` |
| Carga de secretos | `apiserver/ix/tools/secrets_loader.py` |
| Servicios de negocio | `apiserver/ix/svc/` |
| Asignación a despachadores | `apiserver/ix/svc/assignament_dispatchers.py` |
| Redistribución automática | `apiserver/ix/apps/automatic_redistribution/` |
| Modelos SQLAlchemy | `apiserver/ix/models/` (base en `base.py`) |
| Modelos de la base SAP | `apiserver/ix/sapmodels/` |
| Sesiones de BD | `apiserver/ix/db/tools.py`, `apiserver/ix/db/context_db.py` |
| Repositorios | `apiserver/ix/repositories/` |
| Autorelevo (boleta, productos, documentos) | `apiserver/ix/boletas_informativas/auto_relevo/api/` |
| Boletas OXXO y NPS | `apiserver/ix/boletas_informativas/oxxo/`, `apiserver/ix/boletas_informativas/nps/` |
| Generación de asistencias por patrocinador | `apiserver/ix/auto_gen_assist/api/` |
| WhatsApp (creación de ticket, colisión, Telasist) | `apiserver/ix/whatsApp/endpoints/` |
| AHIO | `apiserver/ix/apps/ahio/` |
| Reembolsos | `apiserver/ix/apps/reimbursements/` |
| Validación de póliza | `apiserver/ix/apps/validate_policy/` |
| Catálogo vehicular | `apiserver/ix/apps/vehicle_catalog/` |
| Sincronización SAP y timbrado | `apiserver/ix/vps/`, `apiserver/ix/tools/sap/`, `apiserver/ix/tools/timbrado/` |
| OFAC | `apiserver/ix/ofac/` |
| Tareas programadas | `apiserver/cron.yaml` |
| Configuración de despliegue | `apiserver/app.morfeo-{dev-321917,test,prod}.yaml`, `deploy.py` |
| Migraciones | `apiserver/migrations/`, `run-migrations.sh` |
| Pruebas del backend | `apiserver/ix/tests/`, `run-tests-backend.sh` |
| Cliente HTTP del admin | `admin/src/app/api/api.service.ts`, `admin/src/app/api/request.service.ts` |
| Rutas del admin | `admin/src/app/routes/` |
| Módulo Autorelevo en el admin | `admin/src/app/app-modules/relevo-car/` |
| Proxy de desarrollo del admin | `admin/proxy.conf.json` |

- `K2-Full-Portal/apiserver/ix/apps/form_response_import/task.py`: importación de Excel con cola en memoria + hilos daemon (patrón a no replicar; ver spec del importador genérico en docs/tareas/feat-autorelevo-reporte-avasa/).
- `K2-Full-Portal/apiserver/ix/apps/csv/`: CSVProcessor con estrategias (solo CSV).
- `K2-Full-Portal/apiserver/ix/apps/importador/`: importador genérico xlsx/csv → tabla. Agregar un layout = un `ImportLayout` en `layouts.py` (registro validado al importar). Endpoint `POST /api/importador/<layout>`.
- `bin/k2-bruno`: spec con `form: [{name, file|value}]` genera cuerpos multipart (subida de archivos).
