{%- set yaml_metadata -%}

source_model: stg_inv_items__lrsn_psft
src_pk: item_hk
src_cdk: effdt
src_hashdiff: hdiff
src_payload:
    - inv_item_id
    - inv_item_type
    - inv_item_height
    - inv_item_length
    - inv_item_width
    - inv_item_weight
    - inv_item_volume
    - inv_item_size
    - inv_item_color
    - effdt
    - upc_id
    - setid
src_ldts: load_dts
src_source: rec_src

{%- endset -%}

{% set metadata_dict = fromyaml(yaml_metadata) %}

{{ automate_dv.ma_sat(src_pk=metadata_dict['src_pk'],
                      src_cdk=metadata_dict['src_cdk'],
                      src_payload=metadata_dict['src_payload'],
                      src_hashdiff=metadata_dict['src_hashdiff'],
                      src_ldts=metadata_dict['src_ldts'],
                      src_source=metadata_dict['src_source'],
                      source_model=metadata_dict['source_model']) }}
