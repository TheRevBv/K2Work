# CDSEBAU-57 — Micrositio Autorelevo v2

## Hallazgos

### 2026-11-04: 500 en `GET /api/v1/boleta-informativa/auto-relevo/tickets`

- Error: `Unknown column 'boleta_informativa_1.numero_reservacion'` en `/admin/relevo-car` (`micrositio-autorelevo-2`, morfeo-dev).
- Causa: el commit `2325fcdc` (código v2) declara columnas en `auto_relevo_boleta_models.py:49,59,60` que no existían en dev.
- Fix: el usuario aplicó el `ALTER` en dev; las columnas quedaron verificadas con `SHOW COLUMNS`.

```sql
ALTER TABLE boleta_informativa
  ADD COLUMN numero_reservacion VARCHAR(100) NULL AFTER folio_servicio,
  ADD COLUMN evaluador_aprobo_servicio TINYINT(1) NULL AFTER tiempo_asignacion,
  ADD COLUMN motivo_evaluacion_servicio TEXT NULL AFTER evaluador_aprobo_servicio;
```

## Pendientes

- Confirmar el 200 del endpoint con sesión iniciada (sin token responde 401).
- Incluir el `ALTER` en el script de liberación del CDM y revisar test y prod: no hay migración alembic para estas tablas.
- Filas con NULL en dev (de 656): `mes_solicitud` 121, `total_dias_journey` 521, `tiempo_autorizacion_valuacion` 515, `tiempo_asignacion` 500. El modelo las declara `nullable=False`; revisar si afectan la respuesta.

## Integración

- 2026-11-04: `2325fcdc` integrado a `dev` de `origin` (TheRevBv/K2-Full-Portal) por fast-forward, sin PR; `dev` estaba en `cf95bb9d`. Entraron 15 commits, incluidos importador y reporte AVASA.
