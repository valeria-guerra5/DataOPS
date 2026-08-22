-- =============================================================================
-- Momento 2 · Rueda Libre — Arquitectura de la cuenta Snowflake como código
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Warehouse — dimensionado mínimo, se apaga solo
-- -----------------------------------------------------------------------------
CREATE WAREHOUSE IF NOT EXISTS WH_TALLER
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Warehouse único del taller Rueda Libre. XSMALL basta: volumen de datos pequeño (Momento 1).';

-- -----------------------------------------------------------------------------
-- 2. Base de datos y esquemas por dominio
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS RUEDA_LIBRE
  COMMENT = 'Data warehouse de Rueda Libre — Momento 2. Storage y compute separados de Neon (OLTP).';

CREATE SCHEMA IF NOT EXISTS RUEDA_LIBRE.RAW
  COMMENT = 'Aterrizaje crudo de las tablas relacionales extraídas de Neon (ELT, patrón Sesión 4).';

CREATE SCHEMA IF NOT EXISTS RUEDA_LIBRE.ORDENES
  COMMENT = 'Ordenes de fuentes semi-estructuradas vía internal stage que simula external stage.';

-- -----------------------------------------------------------------------------
-- 3. Rol de servicio para la ingesta
-- -----------------------------------------------------------------------------
CREATE ROLE IF NOT EXISTS TALLER_LOADER
  COMMENT = 'Rol de servicio: solo puede cargar datos (COPY INTO / write_pandas / DDL de sus propias tablas). No ve nada de negocio más allá de lo que carga.';

GRANT USAGE ON WAREHOUSE WH_TALLER TO ROLE TALLER_LOADER;
GRANT USAGE ON DATABASE RUEDA_LIBRE TO ROLE TALLER_LOADER;

GRANT USAGE, CREATE TABLE, CREATE STAGE, CREATE FILE FORMAT
  ON SCHEMA RUEDA_LIBRE.RAW TO ROLE TALLER_LOADER;
GRANT USAGE, CREATE TABLE, CREATE STAGE, CREATE FILE FORMAT
  ON SCHEMA RUEDA_LIBRE.ORDENES TO ROLE TALLER_LOADER;

GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA RUEDA_LIBRE.RAW TO ROLE TALLER_LOADER;
GRANT ALL PRIVILEGES ON FUTURE TABLES IN SCHEMA RUEDA_LIBRE.ORDENES TO ROLE TALLER_LOADER;

GRANT ROLE TALLER_LOADER TO USER VGUERRAZ5;

-- -----------------------------------------------------------------------------
-- 4. Verificación
-- -----------------------------------------------------------------------------
SHOW WAREHOUSES LIKE 'WH_TALLER';
SHOW DATABASES LIKE 'RUEDA_LIBRE';
SHOW SCHEMAS IN DATABASE RUEDA_LIBRE;
SHOW ROLES LIKE 'TALLER_LOADER';
SHOW GRANTS TO ROLE TALLER_LOADER;
