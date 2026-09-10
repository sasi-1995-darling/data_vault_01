{%- set yaml_metadata -%}

source_model: 'base_party__ml_ebs'
derived_columns:
    rec_src: "!ML EBS"
    brand: '!TMLC'
    load_dts: current_timestamp()
    party_bk: party_id
hashed_columns:
    party_hk: 
        - party_id
        - brand
    hash_diff:
        is_hashdiff: true
        columns:
        - party_id
        - party_name
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}
