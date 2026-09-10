--dim_purchase_order_line_shipment type 1
with cte_hub_po_line_shipment as (
    select * from {{ ref('hub_po_line_shipment') }}
)

, cte_sat_po_line_shipment_detail__emtk_ebs as (
    select * from {{ ref('sat_po_line_shipment_detail__emtk_ebs') }}
)

, cte_sat_po_line_shipment_detail__emtk_ebs__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='cte_sat_po_line_shipment_detail__emtk_ebs'
        ,hk_field='po_line_shipment_hk') }}
)

, cte_sat_po_line_shipment_detail__emtk_ebs_renamed as (
    select
        po_line_shipment_hk
        , line_location_id as src_po_line_shipment_id
        , po_line_id as src_po_line_id
        , po_header_id as src_po_header_id
        , quantity_billed as invoiced_quantity
        , amount_billed
        , ship_to_organization_id
        , ship_to_location_id
        , shipment_num
        , receiving_routing_id
        , to_date(need_by_date) as need_by_date
        , to_date(promised_date) as promised_date
        , to_date(last_accept_date) as last_accept_date
        , shipment_closed_date as shipment_closed_at
        , closed_for_receiving_date as closed_for_receiving_at
        , closed_for_invoice_date as closed_for_invoice_at
        , creation_date as src_created_at
        , last_update_date as src_last_updated_at
        , load_dts as valid_from
    from cte_sat_po_line_shipment_detail__emtk_ebs__latest
)

, cte_final as (

    select
        hub_pols.po_line_shipment_hk as dim_purchase_order_line_shipment_pk
        , hub_pols.po_line_shipment_bk as src_po_line_shipment_bk
        , hub_pols.brand
        , sat_polsd.src_po_line_shipment_id
        , sat_polsd.src_po_line_id
        , sat_polsd.src_po_header_id
        , sat_polsd.invoiced_quantity
        , sat_polsd.amount_billed
        , sat_polsd.ship_to_organization_id
        , sat_polsd.ship_to_location_id
        , sat_polsd.shipment_num
        , sat_polsd.receiving_routing_id
        , sat_polsd.need_by_date
        , sat_polsd.promised_date
        , sat_polsd.last_accept_date
        , sat_polsd.shipment_closed_at
        , sat_polsd.closed_for_receiving_at
        , sat_polsd.closed_for_invoice_at
        , sat_polsd.src_created_at
        , sat_polsd.src_last_updated_at
        , sat_polsd.valid_from
    from cte_hub_po_line_shipment as hub_pols
        inner join cte_sat_po_line_shipment_detail__emtk_ebs_renamed as sat_polsd
            on hub_pols.po_line_shipment_hk = sat_polsd.po_line_shipment_hk
)

select * from cte_final
