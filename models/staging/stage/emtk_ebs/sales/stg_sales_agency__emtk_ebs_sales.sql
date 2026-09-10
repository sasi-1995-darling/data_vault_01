{%- set yaml_metadata -%}
source_model: 'base_sales_agency__emtk_ebs_sales'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  sales_agency_bk: ['org_id', 'salesrep_number']
hashed_columns:
  sales_agency_hk: 
    columns:
    - 'sales_agency_bk'
    - 'brand'
  sales_agency_hdiff:
    is_hashdiff: true
    columns:
    - 'org_id'
    - 'salesrep_number'    
    - 'salesrep_id'
    - 'resource_id'
    - 'last_update_date'
    - 'last_updated_by'
    - 'creation_date'
    - 'created_by'
    - 'last_update_login'
    - 'name'
    - 'start_date_active'
    - 'end_date_active'
    - 'email_address'
    - 'object_version_number'

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
