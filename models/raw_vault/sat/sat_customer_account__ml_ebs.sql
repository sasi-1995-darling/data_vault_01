{%- set yaml_metadata -%}

source_model: 'stg_customer_account__ml_ebs'
src_pk: 
    - account_hk
src_hashdiff: 
  source_column: hashdiff
  alias: hashdiff
src_payload:
    - account_name
    - account_number
    - status
    - key_account_number
    - cust_account_id
    - customer_class_code
    - party_id
    - party_hk
src_ldts: load_dts
src_source: rec_src
{%- endset -%}


{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.sat(src_pk=metadata_dict["src_pk"],
                   src_hashdiff=metadata_dict["src_hashdiff"],
                   src_payload=metadata_dict["src_payload"],
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}