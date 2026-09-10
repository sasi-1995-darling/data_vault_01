{%- set yaml_metadata -%}

source_model: stg_master_item__lrsn_psft
src_pk: 
    - item_hk
src_hashdiff: 
  source_column: hdiff
  alias: hdiff
src_payload:
    - inv_item_id
    - descr
    - descr60
    - unit_measure_std
    - inv_item_group
    - category_id
    - item_field_c6
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
