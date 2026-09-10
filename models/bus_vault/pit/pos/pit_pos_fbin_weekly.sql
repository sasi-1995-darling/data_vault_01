with cte_lowes_pos as (
    select * from {{ ref('stg_pit_pos_fbin_moen_lowes') }}
    union all
    select * from {{ ref('stg_pit_pos_fbin_tmlc_lowes') }}
    union all
    select * from {{ ref('stg_pit_pos_fbin_larson_lowes') }}
    union all
    select * from {{ ref('stg_pit_pos_fbin_thermatru_lowes') }}

)


, cte_homedepot_pos as (
    select * from {{ ref('stg_pit_pos_homedepot_weekly_agg') }}
)

, cte_amazon_pos as (
    select * from {{ ref('stg_pit_pos_amazon_weekly_agg') }}
)

, cte_menards_pos as (
    select * from {{ ref('stg_pit_pos_fbin_larson_menards_weekly_agg') }}
    union all
    select * from {{ ref('stg_pit_pos_fbin_moen_menards') }}
)

, cte_ferguson_pos_moen as ( --added ferguson moen pos
    select
        store_hk
        , reporting_customer
        , brand
        , item_id
        , store_id
        , transaction_date
        , transaction_datekey
        , reporting_channel
        , product_dest_zip_code as product_dest_zip
        , sku
        , sku_status
        , sum(pos_qty) as pos_qty
        , sum(consumer_dollars) as consumer_dollars
        , sum(gross_dollars) as gross_dollars
        , inv_qty::float as inv_qty
        , inv_consumer_dollars::float as inv_consumer_dollars
        , bkcc
        , rec_src
    from {{ ref('pit_pos_daily') }}
    group by all
)

, cte_all_pos as (
    select  
            store_hk
            , reporting_customer
            , brand
            , item_id
            , store_id
            , transaction_date
            , transaction_datekey
            , reporting_channel
            , null as product_dest_zip  --added to accomodate ferguson pos destination zip
            , sku
            , sku_status
            , pos_qty
            , consumer_dollars
            , gross_dollars
            , inv_qty
            , inv_consumer_dollars
            , bkcc
            , rec_src
    from cte_lowes_pos
    union all
    select 
            store_hk
            , reporting_customer
            , brand
            , item_id
            , store_id
            , transaction_date
            , transaction_datekey
            , reporting_channel
            , null as product_dest_zip  --added to accomodate ferguson pos destination zip
            , sku
            , sku_status
            , pos_qty
            , consumer_dollars
            , gross_dollars
            , inv_qty
            , inv_consumer_dollars
            , bkcc
            , rec_src
    from cte_homedepot_pos
    union all
    select 
            store_hk
            , reporting_customer
            , brand
            , item_id
            , store_id
            , transaction_date
            , transaction_datekey
            , reporting_channel
            , null as product_dest_zip  --added to accomodate ferguson pos destination zip
            , sku
            , sku_status
            , pos_qty
            , consumer_dollars
            , gross_dollars
            , inv_qty
            , inv_consumer_dollars
            , bkcc
            , rec_src
    from cte_amazon_pos
    union all
    select 
            store_hk
            , reporting_customer
            , brand
            , item_id
            , store_id
            , transaction_date
            , transaction_datekey
            , reporting_channel
            , null as product_dest_zip  --added to accomodate ferguson pos destination zip
            , sku
            , sku_status
            , pos_qty
            , consumer_dollars
            , gross_dollars
            , inv_qty
            , inv_consumer_dollars
            , bkcc
            , rec_src
    from cte_menards_pos
    union all   --added ferguson moen pos data to union
    select
            store_hk
            , reporting_customer
            , brand
            , item_id
            , store_id
            , transaction_date
            , transaction_datekey
            , reporting_channel
            , product_dest_zip  --ferguson pos destination zip
            , sku
            , sku_status
            , pos_qty
            , consumer_dollars
            , gross_dollars
            , inv_qty
            , inv_consumer_dollars
            , bkcc
            , rec_src
    from cte_ferguson_pos_moen
)

select 
      row_number() over(order by 1) as seq_id
    , current_timestamp as snapshot_dts
    , store_hk
	, reporting_customer
	, brand
	, coalesce(item_id,to_binary('', 'HEX')) as item_id
	, coalesce(store_id::varchar,'N/A') as store_id
	, transaction_date
	, transaction_datekey::integer as transaction_datekey
	, reporting_channel
    , coalesce(product_dest_zip,'N/A') as product_dest_zip --ferguson pos destination zip 2025-09-04
	, coalesce(sku::varchar,'N/A') as sku --added manual varchar formatting to resolve datatype mismatch bug with join to DIM_POG_WEEKLY in REP_POS_WEEKLY infomart
	, coalesce(sku_status,'N/A') as sku_status
	, pos_qty
	, consumer_dollars
	, gross_dollars
    , inv_qty
    , inv_consumer_dollars
    , store_hk as store_key
    , bkcc
    , rec_src
from cte_all_pos