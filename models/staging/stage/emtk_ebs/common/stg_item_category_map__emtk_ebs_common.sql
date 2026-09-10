{%- set yaml_metadata -%}
source_model: 'base_item_category_map__emtk_ebs_common'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: current_timestamp() # multi-active satellite expects all cdks to be loaded at the same time
  brand: '!EMTEK'
  item_bk: ['org_id', 'segment1']
  item_category_cdk: ['category_id', 'category_set_id']
hashed_columns:
  item_hk: 
    columns:
    - 'item_bk'
    - 'brand'
  item_category_hk:
    columns:
    - 'item_bk'
    - 'item_category_cdk'
    - 'brand'
  item_category_hdiff:
    is_hashdiff: true
    columns:
    - 'org_id'
    - 'segment1'
    - 'inventory_item_id'
    - 'organization_id'
    - 'last_update_date'
    - 'last_updated_by'
    - 'creation_date'
    - 'created_by'
    - 'last_update_login'
    - 'request_id'
    - 'program_application_id'
    - 'program_id'
    - 'program_update_date'
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
