---
name: k2-rastrear
description: Rastrea un flujo o pantalla de K2 desde el componente Angular hasta la ruta Flask, el servicio, el modelo y la tabla MySQL. Usar cuando el usuario nombra un componente, endpoint, pantalla o flujo (asistencias, WhatsApp, catálogos, autorelevo) o pide entender/arreglar algo antes de tocar código.
---

# Rastrear un flujo de K2

Repo: `../K2-Full-Portal` (agrégalo con `/add-dir` si no está). Backend Flask en `apiserver/ix/`.

## Cadena

    admin/src/app/app-modules/...  componente .ts/.html
      → admin/src/app/api/api.service.ts   método HTTP (usa RequestService)
      → apiserver/ix/api/endpoints/*.py    ruta con @wrappers.api_resource (prefijo /api)
        o apiserver/ix/apps/*, auto_gen_assist/, boletas_informativas/, vps/, ofac/
      → apiserver/ix/svc/*.py              servicio (reglas)
      → apiserver/ix/models/*.py           modelo SQLAlchemy (repositories/ solo en servicios nuevos)
      → tabla MySQL
    WhatsApp: apiserver/ix/whatsApp/{endpoints,services,schemas,enums.py}
    Mapa completo: docs/arquitectura.md

## Pasos

1. Ubicar el componente: `grep -rn "<NombreComponente>" ../K2-Full-Portal/admin/src --include='*.ts' -l`.
2. Encontrar la llamada en `api.service.ts` y la URL que usa.
3. Buscar la ruta en el backend (no hay Blueprints; busca el decorador): `grep -rn "api_resource(.*<fragmento-de-url>" ../K2-Full-Portal/apiserver/ix --include='*.py'`.
4. Seguir servicio → repositorio/modelo; anotar tablas (`__tablename__`).
5. Confirmar la forma real de los datos con `bin/k2-sql local describe <tabla>` y la skill `k2-bd`.
6. Registrar el rastreo en `docs/tareas/<rama>.md` (sección Hallazgos) con rutas y líneas.

## Reglas

- El backend es Flask, no FastAPI: no asumir schemas Pydantic ni dependencias de FastAPI.
- Buscar siempre el flujo hermano (por ejemplo hogar/vial en WhatsApp) antes de dar el fix por completo.
- No proponer cambios hasta tener la cadena completa.
