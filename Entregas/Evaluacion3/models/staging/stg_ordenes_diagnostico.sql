-- Silver semi-estructurado: mismo trabajo que un modelo Silver relacional (cast,
-- rename, sin lógica de negocio) pero además incluye el LATERAL FLATTEN que en el
-- Momento 2 vivía en snowflake/json/03_materializar_staging.sql. Aquí es donde le
-- corresponde: el aplanado ES la traducción de "fuente cruda" a "algo con forma de
-- tabla" para un dato que, a diferencia de las tablas relacionales, no la tenía de
-- antemano (schema-on-read). No hay joins contra otras fuentes — eso es trabajo de
-- core/fct_diagnosticos_externos.sql.
with fuente as (

    select * from {{ source('raw_rueda_libre_json', 'raw_ordenes_diagnostico') }}

),

aplanado as (

    select
        fuente.raw_data:external_order_ref::varchar        as external_order_ref,
        fuente.raw_data:opened_at::timestamp_ntz            as opened_at,
        fuente.raw_data:priority::varchar                   as priority,
        fuente.raw_data:customer.name::varchar              as customer_name,
        fuente.raw_data:customer.contact.channel::varchar   as contact_channel,
        fuente.raw_data:bike.nickname::varchar              as bike_nickname,
        fuente.raw_data:bike.category::varchar              as bike_category,
        fuente.raw_data:work.estimated_hours::float         as estimated_hours,
        fuente.raw_data:work.customer_authorized::boolean   as customer_authorized,
        tarea.value::varchar                                as requested_task,
        tarea.index::integer                                as requested_task_index

    from fuente,
         lateral flatten(input => fuente.raw_data:work.requested_tasks, outer => true) tarea
    -- outer => true: si algún día llega un diagnóstico sin requested_tasks, el
    -- diagnóstico igual sale en el modelo (con requested_task en NULL) en vez de
    -- desaparecer silenciosamente — más seguro para un modelo Silver que se supone
    -- conserva toda la fuente.

)

select * from aplanado
