{%- set yaml_metadata -%}

source_model: stg_pos_product_customer_inventory__hd_askuity
src_pk: 
    - product_inventory_hk
src_hashdiff: 
  source_column: hash_diff
  alias: hashdiff
src_payload:
    - customer_location_hk
    - day
    - manuf_part_number
    - d_store_nbr
    - sku_nbr
    - str_oh
    - str_oh_units_dly
    - home_depot_account
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
