with cte_fact_purchase_order_line_shipment as (
    select * from {{ ref('fact_purchase_order_line_shipment') }}
    where brand = 'EMTEK'
)

, cte_dim_contact as (
    select * from {{ ref('dim_contact') }}
)

, cte_dim_item as (
    select * from {{ ref('dim_item') }}
)

, cte_dim_item_category as (
    select * from {{ ref('dim_item_category') }}
)

, cte_dim_supplier as (
    select * from {{ ref('dim_supplier') }}
)

, cte_dim_supplier_site as (
    select * from {{ ref('dim_supplier_site') }}
)

, cte_dim_purchase_order as (
    select * from {{ ref('dim_purchase_order') }}
)

, cte_dim_purchase_order_line as (
    select * from {{ ref('dim_purchase_order_line') }}
)

, cte_dim_plant_location as (
    select * from {{ ref('dim_plant_location') }}
)

, cte_dim_purchase_order_line_shipment as (
    select * from {{ ref('dim_purchase_order_line_shipment') }}
)

, cte_final as (
    select
        dim_po.operating_unit_name
        , dim_po.src_po_header_id
        , dim_po.po_number
        , dim_po.type_lookup_code as po_type
        , dim_pol.src_po_line_id
        , dim_pol.po_line_number
        , dim_po.authorization_status
        , dim_po.comments as po_description
        , fact_pols.po_created_date
        , dim_po.approved_at
        , NULLIF(fact_pols.po_first_approved_date, '1900-01-01') as po_first_approved_date
        , dim_s.supplier_name
        , dim_po.buyer_full_name
        , dim_pl.plant_location_code
        , dim_ss.vendor_site_code as supplier_site
        , dim_i.item_number
        , dim_pol.po_line_item_desc
        , dim_pol.unit_of_measure
        , dim_pol.unit_price
        , dim_i.item_cost
        , COALESCE(dim_pol.closure_status, 'OPEN') as closure_status
        , dim_pol.note_to_vendor as supplier_note
        , dim_pol.po_line_notes
        , dim_pol.quantity as ordered_quantity
        , fact_pols.shipped_quantity
        , fact_pols.asn_quantity
        , fact_pols.received_quantity
        , fact_pols.returned_quantity
        , fact_pols.invoiced_quantity
        , dim_s.src_supplier_bk as supplier_number
        , dim_iic.item_category
        , dim_iic.category_description
        , dim_pols.promised_date
        , dim_cse.email_address
        , dim_ss.country as supplier_site_country
        , fact_pols.po_line_closed_date
        , fact_pols.shipment_num
        , fact_pols.po_line_first_shipped_date
        , fact_pols.po_line_last_shipped_date

    from cte_fact_purchase_order_line_shipment as fact_pols
        inner join cte_dim_purchase_order as dim_po
            on fact_pols.dim_purchase_order_pk = dim_po.dim_purchase_order_pk
        inner join cte_dim_purchase_order_line as dim_pol
            on fact_pols.dim_purchase_order_line_pk = dim_pol.dim_purchase_order_line_pk
        inner join cte_dim_purchase_order_line_shipment as dim_pols
            on fact_pols.dim_purchase_order_line_shipment_pk = dim_pols.dim_purchase_order_line_shipment_pk
        inner join cte_dim_plant_location as dim_pl
            on fact_pols.dim_plant_location_pk = dim_pl.dim_plant_location_pk
        inner join cte_dim_supplier as dim_s
            on fact_pols.dim_supplier_pk = dim_s.dim_supplier_pk
        inner join cte_dim_supplier_site as dim_ss
            on fact_pols.dim_supplier_site_pk = dim_ss.dim_supplier_site_pk
        inner join cte_dim_contact as dim_cse
            on fact_pols.dim_contact_supplier_email_pk = dim_cse.dim_contact_pk
        inner join cte_dim_item as dim_i
            on fact_pols.dim_item_pk = dim_i.dim_item_pk
        inner join cte_dim_item_category as dim_iic
            on fact_pols.dim_item_inventory_category_pk = dim_iic.dim_item_category_pk
    --limit to 5 years of data for Tableau                   
    where fact_pols.po_created_date >= DATEADD(year, -5, CURRENT_DATE)
)

select * from cte_final
