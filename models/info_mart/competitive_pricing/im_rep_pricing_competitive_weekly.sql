{{ config(alias='rep_pricing_competitive_weekly') }}

select 
f.product_bk as customer_product_id,
f.product_id,
f.data_source as source,
f.date,
week(f.date) as week_of,
f.availability_percent,
f.average_regular_price,
f.minimum_regular_price,
f.maximum_regular_price,
f.mode_regular_price,
f.average_promotion_price,
f.minimum_promotion_price,
f.maximum_promotion_price,
f.mode_promotion_price,
b.brand_bk as brand_name,
b.subbrand,
b.subsubbrand,
r.retailer_bk as retailer_name,
r.country,
r.alias,
p.product_name,
p.map_price,
cp.ranking_product_id,
coalesce(p.rpc,cp.rpc) as rpc,
coalesce(p.ean,cp.ean) as ean,
coalesce(p.upc,cp.upc) as upc,
coalesce(p.model,cp.model) as model,
cp.url,
p.brand_id,
f.bkcc,
f.rec_src
from 
{{ ref('im_fact_pricing_competitive_weekly') }} f --fact 
left join 
{{ ref('im_pricing_competitive_dim_brand_v2') }} b
on f.brand_bk=b.brand_bk
left join
{{ ref('im_pricing_competitive_dim_retailer') }} r
on f.retailer_bk=r.retailer_bk
left join
{{ ref('im_pricing_competitive_dim_product_v2') }} p
on f.product_bk=p.product_bk
left join
{{ ref('im_dim_competitive_product') }} cp
on f.product_id=cp.competitive_product_bk and f.retailer_bk=cp.retailer_bk