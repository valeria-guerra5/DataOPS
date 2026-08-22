-- =============================================================================
-- Momento 2 · Rueda Libre — DAG de Tasks: ingesta + aplanado de diagnósticos
-- =============================================================================

USE WAREHOUSE WH_TALLER;
USE DATABASE RUEDA_LIBRE;
USE SCHEMA ORDENES;

GRANT EXECUTE TASK ON ACCOUNT TO ROLE TALLER_LOADER;

-- -----------------------------------------------------------------------------
-- 1. Crear el DAG — nace suspendido, siempre
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TASK TASK_INGEST_ORDENES_DIAGNOSTICO
  WAREHOUSE = WH_TALLER
  SCHEDULE = 'USING CRON 0 * * * * America/Bogota'
AS
  COPY INTO RAW_ORDENES_DIAGNOSTICO (raw_data)
  FROM (
      SELECT $1
      FROM @rueda_libre_stage
  )
  FILE_FORMAT = (FORMAT_NAME = rueda_libre_json_format);

CREATE OR REPLACE TASK TASK_FLATTEN_ORDENES_DIAGNOSTICO
  WAREHOUSE = WH_TALLER
  AFTER TASK_INGEST_ORDENES_DIAGNOSTICO
AS
  INSERT OVERWRITE INTO STG_ORDENES_DIAGNOSTICO (
      external_order_ref, opened_at, priority, customer_name, customer_bank_account, contact_channel,
      bike_nickname, bike_category, estimated_hours, customer_authorized, requested_task
  )
  SELECT
      raw_data:external_order_ref::STRING,
      raw_data:opened_at::TIMESTAMP_NTZ,
      raw_data:priority::STRING,
      raw_data:customer.name::STRING,
      raw_data:customer.bank_account::STRING,
      raw_data:customer.contact.channel::STRING,
      raw_data:bike.nickname::STRING,
      raw_data:bike.category::STRING,
      raw_data:work.estimated_hours::FLOAT,
      raw_data:work.customer_authorized::BOOLEAN,
      t.value::STRING
  FROM RAW_ORDENES_DIAGNOSTICO,
       LATERAL FLATTEN(input => raw_data:work.requested_tasks) t;

SHOW TASKS;

-- -----------------------------------------------------------------------------
-- 2. Activar el DAG completo de una sola vez
-- -----------------------------------------------------------------------------

ALTER TASK TASK_FLATTEN_ORDENES_DIAGNOSTICO RESUME;
ALTER TASK TASK_INGEST_ORDENES_DIAGNOSTICO RESUME;

SHOW TASKS; -- Ambas deberían aparecer en estado "started".

-- -----------------------------------------------------------------------------
-- 3. Disparar sin esperar el CRON (para la demo / sustentación)
-- -----------------------------------------------------------------------------
EXECUTE TASK TASK_INGEST_ORDENES_DIAGNOSTICO;

-- -----------------------------------------------------------------------------
-- 4. Ver qué pasó — primera parada para depurar, antes que cualquier log de
--    aplicación (aquí no existe ninguno: todo el pipeline vive en Snowflake).
-- -----------------------------------------------------------------------------
SELECT *
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY())
WHERE database_name = 'RUEDA_LIBRE'
ORDER BY scheduled_time DESC
LIMIT 20;
