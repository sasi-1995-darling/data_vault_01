{%- set yaml_metadata -%}
source_model: 'stg_po_action__emtk_ebs_po'
src_pk: 'purchase_order_hk'
src_cdk: 
    - 'action_code'
    - 'action_date'
    - 'sequence_num'
src_payload:
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
src_hashdiff: 'po_action_hdiff'
src_ldts: 'load_dts'
src_source: 'rec_src'
{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.ma_sat(src_pk=metadata_dict['src_pk'],
                      src_cdk=metadata_dict['src_cdk'],
                      src_payload=metadata_dict['src_payload'],
                      src_hashdiff=metadata_dict['src_hashdiff'],
                      src_eff=none,
                      src_ldts=metadata_dict['src_ldts'],
                      src_source=metadata_dict['src_source'],
                      source_model=metadata_dict['source_model']) }}
