# BUG-EA10EF70 — Estado y Municipio donde se requiere el auto

**Ticket:** el asegurado no puede indicar que necesita el auto en otra ubicación distinta a la de su póliza.

## Hallazgos
- La sucursal de AVASA se elige después de la autorización, en otra sesión: `micrositio sucursal.component.ts` filtraba con `session().municipio/estado` (dirección de la póliza del login).
- K2 no tenía dónde guardar la ubicación de entrega (`boleta_informativa` sin campo; `ubicacion_titular` es la del titular). Alembic no versiona estas tablas: cambios por script SQL.

## Fix (decidido con el usuario: casilla en captura + campos en K2)
- **SQL** `datos/BUG-EA10EF70/alter-boleta-entrega.sql`: `estado_entrega_id` (FK `state.id`) y `municipio_entrega_id` (FK `district.id`) en `boleta_informativa`. El micrositio usa selects con `GET /api/v1/boleta-informativa/auto-relevo/catalogo/estados` y `.../catalogo/estados/<id>/municipios`, que devuelven `{data: [{value, label}]}` de la A a la Z (México = country 1); el detalle del folio devuelve también los nombres porque AVASA busca sucursales por nombre.
- **K2** (`fix/BUG-EA10EF70`): modelo, alta (`create_boleta_informativa`), edición (`_update_boleta_informativa`) y serialización (`related_models`).
- **Micrositio** (`fix/BUG-EA10EF70`, base = dev de la VDI `5a46ea0`): casilla "¿Necesitas el auto en otra ubicación?" con Estado/Municipio obligatorios; `crearTicket` los manda en `boleta_informativa`; `mapearFolio` los lee; sucursal los usa antes que la dirección de la póliza.
- Parches: `datos/BUG-EA10EF70/{k2,micrositio}-ubicacion-entrega.patch`.

## Pendiente
- Ejecutar el SQL en dev **antes** de desplegar K2 (si no, SQLAlchemy falla al leer la boleta).
- Tests de backend no corridos aquí (sin pytest local).
