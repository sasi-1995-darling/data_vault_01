{%- set yaml_metadata -%}

source_model: 'base_cust_account__ml_ebs'
derived_columns:
    rec_src: "!ML EBS"
    brand: '!TMLC'
    load_dts: current_timestamp()
    cust_account_bk: cust_account_id
hashed_columns:
    cust_account_hk: 
        - cust_account_bk
        - brand
    party_hk: 
        - party_id
        - brand
    hash_diff:
        is_hashdiff: true
        columns:
        - cust_account_id
        - party_id
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}
