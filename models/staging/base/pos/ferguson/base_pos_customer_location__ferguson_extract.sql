{% set source_names = '{
        "hofr_m_3_a_new": ["HOFR","NULL"],
        "hofr_m_3_a_new_grove": ["HOFR_GROVE","NULL"],
        "moen_m_3_a_new": ["MOEN","BUILD_COM_ORDER"],
        "moen_m_3_a_new_cfg": ["MOEN_CFG","BUILD_COM_ORDER"],
        "moen_m_3_a_new_grove": ["MOEN_GROVE","BUILD_COM_ORDER"]
    }' %}


with cte_sell_ship_location as (

    {% for src, src_name in fromjson(source_names).items() %}

        select distinct
            to_char(sell_location_id) as location_id
            , sell_location_name as location_name
            , null as location_city
            , null as location_state
            , null as location_zip
            , '{{ src_name[0] }}' as rec_src
        from {{ source('ferguson_pos_m3a', src) }}
        --where sell_location_id is not null
        union
        select distinct
            to_char(ship_location_id) as location_id
            , ship_location_name as location_name
            , ship_location_city as location_city
            , ship_location_state as location_state
            , ship_location_zip as location_zip
            , '{{ src_name[0] }}' as rec_src
        from {{ source('ferguson_pos_m3a', src) }}
        where ship_location_id is not null
        {% if not loop.last %}
            union all
        {% endif %}


    {% endfor %}
)

, cte_ranked_data as (
    select
        *
        , ROW_NUMBER() over (
            partition by location_id order by
                case when location_name is null then 1 else 0 end
                + case when location_city is null then 1 else 0 end
                + case when location_state is null then 1 else 0 end
                + case when location_zip is null then 1 else 0 end
        ) as rn
    from
        cte_sell_ship_location
)

select
    location_id
    , location_name
    , location_city
    , location_state
    , location_zip
    , rec_src
from
    cte_ranked_data
where
    rn = 1
