with fuente as (

    select * from {{ source('raw_rueda_libre', 'tecnicos') }}

),

renombrado as (

    select
        tecnico_id::integer          as tecnico_id,
        nombre::varchar              as nombre,
        especialidad::varchar        as especialidad,
        fecha_contratacion::date     as fecha_contratacion

    from fuente

)

select * from renombrado
