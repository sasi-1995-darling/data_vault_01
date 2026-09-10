{%- set source_model = "stg_supplier__emtk_ebs_po" -%}
{%- set src_pk = "supplier_hk" -%}
{%- set src_hashdiff = "supplier_hdiff" -%}
{%- set src_payload = [ 
  'segment1',
  'brand',
  'vendor_id',
  'last_update_date',
  'last_updated_by',
  'vendor_name',
  'vendor_name_alt',
  'last_update_login',
  'creation_date',
  'created_by',
  'vendor_type_lookup_code',
  'one_time_flag',
  'bill_to_location_id',
  'terms_id',
  'always_take_disc_flag',
  'pay_date_basis_lookup_code',
  'pay_group_lookup_code',
  'num_1099',
  'start_date_active',
  'payment_method_lookup_code',
  'qty_rcv_tolerance',
  'qty_rcv_exception_code',
  'enforce_ship_to_location_code',
  'receipt_days_exception_code',
  'receiving_routing_id',
  'state_reportable_flag',
  'federal_reportable_flag',
  'attribute1',
  'program_update_date',
  'tax_reporting_name',
  'party_id',
  'tca_sync_num_1099',
  'tca_sync_vendor_name',
  'tca_sync_vat_reg_num'] -%}
{%- set src_ldts = "load_dts" -%}
{%- set src_source = "rec_src" -%}

{{ automate_dv.sat(src_pk=src_pk, src_hashdiff=src_hashdiff,
                   src_payload=src_payload, src_eff=src_eff,
                   src_ldts=src_ldts, src_source=src_source,
                   source_model=source_model) }}
