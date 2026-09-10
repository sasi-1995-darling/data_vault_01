with cte_rcv_transactions as (
    select
        transaction_id::varchar as transaction_id -- BK
        , po_line_id::varchar as po_line_id
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , creation_date
        , created_by
        , last_update_login
        , request_id
        , program_application_id
        , program_id
        , program_update_date
        , transaction_type
        , transaction_date
        , quantity
        , unit_of_measure
        , shipment_header_id
        , shipment_line_id
        , user_entered_flag
        , source_document_code
        , destination_type_code
        , primary_quantity
        , primary_unit_of_measure
        , uom_code
        , employee_id
        , parent_transaction_id
        , po_header_id
        , po_line_location_id
        , po_distribution_id
        , po_revision_num
        , po_unit_price
        , currency_conversion_date
        , routing_header_id
        , deliver_to_person_id
        , deliver_to_location_id
        , vendor_id
        , vendor_site_id
        , organization_id
        , subinventory
        , location_id
        , inspection_status_code
        , vendor_lot_num
        , rma_reference
        , attribute1
        , attribute2
        , attribute3
        , attribute4
        , attribute5
        , attribute6
        , attribute7
        , attribute8
        , attribute9
        , attribute10
        , attribute11
        , attribute12
        , attribute13
        , attribute14
        , attribute15
        , reason_id
        , destination_context
        , source_doc_unit_of_measure
        , source_doc_quantity
        , interface_transaction_id
        , group_id
        , country_of_origin_code
        , oe_order_header_id
        , oe_order_line_id
        , customer_id
        , customer_site_id
        , from_subinventory

    from {{ source('emtk_ebs_po__po', 'rcv_transactions') }} as rt
    /* limit to just transactions tied to po_lines */
    where exists (
            select 1 as constant
            from
                {{ source('emtk_ebs_po__po', 'po_lines_all') }} as pla
            where rt.po_line_id = pla.po_line_id
                and pla._fivetran_deleted = false
        )
        and _fivetran_deleted = false
)

, cte_rcv_shipment_headers as (
    select
        shipment_header_id
        , shipment_num
        , shipped_date
    from {{ source('emtk_ebs_po__po', 'rcv_shipment_headers') }}
)

, cte_final as (
    select
        rt.transaction_id
        , rt.po_line_id
        , rt.last_update_date
        , rt._fivetran_synced
        , rt.last_updated_by
        , rt.creation_date
        , rt.created_by
        , rt.last_update_login
        , rt.request_id
        , rt.program_application_id
        , rt.program_id
        , rt.program_update_date
        , rt.transaction_type
        , rt.transaction_date
        , rt.quantity
        , rt.unit_of_measure
        , rt.shipment_header_id
        , rsh.shipment_num
        , rsh.shipped_date
        , rt.shipment_line_id
        , rt.user_entered_flag
        , rt.source_document_code
        , rt.destination_type_code
        , rt.primary_quantity
        , rt.primary_unit_of_measure
        , rt.uom_code
        , rt.employee_id
        , rt.parent_transaction_id
        , rt.po_header_id
        , rt.po_line_location_id
        , rt.po_distribution_id
        , rt.po_revision_num
        , rt.po_unit_price
        , rt.currency_conversion_date
        , rt.routing_header_id
        , rt.deliver_to_person_id
        , rt.deliver_to_location_id
        , rt.vendor_id
        , rt.vendor_site_id
        , rt.organization_id
        , rt.subinventory
        , rt.location_id
        , rt.inspection_status_code
        , rt.vendor_lot_num
        , rt.rma_reference
        , rt.attribute1
        , rt.attribute2
        , rt.attribute3
        , rt.attribute4
        , rt.attribute5
        , rt.attribute6
        , rt.attribute7
        , rt.attribute8
        , rt.attribute9
        , rt.attribute10
        , rt.attribute11
        , rt.attribute12
        , rt.attribute13
        , rt.attribute14
        , rt.attribute15
        , rt.reason_id
        , rt.destination_context
        , rt.source_doc_unit_of_measure
        , rt.source_doc_quantity
        , rt.interface_transaction_id
        , rt.group_id
        , rt.country_of_origin_code
        , rt.oe_order_header_id
        , rt.oe_order_line_id
        , rt.customer_id
        , rt.customer_site_id
        , rt.from_subinventory
    from cte_rcv_transactions as rt
        left join cte_rcv_shipment_headers as rsh
            on rt.shipment_header_id = rsh.shipment_header_id
)

select * from cte_final
