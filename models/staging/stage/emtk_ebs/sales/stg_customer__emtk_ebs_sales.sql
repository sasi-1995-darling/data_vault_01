{%- set yaml_metadata -%}
source_model: 'base_customer__emtk_ebs_sales'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: current_timestamp()
  brand: '!EMTEK'
  customer_bk: 'account_number'
hashed_columns:
  customer_hk: 
    columns:
    - 'customer_bk'
    - 'brand'
  customer_hdiff:
    is_hashdiff: true
    columns:
    - 'account_number'
    - 'cust_account_id'
    - 'party_id'
    - 'last_update_date'
    - 'last_updated_by'
    - 'creation_date'
    - 'created_by'
    - 'last_update_login'
    - 'request_id'
    - 'program_application_id'
    - 'program_id'
    - 'program_update_date'
    - 'attribute1'
    - 'attribute2'
    - 'attribute3'
    - 'attribute4'
    - 'attribute10'
    - 'attribute11'
    - 'attribute13'
    - 'attribute15'
    - 'attribute16'
    - 'attribute17'
    - 'attribute19'
    - 'attribute20'
    - 'orig_system_reference'
    - 'status'
    - 'customer_class_code'
    - 'freight_term'
    - 'ship_via'
    - 'payment_term_id'
    - 'tax_header_level_flag'
    - 'account_name'
    - 'account_replication_key'
    - 'object_version_number'
    - 'created_by_module'
    - 'application_id'

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
