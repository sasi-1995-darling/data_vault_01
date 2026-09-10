--dim_purchase_order type 1
with cte_hub_purchase_order as (
    select * from {{ ref('hub_purchase_order') }}
)

, cte_sat_po_detail__emtk_ebs__emtk_ebs as (
    select * from {{ ref('sat_po_detail__emtk_ebs') }}
)

, cte_sat_po_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_po_detail__emtk_ebs__emtk_ebs'
        ,hk_field='purchase_order_hk') }}
)

/*
    could pull in msat_po_action__emtk_ebs to add first_approved_at, but will just have on fact tables for now
*/

, cte_sat_po_detail__emtk_ebs_renamed as (
    select
        purchase_order_hk
        , org_id as operating_unit_code
        , decode(org_id, 101, 'EMTEK', 181, 'SCHAUB') as operating_unit_name
        , poh_segment1 as po_number
        , po_header_id as src_po_header_id
        , agent_id as buyer_id
        , full_name as buyer_full_name
        , note_to_vendor
        , note_to_receiver
        , comments
        , authorization_status
        , approved_flag
        , approved_date as approved_at
        , closed_code
        , closed_date as closed_at
        , type_lookup_code
        , terms_id
        , fob_lookup_code
        , freight_terms_lookup_code
        , rate_date
        , start_date
        , submit_date as submitted_at
        , revised_date as revised_at
        , try_to_boolean(user_hold_flag) as is_user_held
        , try_to_boolean(cancel_flag) as is_cancelled
        , try_to_boolean(frozen_flag) as is_frozen
        , clm_effective_date as clm_effective_at
        , clm_document_number
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
    from cte_sat_po_detail__emtk_ebs__latest
)

, cte_final as (

    select
        hub_po.purchase_order_hk as dim_purchase_order_pk
        , hub_po.purchase_order_bk as src_purchase_order_bk
        , sat_pod.operating_unit_code
        , sat_pod.operating_unit_name
        , sat_pod.po_number
        , sat_pod.src_po_header_id
        , sat_pod.buyer_id
        , sat_pod.buyer_full_name
        , sat_pod.note_to_vendor
        , sat_pod.note_to_receiver
        , sat_pod.comments
        , sat_pod.authorization_status
        , sat_pod.approved_flag
        , sat_pod.approved_at
        , sat_pod.closed_code
        , sat_pod.closed_at
        , sat_pod.type_lookup_code
        , sat_pod.terms_id
        , sat_pod.fob_lookup_code
        , sat_pod.freight_terms_lookup_code
        , sat_pod.rate_date
        , sat_pod.start_date
        , sat_pod.submitted_at
        , sat_pod.revised_at
        , sat_pod.is_user_held
        , sat_pod.is_cancelled
        , sat_pod.is_frozen
        , sat_pod.clm_effective_at
        , sat_pod.clm_document_number
        , sat_pod.src_created_at
        , sat_pod.src_last_updated_at
        , sat_pod.valid_from
    from cte_hub_purchase_order as hub_po
        inner join cte_sat_po_detail__emtk_ebs_renamed as sat_pod
            on hub_po.purchase_order_hk = sat_pod.purchase_order_hk
)

select * from cte_final
