{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_invoice_header__ml_ebs as (
    select * from {{ ref('sat_invoice_header__ml_ebs') }}
)
, cte_sat_invoice_header__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_invoice_header__ml_ebs'
        ,hk_field='invoice_hk') }}
)
, cte_lsat_invoice_line__ml_ebs as (
    select * from {{ ref('lsat_invoice_line__ml_ebs') }}
)
, cte_lsat_invoice_line__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_lsat_invoice_line__ml_ebs'
        ,hk_field='invoice_line_hk') }}
)
, cte_sat_order_lines_all__ml_ebs as (
    select * from {{ ref('sat_order_lines_all__ml_ebs') }}
)
, cte_sat_order_lines_all__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_order_lines_all__ml_ebs'
        ,hk_field='order_line_hk') }}
)
, cte_sat_payment_schedule_all__ml_ebs as (
    select * from {{ ref('sat_payment_schedule_all__ml_ebs') }}
)
, cte_sat_payment_schedule_all__ml_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_payment_schedule_all__ml_ebs'
        ,hk_field='payment_schedule_hk') }}
)

, base_items as
(
    select
    to_varchar(rctl.inventory_item_id) as item_id
    , psa.gl_date as date_posted
from cte_sat_invoice_header__ml_ebs__latest as rct
    inner join cte_lsat_invoice_line__ml_ebs__latest as rctl
        on rctl.invoice_hk = rct.invoice_hk
            and rct.org_id = rctl.org_id
            and rctl.line_type = 'LINE'
            and rctl.unit_selling_price != 0
    inner join {{ ref('link_invoice_line_order_line') }} ilol 
        on ilol.invoice_line_hk = rctl.invoice_line_hk
    inner join cte_sat_order_lines_all__ml_ebs__latest ola 
        on ilol.order_line_hk = ola.order_line_hk
        and ola.item_type_code not in ('OPTION','CLASS','CONFIG')
    inner join {{ ref('link_invoice_payment_schedule') }} ips
        on ips.invoice_hk = rctl.invoice_hk
    inner join cte_sat_payment_schedule_all__ml_ebs__latest psa
        on psa.payment_schedule_hk = ips.payment_schedule_hk
        and psa.class||'' in ('INV','DM','CM')
)

, item_dates as
(
select distinct s.item_id, ref_item.base_material, s.date_posted from 
base_items s
left join {{ ref('ref_item_master') }} ref_item
    on ref_item.item_id = s.item_id
    and ref_item.brand = 'TMLC'
)

, ranked_consumer_price as (
    select
        id.item_id
        , id.date_posted
        , xref_cp.price as consumer_price
        , row_number() over (partition by id.item_id, id.date_posted order by abs(datediff(day, xref_cp.day, id.date_posted))) as rn
    from item_dates as id
        left join
            (
                select *
                from {{ ref('ref_xref_consumer_price') }}
                where key_account_number = '53'
            )
                as xref_cp
            on id.base_material = xref_cp.base_material

)
, consumer_price as (
    select
        item_id
        , date_posted
        , consumer_price
    from ranked_consumer_price where rn = 1
)

select * from consumer_price