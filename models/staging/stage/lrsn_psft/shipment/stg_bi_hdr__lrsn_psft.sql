{%- set yaml_metadata -%}

source_model: 'base_bi_hdr__lrsn_psft'
derived_columns:
    rec_src: "!LRSN PSFT"
    brand: '!LRSN'
    load_dts: current_timestamp()
    invoice_bk: invoice
    ship_to_customer_bk: ship_to_cust_id
    sold_to_customer_bk: sold_to_cust_id
    bill_to_customer_bk: bill_to_cust_id
    invoice_ship_to_customer_bk:
        - invoice 
        - ship_to_cust_id
    invoice_sold_to_customer_bk: 
        - invoice
        - sold_to_cust_id
    invoice_bill_to_customer_bk: 
        - invoice
        - bill_to_cust_id
hashed_columns:
    invoice_hk: 
        - invoice_bk
        - brand
    ship_to_customer_hk: 
        - ship_to_customer_bk
        - brand
    sold_to_customer_hk: 
        - sold_to_customer_bk
        - brand
    bill_to_customer_hk: 
        - bill_to_customer_bk
        - brand
    invoice_ship_to_customer_hk:
        - invoice_ship_to_customer_bk
        - brand
    invoice_sold_to_customer_hk: 
        - invoice_sold_to_customer_bk
        - brand
    invoice_bill_to_customer_hk: 
        - invoice_bill_to_customer_bk
        - brand
    hdiff:
        is_hashdiff: true
        columns:
            - 'business_unit'
            - 'invoice'
            - 'bill_to_cust_id'
            - 'bill_status'
            - 'invoice_type'
            - 'sales_person'
            - 'invoice_amount'
            - 'invoice_dt'
            - 'dt_invoiced'
            - 'entry_type'
            - 'entry_reason'
            - 'order_no'
            - 'ship_to_cust_id'
            - 'ship_from_bu'
            - 'sold_to_cust_id'
            - 'user1'
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
