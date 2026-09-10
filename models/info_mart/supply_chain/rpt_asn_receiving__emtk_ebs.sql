with cte_fact_purchase_order_line_shipment as (
    select
        dim_purchase_order_line_pk
        , asn_quantity
    from {{ ref('fact_purchase_order_line_shipment') }}
    where brand = 'EMTEK'
)

, cte_fact_purchase_order_line_transaction as (
    select
        f_polt.fact_purchase_order_line_transaction_pk
        , f_polt.dim_purchase_order_line_shipment_pk
        , f_polt.shipment_line_id
        , f_polt.quantity
        , f_polt.inspection_status_code
        , f_polt.transaction_type
        , f_polt.shipment_num
        , f_polt.shipped_date
        , f_polt.shipment_header_id
        , f_polt.dim_purchase_order_pk
        , f_polt.dim_purchase_order_line_pk
        , f_polt.dim_plant_location_pk
        , f_polt.dim_supplier_pk
        , f_polt.dim_supplier_site_pk
        , f_polt.dim_contact_supplier_email_pk
        , f_polt.dim_item_pk
        , f_polt.dim_item_inventory_category_pk
        , f_polt.po_created_date
    from {{ ref('fact_purchase_order_line_transaction') }} as f_polt
    ,
        lateral
        (
            select 1 as constant
            from cte_fact_purchase_order_line_shipment as filter_join
            where filter_join.asn_quantity > 0
                and f_polt.dim_purchase_order_line_pk = filter_join.dim_purchase_order_line_pk
        )
    where f_polt.brand = 'EMTEK'
        --limit to 5 years of data for Tableau        
        and f_polt.po_created_date >= DATEADD(year, -5, CURRENT_DATE)
)

, cte_dim_contact as (
    select dim_contact_pk
    from {{ ref('dim_contact') }}
)

, cte_dim_item as (
    select
        dim_item_pk
        , item_number
        , description
    from {{ ref('dim_item') }}
)

, cte_dim_item_category as (
    select dim_item_category_pk
    from {{ ref('dim_item_category') }}
)

, cte_dim_supplier as (
    select
        dim_supplier_pk
        , supplier_name
    from {{ ref('dim_supplier') }}
)

, cte_dim_supplier_site as (
    select
        dim_supplier_site_pk
        , vendor_site_code
    from {{ ref('dim_supplier_site') }}
)

, cte_dim_purchase_order as (
    select
        dim_purchase_order_pk
        , po_number
        , operating_unit_name
    from {{ ref('dim_purchase_order') }}
)

, cte_dim_purchase_order_line as (
    select
        dim_purchase_order_line_pk
        , po_line_number
        , quantity
        , unit_price
        , src_po_line_id
    from {{ ref('dim_purchase_order_line') }}
)

, cte_dim_plant_location as (
    select dim_plant_location_pk
    from {{ ref('dim_plant_location') }}
)

, cte_dim_purchase_order_line_shipment as (
    select
        dim_purchase_order_line_shipment_pk
        , receiving_routing_id
    from {{ ref('dim_purchase_order_line_shipment') }}
)

, cte_in_transit_quantity as (
    select
        fact_polt.shipment_line_id
        , SUM(fact_polt.quantity) as in_transit_quantity
    from cte_fact_purchase_order_line_transaction as fact_polt
    where fact_polt.inspection_status_code = 'NOT INSPECTED'
        and not exists
        (
            select 1 as constant
            from cte_fact_purchase_order_line_transaction as filter_join
            where filter_join.transaction_type in ('DELIVER', 'RETURN TO VENDOR', 'ACCEPT', 'REJECT')
                and fact_polt.shipment_line_id = filter_join.shipment_line_id
        )
    group by fact_polt.shipment_line_id

)

, cte_inspection_quantity as (
    select
        fact_polt.shipment_line_id
        , SUM(fact_polt.quantity) as inspection_quantity
    from cte_fact_purchase_order_line_transaction as fact_polt
    where fact_polt.inspection_status_code in ('ACCEPTED', 'REJECTED')
        and not exists
        (
            select 1 as constant
            from cte_fact_purchase_order_line_transaction as filter_join
            where filter_join.transaction_type in ('DELIVER', 'RETURN TO VENDOR')
                and fact_polt.shipment_line_id = filter_join.shipment_line_id
        )
    group by fact_polt.shipment_line_id

)

, cte_grouped_rename as (
    select
        dim_po.po_number
        , fact_polt.shipment_line_id -- join key
        , dim_po.operating_unit_name
        , dim_s.supplier_name
        , dim_ss.vendor_site_code as supplier_site
        , dim_pol.po_line_number
        , DECODE(dim_pols.receiving_routing_id, 2, 'Inspection Required', 'Direct Delivery') as receipt_routing
        , dim_i.item_number
        , dim_i.description as item_desc
        , fact_polt.shipment_num
        , fact_polt.shipped_date
        , dim_pol.quantity as ordered_quantity
        , (dim_pol.unit_price * dim_pol.quantity) as po_line_amount
        , itq.in_transit_quantity
        , iq.inspection_quantity
        , dim_pol.src_po_line_id
        , fact_polt.shipment_header_id
    from cte_fact_purchase_order_line_transaction as fact_polt
        inner join cte_dim_purchase_order as dim_po
            on fact_polt.dim_purchase_order_pk = dim_po.dim_purchase_order_pk
        inner join cte_dim_purchase_order_line as dim_pol
            on fact_polt.dim_purchase_order_line_pk = dim_pol.dim_purchase_order_line_pk
        inner join cte_dim_purchase_order_line_shipment as dim_pols
            on fact_polt.dim_purchase_order_line_shipment_pk = dim_pols.dim_purchase_order_line_shipment_pk
        inner join cte_dim_plant_location as dim_pl
            on fact_polt.dim_plant_location_pk = dim_pl.dim_plant_location_pk
        inner join cte_dim_supplier as dim_s
            on fact_polt.dim_supplier_pk = dim_s.dim_supplier_pk
        inner join cte_dim_supplier_site as dim_ss
            on fact_polt.dim_supplier_site_pk = dim_ss.dim_supplier_site_pk
        inner join cte_dim_contact as dim_cse
            on fact_polt.dim_contact_supplier_email_pk = dim_cse.dim_contact_pk
        inner join cte_dim_item as dim_i
            on fact_polt.dim_item_pk = dim_i.dim_item_pk
        inner join cte_dim_item_category as dim_iic
            on fact_polt.dim_item_inventory_category_pk = dim_iic.dim_item_category_pk
        inner join cte_in_transit_quantity as itq
            on fact_polt.shipment_line_id = itq.shipment_line_id
        left outer join cte_inspection_quantity as iq
            on fact_polt.shipment_line_id = iq.shipment_line_id

    where itq.in_transit_quantity > 0
        and fact_polt.transaction_type = 'RECEIVE'

)

, cte_final as (
    select
        gr.shipment_header_id
        , gr.shipment_line_id
        , gr.operating_unit_name
        , gr.supplier_name
        , gr.supplier_site
        , gr.po_number
        , gr.po_line_number
        , gr.receipt_routing
        , gr.item_number
        , gr.item_desc
        , gr.shipment_num
        , gr.shipped_date
        , SUM(gr.ordered_quantity) as ordered_quantity
        , SUM(gr.po_line_amount) as po_line_amount
        , gr.in_transit_quantity
        , gr.inspection_quantity
        , gr.src_po_line_id
    from cte_grouped_rename as gr
    group by all
)

select * from cte_final
