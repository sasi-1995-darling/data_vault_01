{%- set yaml_metadata -%}

source_model: stg_pos_moen_hofr__ferguson_extract
src_pk: 
    - product_customer_hk
src_hashdiff: 
  source_column: hash_diff
  alias: hashdiff
src_payload:
    - sell_location_id_hk
    - ship_location_id_hk
    - _file
    - _fivetran_synced
    - year_month
    - date
    - transaction_type
    - order_channel
    - build_com_order
    - customer_group
    - fei_product_code
    - product_dest_zip
    - shipped_qty
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
