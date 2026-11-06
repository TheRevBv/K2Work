# Micrositio Autorelevo

Micrositio para que el asegurado de Chubb solicite un vehículo de reemplazo (Auto Relevo) cuando su vehículo está fuera de circulación. Consume el backend de K2 (Flask) y, para reservación, AVASA. El análisis de contexto y el prompt original están en [`Autorelevo_Contexto_y_Prompt_Codex.md`](Autorelevo_Contexto_y_Prompt_Codex.md), cuya fuente de requisitos es el PRD de Confluence "PRD Micrositio AutoRelevo" (espacio CDS1).

## Alcance

- Responsable de este espacio: Joshua (solicitud rechazada, carga de documentos, flujos de pérdida parcial, pérdida total, detención legal y avería mecánica).
- Reservación de vehículo: Donovan (fuera de alcance aquí; dependencias compartidas: tipo de plan y estatus "servicio autorizado").

## Repositorios y variantes

Reglas de uso: skill `k2-autorelevo`. Ubicados en `../` (`~/github` es un symlink a `~/Código`, no son copias).

| Directorio | Qué es |
|---|---|
| `micrositio-autorelevo-real` | Único repo de trabajo. Contiene todas las ramas, incluida `CDSEBAU-39-Autorelevo-v2`; se cambia de contexto con `git switch` |

El 2026-11-03 se borró `K2-micrositio-autorelevo` (solo caché) y se quitaron los worktrees `autorelevo-fix`, `autorelevo-review` y `autorelevo-vdi`; sus ramas siguen en `-real`.

El 2026-11-05 se consolidó todo en `-real`: se borró `micrositio-autorelevo` y se quitó el worktree `autorelevo-infra`. La `wip` del repo borrado quedó como `wip/respaldo-2026-09-26-micrositio`.

## Documentación en el repo del micrositio

`micrositio-autorelevo/docs/`: `ANALISIS-MICROSITIO-REAL.md`, `CAMBIOS-TEMPORALES-VS-VDI.md`, `DIAGNOSTICO-K2.md`, `INSTRUCCIONES-FASE2.md`, `INSTRUCCIONES-FASE2-RONDA2.md`, `REANALISIS-2026-09-24.md`, `patches/`, `scripts/` y respaldos JSON de cancelaciones y cierres de folios.

## Backend relacionado

- Código K2: `apiserver/ix/boletas_informativas/auto_relevo/api/` y admin `admin/src/app/app-modules/relevo-car/`.
- Rol de operador: `operador_autorelevo` (`apiserver/ix/config/baseconfig.py`).
- Identificadores distintos: `ServicioAutoRelevo.id` (ticket, `GET /tickets/{id}`), `BoletaInformativa.id` y `folio_servicio`, `hash_id` de documentos.

## Ejecución del cascarón

Node 20.20.2. `npx nx serve autorelevo`; OTP de prueba `123456`. Validación: `npx nx lint autorelevo`, `npx nx test autorelevo`, `npx nx build autorelevo`, `npx nx e2e autorelevo-e2e`.

Credenciales de prueba del API de K2: las credenciales de prueba están en el .env del apiserver (ver skill k2-autorelevo).
