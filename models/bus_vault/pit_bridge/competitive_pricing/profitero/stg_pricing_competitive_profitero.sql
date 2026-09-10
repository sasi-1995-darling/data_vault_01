{{
    config(
        materialized='ephemeral'
    )
}}
with cte_sat_price__profitero as
(
    select 
        date,
        customer_product_id,
        product_id,
        retailer_id,
        load_dts,
        product_hk,
        retailer_hk,
        promotion_text,
        availability,
        rec_src,
        regular_price,
        promotion_price
    from   
    {{ ref('lsat_price_availability__profitero') }}   

),
cte_sat_price__profitero__latest as (
    select * from cte_sat_price__profitero
    qualify row_number() over(partition by date,customer_product_id,product_id,retailer_id order by load_dts desc)=1
) 
select
c.date,
c.customer_product_id, --(or hk)
c.product_id,
hp.product_bk,
c.product_hk as product_key,
hr.retailer_bk, --(or hk)
c.retailer_hk as retailer_key,
c.promotion_text,
c.availability,
hb.brand_bk,
hb.brand_hk as brand_key,
'PROFITERO' as data_source,
c.rec_src as sat_rec_src,
hp.rec_src,
hp.bkcc, --added to isolate brands for Ferguson consumer pricing calcs 2025-08-28
c.regular_price,
c.promotion_price
from 
{{ ref('hub_product_v2') }} hp
inner join
cte_sat_price__profitero__latest c
on hp.product_hk=c.product_hk
inner join 
{{ ref('hub_retailer') }} hr
on hr.retailer_hk=c.retailer_hk
left join
{{ ref('lnk_product_brand') }} lpb
on hp.product_hk=lpb.product_hk
left join
{{ ref('hub_brand_v2') }} hb
on lpb.brand_hk=hb.brand_hk