{%- set yaml_metadata -%}

source_model: 'base_invoice_line__tt_e21'
derived_columns:
    base_part_code: part_code
    rec_src: "!TT E21TRUBIS"
    load_dts: TO_TIMESTAMP_TZ(current_timestamp())
    brand: '!THTRU'
    invoice_line_bk: concat(base_part_code,'||',item_no)
    invoice_bk: to_char(invoice_numb)
    item_bk: part_code
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
    hdiff:
        is_hashdiff: true
        columns:
            - 'mstr_inv_numb'
            - 'invoice_numb'
            - 'order_numb'
            - 'ord_item'
            - 'base_part_code'
            - 'item_no'
            - 'ship_qty'
            - 'item_status'
            - 'item_list_price'
            - 'item_sales_amt'
            - 'item_cogs_amt'
            - 'item_priceid'
            - 'item_rep'
            - 'qty'
            - 'item_price'
            - 'cost_ctr'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict["source_model"] %}
{% set derived_columns = metadata_dict["derived_columns"] %}
{% set hashed_columns = metadata_dict["hashed_columns"] %}

{{
    automate_dv.stage(
        include_source_columns=true,
        source_model=source_model,
        derived_columns=derived_columns,
        hashed_columns=hashed_columns,
        ranked_columns=none,
    )
}}
