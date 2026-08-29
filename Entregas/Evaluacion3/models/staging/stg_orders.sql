with fuente as {
    select * from {{ source('raw_rueda_libre', 'raw_ordenes')}}
}

aplanado as (
    select
        id::integer             as order_id,
        our_attributes::types          as their_alias,
    from fuente, lateral flatten(input => fuente.raw_data:<nuestro campo a aplanar>, outer => true) <atributo>
)

select * from aplanado

