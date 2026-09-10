{{
    config(
        materialized='ephemeral'
    )
}}
with stg_price__profitero as
(
 select *,to_char(date, 'YYYYMMDD') date_datekey from   
    {{ ref('stg_pricing_competitive_profitero') }} 

), dim_date as
-- logic to roll up transaction date to last date of the current fiscal week of transaction
(select max(date) over(partition by FISCAL_445_CAL_WEEK_YYYYWW order by date desc) as transaction_date,
        to_char(transaction_date, 'YYYYMMDD') transaction_datekey,*
        from {{ ref('im_pos_dim_date_fiscal_445') }}
        -- filters out latest partial week        
        where year(date)<year(current_date()) or
       ( (year(date)=year(current_date())) and (fiscal_445_cal_week<(select fiscal_445_cal_week from {{ ref('im_pos_dim_date_fiscal_445') }} where date=current_date())) and date<current_date())
)
select
d.transaction_date as date,
d.transaction_datekey as date_key,
c.customer_product_id,
c.product_id,
c.product_bk,
c.product_key,
c.retailer_bk,
c.retailer_key,
c.promotion_text,
c.brand_bk,
c.brand_key,
case when c.availability in('Y','S') then 1 else 0 end as available,
c.data_source,
c.bkcc,
c.rec_src,
c.regular_price,
c.promotion_price
from
stg_price__profitero c
inner join
dim_date d
on c.date_datekey = d.date_bk