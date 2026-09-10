{%- set yaml_metadata -%}

source_model: 'base_bi_line__lrsn_psft'
derived_columns:
    line_no: 'line_seq_num'
    rec_src: "!LRSN PSFT"
    brand: '!LRSN'
    load_dts: current_timestamp()
    invoice_line_no_item_bk:
        - invoice
        - line_no
        - product_id
    invoice_bk: invoice
    item_bk: product_id
hashed_columns:
    invoice_line_no_item_hk:
        - invoice_line_no_item_bk
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
            - 'business_unit'
            - 'invoice'
            - 'line_seq_num'
            - 'unit_of_measure'
            - 'qty'
            - 'unit_amt'
            - 'gross_extended_amt'
            - 'net_extended_amt'
            - 'net_extended_bse'
            - 'tax_amt'
            - 'tax_amt_bse'
            - 'tot_discount_amt'
            - 'entry_type'
            - 'order_no'
            - 'order_int_line_no'
            - 'product_id'
            - 'ship_from_bu'
            - 'ship_to_cust_id'
            - 'ship_to_addr_num'
            - 'ship_date'
            - 'sold_to_cust_id'
            - 'sold_to_addr_num'
            - 'user2'
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
