{%- set yaml_metadata -%}

source_model: stg_prod_grp__lrsn_psft
src_pk: 
    - item_hk
src_hashdiff: 
  source_column: hdiff
  alias: hdiff
src_payload:
    - product_id
    - l_company
    - l_group
    - l_category
    - l_class
    - l_series
    - l_model
    - user_dim_1
    - user_dim_5
    - user_dim_8
    - user_dim_14
    - product_kit_id
    - l_sizew
    - l_sizeh
    - release_flag
    - setid
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
