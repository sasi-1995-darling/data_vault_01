{{
    config(
        materialized='table'
    )
}}

with cte_sat_shipment__moen_sap as (select * from {{ ref('sat_shipment__moen_sap') }})

, cte_sat_shipment__moen_sap_latest as (
    {{ generate_cte_satellite_latest('cte_sat_shipment__moen_sap','copa_sales_hk') }}
)

, base_items as (
    select distinct
        hi.item_bk as item_id
        , sshp.date_posted
    from {{ ref('hub_shipment_sap') }} as hshp
        inner join cte_sat_shipment__moen_sap_latest as sshp
            on hshp.copa_sales_hk = sshp.copa_sales_hk
        left join {{ ref('link_item_cust_shipment') }} as lics
            on hshp.copa_sales_hk = lics.copa_sales_hk
        left join {{ ref('hub_item') }} as hi
            on lics.item_hk = hi.item_hk
    where sshp.date_posted >= '2019-01-01'
)

, ranked_consumer_price as (
    select
        id.item_id
        , id.date_posted
        , xref_cp.price as consumer_price
        , row_number()
            over (partition by id.item_id, id.date_posted order by abs(datediff(day, xref_cp.day, id.date_posted)))
            as rn
    from base_items as id
        left join
            (
                select *
                from {{ ref('ref_xref_consumer_price') }}
                where key_account_number = '102'
            )
                as xref_cp
            on id.item_id = xref_cp.base_material

)

, consumer_price as (
    select
        item_id
        , date_posted
        , consumer_price
    from ranked_consumer_price where rn = 1
)

select
    item_id
    , date_posted
    , avg(consumer_price) as consumer_price
from consumer_price
group by item_id, date_posted
