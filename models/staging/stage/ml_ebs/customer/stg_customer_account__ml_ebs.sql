{%- set yaml_metadata -%}
source_model: 'base_customer_account__ml_ebs'
derived_columns:
  rec_src: '!ML_EBS'
  load_dts: current_timestamp()
  brand: '!TMLC'
  account_bk: 'account_number'
  customer_bk: 'party_id'
hashed_columns:
  account_hk: 
    columns:
    - 'account_bk'
    - 'brand'
  customer_hk: 
    columns:
    - 'customer_bk'
    - 'brand'
  party_hk: 
    - 'party_id'
    - 'brand'
  hashdiff:
    is_hashdiff: true
    columns:
    - account_name
    - account_number
    - status
    - key_account_number
    - cust_account_id
    - customer_class_code
    - party_id
    - party_hk

{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict['source_model'] %}
{% set derived_columns = metadata_dict['derived_columns'] %}
{% set hashed_columns = metadata_dict['hashed_columns'] %}

{{ automate_dv.stage(include_source_columns=true,
                     source_model=source_model,
                     derived_columns=derived_columns,
                     null_columns=none,
                     hashed_columns=hashed_columns,
                     ranked_columns=none) }}