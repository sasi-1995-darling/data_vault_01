{%- set yaml_metadata -%}
source_model: 'base_po_line_item_plant_location__emtk_ebs_po'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  po_line_bk: 'po_line_id'
  plant_location_bk: ['organization_code', 'location_code']
  item_bk: ['org_id', 'segment1']
hashed_columns:
  po_line_item_plant_location_hk: 
    columns:
    - 'po_line_bk'
    - 'plant_location_bk'
    - 'item_bk'
    - 'brand'     
  po_line_hk: 
    columns:
    - 'po_line_bk'
    - 'brand'     
  plant_location_hk: 
    columns:
    - 'plant_location_bk'
    - 'brand'     
  item_hk: 
    columns:
    - 'item_bk'
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
