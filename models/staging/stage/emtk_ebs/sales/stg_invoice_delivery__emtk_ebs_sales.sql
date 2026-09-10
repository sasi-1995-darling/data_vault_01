{%- set yaml_metadata -%}
source_model: 'base_invoice_delivery__emtk_ebs_sales'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  invoice_bk: ['org_id', 'trx_number', 'interface_header_attribute1']  
  delivery_bk: delivery_detail_id
hashed_columns:
  invoice_delivery_hk: 
    columns:
    - 'invoice_bk'
    - 'delivery_bk'
    - 'brand'
  invoice_hk:
    columns:
    - 'invoice_bk'
    - 'brand'
  delivery_hk: 
    columns:
    - 'delivery_bk'
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
