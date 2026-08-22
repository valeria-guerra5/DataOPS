-- =============================================================================
-- Momento 2 · Rueda Libre — Ingesta semi-estructurada (patrón Sesión 5)
-- Fuente: ordenes_diagnostico.json
-- =============================================================================

USE WAREHOUSE WH_TALLER;
USE DATABASE RUEDA_LIBRE;
USE SCHEMA ORDENES;

-- -----------------------------------------------------------------------------
-- 1. File Format
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FILE FORMAT rueda_libre_json_format
    TYPE = JSON
    STRIP_OUTER_ARRAY = TRUE;

-- -----------------------------------------------------------------------------
-- 2. Internal Stage
-- -----------------------------------------------------------------------------
CREATE OR REPLACE STAGE rueda_libre_stage
    FILE_FORMAT = rueda_libre_json_format;

LIST @rueda_libre_stage;

SELECT $1
FROM @rueda_libre_stage (FILE_FORMAT => rueda_libre_json_format)
LIMIT 5;

-- -----------------------------------------------------------------------------
-- 3. RAW_ORDENES_DIAGNOSTICO — la tabla de una sola columna VARIANT
-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS RAW_ORDENES_DIAGNOSTICO (
    raw_data        VARIANT
)
COMMENT = 'Aterrizaje crudo de diagnósticos externos. Sin esquema declarado de antemano (schema-on-read).';

COPY INTO RAW_ORDENES_DIAGNOSTICO (raw_data)
FROM (
    SELECT $1 FROM @rueda_libre_stage
)
FILE_FORMAT = (FORMAT_NAME = rueda_libre_json_format);

SELECT COUNT(*) FROM RAW_ORDENES_DIAGNOSTICO;


