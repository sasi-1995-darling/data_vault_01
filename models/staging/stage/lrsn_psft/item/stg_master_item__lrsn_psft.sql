{%- set yaml_metadata -%}

source_model: 'base_master_item__lrsn_psft'
derived_columns:
    rec_src: "!LRSN PSFT"
    brand: '!LRSN'
    load_dts: current_timestamp()
    item_bk: inv_item_id
hashed_columns:
    item_hk: 
        - item_bk
        - brand
    hdiff:
        is_hashdiff: true
        columns:
           - 'inv_item_id'
           - 'descr'
           - 'descr60'
           - 'unit_measure_std'
           - 'inv_item_group'
           - 'category_id'
           - 'item_field_c6'
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
