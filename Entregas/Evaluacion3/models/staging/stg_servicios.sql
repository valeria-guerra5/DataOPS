with fuente as (

    select * from {{ source('raw_rueda_libre', 'servicios') }}

),

renombrado as (

    select
        servicio_id::integer               as servicio_id,
        nombre::varchar                    as nombre,
        descripcion::varchar               as descripcion,
        precio_base::numeric(10, 2)        as precio_base,
        duracion_estimada_min::integer     as duracion_estimada_min

    from fuente

)

select * from renombrado
