# BUG-56B60FEE — Sucursales según la póliza aunque se capture otra ubicación

- Proyecto: Micrositio Autorelevo · SIT · Alta · reportó QA el 27 nov 2026
- Rama: `fix/BUG-56B60FEE` en K2-Full-Portal (desde `origin/dev`)

## Síntoma

Con el check "otra ubicación" y un estado y municipio distintos, la pantalla de selección de sucursal (`/estado/sucursal`) lista solo las sucursales de la dirección de la póliza (folio K2-686 en test).

## Rastreo

1. Micrositio `k2-api.service.ts` `crearTicket()` manda `boleta_informativa.estado_entrega_id` y `municipio_entrega_id` en el POST de tickets.
2. K2 `auto_relevo_boleta_service.py` `create_ticket()` pasa el payload por `parser_sinister_to_boleta()`, que reconstruye `boleta_informativa` y solo copiaba `motivo_servicio_id`.
3. `auto_relevo_data_manager.create_boleta_informativa()` lee `estado_entrega_id`/`municipio_entrega_id` de ese dict, así que se guardaban en `NULL`.
4. `serialize_servicio()` devuelve `estado_entrega`/`municipio_entrega` en `None` y `sucursal.component.ts` cae a la ubicación de la sesión (póliza).

`update_ticket` sí respeta los campos; el admin no los envía.

## Fix

`parser_sinister_to_boleta()` copia `motivo_servicio_id`, `estado_entrega_id` y `municipio_entrega_id` de `payload["boleta_informativa"]`.

## Pruebas

- Prueba del parser con y sin ubicación de entrega: ok.
- Pendiente: crear un folio nuevo con otra ubicación en dev/test y revisar las sucursales. Los folios ya creados (K2-686) siguen sin ubicación de entrega.
