{%- set yaml_metadata -%}

source_model: 'base_pos_fiscal_calendar'
derived_columns:
    load_dts: current_timestamp()
    rec_src: '!FILE'
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
