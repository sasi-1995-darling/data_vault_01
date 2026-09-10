{%- set yaml_metadata -%}

source_model: 'base_ausp_brand__moen_sap'
derived_columns:
    rec_src: "!MOEN SAP"
    brand: '!MOEN'
    load_dts: current_timestamp()
    item_bk: objek
    item_id: objek
    item_brand: atwrt
hashed_columns:
    item_hk: 
        - item_bk
        - brand
    hdiff:
        is_hashdiff: true
        columns:
           - 'item_id'
           - 'item_brand'
           
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict["source_model"] %}
{% set derived_columns = metadata_dict["derived_columns"] %}
{% set hashed_columns = metadata_dict["hashed_columns"] %}

{{
    automate_dv.stage(
        include_source_columns=false,
        source_model=source_model,
        derived_columns=derived_columns,
        hashed_columns=hashed_columns,
        ranked_columns=none,
    )
}}