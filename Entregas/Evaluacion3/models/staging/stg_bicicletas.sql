with fuente as (

    select * from {{ source('raw_rueda_libre', 'bicicletas') }}

),

renombrado as (

    select
        bicicleta_id::integer   as bicicleta_id,
        cliente_id::integer     as cliente_id,
        marca::varchar          as marca,
        modelo::varchar         as modelo,
        tipo::varchar           as tipo,
        numero_serie::varchar   as numero_serie,
        estado::varchar         as estado

    from fuente

)

select * from renombrado
