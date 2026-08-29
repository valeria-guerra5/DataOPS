-- Gold — responde: "¿cuáles son nuestros clientes de mayor valor, medido en órdenes y
-- en gasto histórico, y cuáles nunca han vuelto después de registrarse?"
-- Grano: 1 fila por cliente_id. Cruza clientes -> bicicletas -> ordenes_servicio
-- (dos saltos, porque ordenes_servicio no tiene cliente_id directo — apunta a una
-- bicicleta, y la bicicleta apunta al cliente). Solo usa ref() sobre modelos Silver.
with clientes as (

    select * from {{ ref('stg_clientes') }}

),

bicicletas as (

    select * from {{ ref('stg_bicicletas') }}

),

ordenes as (

    select * from {{ ref('stg_ordenes_servicio') }}

),

ordenes_por_cliente as (

    select
        bicicletas.cliente_id,
        count(*)                    as total_ordenes,
        sum(ordenes.total)          as gasto_total,
        min(ordenes.fecha_ingreso)  as primera_orden_at,
        max(ordenes.fecha_ingreso)  as ultima_orden_at

    from ordenes
    inner join bicicletas
        on ordenes.bicicleta_id = bicicletas.bicicleta_id
    group by bicicletas.cliente_id

),

final as (

    select
        clientes.cliente_id,
        clientes.nombre,
        clientes.email,
        clientes.nivel_fidelidad,
        clientes.fecha_registro,
        coalesce(ordenes_por_cliente.total_ordenes, 0)   as total_ordenes,
        coalesce(ordenes_por_cliente.gasto_total, 0)     as gasto_total,
        ordenes_por_cliente.primera_orden_at,
        ordenes_por_cliente.ultima_orden_at,
        datediff('day', ordenes_por_cliente.ultima_orden_at, current_date()) as dias_desde_ultima_orden,
        case
            when ordenes_por_cliente.total_ordenes is null then 'sin_ordenes'
            when ordenes_por_cliente.total_ordenes >= 5     then 'alto'
            when ordenes_por_cliente.total_ordenes >= 2     then 'medio'
            else 'bajo'
        end as nivel_actividad

    from clientes
    left join ordenes_por_cliente
        on clientes.cliente_id = ordenes_por_cliente.cliente_id

)

select * from final
