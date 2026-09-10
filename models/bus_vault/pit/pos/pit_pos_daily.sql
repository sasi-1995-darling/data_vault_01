with cte_ferguson_pos as (  --unioning the 3 ferguson pos sources moen_new, moen_cfg_new and moen_new_gross$_history
    select
        ms.reporting_customer
        , ms.store_hk
        , ms.store_id
        , ms.sales_organization
        , ms.distribution_channel
        , ms.customer_division
        , ms._file
        , ms._line
        , ms.year_month
        , try_to_date(ms.date) as date --reformatting for a standard date format
        , ms.transaction_type
        , ms.sell_location_id
        , ms.legacy_sell_location_id
        , ms.sell_location_name
        , ms.ship_location_zip
        , ms.ship_location_city
        , ms.ship_location_state
        , ms.order_channel
        , ms.build_com_order
        , ms.customer_group
        , ms.sku
        , ms.fei_product_no
        , ms.fei_product_description
        , ms.vendor_code
        , ms.shipped_qty
        , ms.product_dest_city
        , ms.product_dest_state
        , ms.product_dest_zip_code
        , ms.uom
        , ms.load_dts
        , ms.ship_customer_id
        , ms.dest_customer_id
        , ms.item_number
        , ms.file_source
        , ms.brand
        , ms.gross_dollars
        , ms.rec_src
        , ms.bkcc
    from {{ ref('pit_stg_pos_ferguson_moen_new_daily') }} as ms
    where ms.year_month is not null --excludes null records from excel file
        and ms.year_month > '202507' --cutoff date for historic gross sales data

    union all

    select
        cs.reporting_customer
        , cs.store_hk
        , cs.store_id
        , cs.sales_organization
        , cs.distribution_channel
        , cs.customer_division
        , cs._file
        , cs._line
        , cs.year_month
        , try_to_date(cs.date) as date --reformatting for a standard date format
        , cs.transaction_type
        , cs.sell_location_id
        , cs.legacy_sell_location_id
        , cs.sell_location_name
        , cs.ship_location_zip
        , cs.ship_location_city
        , cs.ship_location_state
        , cs.order_channel
        , cs.build_com_order
        , cs.customer_group
        , cs.sku
        , cs.fei_product_no
        , cs.fei_product_description
        , cs.vendor_code
        , cs.shipped_qty
        , cs.product_dest_city
        , cs.product_dest_state
        , cs.product_dest_zip_code
        , cs.uom
        , cs.load_dts
        , cs.ship_customer_id
        , cs.dest_customer_id
        , cs.item_number
        , cs.file_source
        , cs.brand
        , cs.gross_dollars
        , cs.rec_src
        , cs.bkcc
    from {{ ref('pit_stg_pos_ferguson_moen_cfg_new_daily') }} as cs
    where cs.year_month is not null --excludes null records from excel file
        and cs.year_month > '202507' --cutoff date for historic gross sales data

    union all

    select
        hs.reporting_customer
        , hs.store_hk
        , hs.store_id
        , hs.sales_organization
        , hs.distribution_channel
        , hs.customer_division
        , hs._file
        , hs._line
        , hs.year_month
        , try_to_date(hs.date) as date --reformatting for a standard date format
        , hs.transaction_type
        , hs.sell_location_id
        , hs.legacy_sell_location_id
        , hs.sell_location_name
        , hs.ship_location_zip
        , hs.ship_location_city
        , hs.ship_location_state
        , hs.order_channel
        , hs.build_com_order
        , hs.customer_group
        , hs.sku
        , hs.fei_product_no
        , hs.fei_product_description
        , hs.vendor_code
        , hs.shipped_qty
        , hs.product_dest_city
        , hs.product_dest_state
        , hs.product_dest_zip_code
        , hs.uom
        , hs.load_dts
        , hs.ship_customer_id
        , hs.dest_customer_id
        , hs.item_number
        , hs.file_source
        , hs.brand
        , hs.gross_dollars
        , hs.rec_src
        , hs.bkcc
    from {{ ref('pit_stg_pos_ferguson_moen_new_gross_dollarized_history') }} as hs
    where hs.year_month is not null --excludes null records from excel file
        and hs.year_month <= '202507' --cutoff date for historic gross sales data
)

--fiscal calendar data brought in for pricing data joins on fiscal year month and weekly aggregation
, cte_fiscal_445_calendar as (
    select
        date
        , fiscal_445_cal_week_yyyyww
        , fiscal_445_cal_month_yyyymm::integer as fiscal_445_cal_month__date_yyyymm
        --transaction datekey (fiscal week end date) from pos logic
        , max(date) over (partition by fiscal_445_cal_week_yyyyww order by date desc) as transaction_date
    from {{ ref('pit_date_fiscal_445') }}
    where date <= current_date --isolates current and prior dates from fiscal calendar data
)

, cte_basematerial_item_map_winn as ( --pulls in winn item hash key and base material hash key for joins to pricing data
    select distinct
        item_number
        , item_hk
        , system_base_material
        , base_material_key
    from {{ ref('pb_items_by_plant') }}
    where bkcc = 'Hiding_Tiger'
)


--pulls in average monthly (fiscal period) gross price for Ferguson US wholesale
, cte_pb_shipment_avg_gross_price_ferguson as (
    select
        base_material_key
        , fiscal_445_cal_month__date_yyyymm
        , avg_gross_price
    from {{ ref('pb_shipment_avg_gross_price_monthly') }}
    where key_account_number = '101'
        and sales_org = 'USFS'
        and channel = 'WH'
        and source = 'MOEN'
)

, cte_pb_profitero_avg_consumer_price_build as ( --pulls in average consumer price from profitero for winn products on build.com (1st preference - ferguson's sales website)
    select
        base_material_key
        , fiscal_445_cal_month__date_yyyymm
        , avg_consumer_price
    from {{ ref('pb_profitero_avg_consumer_price_monthly') }}
    where retailer_bk = 'build.com [build]'
        and sat_rec_src = 'US.PROFITERO_WINN.PRICING_AVAILABILITY_HISTORY'
)

, cte_pb_profitero_avg_consumer_price_amazon as ( --pulls in average consumer price from profitero for winn products on amazon.com (2nd preference for ferguson consumer pricing)
    select
        base_material_key
        , fiscal_445_cal_month__date_yyyymm
        , avg_consumer_price
    from {{ ref('pb_profitero_avg_consumer_price_monthly') }}
    where retailer_bk = 'amazon.com'
        and sat_rec_src = 'US.PROFITERO_WINN.PRICING_AVAILABILITY_HISTORY'
)

--pulls in average gross to consumer price multiplier for build.com and ferguson's US Wholesale sales
, cte_pb_average_gross_to_consumer_markup_rate_monthly_ferguson as (
    select
        fiscal_445_cal_month__date_yyyymm
        , avg_consumer_markup_rate
    from {{ ref('pb_avg_gross_to_consumer_markup_rate_monthly') }}
    where key_account_number = '101'
        and sales_org = 'USFS'
        and channel = 'WH'
        and retailer_bk = 'build.com [build]'
)

, cte_consolidated_ferguson_base as (
    select
        fei.reporting_customer
        , fei.store_hk
        , fei.store_id
        , fei.sales_organization
        , fei.distribution_channel as reporting_channel
        , fei.customer_division
        , fei._file
        , fei._line::integer as _line
        , fei.year_month
        , fei.date
        , cal.transaction_date
        , to_varchar(date(cal.transaction_date), 'yyyymmdd')::integer as transaction_datekey
        , fei.transaction_type
        , fei.sell_location_id::integer as sell_location_id
        , lpad(fei.legacy_sell_location_id::integer, 4, 0) as legacy_sell_location_id
        , fei.sell_location_name
        , fei.ship_location_zip
        , fei.ship_location_city
        , fei.ship_location_state
        , fei.order_channel
        , fei.build_com_order
        , fei.customer_group
        , fei.sku
        , 'N/A' as sku_status
        , fei.fei_product_no as reporting_customer_product_number
        , fei.fei_product_description as reporting_customer_product_description
        , fei.shipped_qty as pos_qty
        , fei.product_dest_city
        , fei.product_dest_state
        , fei.product_dest_zip_code
        , fei.uom
        , fei.ship_customer_id
        , fei.dest_customer_id
        , fei.item_number
        , map.item_hk as item_id
        , map.base_material_key
        , fei.file_source
        , fei.brand
        , case       --utilizes historically derived gross dollars prior to cut-off data and MDP average gross price * ferguson pos quantity after cut-off date
            when fei.year_month <= '202507'
                then round(fei.gross_dollars::float, 2)
            when fei.year_month > '202507'
                then round((fei.shipped_qty * agp.avg_gross_price)::float, 2)
        end as gross_dollars
        , round(coalesce((fei.shipped_qty * acpb.avg_consumer_price), (fei.shipped_qty * acpa.avg_consumer_price), (fei.shipped_qty * agp.avg_gross_price * mkr.avg_consumer_markup_rate))::float, 2) as consumer_dollars --multiplies the build.com price by the ferguson pos quantity first, amazon price if no build price exists, then uses gross price with the average markup rate from ferguson gross sales to build.com profitero price for the corresponding fiscal period 
        , null as inv_qty
        , null as inv_consumer_dollars
        , fei.rec_src
        , fei.bkcc
    from cte_ferguson_pos as fei
        left join cte_fiscal_445_calendar as cal
            on fei.date = cal.date
        left join cte_basematerial_item_map_winn as map
            on coalesce(fei.item_number, fei.vendor_code) = map.item_number
        left join cte_pb_shipment_avg_gross_price_ferguson as agp
            on map.base_material_key = agp.base_material_key
                and cal.fiscal_445_cal_month__date_yyyymm = agp.fiscal_445_cal_month__date_yyyymm
        left join cte_pb_profitero_avg_consumer_price_build as acpb
            on map.base_material_key = acpb.base_material_key
                and cal.fiscal_445_cal_month__date_yyyymm = acpb.fiscal_445_cal_month__date_yyyymm
        left join cte_pb_profitero_avg_consumer_price_amazon as acpa
            on map.base_material_key = acpa.base_material_key
                and cal.fiscal_445_cal_month__date_yyyymm = acpa.fiscal_445_cal_month__date_yyyymm
        left join cte_pb_average_gross_to_consumer_markup_rate_monthly_ferguson as mkr
            on cal.fiscal_445_cal_month__date_yyyymm = mkr.fiscal_445_cal_month__date_yyyymm
)

select
    random() as seq_id
    , 'PIT_POS_DAILY' as pit_rec_src
    , current_date as snapshotdate
    , convert_timezone('UTC', current_timestamp) as pit_load_dts
    , reporting_customer
    , store_hk
    , store_id
    , sales_organization
    , reporting_channel
    , customer_division
    , _file
    , _line
    , year_month
    , date
    , transaction_date
    , transaction_datekey
    , transaction_type
    , sell_location_id
    , legacy_sell_location_id
    , sell_location_name
    , ship_location_zip
    , ship_location_city
    , ship_location_state
    , order_channel
    , build_com_order
    , customer_group
    , sku
    , sku_status
    , reporting_customer_product_number
    , reporting_customer_product_description
    , pos_qty
    , product_dest_city
    , product_dest_state
    , product_dest_zip_code
    , uom
    , ship_customer_id
    , dest_customer_id
    , item_number
    , item_id
    , base_material_key
    , file_source
    , brand
    , gross_dollars
    , consumer_dollars
    , inv_qty
    , inv_consumer_dollars
    , rec_src
    , bkcc
from cte_consolidated_ferguson_base
