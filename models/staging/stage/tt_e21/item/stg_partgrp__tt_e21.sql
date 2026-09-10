{%- set yaml_metadata -%}

source_model: 'base_partgrp__tt_e21'
derived_columns:
    rec_src: "!TT E21TRUBIS"
    load_dts: current_timestamp()
hashed_columns:
    partgrp_hk: 'part_grp'
    hdiff:
        is_hashdiff: true
        columns:
            - 'part_grp'
            - 'part_grp_desc'
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
