# Arquitectura de K2

Fuente: lectura del código en `K2-Full-Portal` (rama de trabajo, solo lectura). Cada afirmación proviene de archivos concretos citados entre paréntesis.

## Capas

```
Angular 14 (admin/)
  componentes -> admin/src/app/api/api.service.ts -> request.service.ts
        |  HTTP /api/...   (ng serve: proxy.conf.json -> http://localhost:8080)
        v
Flask 3 (apiserver/ix/app.py)
  ix/api/endpoints/*.py       rutas declaradas con @wrappers.api_resource(ruta, método)
  ix/apps/*/endpoints|routes  rutas por dominio
        |
        v
  ix/svc/*.py                 lógica de servicio
        |
        v
  ix/repositories/*.py        solo en servicios nuevos (dispatcher, follow-up)
  ix/models/*.py              modelos SQLAlchemy 2.0 (ix/models/base.py)
        |
        v
MySQL (mysqlclient; sesiones en ix/db/tools.py)
```

Notas verificadas:

- `ix/api/wrappers.py` define `api_resource`, que registra la ruta con `app.route` bajo `config.API_ROOT = '/api'` (`ix/config/baseconfig.py`) y maneja `ApiError`, `WebServiceError` e `IntegrityError`.
- `ix/app.py` crea la app Flask, configura CORS (orígenes `dev.k2web.online` y `cds.k2web.online`) e importa todos los módulos de endpoints para registrar las rutas; también registra Swagger UI (`flask_swagger_ui`).
- `ix/ctrl/` contiene únicamente `__init__.py`; `ix/api/endpoints/auth.py` importa `from ix import ctrl`.
- Los repositorios existen solo para algunos servicios: `dispatcher_list_repository`, `dispatcher_skill_repository`, `assistance_cases_follow_up_respository` y la base `base_repository` (`ix/repositories/`, interfaces en `ix/repositories/interfaces/`). El resto de los servicios accede a los modelos directamente.
- `main.py` importa `app` de `ix.app`; en local corre en `127.0.0.1:8080`.
- Hay 224 apariciones de `__tablename__` bajo `apiserver/ix` (modelos principales en `ix/models`, SAP en `ix/sapmodels`, catálogo vehicular en `ix/apps/vehicle_catalog/models.py`).

## Paquetes de `apiserver/ix/`

| Paquete | Contenido |
|---|---|
| `api/` | Infraestructura HTTP: `wrappers.py`, `schemas.py`, `apivalidator.py`, `errors.py`, `swagger_generator.py`, `requestfilter/`, `encoder/`; y `endpoints/` con 60 módulos (tickets, casos, proveedores, facturas, usuarios, catálogos, etc.) |
| `apps/` | Módulos por dominio con sus propios endpoints/servicios: `ahio`, `assistance_cases`, `assistance_tickets`, `providers`, `reimbursements`, `form_*`, `validate_policy`, `vehicle_catalog`, `oauth2`, `vip_clients`, `automatic_redistribution`, `automatic_closing`, `claims_monitoring`, entre otros |
| `auto_gen_assist/` | Generación de asistencias vía patrocinadores: `api/` con rutas de `draft_ticket`, `api_sponsor_adapters`, `location_request`, `user_sponsor_role`, `sponsor_cancellation_catalogs` |
| `boletas_informativas/` | Boletas informativas: `auto_relevo/` (boleta, productos, gestor de documentos), `oxxo/`, `nps/` |
| `whatsApp/` | Endpoints de WhatsApp: `ticket_creation`, `collision`, `meli_composer`, `telasist_webhook`, `telasist_cancel_service`; más `services/`, `schemas/` |
| `vps/` | Endpoints y herramientas de sincronización (`vps/endpoints`, `vps/vpstools`); los cron llaman a `/api/vps/...` |
| `ofac/` | Rutas de consulta OFAC (`ofac_routes.py`) |
| `svc/` | Capa de servicios (76 módulos): asistencias, casos, facturas, proveedores, asignación de despachadores, notificaciones |
| `models/` | Modelos SQLAlchemy (124 módulos) |
| `sapmodels/` | Modelos de la base SAP, con su propia `base.py` |
| `repositories/` | Repositorios e interfaces |
| `auth/` | `auth.py`, `jwt.py` |
| `tools/` | Librerías y utilidades: `libraries/flask_jwt.py`, `sap/`, `timbrado/`, `storage/`, `validators/`, `reports/`, `secrets_loader.py` |
| `config/` | `baseconfig.py`, `appconfig.py` |
| `db/` | Estrategias y creación de sesión (`context_db.py`, `tools.py`, `vehicle_catalog_db_strategy.py`) |
| `tests/` | Pruebas pytest (`conftest.py`, `fixtures/`, subcarpetas por dominio) |

## Frontend (`admin/`)

- Angular 14 (`admin/package.json`), módulos de negocio bajo `admin/src/app/app-modules/` (`assistances`, `claims`, `dynamic-forms`, `informative-ticket`, `non-auto-assistances`, `relevo-car`, `shared`, `utilities`).
- HTTP centralizado en `admin/src/app/api/api.service.ts` (usa `RequestService` y `HttpClient`).
- Rutas en `admin/src/app/routes/` (`routes.module.ts`, `routes-admin.ts`, `routes-assistance-cases.ts`, `guards/`).
- `npm start` ejecuta `ng serve` con `proxy.conf.json`: `/api` hacia `http://localhost:8080` y `/ws-ahio-erp` hacia `https://ahio.mx`.

## Despliegue

- `apiserver/app.morfeo-dev-321917.yaml`, `app.morfeo-test.yaml`, `app.morfeo-prod.yaml`: configuración de App Engine; el de dev declara runtime `python314`, entrypoint `gunicorn ... main:app` e instancia Cloud SQL `morfeo-dev-321917:us-east1:morfeo-dev-db`.
- `apiserver/cron.yaml`: tareas programadas que llaman a `/api/bulk/...`, `/api/get/assistanceIVR` y `/api/vps/...` (desbloqueo por geocercas, notificaciones, facturas CDS a Chubb, encuestas IVR, sincronización SAP, estado AHIO).
- `deploy.py` (raíz): compila `admin` y despliega; acepta `--npm-install`, `--pip-install`, `--key`, `--project`, `--version`, `--promote`. `deploy-w-secrets.ps1` es la variante con secretos.
- Los secretos se cargan en `ix/app.py` desde variables de entorno (lista `GCP_SECRETS`) y `ix/tools/secrets_loader.py`.

## Migraciones

- Directorio `apiserver/migrations/` (Alembic: `alembic.ini`, `env.py`, `versions/`) con una sola revisión versionada (`9347cb9a2ec3_.py`).
- `run-migrations.sh <check|current|downgrade|init|merge|migrate|revision|upgrade>` ejecuta `python -m flask db <comando>` con `FLASK_APP=main.py`.
- Scripts SQL sueltos en `apiserver/sql/`.

## Pruebas y ejecución local

- `run-backend.sh`: activa `env/`, exporta `FLASK_APP=main.py` y ejecuta `python main.py` (puerto 8080).
- `run-tests-backend.sh [args]`: `python -m pytest <args> --disable-warnings -v -s` desde `apiserver/`.
- Pruebas en `apiserver/ix/tests/` (`conftest.py`, `fixtures/`, `bd_test/`, `whatsApp/`, `test_svc/`, entre otras).
