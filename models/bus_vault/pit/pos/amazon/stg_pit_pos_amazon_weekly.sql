{{
    config(
        materialized='ephemeral'
    )
}}



with cte_amazon_pos as (
    select * from {{ ref('stg_pos_moen_amazon') }}
    union all
    select * from {{ ref('stg_pos_tmlc_amazon') }}
    union all
    select * from {{ ref('stg_pos_sentrysafe_amazon') }}
    union all
    select * from {{ ref('stg_pos_moen_amazon_fivetran') }}
    union all
    select * from {{ ref('stg_pos_tmlc_amazon_fivetran') }}
    union all
    select * from {{ ref('stg_pos_sentrysafe_amazon_fivetran') }}
),
-- logic to roll up transaction date to last date of the current fiscal week of transaction
dim_date as 
(select max(date) over(partition by FISCAL_445_CAL_WEEK_YYYYWW order by date desc) as transaction_date,
        to_char(transaction_date, 'YYYYMMDD') transaction_datekey,*
        from {{ ref('im_pos_dim_date_fiscal_445') }}
        -- filters out latest partial week
        where year(date)<year(current_date()) or
       ( (year(date)=year(current_date())) and (fiscal_445_cal_week<(select fiscal_445_cal_week from {{ ref('im_pos_dim_date_fiscal_445') }} where date=current_date())) and date<current_date())
)


select 
f.item_id,
f.store_hk,
d.transaction_date,
d.transaction_datekey,
f.reporting_channel,
f.sku,
f.store_id,
f.sku_status,
f.pos_qty as pos_qty,
f.consumer_dollars as consumer_dollars,
f.gross_dollars as gross_dollars,
f.inv_qty as inv_qty,
f.inv_consumer_dollars as inv_consumer_dollars,
f.reporting_customer,
f.brand,
f.bkcc,
f.rec_src 
from
cte_amazon_pos f
inner join
dim_date d
on f.transaction_datekey = d.date_bk 