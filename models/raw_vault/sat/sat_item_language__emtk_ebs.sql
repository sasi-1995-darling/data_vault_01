{%- set yaml_metadata -%}
source_model: 'stg_item_language__emtk_ebs_common'
src_pk: 'item_hk'
src_hashdiff: 'item_lang_hdiff'
src_payload:
    - 'org_id'
    - 'segment1'
    - 'inventory_item_id'
    - 'organization_id'
    - 'language'
    - 'source_lang'
    - 'description'
    - 'last_update_date'
    - 'last_updated_by'
    - 'creation_date'
    - 'created_by'
    - 'last_update_login'
    - 'long_description'
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
