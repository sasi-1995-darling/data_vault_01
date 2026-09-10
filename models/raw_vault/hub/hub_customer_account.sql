{%- set yaml_metadata -%}

source_model: 
    - 'stg_customer_account__ml_ebs'
    - 'stg_customer_account__tt_e21'    
src_pk: account_hk
src_nk: 
    - account_bk
    - brand
src_ldts: load_dts
src_source: rec_src
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.hub(src_pk=metadata_dict["src_pk"],
                   src_nk=metadata_dict["src_nk"], 
                   src_ldts=metadata_dict["src_ldts"],
                   src_source=metadata_dict["src_source"],
                   source_model=metadata_dict["source_model"]) }}