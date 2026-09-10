{%- set yaml_metadata -%}

source_model: stg_invoice_line__ml_ebs
src_pk: 
    - invoice_line_hk
src_hashdiff: 
  source_column: hash_diff
  alias: hashdiff
src_payload:
    - customer_trx_line_id
    - customer_trx_id
    - invoice_hk
    - inventory_item_id
    - org_id
    - quantity_invoiced
    - quantity_credited
    - interface_line_attribute6
    - unit_selling_price 
    - ship_to_customer_id
    - quantity_ordered
    - sales_order
    - item_bk
    - line_type
    - memo_line_id
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
