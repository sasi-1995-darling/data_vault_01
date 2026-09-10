{%- set yaml_metadata -%}
source_model: 'base_rst_invoice_line__emtk_ebs_sales'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP())::TIMESTAMP_TZ(9)
  brand: '!EMTEK'
  invoice_line_bk: to_char(customer_trx_line_id)
hashed_columns:
  invoice_line_hk: 
    columns:
    - 'invoice_line_bk'
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
