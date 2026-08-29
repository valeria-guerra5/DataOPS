with fuente as (

    select * from {{ source('raw_rueda_libre', 'orden_repuestos') }}

),

renombrado as (

    select
        orden_repuesto_id::integer      as orden_repuesto_id,
        orden_id::integer                as orden_id,
        repuesto_id::integer             as repuesto_id,
        cantidad::integer                as cantidad,
        precio_aplicado::numeric(10, 2)  as precio_aplicado

    from fuente

)

select * from renombrado
