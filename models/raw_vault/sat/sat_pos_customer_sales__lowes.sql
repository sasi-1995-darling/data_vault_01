{%- set yaml_metadata -%}

source_model: stg_pos_customer_sales__lowes
src_pk: 
    - customer_sales_hk
src_hashdiff: 
  source_column: hash_diff
  alias: hashdiff
src_payload:
    - brand
    - customer_location_hk
    - item_id
    - item_name
    - location_name
    - start_date
    - end_date
    - ty_sales
    - ty_sales_units
    - ty_fulfilled_internet_sales
    - ty_fulfilled_internet_units
    - ty_available_inventory_sales
    - ty_available_inventory_units
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
