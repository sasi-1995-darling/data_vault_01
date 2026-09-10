{%- set yaml_metadata -%}

source_model: 'base_location__ml_ebs'
derived_columns:
    rec_src: "!ML EBS"
    brand: '!TMLC'
    load_dts: current_timestamp()
    zipcode: postal_code
    location_bk: CAST(location_id AS VARCHAR)
hashed_columns:
    location_hk: 
        - location_id
        - brand
    hash_diff:
        is_hashdiff: true
        columns:
        - location_id
        - address1
        - address2
        - address3
        - address4
        - city
        - state
        - zipcode
        - country
        - province
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}
