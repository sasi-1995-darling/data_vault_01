{%- set yaml_metadata -%}

source_model: 'stg_systems_items__ml_ebs_v1'
src_pk: 
    - item_hk
    - inventory_item_id
    - organization_id
src_hashdiff: 
  source_column: hdiff
  alias: hdiff
src_payload:
    - inventory_item_id
    - organization_id
    - description
    - primary_unit_of_measure
    - item_type
    - inventory_item_status_code
    - material
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
