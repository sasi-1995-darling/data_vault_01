{%- set yaml_metadata -%}
source_model: 'base_invoice_adjustment_customer__emtk_ebs_sales'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  invoice_adjustment_bk: ['org_id', 'trx_number', 'interface_header_attribute1', 'trx_date']
  customer_bk: 'account_number'
  customer_bill_location_bk: 'bill_location_id'
  invoice_adjustment_customer_bk: ['account_number', 'org_id', 'trx_number', 'interface_header_attribute1', 'trx_date', 'bill_location_id']
hashed_columns:
  invoice_adjustment_hk: 
    columns:
    - 'invoice_adjustment_bk'
    - 'brand'
  customer_hk: 
    columns:
    - 'customer_bk'
    - 'brand'
  customer_bill_location_hk: 
    columns:
    - 'customer_bill_location_bk'
    - 'brand'
  invoice_adjustment_customer_hk: 
    columns:
    - 'invoice_adjustment_customer_bk'
    - 'brand'

{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict['source_model'] %}
{% set derived_columns = metadata_dict['derived_columns'] %}
{% set hashed_columns = metadata_dict['hashed_columns'] %}

{{ automate_dv.stage(include_source_columns=true,
                     source_model=source_model,
                     derived_columns=derived_columns,
                     null_columns=none,
                     hashed_columns=hashed_columns,
                     ranked_columns=none) }}
