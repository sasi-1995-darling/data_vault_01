{{
    config(
        materialized='ephemeral'
    )
}}


with cte_data__larson_menards as (

    select * from {{ ref('stg_pit_pos_fbin_larson_menards') }}
)

, dim_date as-- logic to roll up transaction date to last date of the current fiscal week of transaction
    (select
        max(date) over (partition by fiscal_445_cal_week_yyyyww order by date desc) as transaction_date
        , to_char(transaction_date, 'YYYYMMDD') as transaction_datekey
        , *
    from {{ ref('im_pos_dim_date_fiscal_445') }}
    -- filters out latest partial week        
    where year(date) < year(current_date())
        or ((year(date) = year(current_date())) and (fiscal_445_cal_week < (select fiscal_445_cal_week from {{ ref('im_pos_dim_date_fiscal_445') }} where date = current_date())) and date < current_date())
)

select
    f.item_id
    , f.store_hk
    , d.transaction_date
    , d.transaction_datekey
    , f.reporting_channel
    , f.reporting_customer
    , f.sku
    , f.store_id
    , f.pos_qty
    , f.consumer_dollars
    , f.sku_status
    , f.gross_dollars
    , f.brand
    , f.shipping_city
    , f.shipping_state
    , f.shipping_zip
    , f.product_dest_zip
    , f.inv_qty
    , f.inv_consumer_dollars
    , f.bkcc
    , f.rec_src
from
    cte_data__larson_menards as f
    inner join
        dim_date as d
        on f.transaction_datekey = d.date_bk
