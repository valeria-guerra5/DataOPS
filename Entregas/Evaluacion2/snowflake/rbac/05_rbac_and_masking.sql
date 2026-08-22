-- =============================================================================
-- Momento 2 · Rueda Libre — RBAC, masking
-- =============================================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE WH_TALLER;
USE DATABASE RUEDA_LIBRE;
USE SCHEMA ORDENES;

CREATE ROLE IF NOT EXISTS ROLE_TALLER_TECNICO
  COMMENT = 'Mecánico que atiende el diagnóstico. Ve el dato sensible completo.';
CREATE ROLE IF NOT EXISTS ROLE_TALLER_RECEPCION
  COMMENT = 'Agenda y seguimiento. Ve el dato sensible parcialmente enmascarado.';
CREATE ROLE IF NOT EXISTS ROLE_TALLER_GERENCIA
  COMMENT = 'Métricas agregadas del taller. Nunca ve el dato sensible en claro.';

GRANT USAGE ON WAREHOUSE WH_TALLER TO ROLE ROLE_TALLER_TECNICO;
GRANT USAGE ON WAREHOUSE WH_TALLER TO ROLE ROLE_TALLER_RECEPCION;
GRANT USAGE ON WAREHOUSE WH_TALLER TO ROLE ROLE_TALLER_GERENCIA;

GRANT USAGE ON DATABASE RUEDA_LIBRE TO ROLE ROLE_TALLER_TECNICO;
GRANT USAGE ON DATABASE RUEDA_LIBRE TO ROLE ROLE_TALLER_RECEPCION;
GRANT USAGE ON DATABASE RUEDA_LIBRE TO ROLE ROLE_TALLER_GERENCIA;

GRANT USAGE ON SCHEMA ORDENES TO ROLE ROLE_TALLER_TECNICO;
GRANT USAGE ON SCHEMA ORDENES TO ROLE ROLE_TALLER_RECEPCION;
GRANT USAGE ON SCHEMA ORDENES TO ROLE ROLE_TALLER_GERENCIA;

GRANT SELECT ON TABLE STG_ORDENES_DIAGNOSTICO TO ROLE ROLE_TALLER_TECNICO;
GRANT SELECT ON TABLE STG_ORDENES_DIAGNOSTICO TO ROLE ROLE_TALLER_RECEPCION;
GRANT SELECT ON TABLE STG_ORDENES_DIAGNOSTICO TO ROLE ROLE_TALLER_GERENCIA;

GRANT ROLE ROLE_TALLER_TECNICO   TO USER VGUERRAZ5;
GRANT ROLE ROLE_TALLER_RECEPCION TO USER VGUERRAZ5;
GRANT ROLE ROLE_TALLER_GERENCIA  TO USER VGUERRAZ5;

SHOW GRANTS TO ROLE ROLE_TALLER_TECNICO;
SHOW GRANTS TO ROLE ROLE_TALLER_RECEPCION;
SHOW GRANTS TO ROLE ROLE_TALLER_GERENCIA;

SELECT * FROM STG_ORDENES_DIAGNOSTICO;

-- ----
-- MASKING POLICY 
-- ----

-- Cambio a cuenta enterprise para la creación y manejo de la masking policy
-- ALTER ACCOUNT KQ08798 SET EDITION = 'ENTERPRISE';

-- -----------------------------------------------------------------------------
-- 1. La política 
-- -----------------------------------------------------------------------------
CREATE OR REPLACE MASKING POLICY mask_customer_bank_account
  AS (val STRING) RETURNS STRING ->
  CASE
    WHEN CURRENT_ROLE() = 'ROLE_TALLER_RECEPCION' THEN val
    WHEN CURRENT_ROLE() = 'ROLE_TALLER_GERENCIA'
      THEN CONCAT('******', RIGHT(val, 4))  -- '1111111111' -> '******1111'
    ELSE '**********'  -- ROLE_TALLER_TECNICO en este caso
  END;

-- -----------------------------------------------------------------------------
-- 2. Atar la política a la columna
-- -----------------------------------------------------------------------------
ALTER TABLE STG_ORDENES_DIAGNOSTICO
  MODIFY COLUMN customer_bank_account
  SET MASKING POLICY mask_customer_bank_account;

-- -----------------------------------------------------------------------------
-- 3. Demostración esperada — mismo SELECT,
--    tres resultados distintos según el rol activo:
-- -----------------------------------------------------------------------------
USE ROLE ROLE_TALLER_TECNICO;
SELECT customer_name, customer_bank_account FROM STG_ORDENES_DIAGNOSTICO;

USE ROLE ROLE_TALLER_RECEPCION;
SELECT customer_name, customer_bank_account FROM STG_ORDENES_DIAGNOSTICO;

USE ROLE ROLE_TALLER_GERENCIA;
SELECT customer_name, customer_bank_account FROM STG_ORDENES_DIAGNOSTICO;
