with fuente as (

    select * from {{ source('raw_rueda_libre', 'repuestos') }}

),

renombrado as (

    select
        repuesto_id::integer            as repuesto_id,
        nombre::varchar                 as nombre,
        categoria::varchar              as categoria,
        precio_unitario::numeric(10, 2) as precio_unitario,
        stock::integer                  as stock

    from fuente

)

select * from renombrado
