{%- set yaml_metadata -%}
source_model: 'stg_item_cost__emtk_ebs_common'
src_pk: 'item_hk'
src_hashdiff: 'item_cost_hdiff'
src_payload:
    - 'org_id'
    - 'segment1'
    - 'organization_id'
    - 'inventory_item_id'
    - 'creation_date'    
    - 'last_update_date'
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
src_ldts: load_dts
src_source: rec_src
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{% set source_model = metadata_dict['source_model'] %}
{% set src_pk = metadata_dict['src_pk'] %}
{% set src_hashdiff = metadata_dict['src_hashdiff'] %}
{% set src_payload = metadata_dict['src_payload'] %}
{% set src_ldts = metadata_dict['src_ldts'] %}
{% set src_source = metadata_dict['src_source'] %}


{{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                   src_payload=src_payload, src_eff=none,
                   src_ldts=src_ldts, src_source=src_source,
                   source_model=source_model) }}
