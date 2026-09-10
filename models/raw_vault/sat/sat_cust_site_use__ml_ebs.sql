{%- set yaml_metadata -%}

source_model: stg_cust_site_use__ml_ebs
src_pk: 
    - site_use_hk
src_hashdiff: 
  source_column: hash_diff
  alias: hashdiff
src_payload:
    - site_use_id
    - org_id
    - location
    - status
    - site_use_code
    - cust_acct_site_hk
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
