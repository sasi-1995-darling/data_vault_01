with cte_po_headers_all as (
    select
        po_header_id
        , agent_id
        , type_lookup_code
        , last_update_date
        , _fivetran_synced
        , last_updated_by
        , segment1
        , last_update_login
        , creation_date
        , created_by
        , vendor_id
        , vendor_site_id
        , vendor_contact_id
        , ship_to_location_id
        , bill_to_location_id
        , terms_id
        , fob_lookup_code
        , freight_terms_lookup_code
        , rate_date
        , from_header_id
        , start_date
        , authorization_status
        , revision_num
        , revised_date
        , approved_flag
        , approved_date
        , note_to_vendor
        , note_to_receiver
        , print_count
        , printed_date
        , confirming_order_flag
        , comments
        , acceptance_required_flag
        , closed_date
        , user_hold_flag
        , cancel_flag
        , frozen_flag
        , attribute15
        , closed_code
        , request_id
        , program_application_id
        , program_id
        , program_update_date
        , org_id
        , wf_item_key
        , change_summary
        , document_creation_method
        , submit_date
        , supplier_notif_method
        , email_address
        , clm_effective_date
        , clm_document_number
    from {{ source('emtk_ebs_po__po', 'po_headers_all') }}
    where _fivetran_deleted = false
)

, cte_supplier_bk as (
    select
        segment1
        , vendor_id
    from {{ source("emtk_ebs_po__ap", "ap_suppliers") }}
    where _fivetran_deleted = false
)

, cte_buyer_name_lookup as (

    select
        person_id
        , full_name
    from {{ source('emtk_ebs_po__hr', 'per_all_people_f') }}
    where _fivetran_deleted = false
        and effective_start_date < CURRENT_DATE
        and effective_end_date >= CURRENT_DATE

)

, cte_purchase_order_final as (
    select
        poh.org_id
        , poh.segment1 as poh_segment1
        , COALESCE(sup.segment1, '-1') as sup_segment1
        , COALESCE(poh.vendor_site_id, '-1') as vendor_site_id
        , poh.po_header_id
        , poh.agent_id
        , bnl.full_name
        , poh.type_lookup_code
        , poh.last_update_date
        , poh._fivetran_synced
        , poh.last_updated_by
        , poh.last_update_login
        , poh.creation_date
        , poh.created_by
        , poh.vendor_id
        , poh.vendor_contact_id
        , poh.ship_to_location_id
        , poh.bill_to_location_id
        , poh.terms_id
        , poh.fob_lookup_code
        , poh.freight_terms_lookup_code
        , poh.rate_date
        , poh.from_header_id
        , poh.start_date
        , poh.authorization_status
        , poh.revision_num
        , poh.revised_date
        , poh.approved_flag
        , poh.approved_date
        , poh.note_to_vendor
        , poh.note_to_receiver
        , poh.print_count
        , poh.printed_date
        , poh.confirming_order_flag
        , poh.comments
        , poh.acceptance_required_flag
        , poh.closed_date
        , poh.user_hold_flag
        , poh.cancel_flag
        , poh.frozen_flag
        , poh.attribute15
        , poh.closed_code
        , poh.request_id
        , poh.program_application_id
        , poh.program_id
        , poh.program_update_date
        , poh.wf_item_key
        , poh.change_summary
        , poh.document_creation_method
        , poh.submit_date
        , poh.supplier_notif_method
        , poh.email_address
        , poh.clm_effective_date
        , poh.clm_document_number

    from cte_po_headers_all as poh
        left outer join cte_supplier_bk as sup on poh.vendor_id = sup.vendor_id
        left outer join cte_buyer_name_lookup as bnl on poh.agent_id = bnl.person_id

)

select * from cte_purchase_order_final
