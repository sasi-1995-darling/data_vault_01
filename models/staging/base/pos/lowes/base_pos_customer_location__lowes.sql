with src_data as (
    select
        location_id
        , location_desc
        , delivery_city
        , delivery_state
        , delivery_code
        , salesfloor_footage
        , district_district as district
        , region_id
        , region_desc
        , division_division as division
        , advertising_area
        , geo_id
        , geo_desc
        , forecast_zone
        , supporting_center
        , supporting_fdc
        , supporting_transload
        , open_date
        , 'LOWES' as rec_src
    from {{ source('lowes_us', 'location') }}
    union all
{% set source_names = '{
        "sales_inventory_moen": ["LOWES"],
        "sales_inventory_masterlock": ["LOWES"],
        "sales_inventory_larson": ["LOWES"]
    }' %}

    {% for src, src_name in fromjson(source_names).items() %}
        select distinct
            s.location_id
            , '' as location_desc
            , '' as delivery_city
            , '' as delivery_state
            , '' as delivery_code
            , '' as salesfloor_footage
            , '' as district
            , '' as region_id
            , '' as region_desc
            , '' as division
            , '' as advertising_area
            , '' as geo_id
            , '' as geo_desc
            , '' as forecast_zone
            , '' as supporting_center
            , '' as supporting_fdc
            , '' as supporting_transload
            , null as open_date
            , '{{ src_name[0] }}' as rec_src
        from
            {{ source('lowes_vpp', src) }} as s
            left join
                {{ source('lowes_us', 'location') }} as l on
                s.location_id = l.location_id
        where l.location_id is null
        {% if not loop.last %}
            union all
        {% endif %}
    {% endfor %}
    union all
    select distinct
        coalesce(nullif(to_char(s.location_id), ''), '907') as location_id
        , '' as location_desc
        , '' as delivery_city
        , '' as delivery_state
        , '' as delivery_code
        , '' as salesfloor_footage
        , '' as district
        , '' as region_id
        , '' as region_desc
        , '' as division
        , '' as advertising_area
        , '' as geo_id
        , '' as geo_desc
        , '' as forecast_zone
        , '' as supporting_center
        , '' as supporting_fdc
        , '' as supporting_transload
        , null as open_date
        , 'LOWES' as rec_src
    from
        {{ source('lowes_tsm', 'tsm_lowes_us') }} as s
        left join
            {{ source('lowes_us', 'location') }} as l on
            s.location_id = l.location_id
    where l.location_id is null
    union all
     select distinct
            to_char(s.location_id) as location_id
            , '' as location_desc
            , '' as delivery_city
            , '' as delivery_state
            , '' as delivery_code
            , '' as salesfloor_footage
            , '' as district
            , '' as region_id
            , '' as region_desc
            , '' as division
            , '' as advertising_area
            , '' as geo_id
            , '' as geo_desc
            , '' as forecast_zone
            , '' as supporting_center
            , '' as supporting_fdc
            , '' as supporting_transload
            , null as open_date
            , 'LOWES' as rec_src
        from
            {{ source('lowes_vpp', 'sales_inventory') }} as s
            left join
                {{ source('lowes_us', 'location') }} as l on
                s.location_id = l.location_id
        where l.location_id is null
)

select distinct
    location_id
    , location_desc
    , delivery_city
    , delivery_state
    , delivery_code
    , salesfloor_footage
    , district
    , region_id
    , region_desc
    , division
    , advertising_area
    , geo_id
    , geo_desc
    , forecast_zone
    , supporting_center
    , supporting_fdc
    , supporting_transload
    , open_date
    , rec_src
from src_data
