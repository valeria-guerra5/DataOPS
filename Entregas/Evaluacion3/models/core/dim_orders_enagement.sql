WITH pedidos as (
    select * from {{ ref('stg_orders') }}
),
metricas_por_cuentas as (
    select
        account_id,
        count(*)               as total_orders,
        sum(total_amount_usd)  as total_revenue_usd,
        min(ordered_at)        as first_order_at,
        max(ordered_at)        as last_order_at
    from pedidos
    group by account_id
),
final as (

    select
        cuentas.account_id,
        cuentas.account_name,
        cuentas.website,
        cuentas.sales_rep_id,
        coalesce(metricas_por_cuenta.total_orders, 0)      as total_orders,
        coalesce(metricas_por_cuenta.total_revenue_usd, 0) as total_revenue_usd,
        metricas_por_cuenta.first_order_at,
        metricas_por_cuenta.last_order_at,
        case
            when metricas_por_cuenta.total_orders is null then 'sin_pedidos'
            when metricas_por_cuenta.total_orders >= 10    then 'alto'
            when metricas_por_cuenta.total_orders >= 3     then 'medio'
            else 'bajo'
        end as engagement_tier

    from cuentas
    left join metricas_por_cuenta
        on cuentas.account_id = metricas_por_cuenta.account_id

)
select * from final