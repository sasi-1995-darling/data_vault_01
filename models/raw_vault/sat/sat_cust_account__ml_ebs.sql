{%- set yaml_metadata -%}

source_model: stg_cust_account__ml_ebs
src_pk: 
    - cust_account_hk
src_hashdiff: 
  source_column: hash_diff
  alias: hashdiff
src_payload:
    - cust_account_id
    - party_id
    - party_hk
    - account_name
    - account_number
    - key_account_number
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
