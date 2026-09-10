{%- set yaml_metadata -%}
source_model: 'base_plant_location__emtk_ebs_po'
derived_columns:
  rec_src: '!EMTEK_EBS'
  load_dts: '_fivetran_synced'
  brand: '!EMTEK'
  plant_location_bk: ['organization_code', 'location_code']
hashed_columns:
  plant_location_hk: 
    columns:
    - 'plant_location_bk'
    - 'brand'    
  plant_location_hdiff:
    is_hashdiff: true
    columns:
    - 'organization_code'
    - 'location_code'
    - 'location_id'
    - 'description'
    - 'ship_to_location_id'
    - 'ship_to_site_flag'
    - 'receiving_site_flag'
    - 'bill_to_site_flag'
    - 'in_organization_flag'
    - 'office_site_flag'
    - 'inventory_organization_id'
    - 'style'
    - 'address_line_1'
    - 'address_line_2'
    - 'town_or_city'
    - 'country'
    - 'postal_code'
    - 'region_1'
    - 'region_2'
    - 'telephone_number_1'
    - 'telephone_number_2'
    - 'last_update_date'
    - 'last_updated_by'
    - 'last_update_login'
    - 'created_by'
    - 'creation_date'
    - 'entered_by'
    - 'ece_tp_location_code'
    - 'object_version_number'
    - 'derived_locale'
    - 'legal_address_flag'

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
