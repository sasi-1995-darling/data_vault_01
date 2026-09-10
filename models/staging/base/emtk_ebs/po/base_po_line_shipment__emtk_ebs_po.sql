with cte_po_line_locations_all as (
    select
        line_location_id::varchar as line_location_id -- BK
        , po_line_id::varchar as po_line_id
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , po_header_id
        , last_update_login
        , creation_date
        , created_by
        , quantity
        , quantity_received
        , quantity_accepted
        , quantity_rejected
        , quantity_billed
        , quantity_cancelled
        , unit_meas_lookup_code
        , ship_to_location_id
        , need_by_date
        , promised_date
        , last_accept_date
        , price_override
        , approved_flag
        , approved_date
        , cancel_flag
        , cancelled_by
        , cancel_date
        , receipt_required_flag
        , qty_rcv_tolerance
        , qty_rcv_exception_code
        , enforce_ship_to_location_code
        , receipt_days_exception_code
        , invoice_close_tolerance
        , receive_close_tolerance
        , ship_to_organization_id
        , shipment_num
        , closed_code
        , request_id
        , program_application_id
        , program_id
        , program_update_date
        , receiving_routing_id
        , accrue_on_receipt_flag
        , closed_date
        , closed_by
        , org_id
        , quantity_shipped
        , country_of_origin_code
        , note_to_receiver
        , amount_billed
        , shipment_closed_date
        , closed_for_receiving_date
        , closed_for_invoice_date
        , value_basis
    from {{ source('emtk_ebs_po__po', 'po_line_locations_all') }}
    where _fivetran_deleted = false
)

select * from cte_po_line_locations_all
