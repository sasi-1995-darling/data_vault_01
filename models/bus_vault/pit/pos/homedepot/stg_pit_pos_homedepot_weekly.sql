{{
    config(
        materialized='ephemeral'
    )
}}


with cte_homedepot_pos as (
    select * from {{ ref('stg_pos_masterlock_homedepot') }}
    union all
    select * from {{ ref('stg_pos_moen_homedepot') }}
    union all
    select * from {{ ref('stg_pos_larson_homedepot') }}
    union all
    select * from {{ ref('stg_pos_fiberon_homedepot') }}

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
f.item_id,
f.store_hk,
d.transaction_date,
d.transaction_datekey,
f.reporting_channel,
f.sku,
f.store_id,
f.sku_status,
case f.sku_status       --logic to rank by most to least common sku status in POS data
    when '100-ACTIVE' then '1_' || f.sku_status
    when '600-DELETE' then '2_' || f.sku_status
    when '500-CLEARANCE' then '3_' || f.sku_status
    when '400-INACTIVE' then '4_' || f.sku_status
    when '-1-UNKNOWN' then '5_' || f.sku_status
    when '200-SEASONAL' then '6_' || f.sku_status
    when '300-OUT OF SEASON' then '7_' || f.sku_status
    else '15_' || f.sku_status
end sku_status_rank,
split(min(sku_status_rank) over (partition by f.item_id, f.store_hk, d.transaction_date, d.transaction_datekey, f.sku, f.reporting_channel, f.store_id, f.reporting_customer, f.brand order by sku_status_rank), '_')[
            1
        ]::string as sku_status_preference, --logic to select preferred status based on derived rank for downstream weekly aggregation
f.pos_qty,
f.consumer_dollars,
f.gross_dollars,
--f.inv_qty,
--f.inv_consumer_dollars,
case when d.date = d.transaction_date then f.inv_qty else 0 end as inv_qty,
case when d.date = d.transaction_date then f.inv_consumer_dollars else 0 end as inv_consumer_dollars,
f.reporting_customer,
f.brand,
f.bkcc,
f.rec_src
from
cte_homedepot_pos f
inner join
dim_date d
on f.transaction_datekey = d.date_bk