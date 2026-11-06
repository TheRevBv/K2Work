# CDS Time Tracker

Página: `https://storage.googleapis.com/morfeo-cds-herramientas-html/timetracker.html` (HTML estático).
API: `https://fn-rti-ayk3x7mm3q-ue.a.run.app` (Cloud Run). Cliente: `bin/k2-timetracker`.
Accesos: `~/Documentos/ObsidianVault/Trabajo/Cds/timetracker.env` (`TIMETRACKER_USER`, `TIMETRACKER_PASSWORD`).

Todas las llamadas llevan `Authorization: Bearer <token>` y `Content-Type: application/json`.

## Endpoints

| Método | Ruta | Uso |
|---|---|---|
| POST | `/tt/auth/login` | `{email, password}` → `{token, ...}` (la página lo guarda en `localStorage.tt_session`) |
| POST | `/tt/auth/logout` | cierra la sesión |
| GET | `/tt/proyectos?date=YYYY-MM-DD` | proyectos disponibles ese día |
| GET | `/tt/catalogos` | catálogos; para capturar solo importa `bau_actividades` |
| GET | `/tt/horas?month=YYYY-MM` | días capturados del mes (propios; admin: `&email=`) |
| GET | `/tt/horas/all?month=YYYY-MM` | vista de equipo (admin) |
| POST | `/tt/horas` | guarda **el día completo** (reemplaza lo que haya) → `{ok: true}` |

### `GET /tt/proyectos`

```json
{"codigo": "2026_58P_MicrositioAutorelevo", "nombre": "Micrositio Autorelevo",
 "estado": "En proceso", "tipo": "Proyecto", "bucket": "New Business"}
```

- `estado`: `En proceso`, `QA`, `Diseño`, `Dependencias`, `Finalizado` (nombre con ✓), `Cancelado`, `activo`.
- Especiales: `BAU` (BAU / Soporte, exige `actividad_bau`) y `VAC` (Vacaciones, `excluir_costo`).

### `GET /tt/catalogos`

Claves: `areas`, `autorizadores`, `buckets`, `proyectos_padre`, `lideres_tecnicos`, `lideres_proyecto`, `bau_actividades`.
`bau_actividades`: Proceso Reversa de folios, Incidencias Qonect, Incidencias Konecta, Incidencias telefonía,
Incidencias Blip, Incidencias Meli, Administración de telefonía, Capacitación, Documentación, Incidencias SAP,
Incidencias K2, Reset de cuenta de usuario, Apoyo en infraestructura.

### `GET /tt/horas?month=`

```json
{"email": "...", "fecha": "2026-10-05", "total": 8, "timestamp": "...",
 "entradas": [{"codigo": "2026_58P_MicrositioAutorelevo", "nombre": "Micrositio Autorelevo", "horas": 7,
               "descripcion": "...", "capex_opex": "CAPEX", "bucket": "Operations Management", "tipo_proyecto": "Proyecto"}]}
```

`capex_opex`, `bucket` y `tipo_proyecto` los rellena el servidor; no se mandan.
Proyectos finalizados (ej. `2026_62R_MejorasGruas2.0`) se guardan con `capex_opex: ""`, también desde la página; no se corrige desde el cliente.

### `POST /tt/horas`

```json
{"fecha": "2026-10-12",
 "entradas": [
   {"codigo": "2026_5P_ColisiónAjusteMóvil-F4", "nombre": "Colisión Ajuste Móvil - F4", "horas": 4, "descripcion": "..."},
   {"codigo": "BAU", "nombre": "BAU / Soporte", "horas": 1, "descripcion": "...", "actividad_bau": "Incidencias K2"}]}
```

Respuesta: `{"ok": true, "total": 8.0}` (`total` = horas del día ya guardado).

Headers que manda la página: `authorization: Bearer <token>` (token tipo UUID, no JWT),
`content-type: application/json`, `referer: https://storage.googleapis.com/`. No hace falta cookie.

Reglas de la página: una entrada por `codigo` (filas repetidas se suman y las descripciones se unen con ` / `),
`descripcion` obligatoria, BAU exige `actividad_bau`, total ≤ 24 h. Verde a 8 h, rojo arriba de 8.

## Proyectos que uso

| Trabajo | Código |
|---|---|
| Dailies, weeklies, soporte, análisis | `BAU` (Incidencias K2 / Documentación) |
| Micrositio y autorelevo | `2026_58P_MicrositioAutorelevo` |
| Ajuste móvil (volante, colisión) | `2026_5P_ColisiónAjusteMóvil-F4` |
