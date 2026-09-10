{{
    config(
        materialized='ephemeral'
    )
}}

with cte_sat_sales_inventory__moen_lowes as (
    select
        store_hk
        , end_date
        , item_id
        , location_id
        , ty_sales_units
        , ty_sales
        , ty_fulfilled_internet_sales
        , rec_src
        , load_dts
    from {{ ref('sat_sales_inventory__moen_lowes') }}
)

, cte_sat_sales_inventory__moen_lowes_latest as (
    {{ generate_cte_satellite_latest('cte_sat_sales_inventory__moen_lowes','store_hk, item_id, end_date') }}
)

, cte_sat_sales_inventory__tsm_lowes as (
    select
        store_hk
        , end_date_dt as end_date
        , item_number
        , sales_units_ty
        , sales_ty
        , internet_sales_ty
        , _line
        , _file
        , rec_src
        , load_dts
    from {{ ref('sat_sales_inventory__tsm_lowes') }}
)

, cte_sat_sales_inventory__tsm_lowes_latest as (
    {{ generate_cte_satellite_latest('cte_sat_sales_inventory__tsm_lowes','store_hk, item_number, end_date, _line, _file') }}        
)

, cte_basematerial_item_map as (     --direct from Orion PIT_POS_WEEKLY logic
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

, cte_ref_lowes_stocked_stores_by_item_sat as (
    select
        lowes_sku_bk
        , week_id
        , lowes_business_unit_desc
        , stocked_stores
        , load_dts
    from {{ ref('ref_lowes_stocked_stores_by_item_sat') }}
)

, cte_ref_lowes_stocked_stores_by_item_sat_latest as (
    {{ generate_cte_satellite_latest('cte_ref_lowes_stocked_stores_by_item_sat','week_id, lowes_sku_bk, lowes_business_unit_desc') }}        
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

-- pos needed to determine sku being actively stocked at the store lvl; i.e. total pos$ as part of calc
, cte_lowes_moen_with_tsm_pos_base as (
    select
        try_to_date(ssim.end_date) as end_date
        , ssim.item_id
        , hs.store_bk as location_id
        , hs.store_hk
        , hs.bkcc
        , ssim.rec_src
        , ssim.ty_sales_units
        , ssim.ty_sales
        , ssim.ty_fulfilled_internet_sales
    from {{ ref('hub_store') }} as hs
        inner join cte_sat_sales_inventory__moen_lowes_latest as ssim
            on hs.store_hk = ssim.store_hk
                and hs.bkcc = 'Laughing_Hyena'
    where year(date(ssim.end_date)) >= 2023

    union all

    select
        coalesce(try_to_date(ssit.end_date), try_to_date(current_date())) as pos_date
        , ssit.item_number as item_id
        , hs.store_bk as location_id
        , hs.store_hk
        , hs.bkcc
        , ssit.rec_src
        , ssit.sales_units_ty as ty_sales_units
        , replace(replace(ssit.sales_ty, '$', ''), ',', '')::float as ty_sales
        , replace(replace(ssit.internet_sales_ty, '$', ''), ',', '')::float as ty_fulfilled_internet_sales
    from {{ ref('hub_store') }} as hs
        inner join cte_sat_sales_inventory__tsm_lowes_latest as ssit
            on hs.store_hk = ssit.store_hk
                and hs.bkcc = 'Laughing_Hyena'
    where try_to_number(ssit.sales_units_ty) is not null
        and try_to_number(ssit.sales_ty) is not null
        and try_to_number(ssit.internet_sales_ty) is not null
        and year(pos_date) >= 2023
)

, cte_lowes_moen_pos_by_store as (
    select
        end_date
        , item_id
        , location_id
        , store_hk
        , rec_src
        , bkcc
        , sum(ty_sales) as pos_amount
        -- rown = derive a quantity of stores based on largest dollar amt, where item is sold(+) or returned(-) for that week
        , row_number() over (partition by end_date, item_id order by pos_amount desc) as rown
    from cte_lowes_moen_with_tsm_pos_base
    where year(end_date) >= 2023
        and location_id <> '907' --ecommerce generic location excluded
    group by all
)

, cte_lowes_moen_pog_agg as (
    select distinct
        rslss.week_id
        , rhlss.lowes_sku_bk as item_id
        , rslss.stocked_stores
    from {{ ref('ref_lowes_stocked_stores_by_item_hub') }} as rhlss
        inner join cte_ref_lowes_stocked_stores_by_item_sat_latest as rslss
            on rhlss.lowes_sku_bk = rslss.lowes_sku_bk
                and lowes_business_unit_desc in ('MOEN INC')
)

, cte_lowes_moen_pog_weekly_by_store_base as (
    select
        pos.end_date
        , pos.item_id
        , pos.location_id
        , pos.store_hk
        , pos.rec_src
        , pos.bkcc
        , case
            when pog.stocked_stores >= pos.rown then 'Y' -- use our derived value to determine if store is considered actve or not.(potentially rules out return only sku at store)
            else 'N'
        end as active_sku
    from cte_lowes_moen_pos_by_store as pos
        inner join cte_lowes_moen_pog_agg as pog
            on pos.item_id = pog.item_id
                and pos.end_date = pog.week_id
)

, lowes_moen_weekly_base as (
    select
        'LOWES' as reporting_customer
        , 'MOEN' as brand
        , bmp.item_id as item_key
        , xref.moen_us as item_number
        , pos.item_id as sku    --called lowes sku to facilitate better alignment in join with FACT_POS_WEEKLY in downstream infomart
        , to_varchar(date(fc.fbin_week_end_date), 'YYYYMMDD')::integer as transaction_datekey
        , pos.store_hk as store_key
        , pos.location_id as store_id
        , case
            when pos.location_id = '907' then 'Y'
            else coalesce(pog.active_sku, 'U')
        end as active_sku_flag
        , case
            when (pos.location_id = '907' or pog.active_sku = 'Y') then 1
            else 0
        end as stocked_store_flag
        , case
            when pos.location_id = '907' then 'EC'
            else 'RT'
        end as fulfillment_channel
        , to_varchar(date(fc.fbin_week_start_date), 'YYYYMMDD')::integer as fiscal_445_week_start_date__yyyymmdd
        , to_varchar(date(fc.fbin_week_end_date), 'YYYYMMDD')::integer as fiscal_445_week_end_date__yyyymmdd
        , pos.bkcc
        , pos.rec_src
        , sum(pos.ty_sales_units) as pos_quantity
        , sum(pos.ty_sales) as pos_amount
    from cte_lowes_moen_with_tsm_pos_base as pos
        inner join cte_pit_fbin_fiscal_calendar as fc
            on pos.end_date = fc.date
        left join cte_lowes_moen_xref_latest as xref
            on pos.item_id = xref.lowes_sku
        left join cte_basematerial_item_map as bmp
            on xref.base_material_hk = bmp.base_material_key
        left join cte_lowes_moen_pog_weekly_by_store_base as pog
            on pos.end_date = pog.end_date
                and pos.item_id = pog.item_id
                and pos.location_id = pog.location_id
    group by all
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
from lowes_moen_weekly_base
qualify --removed item_key filter and updated qualify function to use lowes sku to prevent unmatched skus from being excluded
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
