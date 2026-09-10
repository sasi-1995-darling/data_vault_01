{%- set yaml_metadata -%}
source_model: 'stg_item_category_map__emtk_ebs_common'
src_pk: 'item_hk'
src_cdk: 
    - 'category_id'
    - 'category_set_id'
src_payload:
    - 'item_category_hk'
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
src_hashdiff: 'item_category_hdiff'
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
