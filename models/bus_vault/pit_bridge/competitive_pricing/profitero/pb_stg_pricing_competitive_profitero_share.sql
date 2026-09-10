{{
    config(
        materialized='ephemeral'
    )
}}
with cte_lmsat_price__profitero_share as
(
    select date, customer_product_id, product_id, retailer_id, load_dts, product_hk, retailer_hk, promotion_text, availability, rec_src, regular_price, promotion_price
    from {{ ref('lmsat_price_availability__fiberon_profitero_share') }}
    union all
    select date, customer_product_id, product_id, retailer_id, load_dts, product_hk, retailer_hk, promotion_text, availability, rec_src, regular_price, promotion_price
    from {{ ref('lmsat_price_availability__fypon_profitero_share') }}
    union all
    select date, customer_product_id, product_id, retailer_id, load_dts, product_hk, retailer_hk, promotion_text, availability, rec_src, regular_price, promotion_price
    from {{ ref('lmsat_price_availability__larson_profitero_share') }}
    union all
    select date, customer_product_id, product_id, retailer_id, load_dts, product_hk, retailer_hk, promotion_text, availability, rec_src, regular_price, promotion_price
    from {{ ref('lmsat_price_availability__security_profitero_share') }}
    union all
    select date, customer_product_id, product_id, retailer_id, load_dts, product_hk, retailer_hk, promotion_text, availability, rec_src, regular_price, promotion_price
    from {{ ref('lmsat_price_availability__thermatru_profitero_share') }}
    union all
    select date, customer_product_id, product_id, retailer_id, load_dts, product_hk, retailer_hk, promotion_text, availability, rec_src, regular_price, promotion_price
    from {{ ref('lmsat_price_availability__winn_profitero_share') }}
),
cte_lmsat_price__profitero_share__latest as (
    select * from cte_lmsat_price__profitero_share
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
'PROFITERO_SHARE' as data_source,
c.rec_src as sat_rec_src,
hp.rec_src,
hp.bkcc, --added to isolate brands for Ferguson consumer pricing calcs 2025-08-28
c.regular_price,
c.promotion_price
from 
{{ ref('lnk_product_retailer') }} lpr
inner join
{{ ref('hub_product_v2') }} hp
on lpr.product_hk = hp.product_hk
inner join
cte_lmsat_price__profitero_share__latest c
on lpr.product_hk = c.product_hk
and lpr.retailer_hk = c.retailer_hk
inner join 
{{ ref('hub_retailer') }} hr
on lpr.retailer_hk = hr.retailer_hk
left join
{{ ref('lnk_product_brand') }} lpb
on hp.product_hk = lpb.product_hk
left join
{{ ref('hub_brand_v2') }} hb
on lpb.brand_hk = hb.brand_hk
