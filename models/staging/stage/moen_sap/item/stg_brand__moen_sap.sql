{%- set yaml_metadata -%}

source_model: 'base_brand__moen_sap'
derived_columns:
    rec_src: rec_src
    load_dts: current_timestamp()
    brand_bk: 
        - atwrt
hashed_columns:
    brand_hk: 
        - atwrt
    hdiff:
        is_hashdiff: true
        columns:
           - atwrt

           
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