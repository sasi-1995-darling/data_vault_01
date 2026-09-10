{% set source_names = '{
        "fei_product_code_moen_sap_xref": ["MOEN","NULL"],
        "fei_product_code_hofr_sap_xref": ["HOFR","NULL"]
    }' %}

{% for src, src_name in fromjson(source_names).items() %}
    select
        _file
        , _line
        , _modified
        , _fivetran_synced
        , fei_product_code
        , sap_material_number
        , sap_account_number
        , '{{ src_name[0] }}' as rec_src
    from {{ source('ferguson_pos_m3a', src) }}
    where fei_product_code is not null
    {% if not loop.last %}
        union all
    {% endif %}
{% endfor %}