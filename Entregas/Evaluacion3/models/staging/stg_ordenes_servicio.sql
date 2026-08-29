with fuente as (

    select * from {{ source('raw_rueda_libre', 'ordenes_servicio') }}

),

renombrado as (

    select
        orden_id::integer                    as orden_id,
        bicicleta_id::integer                 as bicicleta_id,
        tecnico_id::integer                   as tecnico_id,
        fecha_ingreso::date                   as fecha_ingreso,
        fecha_entrega_estimada::date          as fecha_entrega_estimada,
        fecha_entrega_real::date              as fecha_entrega_real,
        estado::varchar                       as estado,
        total::numeric(10, 2)                 as total,
        notas::varchar                        as notas

    from fuente

)

select * from renombrado
