{%- set yaml_metadata -%}

source_model: 'base_prod_item__lrsn_psft'
derived_columns:
    rec_src: "!LRSN PSFT"
    brand: '!LRSN'
    load_dts: current_timestamp()
    item_bk: product_id
hashed_columns:
    item_hk: 
        - item_bk
        - brand
    hdiff:
        is_hashdiff: true
        columns:
           - 'product_id'
           - 'descr'
           - 'product_kit_flag'
           - 'eff_status'
           - 'inv_item_id'
           - 'setid'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict["source_model"] %}
{% set derived_columns = metadata_dict["derived_columns"] %}
{% set hashed_columns = metadata_dict["hashed_columns"] %}

{{
    automate_dv.stage(
        include_source_columns=true,
        source_model=source_model,
        derived_columns=derived_columns,
        hashed_columns=hashed_columns,
        ranked_columns=none,
    )
}}
