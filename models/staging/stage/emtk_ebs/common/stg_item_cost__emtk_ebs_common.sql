{%- set yaml_metadata -%}
source_model: 'base_item_cost__emtk_ebs_common'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  item_bk: ['org_id', 'segment1']
hashed_columns:
  item_hk: 
    columns:
    - 'item_bk'
    - 'brand'
  item_cost_hdiff:
    is_hashdiff: true
    columns:
    - 'org_id'
    - 'segment1'
    - 'organization_id'
    - 'inventory_item_id'
    - 'last_update_date'
    - 'creation_date'
    - 'cost_type_id'
    - 'item_cost'
    - 'unburdened_cost'
    - 'burden_cost'
    - 'material_cost'
    - 'material_overhead_cost'
    - 'pl_material'
    - 'pl_material_overhead'
    - 'pl_outside_processing'
    - 'pl_resource'
    - 'pl_overhead'
    - 'pl_item_cost'
    - 'tl_material'
    - 'tl_material_overhead'
    - 'tl_outside_processing'
    - 'tl_resource'
    - 'tl_overhead'
    - 'tl_item_cost'
    - 'request_id'
    - 'last_update_login'
    - 'cost_update_id'
    - 'last_updated_by'
    - 'created_by'
    - 'outside_processing_cost'
    - 'overhead_cost'
    - 'resource_cost'
    - 'program_application_id'
    - 'inventory_asset_flag'
    - 'program_id'
    - 'based_on_rollup_flag'
    - 'shrinkage_rate'
    - 'lot_size'
    - 'defaulted_flag'
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
