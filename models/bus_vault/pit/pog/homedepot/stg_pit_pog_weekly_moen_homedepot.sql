{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_pog_weekly__homedepot as (
    select
        store_hk
        , manuf_part_number
        , sku_nbr
        , d_active_sku_2
        , d_assortment
        , d_pog_2
        , d_store_nbr
        , home_depot_account
        , week
        , rec_src
        , load_dts
    from {{ ref('sat_pog_weekly__homedepot') }}
)

, cte_sat_pog_weekly__homedepot_latest as (
    {{ generate_cte_satellite_latest('cte_sat_pog_weekly__homedepot','store_hk, sku_nbr, week, home_depot_account, d_pog_2, d_active_sku_2, d_assortment') }}        
)

, cte_sat_sales__homedepot as (
    select
        day
        , sku_nbr
        , d_store_nbr
        , store_hk
        , merch_vendor
        , manuf_part_number
        , fulfillment_channel
        , home_depot_account
        , sku_status
        , sales_units
        , sales
        , rec_src
        , load_dts
    from {{ ref('sat_sales__homedepot') }}
    where sales is not null
)

, cte_sat_sales__homedepot_latest as (
    {{ generate_cte_satellite_latest('cte_sat_sales__homedepot','day, sku_nbr, store_hk, merch_vendor, manuf_part_number, fulfillment_channel, home_depot_account, sku_status') }}        
)
--updated home depot fiscal calendar cte to align home depot calendar to fiscal calendar week ranges
, cte_pit_hd_fiscal_calendar_daily as (
    select distinct
        hd.date
        ,hd.date_bk
        ,concat('Fiscal Week ', thd_cal_week, ' of ', thd_cal_year) as hd_fiscal_week
        ,case dayofweek(date(hd.date))      --logic to align home depot calendar week to fiscal calendar week start
            when 0 then dateadd(day, -7, date(hd.date))
            else dateadd(day, -dayofweek(date(hd.date)), date(hd.date))
         end fbin_week_start_date
        ,case dayofweek(date(hd.date))  --logic to align home depot calendar week to fiscal calendar week end
            when 0 then dateadd(day, -1, date(hd.date))
            else dateadd(day, 6-dayofweek(date(hd.date)), date(hd.date))
        end fbin_week_end_date
    from {{ ref('pit_date_pos_thd_askuity') }} as hd
)

, cte_pit_hd_fiscal_calendar_weekly as (
    select distinct
        hd_fiscal_week
        , fbin_week_start_date
        , fbin_week_end_date
    from cte_pit_hd_fiscal_calendar_daily

)

, moen_known_item_attributes as (--from Orion's PIT_POS_WEEKLY, pulls all known home depot sku to manuf_part_number (moen sku) relationships for UNKNOWN manuf_part_number resolution further down
    select distinct
        sku_nbr
        , first_value(manuf_part_number) over (partition by sku_nbr order by run_date desc) as manuf_part_number
    from {{ ref('ref_pos_home_depot_itemattributes') }}
    where manuf_part_number != 'UNKNOWN'
)

, cte_hd_pog_agg as (
    select
        spog.manuf_part_number
        , spog.sku_nbr
        , spog.d_active_sku_2 as active_sku
        , spog.d_assortment as assortment
        , spog.d_pog_2 as pog
        , hs.store_bk as store_number
        , hs.store_hk 
        , spog.home_depot_account
        , case spog.home_depot_account
            when 'Moen_CSI' then 'MOEN'
            when 'Moen_Vendordrill_Data' then 'MOEN'
            else 'Other'
        end as business_unit
        , spog.week
        , fcw.fbin_week_start_date
        , fcw.fbin_week_end_date
        , hs.bkcc
        , spog.rec_src
    from {{ ref('hub_store') }} as hs
        inner join cte_sat_pog_weekly__homedepot_latest as spog     --data exists only for >= 2022
            on hs.store_hk = spog.store_hk
                and hs.bkcc = 'Talking_Tom'
        inner join cte_pit_hd_fiscal_calendar_weekly as fcw
            on spog.week = fcw.hd_fiscal_week
    where spog.home_depot_account in ('Moen_CSI', 'Moen_Vendordrill_Data') --moen specific sources
)--removed redundant qualify function

, cte_hd_pos_agg as (
    select
        case
        spos.home_depot_account
            when 'Moen_CSI' then 'MOEN'
            when 'Moen_Vendordrill_Data' then 'MOEN'
            else 'Other'
        end as business_unit
        , spos.home_depot_account
        , spos.sku_nbr
        , spos.manuf_part_number as part_number
        , hs.store_bk as store_number
        , hs.store_hk
        ,case       --reporting channel logic utilized in MDP Home Depot POS build
            when spos.fulfillment_channel = 'In Store' then 'RT'
            when spos.fulfillment_channel = 'DTC' then 'EC'
            else 'EC'
        end fulfillment_channel
        , fc.fbin_week_start_date
        , fc.fbin_week_end_date
        , spos.rec_src
        , hs.bkcc
        , sum(spos.sales_units) as pos_quantity
        , sum(spos.sales) as pos_amount
    from {{ ref('hub_store') }} as hs
        inner join cte_sat_sales__homedepot_latest as spos
            on hs.store_hk = spos.store_hk
                and hs.bkcc = 'Talking_Tom'
        inner join cte_pit_hd_fiscal_calendar_daily as fc
            on date(spos.day) = fc.date
                and spos.home_depot_account in ('Moen_CSI', 'Moen_Vendordrill_Data')
                and year(fc.fbin_week_end_date) >= 2023
    group by all
)

, cte_hd_pog_weekly_base as (
    select
        'HOME DEPOT' as reporting_customer
        , coalesce(pos.business_unit, pog.business_unit) as brand
        , coalesce(pos.home_depot_account, pog.home_depot_account) as retailer_account
        , coalesce(pos.sku_nbr, pog.sku_nbr) as sku_nbr
        , coalesce(pos.part_number, pog.manuf_part_number) as manuf_part_number
        , coalesce(pog.active_sku, 'U') as active_sku
        , case pog.active_sku
            when 'Y' then 1
            when 'N' then 0
            else 0
        end as stocked_store
        , coalesce(pos.store_hk, pog.store_hk) as store_hk
        , coalesce(pos.store_number, pog.store_number) as store_number
        , coalesce(pos.fulfillment_channel, 'RT') as fulfillment_channel
        , coalesce(pos.fbin_week_start_date, pog.fbin_week_start_date) as fbin_week_start_date
        , coalesce(pos.fbin_week_end_date, pog.fbin_week_end_date) as fbin_week_end_date
        , coalesce(pos.rec_src, pog.rec_src) as rec_src
        , coalesce(pos.bkcc, pog.bkcc) as bkcc
        , pos.pos_quantity
        , pos.pos_amount
    from cte_hd_pos_agg as pos
        full outer join cte_hd_pog_agg as pog
            on pos.home_depot_account = pog.home_depot_account
                and pos.fbin_week_end_date = pog.fbin_week_end_date
                and pos.sku_nbr = pog.sku_nbr
                and pos.store_number = pog.store_number
)

, pog_moen_resolve_unknowns_from_knowns as (
    select
        kiam.manuf_part_number as item
        , pog.reporting_customer
        , pog.retailer_account
        , pog.sku_nbr
        , pog.manuf_part_number
        , pog.active_sku
        , pog.stocked_store
        , pog.store_hk
        , pog.store_number
        , pog.fulfillment_channel
        , pog.brand
        , pog.fbin_week_start_date
        , pog.fbin_week_end_date
        , pog.bkcc
        , pog.rec_src
        , pog.pos_quantity
        , pog.pos_amount
    from cte_hd_pog_weekly_base as pog
        left join moen_known_item_attributes as kiam
            on pog.sku_nbr = kiam.sku_nbr
    where pog.manuf_part_number = 'UNKNOWN'
)

, moen_pog_weekly_consolidated as (
    select
        pog.manuf_part_number as item
        , pog.reporting_customer
        , pog.retailer_account
        , pog.sku_nbr
        , pog.manuf_part_number
        , pog.active_sku
        , pog.stocked_store
        , pog.store_hk
        , pog.store_number
        , pog.fulfillment_channel
        , pog.brand
        , pog.fbin_week_start_date
        , pog.fbin_week_end_date
        , pog.bkcc
        , pog.rec_src
        , pog.pos_quantity
        , pog.pos_amount
    from cte_hd_pog_weekly_base as pog
    where pog.manuf_part_number != 'UNKNOWN'

    union all

    select
        coalesce(k.item, 'UNKNOWN') as item
        , k.reporting_customer
        , k.retailer_account
        , k.sku_nbr
        , k.manuf_part_number
        , k.active_sku
        , k.stocked_store
        , k.store_hk
        , k.store_number
        , k.fulfillment_channel
        , k.brand
        , k.fbin_week_start_date
        , k.fbin_week_end_date
        , k.bkcc
        , k.rec_src
        , k.pos_quantity
        , k.pos_amount
    from pog_moen_resolve_unknowns_from_knowns as k
)


, moen_item_no_match_master as (
    select distinct item as item_id from moen_pog_weekly_consolidated
    minus
    select distinct item_id from {{ ref('pb_items_by_plant') }}
    where bkcc = 'Hiding_Tiger'
)

, moen_item_match_master as ( -- connect item_id from POG to item_HK in pit bridge
    select distinct
        pog.item as pog_item_id
        , rim.item_hk as rim_item_id
    from moen_pog_weekly_consolidated as pog
        left join (
            select
                item_hk
                , bkcc
                , item_number
            from {{ ref('pb_items_by_plant') }}
            where bkcc = 'Hiding_Tiger'
            qualify row_number() over (partition by item_number, bkcc order by sat_plant_item_load_dts desc) = 1
        ) as rim on pog.item = rim.item_number
)

, moen_item_map as (
    select
        pog_item_id
        , rim_item_id
    from moen_item_match_master
    where rim_item_id is not null

    union all

    select
        pog.item_id as pog_item_id
        , rim.item_hk as rim_item_id
    from moen_item_no_match_master as pog
        left join (
            select
                item_hk
                , bkcc
                , item_number
            from {{ ref('pb_items_by_plant') }}
            where bkcc = 'Hiding_Tiger'
            qualify row_number() over (partition by item_number, bkcc order by sat_plant_item_load_dts desc) = 1
        ) as rim
            on upper(rim.item_number) = upper(split_part(pog.item_id, '-', 0))
)

    select
        'HOME DEPOT' as reporting_customer
        , pog.brand
        , mim.rim_item_id as item_key
        , pog.item as item_number
        , pog.sku_nbr as sku    --called home depot sku in for better alignment on join to FACT_POS_WEEKLY in downstream informart
        , to_varchar(date(pog.fbin_week_end_date), 'YYYYMMDD')::integer as transaction_datekey
        , pog.store_hk as store_key
        , pog.store_number as store_id
        , pog.active_sku as active_sku_flag
        , pog.stocked_store as stocked_store_flag
        , to_varchar(date(pog.fbin_week_start_date), 'YYYYMMDD')::integer as fiscal_445_week_start_date__yyyymmdd
        , to_varchar(date(pog.fbin_week_end_date), 'YYYYMMDD')::integer as fiscal_445_week_end_date__yyyymmdd
        , pog.bkcc
        , pog.rec_src
    from moen_pog_weekly_consolidated as pog
        left join moen_item_map as mim
            on pog.item = mim.pog_item_id   --removed filter that excluded home depot skus with no match to fbin item number
    qualify
        row_number()
            over (
                partition by reporting_customer, pog.brand, pog.sku_nbr, transaction_datekey, pog.store_hk --updated qualify function to utilize sku in place of item_key to prevent unmatched skus from being excluded
                order by case active_sku_flag
                    when 'Y' then 1
                    when 'N' then 2
                    else 3
                end
            )
        = 1
