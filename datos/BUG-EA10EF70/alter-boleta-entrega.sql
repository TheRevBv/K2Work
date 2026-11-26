-- BUG-EA10EF70: ubicación donde el asegurado requiere el auto (si no es la de la póliza).
ALTER TABLE boleta_informativa
  ADD COLUMN estado_entrega VARCHAR(100) NULL AFTER motivo_activacion_servicio,
  ADD COLUMN municipio_entrega VARCHAR(100) NULL AFTER estado_entrega;
