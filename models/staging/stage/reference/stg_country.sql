{%- set yaml_metadata -%}

source_model: 'base_country'
derived_columns:
    rec_src: "!bronze.reference"
    load_dts: current_timestamp()
hashed_columns:
    ref_id: 
        - country
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