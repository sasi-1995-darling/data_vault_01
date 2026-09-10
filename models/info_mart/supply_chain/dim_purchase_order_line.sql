--dim_po_line type 1
with cte_hub_po_line as (
    select * from {{ ref('hub_po_line') }}
)

, cte_sat_po_line_detail__emtk_ebs as (
    select * from {{ ref('sat_po_line_detail__emtk_ebs') }}
)

, cte_sat_po_line_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_po_line_detail__emtk_ebs'
        ,hk_field='po_line_hk') }}
)

, cte_sat_po_line_detail__emtk_ebs_renamed as (
    select
        po_line_hk
        , po_line_id as src_po_line_id
        , po_header_id as src_po_header_id
        , line_num as po_line_number
        , item_id as src_item_id
        , item_description as po_line_item_desc
        , unit_meas_lookup_code as unit_of_measure
        , list_price_per_unit
        , unit_price
        , quantity
        , qty_rcv_tolerance
        , over_tolerance_error_flag as over_tolerance_error_status
        , attribute1 as po_line_notes
        , note_to_vendor
        , vendor_product_num
        , closed_code as closure_status
        , closed_date as closed_at
        , try_to_boolean(cancel_flag) as is_cancelled
        , cancel_date as cancelled_at        
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
    from cte_sat_po_line_detail__emtk_ebs__latest
)

, cte_final as (

    select
        hub_pol.po_line_hk as dim_purchase_order_line_pk
        , hub_pol.po_line_bk as src_purchase_order_line_bk
        , hub_pol.brand
        , sat_pold.src_po_line_id
        , sat_pold.src_po_header_id
        , sat_pold.po_line_number
        , sat_pold.src_item_id
        , sat_pold.po_line_item_desc
        , sat_pold.unit_of_measure
        , sat_pold.list_price_per_unit
        , sat_pold.unit_price
        , sat_pold.quantity
        , sat_pold.qty_rcv_tolerance
        , sat_pold.over_tolerance_error_status
        , sat_pold.is_cancelled
        , sat_pold.cancelled_at
        , sat_pold.po_line_notes
        , sat_pold.note_to_vendor
        , sat_pold.vendor_product_num
        , sat_pold.closure_status
        , sat_pold.closed_at
        , sat_pold.src_created_at
        , sat_pold.src_last_updated_at
        , sat_pold.valid_from
    from cte_hub_po_line as hub_pol
        inner join cte_sat_po_line_detail__emtk_ebs_renamed as sat_pold
            on hub_pol.po_line_hk = sat_pold.po_line_hk
)

select * from cte_final
