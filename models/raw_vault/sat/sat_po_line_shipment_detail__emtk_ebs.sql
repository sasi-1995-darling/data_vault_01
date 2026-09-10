{%- set yaml_metadata -%}
source_model: 'stg_po_line_shipment__emtk_ebs_po'
src_pk: 'po_line_shipment_hk'
src_hashdiff: 'po_line_shipment_hdiff'
src_payload:
    - 'line_location_id'
    - 'po_line_id'
    - 'last_update_date'
    - 'last_updated_by'
    - 'po_header_id'
    - 'last_update_login'
    - 'creation_date'
    - 'created_by'
    - 'quantity'
    - 'quantity_received'
    - 'quantity_accepted'
    - 'quantity_rejected'
    - 'quantity_billed'
    - 'quantity_cancelled'
    - 'unit_meas_lookup_code'
    - 'ship_to_location_id'
    - 'need_by_date'
    - 'promised_date'
    - 'last_accept_date'
    - 'price_override'
    - 'approved_flag'
    - 'approved_date'
    - 'cancel_flag'
    - 'cancelled_by'
    - 'cancel_date'
    - 'receipt_required_flag'
    - 'qty_rcv_tolerance'
    - 'qty_rcv_exception_code'
    - 'enforce_ship_to_location_code'
    - 'receipt_days_exception_code'
    - 'invoice_close_tolerance'
    - 'receive_close_tolerance'
    - 'ship_to_organization_id'
    - 'shipment_num'
    - 'closed_code'
    - 'request_id'
    - 'program_application_id'
    - 'program_id'
    - 'program_update_date'
    - 'receiving_routing_id'
    - 'accrue_on_receipt_flag'
    - 'closed_date'
    - 'closed_by'
    - 'org_id'
    - 'quantity_shipped'
    - 'country_of_origin_code'
    - 'note_to_receiver'
    - 'amount_billed'
    - 'shipment_closed_date'
    - 'closed_for_receiving_date'
    - 'closed_for_invoice_date'
    - 'value_basis'
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
