-- =============================================================================
-- Momento 2 · Rueda Libre — Notación de punto y LATERAL FLATTEN
-- =============================================================================
-- El array anidado que justifica FLATTEN aquí es `work.requested_tasks`:
-- cada diagnóstico puede pedir 1 o varios servicios (2 en dos de los tres
-- diagnósticos del dataset, 3 en el tercero). Tratamos cada diagnóstico como
-- una "factura" y cada tarea solicitada como uno de sus "ítems": FLATTEN
-- multiplica la fila padre una vez por cada tarea.
-- =============================================================================

USE WAREHOUSE WH_TALLER;
USE DATABASE RUEDA_LIBRE;
USE SCHEMA ORDENES;

SELECT
    raw_data:external_order_ref::STRING          AS external_order_ref,
    raw_data:opened_at::TIMESTAMP_NTZ             AS opened_at,
    raw_data:priority::STRING                     AS priority,
    raw_data:customer.name::STRING                AS customer_name,
    raw_data:customer.bank_account::STRING        AS customer_bank_account,
    raw_data:customer.contact.channel::STRING     AS contact_channel,
    raw_data:bike.nickname::STRING                AS bike_nickname,
    raw_data:bike.category::STRING                AS bike_category,
    raw_data:work.estimated_hours::FLOAT          AS estimated_hours,
    raw_data:work.customer_authorized::BOOLEAN    AS customer_authorized,
    t.value::STRING                               AS requested_task
FROM RAW_ORDENES_DIAGNOSTICO,
     LATERAL FLATTEN(input => raw_data:work.requested_tasks) t
ORDER BY external_order_ref, t.index;

CREATE TABLE IF NOT EXISTS STG_ORDENES_DIAGNOSTICO (
    external_order_ref   STRING,
    opened_at            TIMESTAMP_NTZ,
    priority             STRING,
    customer_name        STRING,   
    customer_bank_account STRING,   -- PII: protegida con Masking Policy
    contact_channel      STRING,
    bike_nickname        STRING,
    bike_category        STRING,
    estimated_hours      FLOAT,
    customer_authorized  BOOLEAN,
    requested_task       STRING,
    _loaded_at           TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
)
COMMENT = 'Diagnósticos externos aplanados (1 fila por tarea solicitada). Fuente para RBAC/Masking.';

TRUNCATE TABLE STG_ORDENES_DIAGNOSTICO;

INSERT INTO STG_ORDENES_DIAGNOSTICO (
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
FROM ORDENES.RAW_ORDENES_DIAGNOSTICO,
     LATERAL FLATTEN(input => raw_data:work.requested_tasks) t;

SELECT * FROM STG_ORDENES_DIAGNOSTICO ORDER BY external_order_ref;
-- Esperado: 7 filas, 3 external_order_ref distintos.
