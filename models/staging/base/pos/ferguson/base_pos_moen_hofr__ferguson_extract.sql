{% set source_names = '{
        "hofr_m_3_a_new": ["HOFR","NULL"],
        "hofr_m_3_a_new_grove": ["HOFR_GROVE","NULL"],
        "moen_m_3_a_new": ["MOEN","BUILD_COM_ORDER"],
        "moen_m_3_a_new_cfg": ["MOEN_CFG","BUILD_COM_ORDER"],
        "moen_m_3_a_new_grove": ["MOEN_GROVE","BUILD_COM_ORDER"]
    }' %}

{% for src, src_name in fromjson(source_names).items() %}

    select
        _file
    , _line    
    , _fivetran_synced
    , {{ src_name[1] }} as build_com_order
    , customer_group
    , try_to_date(date) as date
    , fei_product_code
    , legacy_sell_location_id
    , order_channel
    , product_dest_city
    , product_dest_state
    , product_dest_zip
    , to_char(sell_location_id) as sell_location_id
    , to_char(ship_location_id) as ship_location_id
    , shipped_qty
    , transaction_type
    , year_month
    , '{{ src_name[0] }}' as rec_src
    from {{ source('ferguson_pos_m3a', src) }}
    where fei_product_code is not null and date is not null --and sell_location_id is not null
    {% if not loop.last %}
        union all
    {% endif %}

{% endfor %}