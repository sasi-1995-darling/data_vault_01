{%- set yaml_metadata -%}

source_model: 'base_cust_site_use__ml_ebs'
derived_columns:
    rec_src: "!ML EBS"
    brand: '!TMLC'
    load_dts: current_timestamp()
    site_use_bk: site_use_id
hashed_columns:
    site_use_hk: 
        - site_use_bk
        - brand
    cust_acct_site_hk: 
        - cust_acct_site_id
        - brand
    hash_diff:
        is_hashdiff: true
        columns:
        - site_use_id
        - org_id
        - location
        - status
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}
