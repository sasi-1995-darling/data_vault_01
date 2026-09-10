{%- set yaml_metadata -%}

source_model: 'base_category_map__file_extract'
derived_columns:
    rec_src: "!ML EBS"
    load_dts: current_timestamp()
    ref_id: category_id
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{
    automate_dv.stage(
        include_source_columns=true,
        source_model=metadata_dict["source_model"],
        derived_columns=metadata_dict["derived_columns"],
    )
}}
