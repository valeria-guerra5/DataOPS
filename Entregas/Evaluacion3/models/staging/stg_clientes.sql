-- Silver: cast y rename únicamente sobre la fuente cruda. Sin joins, sin lógica de
-- negocio — eso vive en core/. Usa exclusivamente source().
with fuente as (

    select * from {{ source('raw_rueda_libre', 'clientes') }}

),

renombrado as (

    select
        cliente_id::integer        as cliente_id,
        nombre::varchar             as nombre,
        email::varchar              as email,
        telefono::varchar           as telefono,
        fecha_registro::date        as fecha_registro,
        nivel_fidelidad::varchar    as nivel_fidelidad

    from fuente

)

select * from renombrado
