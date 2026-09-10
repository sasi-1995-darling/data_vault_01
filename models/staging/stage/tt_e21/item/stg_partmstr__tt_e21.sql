{%- set yaml_metadata -%}

source_model: 'base_partmstr__tt_e21'
derived_columns:
    rec_src: "!TT E21TRUBIS"
    brand: '!THTRU'
    load_dts: current_timestamp()
    item_bk: part_code
    item_id: part_code
    base_material: part_code
hashed_columns:
    item_hk: 
        - item_bk
        - brand
    hdiff:
        is_hashdiff: true
        columns:
            - 'item_id'
            - 'part_desc'
            - 'uom'
            - 'part_type'
            - 'part_status'
            - 'long_desc1'
            - 'long_desc2'
            - 'long_desc3'
            - 'long_desc4'
            - 'long_desc5'
            - 'long_desc6'
            - 'long_desc7'
            - 'long_desc8'
            - 'long_desc9'
            - 'long_desc10'
            - 'tt_color'
            - 'tt_shape'
            - 'part_length'
            - 'part_width'
            - 'part_height'
            - 'sellable'
            - 'base_part_flag'
            - 'part_grp'
            - 'part_subgrp'
            - 'part_subgrp2'
            - 'part_subgrp3'
            
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
