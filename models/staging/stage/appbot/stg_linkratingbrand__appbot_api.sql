{%- set yaml_metadata -%}

source_model: 'base_linkratingbrand__appbot_api'
derived_columns:
    load_dts: current_timestamp()
    rec_src: "!APPBOT"
hashed_columns:
    link_rating_brand_hk:
        - link_rating_brand
    rating_hk:
        - rating_bk
    brand_hk:
        - brand_bk


{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{
    automate_dv.stage(
        include_source_columns=true,
        source_model=metadata_dict["source_model"],
        derived_columns=metadata_dict["derived_columns"],
        hashed_columns=metadata_dict["hashed_columns"],
    )
}}
