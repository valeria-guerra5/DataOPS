with fuente as (

    select * from {{ source('raw_rueda_libre', 'citas') }}

),

renombrado as (

    select
        cita_id::integer         as cita_id,
        cliente_id::integer      as cliente_id,
        bicicleta_id::integer    as bicicleta_id,
        tecnico_id::integer      as tecnico_id,   -- puede asignarse después, nullable
        fecha_hora::timestamp    as fecha_hora,
        estado::varchar          as estado

    from fuente

)

select * from renombrado
