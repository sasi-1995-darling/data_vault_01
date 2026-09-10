{%- set yaml_metadata -%}

source_model: 'base_cust_acct_site__ml_ebs'
derived_columns:
    rec_src: "!ML EBS"
    brand: '!TMLC'
    load_dts: current_timestamp()
    cust_acct_site_bk: cust_acct_site_id
hashed_columns:
    cust_acct_site_hk: 
        - cust_acct_site_bk
        - brand
    hash_diff:
        is_hashdiff: true
        columns:
        - cust_acct_site_id
        - party_site_id
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}
