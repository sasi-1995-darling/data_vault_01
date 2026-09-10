{%- set yaml_metadata -%}

source_model: stg_pos_product_customer__hd_askuity
src_pk: 
    - product_customer_hk
src_hashdiff: 
  source_column: hash_diff
  alias: hashdiff
src_payload:
    - customer_location_hk
    - product_inventory_hk
    - day
    - fulfillment_channel
    - manuf_part_number
    - merch_vendor
    - sku_nbr
    - sku_status
    - d_store_nbr
    - sales_units
    - m_ty_returns_sum
    - m_ty_return_units_sum
    - sales
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
