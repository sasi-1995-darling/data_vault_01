{%- set yaml_metadata -%}

source_model: 'stg_invoice_line__tt_e21'
src_pk: 
    - invoice_line_hk
src_hashdiff: 
  source_column: hdiff
  alias: hdiff
src_payload:
    - mstr_inv_numb
    - invoice_numb
    - order_numb
    - ord_item
    - base_part_code
    - item_no
    - ship_qty
    - item_status
    - item_list_price
    - item_sales_amt
    - item_cogs_amt
    - item_priceid
    - item_rep
    - qty
    - item_price
    - cost_ctr
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
