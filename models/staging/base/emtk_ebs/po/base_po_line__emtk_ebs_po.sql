with cte_po_lines_all as (
    select
        po_line_id::varchar as po_line_id -- BK
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , po_header_id
        , line_type_id
        , line_num
        , last_update_login
        , creation_date
        , created_by
        , item_id
        , category_id
        , item_description
        , unit_meas_lookup_code
        , quantity_committed
        , list_price_per_unit
        , unit_price
        , quantity
        , note_to_vendor
        , qty_rcv_tolerance
        , over_tolerance_error_flag
        , cancel_flag
        , cancelled_by
        , cancel_date
        , vendor_product_num
        , capital_expense_flag
        , negotiated_by_preparer_flag
        , attribute1
        , price_type_lookup_code
        , closed_code
        , request_id
        , program_application_id
        , program_id
        , program_update_date
        , closed_date
        , closed_by
        , org_id
        , retroactive_date
        , contract_id
        , order_type_lookup_code
        , purchase_basis
        , base_unit_price
        , manual_price_change_flag
        , clm_total_amount_ordered
    from {{ source('emtk_ebs_po__po', 'po_lines_all') }}
    where _fivetran_deleted = false
)

, cte_po_headers_all as (
    select
        po_header_id
        , org_id
        , segment1
    from {{ source('emtk_ebs_po__po', 'po_headers_all') }}
    where _fivetran_deleted = false
)

, cte_final as (
    select
        pla.po_line_id
        , pla.last_update_date
        , pla.last_updated_by
        , pla.po_header_id
        , pla.line_type_id
        , pla.line_num
        , pla.last_update_login
        , pla.creation_date
        , pla.created_by
        , pla.item_id
        , pla.category_id
        , pla.item_description
        , pla.unit_meas_lookup_code
        , pla.quantity_committed
        , pla.list_price_per_unit
        , pla.unit_price
        , pla.quantity
        , pla.note_to_vendor
        , pla.qty_rcv_tolerance
        , pla.over_tolerance_error_flag
        , pla.cancel_flag
        , pla.cancelled_by
        , pla.cancel_date
        , pla.vendor_product_num
        , pla.capital_expense_flag
        , pla.negotiated_by_preparer_flag
        , pla.attribute1
        , pla.price_type_lookup_code
        , pla.closed_code
        , pla.request_id
        , pla.program_application_id
        , pla.program_id
        , pla.program_update_date
        , pla.closed_date
        , pla.closed_by
        , pla.org_id as po_line_org_id
        , pla.retroactive_date
        , pla.contract_id
        , pla.order_type_lookup_code
        , pla.purchase_basis
        , pla.base_unit_price
        , pla.manual_price_change_flag
        , pla.clm_total_amount_ordered
        , pha.org_id as po_header_org_id
        , pha.segment1 as po_header_segment1
        , pla._fivetran_synced
    from cte_po_lines_all as pla
        inner join cte_po_headers_all as pha
            on pla.po_header_id = pha.po_header_id
)

select * from cte_final
