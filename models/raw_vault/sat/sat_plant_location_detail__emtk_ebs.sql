{%- set source_model = "stg_plant_location__emtk_ebs_po" -%}
{%- set src_pk = "plant_location_hk" -%}
{%- set src_hashdiff = "plant_location_hdiff" -%}
{%- set src_payload = [ 
  'organization_code',
  'location_code',
  'brand',
  'location_id',
  'description',
  'ship_to_location_id',
  'ship_to_site_flag',
  'receiving_site_flag',
  'bill_to_site_flag',
  'in_organization_flag',
  'office_site_flag',
  'inventory_organization_id',
  'style',
  'address_line_1',
  'address_line_2',
  'town_or_city',
  'country',
  'postal_code',
  'region_1',
  'region_2',
  'telephone_number_1',
  'telephone_number_2',
  'last_update_date',
  '_fivetran_synced',
  'last_updated_by',
  'last_update_login',
  'created_by',
  'creation_date',
  'entered_by',
  'ece_tp_location_code',
  'object_version_number',
  'derived_locale',
  'legal_address_flag'] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                   src_payload=src_payload, src_eff=none,
                   src_ldts=src_ldts, src_source=src_source,
                   source_model=source_model) }}
