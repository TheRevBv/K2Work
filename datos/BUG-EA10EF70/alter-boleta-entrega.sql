-- BUG-EA10EF70: ubicación donde el asegurado requiere el auto (si no es la de la póliza),
-- con ids del catálogo state/district.
ALTER TABLE boleta_informativa
  ADD COLUMN estado_entrega_id INT NULL AFTER motivo_activacion_servicio,
  ADD COLUMN municipio_entrega_id INT NULL AFTER estado_entrega_id,
  ADD CONSTRAINT fk_boleta_informativa_estado_entrega FOREIGN KEY (estado_entrega_id) REFERENCES state (id),
  ADD CONSTRAINT fk_boleta_informativa_municipio_entrega FOREIGN KEY (municipio_entrega_id) REFERENCES district (id);

-- Rollback:
-- ALTER TABLE boleta_informativa
--   DROP FOREIGN KEY fk_boleta_informativa_municipio_entrega,
--   DROP FOREIGN KEY fk_boleta_informativa_estado_entrega,
--   DROP COLUMN municipio_entrega_id,
--   DROP COLUMN estado_entrega_id;
