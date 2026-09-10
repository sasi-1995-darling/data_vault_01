{%- set yaml_metadata -%}
source_model: 'base_customer_account__tt_e21'
derived_columns:
  rec_src: '!TT E21TRUBIS'
  load_dts: _fivetran_synced::timestamp_ltz(9)
  brand: '!THTRU'
  account_bk: 'cust_code'
hashed_columns:
  account_hk: 
    columns:
    - 'account_bk'
    - 'brand'
  customer_hdiff:
    is_hashdiff: true
    columns:
    - 'cust_code'
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
