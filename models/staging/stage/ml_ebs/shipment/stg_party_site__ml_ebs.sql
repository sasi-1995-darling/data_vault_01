{%- set yaml_metadata -%}

source_model: 'base_party_site__ml_ebs'
derived_columns:
    rec_src: "!ML EBS"
    brand: '!TMLC'
    load_dts: current_timestamp()
    party_site_bk: party_site_id
hashed_columns:
    party_site_hk: 
        - party_site_id
        - brand
    hash_diff:
        is_hashdiff: true
        columns:
        - party_site_id
        - location_id
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}
