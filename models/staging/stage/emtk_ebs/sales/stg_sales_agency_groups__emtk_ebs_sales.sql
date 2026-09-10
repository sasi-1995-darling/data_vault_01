{%- set yaml_metadata -%}
source_model: 'base_sales_agency_groups__emtk_ebs_sales'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  sales_agency_bk: ['org_id', 'salesrep_number']
  sales_region_bk: 'group_name'
  sales_territory_bk: 'segment1'
  sales_agency_groups_bk: ['org_id', 'segment1', 'salesrep_number', 'group_name']
hashed_columns:
  sales_agency_hk: 
    columns:
    - 'sales_agency_bk'
    - 'brand'
  sales_region_hk:
    columns:
    - 'sales_region_bk'
    - 'brand'
  sales_territory_hk: 
    columns:
    - 'sales_territory_bk'
    - 'brand'
  sales_agency_groups_hk: 
    columns:
    - 'sales_agency_groups_bk'
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
