{%- set yaml_metadata -%}

source_model: stg_item_master__moen_sap
src_pk: 
    - item_hk
src_hashdiff: 
  source_column: hdiff
  alias: hdiff
src_payload:
    - item_id
    - room_area_id
    - item_group_id
    - item_platform_id
    - item_type_id
    - item_finish_id
    - reporting_category_id
    - item_architecture_id
    - item_line_id
    - item_price_category_id
    - item_price_type_group_id
    - business_owner_id
    - business_unit_id
    - imap_flag
    - item_type_code
    - base_material
    - item_status
    - room_area_id_hk
    - item_group_id_hk
    - item_platform_id_hk
    - item_type_id_hk
    - item_finish_id_hk
    - reporting_category_id_hk
    - item_architecture_id_hk
    - item_line_id_hk
    - item_price_category_id_hk
    - item_price_type_group_id_hk
    - business_owner_id_hk
    - business_unit_id_hk
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