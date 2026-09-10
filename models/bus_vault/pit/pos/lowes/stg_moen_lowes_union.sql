{{
    config(
        materialized='ephemeral'
    )
}}

with src as
(
select
    item_id
    , item_name
    , store_hk
    , start_date
    , end_date
    , ty_sales
    , ty_sales_units
    , ty_fulfilled_internet_sales
    , ty_fulfilled_internet_units
    , ty_available_inventory_sales
    , ty_available_inventory_units
    , 'MOEN' as brand
    , rec_src
    , load_dts
from {{ ref('sat_sales_inventory__moen_lowes') }}
where end_date > '2021-12-31' and end_date <= '2026-01-30' --Talend deprecated Fivetran source added from this end_date forward 2026-02-10
qualify row_number() over (partition by store_hk, item_id, end_date order by load_dts desc) = 1

union all

select --added Fivetran source, api migrated from Talend 2026-02-10
    item_id
    , item_name
    , store_hk
    , start_date
    , end_date
    , ty_sales
    , ty_sales_units
    , ty_fulfilled_internet_sales
    , ty_fulfilled_internet_units
    , ty_available_inventory_sales
    , ty_available_inventory_units
    , 'MOEN' as brand
    , rec_src
    , load_dts
from {{ ref('sat_sales_inventory__moen_lowes_ft_api') }}
where end_date > '2026-01-30'
qualify row_number() over (partition by store_hk, item_id, start_date, end_date order by load_dts desc) = 1

union all

select
    to_char(item_number) as item_id
    , item_name
    , store_hk
    , try_to_date(start_date) as start_date
    , try_to_date(end_date) as end_date
    , sales_ty as ty_sales
    , units_ty as ty_sales_units
    , fulfilled_internet_sales_ty as ty_fulfilled_internet_sales
    , fulfilled_internet_units_ty as ty_fulfilled_internet_units
    , available_inventory_ty as ty_available_inventory_sales
    , fulfilled_internet_units_ty as ty_available_inventory_units
    , 'MOEN' as brand
    , rec_src
    , load_dts
from {{ ref('sat_sales_inventory_moen_history__lowes') }}
where try_to_date(end_date) <= '2021-12-31'
qualify
    row_number()
        over (
            partition by store_hk, item_number, end_date, supporting_regional_distribution_center_id
            order by load_dts desc
        )
    = 1

union all

(
    with sat_sales_inventory__tsm_lowes__latest as (
        select * from {{ ref('sat_sales_inventory__tsm_lowes') }}
        qualify row_number() over (partition by store_hk, item_number, end_date, _line, _file order by load_dts) = 1
    )

    select
        to_char(item_number) as item_id
        , item_name
        , store_hk
        , try_to_date(start_date) as start_date
        , try_to_date(end_date) as end_date
        , sum(try_to_double(regexp_replace(sales_ty, '[$%,()]', ''))) as ty_sales
        , sum(try_to_number(regexp_replace(sales_units_ty, '[$%,()]', ''))) as ty_sales_units
        , sum(try_to_double(regexp_replace(internet_sales_ty, '[$%,()]', ''))) as ty_fulfilled_internet_sales
        , sum(try_to_number(regexp_replace(internet_units_ty, '[$%,()]', ''))) as ty_fulfilled_internet_units
        , sum(try_to_number(regexp_replace(available_inventory_ty, '[$%,()]', ''))) as ty_available_inventory_sales
        , sum(try_to_number(regexp_replace(available_inventory_units_ty, '[$%,()]', '')))
            as ty_available_inventory_units
        , 'MOEN' as brand
        , rec_src
        , load_dts
    from sat_sales_inventory__tsm_lowes__latest
    group by all
)
)
select
    item_id
    , item_name
    , store_hk
    , start_date
    , end_date
    , sum(ty_sales) as ty_sales
    , sum(ty_sales_units) as ty_sales_units
    , sum(ty_fulfilled_internet_sales) as ty_fulfilled_internet_sales
    , sum(ty_fulfilled_internet_units) as ty_fulfilled_internet_units
    , sum(ty_available_inventory_sales) as ty_available_inventory_sales
    , sum(ty_available_inventory_units) as ty_available_inventory_units
    , 'MOEN' as brand
    , max(load_dts) as load_dts
from src
group by all
