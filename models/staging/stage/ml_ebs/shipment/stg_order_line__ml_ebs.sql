{%- set yaml_metadata -%}

source_model: 'base_order_line__ml_ebs'
derived_columns:
    rec_src: "!ML EBS"
    brand: '!TMLC'
    load_dts: current_timestamp()
    order_line_bk: to_char(line_id)
hashed_columns:
    order_line_hk: order_line_bk
    hash_diff:
        is_hashdiff: true
        columns:
        - item_type_code
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}
