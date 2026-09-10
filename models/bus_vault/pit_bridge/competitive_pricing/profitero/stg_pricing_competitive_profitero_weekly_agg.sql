{{
    config(
        materialized='ephemeral'
    )
}}
with stg_price__profitero as
(
 select * from   
    {{ ref('stg_pricing_competitive_profitero_weekly') }}

)
select
c.date,
c.date_key,
c.customer_product_id, --(or hk)
c.product_id,
c.product_bk,
c.product_key,
c.retailer_bk, --(or hk)
c.retailer_key,
c.brand_bk,
c.brand_key,
c.data_source,
c.bkcc,
c.rec_src,
sum(c.available)/count(1)*100 as availability_percent,
avg(c.regular_price) as average_regular_price,
min(c.regular_price) as minimum_regular_price,
max(c.regular_price) as maximum_regular_price,
median(c.regular_price) as mode_regular_price,
avg(c.promotion_price) as average_promotion_price,
min(c.promotion_price) as minimum_promotion_price,
max(c.promotion_price) as maximum_promotion_price,
median(c.promotion_price) as mode_promotion_price
from
stg_price__profitero c
group by all
