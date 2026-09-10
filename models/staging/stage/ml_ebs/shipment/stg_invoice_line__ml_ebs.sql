{%- set yaml_metadata -%}

source_model: 'base_invoice_line__ml_ebs'
derived_columns:
    rec_src: "!ML EBS"
    load_dts: TO_TIMESTAMP_TZ(current_timestamp())
    brand: '!TMLC'
    invoice_line_bk: to_char(customer_trx_line_id)
    invoice_bk: to_char(customer_trx_id)
    order_line_bk: to_char(interface_line_attribute6)
    item_bk: 
        - inventory_item_id
        - org_id
hashed_columns:
    invoice_line_hk: 
        - invoice_line_bk
        - brand
    invoice_hk: 
        - invoice_bk
        - brand
    item_hk: 
        - item_bk
        - brand
    order_line_hk: order_line_bk
    invoice_line_order_line_hk:
        - invoice_line_bk
        - brand
        - order_line_bk
    hash_diff:
        is_hashdiff: true
        columns:
        - customer_trx_line_id
        - customer_trx_id
        - inventory_item_id
        - org_id
        - quantity_invoiced
        - quantity_credited
        - interface_line_attribute6
        - unit_selling_price
        - ship_to_customer_id
        - quantity_ordered
        - sales_order
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}
