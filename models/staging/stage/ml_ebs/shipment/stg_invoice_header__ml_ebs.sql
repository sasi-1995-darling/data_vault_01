{%- set yaml_metadata -%}

source_model: 'base_invoice_header__ml_ebs'
derived_columns:
    rec_src: "!ML EBS"
    brand: '!TMLC'
    load_dts: current_timestamp()
    invoice_bk: to_char(customer_trx_id)
    payment_schedule_bk: to_char(customer_trx_id)
hashed_columns:
    invoice_hk: 
        - invoice_bk
        - brand
    payment_schedule_hk: payment_schedule_bk
    invoice_payment_schedule_hk: 
        - payment_schedule_bk
        - invoice_bk
    hash_diff:
        is_hashdiff: true
        columns:
        - sold_to_customer_id
        - bill_to_customer_id
        - bill_to_site_use_id
        - attribute9
        - invoice_currency_code
        - trx_date
        - primary_salesrep_id
        - ship_date_actual
        - purchase_order
        - org_id
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}


{{ automate_dv.stage(include_source_columns=true,
                     source_model=metadata_dict['source_model'],
                     derived_columns=metadata_dict['derived_columns'],
                     hashed_columns=metadata_dict['hashed_columns']) }}
