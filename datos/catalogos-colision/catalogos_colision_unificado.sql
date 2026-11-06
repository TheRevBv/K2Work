-- ===========================================================================
-- K2 Colisión - Catálogos (script unificado: 005 + 006 + 007)
-- Tabla: catalog_equivalence (grouper_='TYPOLOGIES_CRM', padre value_='sinister')
--
--   PARTE 1 (005): tipo de solicitante, tipo de vehículo y estado del vehículo
--   PARTE 2 (006): catálogo "Ubicación actual - Tipo de localización"
--   PARTE 3 (007): homologar "Área Robos" -> "Robos"
--   PARTE 4      : rollback (comentado, correr a mano en orden inverso)
--
-- Requerimiento de Victor, acuerdo con Operación. Los valores que ya no se usan
-- se desactivan (status=0, sin borrar) para que los folios existentes conserven
-- su valor. Idempotente.
--
-- ANTES DE CORRER: revisar el bloque PREVIEW de la parte 1 y validar con
-- Operación la lista de lo que se desactiva. Cada parte tiene su propio
-- START TRANSACTION / COMMIT; revisar el SELECT de verificación antes del COMMIT.
-- ===========================================================================

SET SQL_SAFE_UPDATES = 0;


-- ###########################################################################
-- PARTE 1 (005): tipo de solicitante / tipo de vehículo / estado del vehículo
-- ###########################################################################

SELECT id INTO @p_applicant FROM catalog_equivalence
 WHERE grouper_='TYPOLOGIES_CRM' AND from_ IS NULL AND value_='sinister'
   AND equivalence_='sinister_applicant_type' AND status=1 LIMIT 1;
SELECT id INTO @p_vehicle FROM catalog_equivalence
 WHERE grouper_='TYPOLOGIES_CRM' AND from_ IS NULL AND value_='sinister'
   AND equivalence_='sinister_vehicle_type' AND status=1 LIMIT 1;
SELECT id INTO @p_state FROM catalog_equivalence
 WHERE grouper_='TYPOLOGIES_CRM' AND from_ IS NULL AND value_='sinister'
   AND equivalence_='sinister_vehicle_state' AND status=1 LIMIT 1;

SELECT @p_applicant AS applicant_parent, @p_vehicle AS vehicle_parent, @p_state AS state_parent;
-- Si alguno sale NULL, DETENERSE.

-- PREVIEW: estado actual de los 3 catálogos
SELECT from_, id, value_, to_, equivalence_, description, status
  FROM catalog_equivalence
 WHERE grouper_='TYPOLOGIES_CRM' AND from_ IN (CAST(@p_applicant AS CHAR), CAST(@p_vehicle AS CHAR), CAST(@p_state AS CHAR))
 ORDER BY from_, CAST(equivalence_ AS UNSIGNED);

-- Respaldo (para rollback)
DROP TABLE IF EXISTS bk_005_catalog_equivalence;
CREATE TABLE bk_005_catalog_equivalence AS
SELECT id, status FROM catalog_equivalence
 WHERE grouper_='TYPOLOGIES_CRM' AND from_ IN (CAST(@p_applicant AS CHAR), CAST(@p_vehicle AS CHAR), CAST(@p_state AS CHAR));

START TRANSACTION;

-- 1.1) Tipo de solicitante: agregar Ajustador, Dependencia, Centro de Valuación,
--      Área Robos, Otro (si ya existen se reactivan en el paso 1.3)
INSERT INTO catalog_equivalence (grouper_, from_, to_, value_, equivalence_, description, status)
SELECT 'TYPOLOGIES_CRM', CAST(@p_applicant AS CHAR),
       (SELECT to_ FROM catalog_equivalence WHERE from_=CAST(@p_applicant AS CHAR) AND grouper_='TYPOLOGIES_CRM' LIMIT 1),
       NULL,
       CAST((SELECT IFNULL(MAX(CAST(equivalence_ AS UNSIGNED)),0) FROM catalog_equivalence
              WHERE from_=CAST(@p_applicant AS CHAR) AND grouper_='TYPOLOGIES_CRM') + n.ord AS CHAR),
       n.label, 1
  FROM (SELECT 1 ord, 'Ajustador' label UNION ALL SELECT 2, 'Dependencia'
        UNION ALL SELECT 3, 'Centro de Valuación' UNION ALL SELECT 4, 'Área Robos'
        UNION ALL SELECT 5, 'Otro') n
 WHERE NOT EXISTS (SELECT 1 FROM catalog_equivalence c
                    WHERE c.from_=CAST(@p_applicant AS CHAR) AND c.grouper_='TYPOLOGIES_CRM'
                      AND LOWER(TRIM(c.description))=LOWER(n.label));

-- 1.2) Estado del vehículo: agregar Daño parcial / Pérdida total evidente
INSERT INTO catalog_equivalence (grouper_, from_, to_, value_, equivalence_, description, status)
SELECT 'TYPOLOGIES_CRM', CAST(@p_state AS CHAR),
       (SELECT to_ FROM catalog_equivalence WHERE from_=CAST(@p_state AS CHAR) AND grouper_='TYPOLOGIES_CRM' LIMIT 1),
       NULL,
       CAST((SELECT IFNULL(MAX(CAST(equivalence_ AS UNSIGNED)),0) FROM catalog_equivalence
              WHERE from_=CAST(@p_state AS CHAR) AND grouper_='TYPOLOGIES_CRM') + n.ord AS CHAR),
       n.label, 1
  FROM (SELECT 1 ord, 'Daño parcial' label UNION ALL SELECT 2, 'Pérdida total evidente') n
 WHERE NOT EXISTS (SELECT 1 FROM catalog_equivalence c
                    WHERE c.from_=CAST(@p_state AS CHAR) AND c.grouper_='TYPOLOGIES_CRM'
                      AND LOWER(TRIM(c.description))=LOWER(n.label));

-- 1.3) Activar lo que se queda y desactivar lo que sobra
--      (Equipo ligero/pesado conservan su nombre: Qonect no se afecta.
--       "Pérdida total" se deja activa porque WhatsApp manda ese texto.)
UPDATE catalog_equivalence
   SET status = CASE WHEN LOWER(TRIM(description)) IN
                ('ajustador','dependencia','centro de valuación','área robos','otro') THEN 1 ELSE 0 END
 WHERE grouper_='TYPOLOGIES_CRM' AND from_=CAST(@p_applicant AS CHAR);

UPDATE catalog_equivalence
   SET status = CASE WHEN LOWER(TRIM(description)) IN
                ('equipo ligero','equipo pesado') THEN 1 ELSE 0 END
 WHERE grouper_='TYPOLOGIES_CRM' AND from_=CAST(@p_vehicle AS CHAR);

UPDATE catalog_equivalence
   SET status = CASE WHEN LOWER(TRIM(description)) IN
                ('daño parcial','pérdida total evidente','pérdida total') THEN 1 ELSE 0 END
 WHERE grouper_='TYPOLOGIES_CRM' AND from_=CAST(@p_state AS CHAR);

-- Verificación: revisar antes del COMMIT
SELECT c.from_, c.id, c.value_, c.description, c.status,
       CASE WHEN b.id IS NULL THEN 'NUEVO'
            WHEN b.status <> c.status THEN 'CAMBIÓ' ELSE '' END AS cambio
  FROM catalog_equivalence c
  LEFT JOIN bk_005_catalog_equivalence b ON b.id = c.id
 WHERE c.grouper_='TYPOLOGIES_CRM' AND c.from_ IN (CAST(@p_applicant AS CHAR), CAST(@p_vehicle AS CHAR), CAST(@p_state AS CHAR))
 ORDER BY c.from_, c.status DESC, CAST(c.equivalence_ AS UNSIGNED);

-- Si todo cuadra:
COMMIT;
-- Si no:  ROLLBACK;


-- ###########################################################################
-- PARTE 2 (006): catálogo "Ubicación actual - Tipo de localización"
--   padre : grouper_='TYPOLOGIES_CRM', from_=NULL, value_='sinister',
--           equivalence_='sinister_location_type'
--   hijos : equivalence_ = ID numérico que se guarda en assistance_case.location_type
--           (10-14, los mismos que ya usa la lista fija; 1-9 son históricos y
--           NO se insertan, el admin los sigue mostrando con su mapa fijo)
--           value_ = orden en el selector
--   Si esta parte no se corre, el admin sigue funcionando con la lista fija.
-- ###########################################################################

START TRANSACTION;

-- Padre (copia to_/equivalence2_ de un catálogo hermano para mantener el formato)
INSERT INTO catalog_equivalence (grouper_, from_, to_, value_, equivalence_, equivalence2_, description, status)
SELECT 'TYPOLOGIES_CRM', NULL, s.to_, 'sinister', 'sinister_location_type', s.equivalence2_,
       'Ubicación actual - Tipo de localización', 1
  FROM catalog_equivalence s
 WHERE s.grouper_='TYPOLOGIES_CRM' AND s.from_ IS NULL AND s.value_='sinister'
   AND s.equivalence_='sinister_vehicle_type' AND s.status=1
   AND NOT EXISTS (SELECT 1 FROM catalog_equivalence p
                    WHERE p.grouper_='TYPOLOGIES_CRM' AND p.from_ IS NULL
                      AND p.value_='sinister' AND p.equivalence_='sinister_location_type')
 LIMIT 1;

SELECT id INTO @p_location FROM catalog_equivalence
 WHERE grouper_='TYPOLOGIES_CRM' AND from_ IS NULL AND value_='sinister'
   AND equivalence_='sinister_location_type' LIMIT 1;

SELECT @p_location AS location_parent;  -- si sale NULL: ROLLBACK

-- Hijos
INSERT INTO catalog_equivalence (grouper_, from_, to_, value_, equivalence_, description, status)
SELECT 'TYPOLOGIES_CRM', CAST(@p_location AS CHAR), '20', n.ord, n.loc_id, n.label, 1
  FROM (SELECT '1' ord, '10' loc_id, 'ZONA NO CONCESIONADA' label
        UNION ALL SELECT '2', '11', 'ZONA CONCESIONADA'
        UNION ALL SELECT '3', '12', 'TALLER/AGENCIA'
        UNION ALL SELECT '4', '13', 'CORRALÓN (LIBERACIÓN PROCESO LEGAL)'
        UNION ALL SELECT '5', '14', 'CORRALÓN PROVEEDOR FUERA DE RED') n
 WHERE @p_location IS NOT NULL
   AND NOT EXISTS (SELECT 1 FROM catalog_equivalence c
                    WHERE c.grouper_='TYPOLOGIES_CRM' AND c.from_=CAST(@p_location AS CHAR)
                      AND c.equivalence_=n.loc_id);

-- Verificación
SELECT id, from_, value_, equivalence_, description, status
  FROM catalog_equivalence
 WHERE grouper_='TYPOLOGIES_CRM' AND (id=@p_location OR from_=CAST(@p_location AS CHAR))
 ORDER BY from_ IS NOT NULL, CAST(value_ AS UNSIGNED);

COMMIT;


-- ###########################################################################
-- PARTE 3 (007): homologar "Área Robos" -> "Robos"
--   El admin guarda la DESCRIPCIÓN en sinister.applicant_type; sin esto el
--   selector queda vacío al editar folios históricos.
--   Documento de negocio: Ajustador, Dependencia, Centro de Valuación, Robos, Otro.
-- ###########################################################################

START TRANSACTION;

SELECT id INTO @p_applicant FROM catalog_equivalence
 WHERE grouper_='TYPOLOGIES_CRM' AND from_ IS NULL AND value_='sinister'
   AND equivalence_='sinister_applicant_type' LIMIT 1;

UPDATE catalog_equivalence SET description='Robos'
 WHERE from_=CAST(@p_applicant AS CHAR) AND description='Área Robos';

UPDATE sinister SET applicant_type='Robos' WHERE applicant_type='Área Robos';

COMMIT;


-- ###########################################################################
-- PARTE 4: ROLLBACK (comentado). Correr a mano, en este orden: 007 -> 006 -> 005
-- ###########################################################################

-- ---- Rollback 007 ---------------------------------------------------------
-- SELECT id INTO @p_applicant FROM catalog_equivalence WHERE grouper_='TYPOLOGIES_CRM'
--   AND from_ IS NULL AND value_='sinister' AND equivalence_='sinister_applicant_type' LIMIT 1;
-- UPDATE catalog_equivalence SET description='Área Robos' WHERE from_=CAST(@p_applicant AS CHAR) AND description='Robos';
-- UPDATE sinister SET applicant_type='Área Robos' WHERE applicant_type='Robos';

-- ---- Rollback 006 ---------------------------------------------------------
-- (al quitar el catálogo el admin regresa a su lista fija, mismos IDs 10-14)
-- START TRANSACTION;
-- SELECT id INTO @p_location FROM catalog_equivalence
--  WHERE grouper_='TYPOLOGIES_CRM' AND from_ IS NULL AND value_='sinister'
--    AND equivalence_='sinister_location_type' LIMIT 1;
-- DELETE FROM catalog_equivalence WHERE grouper_='TYPOLOGIES_CRM' AND from_=CAST(@p_location AS CHAR);
-- DELETE FROM catalog_equivalence WHERE id=@p_location;
-- SELECT COUNT(*) AS debe_ser_0 FROM catalog_equivalence
--  WHERE grouper_='TYPOLOGIES_CRM' AND equivalence_='sinister_location_type';
-- COMMIT;

-- ---- Rollback 005 ---------------------------------------------------------
-- Requiere la tabla bk_005_catalog_equivalence; si no existe, NO correr.
-- Si algún folio ya usó los registros nuevos, cambiar el DELETE por
-- UPDATE ... SET status=0 (el valor queda guardado como texto en el folio).
-- SELECT id INTO @p_applicant FROM catalog_equivalence
--  WHERE grouper_='TYPOLOGIES_CRM' AND from_ IS NULL AND value_='sinister'
--    AND equivalence_='sinister_applicant_type' AND status=1 LIMIT 1;
-- SELECT id INTO @p_vehicle FROM catalog_equivalence
--  WHERE grouper_='TYPOLOGIES_CRM' AND from_ IS NULL AND value_='sinister'
--    AND equivalence_='sinister_vehicle_type' AND status=1 LIMIT 1;
-- SELECT id INTO @p_state FROM catalog_equivalence
--  WHERE grouper_='TYPOLOGIES_CRM' AND from_ IS NULL AND value_='sinister'
--    AND equivalence_='sinister_vehicle_state' AND status=1 LIMIT 1;
-- SELECT COUNT(*) AS filas_respaldo FROM bk_005_catalog_equivalence;
-- START TRANSACTION;
-- UPDATE catalog_equivalence c JOIN bk_005_catalog_equivalence b ON b.id = c.id SET c.status = b.status;
-- DELETE c FROM catalog_equivalence c
--   LEFT JOIN bk_005_catalog_equivalence b ON b.id = c.id
--  WHERE c.grouper_='TYPOLOGIES_CRM'
--    AND c.from_ IN (CAST(@p_applicant AS CHAR), CAST(@p_vehicle AS CHAR), CAST(@p_state AS CHAR))
--    AND b.id IS NULL;
-- COMMIT;
-- DROP TABLE bk_005_catalog_equivalence;  -- solo cuando ya no se necesite
