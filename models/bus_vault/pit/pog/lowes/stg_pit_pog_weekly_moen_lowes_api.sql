{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_pog_weekly__lowes as (
    select
        store_hk
        ,item_number
        ,location_id
        ,week_id
        ,hovbu_id
        ,hovbu_desc
        ,stocked_stores
        ,rec_src
        ,load_dts
    from {{ ref('sat_pog_weekly__lowes') }}
    where hovbu_id = '866'  --filter to isolate Moen Lowes POG data
)

, cte_sat_pog_weekly__lowes_latest as (
    {{ generate_cte_satellite_latest('cte_sat_pog_weekly__lowes','store_hk, hovbu_id, item_number, week_id') }}
)

, cte_basematerial_item_map as (    --direct from Orion PIT_POS_WEEKLY logic
    select distinct
        base_material_key
        , first_value(item_hk) over (partition by base_material_key order by item_hk) as item_id
    from {{ ref('pb_items_by_plant') }}
)

, cte_lowes_moen_xref as (
    select
        lowes_sku
        , base_material_hk
        , moen_us
        , load_dts
    from {{ ref('ref_pos_lowes_moen_xref') }}
)

, cte_lowes_moen_xref_latest as (
    {{ generate_cte_satellite_latest('cte_lowes_moen_xref','lowes_sku') }}
)

, cte_pit_fbin_fiscal_calendar as (
    select
        date_bk
        , date
        , fiscal_445_cal_week as fiscal_week_number
        , fiscal_445_cal_month as fiscal_month_number
        , fiscal_445_cal_quarter as fiscal_quarter
        , fiscal_445_cal_year as fiscal_year
        , dateadd(day, -dayofweek(date(date)), date(date)) as fbin_week_start_date
        , dateadd(day, 6 -dayofweek(date(date)), date(date)) as fbin_week_end_date
    from {{ ref('pit_date_fiscal_445') }}
)

,cte_lowes_pog_api_base as(
    select
        'LOWES' as reporting_customer
        , 'MOEN' as brand
        , bmp.item_id as item_key
        , xref.moen_us as item_number
        , spog.item_number as sku
        , to_varchar(date(fc.fbin_week_end_date), 'YYYYMMDD')::integer as transaction_datekey
        , hs.store_hk as store_key
        , hs.store_bk as store_id
        , case spog.stocked_stores
            when 1 then 'Y'
            else 'N'
        end as active_sku_flag
        , spog.stocked_stores as stocked_store_flag
        , to_varchar(date(fc.fbin_week_start_date), 'YYYYMMDD')::integer as fiscal_445_week_start_date__yyyymmdd
        , to_varchar(date(fc.fbin_week_end_date), 'YYYYMMDD')::integer as fiscal_445_week_end_date__yyyymmdd
        , hs.bkcc
        , spog.rec_src
    from {{ ref('hub_store') }} as hs
        inner join cte_sat_pog_weekly__lowes_latest as spog
            on hs.store_hk = spog.store_hk
                and hs.bkcc = 'Laughing_Hyena'
        inner join cte_pit_fbin_fiscal_calendar as fc
            on spog.week_id = fc.date
        left join cte_lowes_moen_xref_latest as xref
            on spog.item_number = xref.lowes_sku
        left join cte_basematerial_item_map as bmp
            on xref.base_material_hk = bmp.base_material_key
)

select
    reporting_customer
    , brand
    , item_key
    , item_number
    , sku
    , transaction_datekey
    , store_key
    , store_id
    , active_sku_flag
    , stocked_store_flag
    , fiscal_445_week_start_date__yyyymmdd
    , fiscal_445_week_end_date__yyyymmdd
    , bkcc
    , rec_src
from cte_lowes_pog_api_base
qualify
    row_number()
        over (
            partition by reporting_customer, brand, sku, transaction_datekey, store_key
            order by case active_sku_flag
                when 'Y' then 1
                when 'N' then 2
                else 3
            end
        )
    = 1