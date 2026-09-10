{% set source_names = '{
        "sales_inventory_moen": ["MOEN","LOWES_VPP"],
        "sales_inventory_masterlock": ["MASTER LOCK","LOWES_VPP"],
        "sales_inventory_larson": ["LARSON","LOWES_VPP"]
    }' %}

{% for src, src_name in fromjson(source_names).items() %}

    select
        item_id
        , item_name
        , location_id
        , location_name
        , start_date
        , end_date
        , ty_sales
        , ty_sales_units
        , ty_fulfilled_internet_sales
        , ty_fulfilled_internet_units
        , ty_available_inventory_sales
        , ty_available_inventory_units
        , '{{ src_name[0] }}' as brand
        , '{{ src_name[1] }}' as rec_src
    from {{ source('lowes_vpp', src) }}
    {% if  src_name[0]  == 'MOEN' %}
        where end_date > '2021-12-31'
    {% endif %}
    {% if not loop.last %}
        union all
    {% endif %}
{% endfor %}

union all

select
    to_char(item_number) as item_id
    , item_name
    , coalesce(nullif(to_char(location_id), ''), '907') as location_id
    , '' as location_name
    , try_to_date(start_date) as start_date
    , try_to_date(end_date) as end_date
    , sum(try_to_double(regexp_replace(sales_ty, '[$%,()]', ''))) as ty_sales
    , sum(try_to_number(regexp_replace(sales_units_ty, '[$%,()]', ''))) as ty_sales_units
    , sum(try_to_double(regexp_replace(internet_sales_ty, '[$%,()]', ''))) as ty_fulfilled_internet_sales
    , sum(try_to_number(regexp_replace(internet_units_ty, '[$%,()]', ''))) as ty_fulfilled_internet_units
    , sum(try_to_number(regexp_replace(available_inventory_ty, '[$%,()]', ''))) as ty_available_inventory_sales
    , sum(try_to_number(regexp_replace(available_inventory_units_ty, '[$%,()]', ''))) as ty_available_inventory_units
    , 'MOEN' as brand
    , 'LOWES_TSM' as rec_src
from {{ source('lowes_tsm', 'tsm_lowes_us') }}
group by all

union all

select
    to_char(item_number) as item_id
    , item_name
    , to_char(location_id) as location_id
    , '' as location_name
    , try_to_date(start_date) as start_date
    , try_to_date(end_date) as end_date
    , sales_ty as ty_sales
    , units_ty as ty_sales_units
    , fulfilled_internet_sales_ty as ty_fulfilled_internet_sales
    , fulfilled_internet_units_ty as ty_fulfilled_internet_units
    , available_inventory_ty as ty_available_inventory_sales
    , fulfilled_internet_units_ty as ty_available_inventory_units
    , 'MOEN' as brand
    , 'LOWES_VPP_HIST' as rec_src
from {{ source('lowes_vpp', 'sales_inventory') }}
where try_to_date(end_date) <= '2021-12-31'
