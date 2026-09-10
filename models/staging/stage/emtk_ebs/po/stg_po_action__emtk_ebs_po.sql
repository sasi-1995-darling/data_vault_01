{%- set yaml_metadata -%}
source_model: 'base_po_action__emtk_ebs_po'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: current_timestamp() # multi-active satellite expects all cdks to be loaded at the same time
  brand: '!EMTEK'  
  purchase_order_bk: ['org_id', 'poh_segment1']
  po_action_cdk: ['action_code', 'action_date', 'sequence_num']
hashed_columns:
  purchase_order_hk: 
    columns:
    - 'purchase_order_bk'
    - 'brand'     
  po_action_hdiff:
    is_hashdiff: true
    columns:
    - 'org_id'
    - 'poh_segment1'
    - 'object_id'
    - 'object_type_code'
    - 'object_sub_type_code'
    - 'last_update_date'
    - 'last_updated_by'
    - 'creation_date'
    - 'created_by'
    - 'employee_id'
    - 'note'
    - 'object_revision_num'
    - 'last_update_login'
    - 'program_update_date'
    - 'program_date'

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
