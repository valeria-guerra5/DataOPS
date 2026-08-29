-- Gold — cruza los DOS orígenes del proyecto: el canal de diagnóstico externo
-- (semi-estructurado, Momento 2) contra la base de clientes ya registrados
-- (relacional, Momento 1/2). Responde: "de los diagnósticos que llegan por el canal
-- externo, ¿cuáles son de un cliente que el taller ya conoce, y qué tan fiel es ese
-- cliente?" — la pregunta que decide si recepción llama para agendar de una vez o si
-- primero tiene que registrar al cliente.
--
-- No existe una llave compartida entre ambas fuentes (external_order_ref no es un FK
-- a ninguna tabla relacional — ver docs/decisiones_momento_3.md), así que el cruce se
-- hace por nombre normalizado. Es una decisión de diseño explícita, no un accidente:
-- es exactamente el tipo de cruce imperfecto que SÍ ocurre en la vida real cuando dos
-- sistemas que no se hablan describen a la misma persona.
--
-- Grano: 1 fila por (external_order_ref, requested_task) — el mismo grano que
-- stg_ordenes_diagnostico; cada fila gana las columnas de cliente si hubo match.
with diagnosticos as (

    select * from {{ ref('stg_ordenes_diagnostico') }}

),

clientes as (

    select * from {{ ref('stg_clientes') }}

),

diagnosticos_normalizados as (

    select
        *,
        lower(trim(customer_name)) as customer_name_normalizado
    from diagnosticos

),

clientes_normalizados as (

    select
        *,
        lower(trim(nombre)) as nombre_normalizado
    from clientes

),

final as (

    select
        diagnosticos_normalizados.external_order_ref,
        diagnosticos_normalizados.opened_at,
        diagnosticos_normalizados.priority,
        diagnosticos_normalizados.customer_name,
        diagnosticos_normalizados.contact_channel,
        diagnosticos_normalizados.bike_nickname,
        diagnosticos_normalizados.bike_category,
        diagnosticos_normalizados.estimated_hours,
        diagnosticos_normalizados.customer_authorized,
        diagnosticos_normalizados.requested_task,
        clientes_normalizados.cliente_id,
        clientes_normalizados.nivel_fidelidad,
        clientes_normalizados.cliente_id is not null as es_cliente_conocido

    from diagnosticos_normalizados
    left join clientes_normalizados
        on diagnosticos_normalizados.customer_name_normalizado = clientes_normalizados.nombre_normalizado

)

select * from final
