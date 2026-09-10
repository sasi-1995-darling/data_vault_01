{%- set source_model = "stg_customer_bill_location__emtk_ebs_sales" -%}
{%- set src_pk = "customer_bill_location_hk" -%}
{%- set src_hashdiff = "customer_bill_location_hdiff" -%}
{%- set src_payload = [ 
    'location_id',
    'location',
    'site_use_id',
    'last_update_date',
    'last_updated_by',
    'creation_date',
    'created_by',
    'last_update_login',
    'request_id',
    'program_application_id',
    'program_id',
    'program_update_date',
    'orig_system_reference',
    'country',
    'address1',
    'address2',
    'address3',
    'address4',
    'city',
    'postal_code',
    'state',
    'province',
    'county',
    'address_key',
    'address_style',
    'address_lines_phonetic',
    'address_effective_date',
    'object_version_number',
    'created_by_module',
    'application_id',
    'timezone_id'] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                   src_payload=src_payload, src_eff=none,
                   src_ldts=src_ldts, src_source=src_source,
                   source_model=source_model) }}