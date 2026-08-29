with fuente as (

    select * from {{ source('raw_rueda_libre', 'orden_servicio_detalle') }}

),

renombrado as (

    select
        detalle_id::integer             as detalle_id,
        orden_id::integer                as orden_id,
        servicio_id::integer             as servicio_id,
        cantidad::integer                as cantidad,
        precio_aplicado::numeric(10, 2)  as precio_aplicado

    from fuente

)

select * from renombrado
