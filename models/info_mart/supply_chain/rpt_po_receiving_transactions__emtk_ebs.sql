with cte_fact_purchase_order_line_transaction as (
    select * from {{ ref('fact_purchase_order_line_transaction') }}
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

, cte_reversed_quantity as (
    select
        dim_purchase_order_line_pk
        , SUM(primary_quantity) as reversed_quantity
    from cte_fact_purchase_order_line_transaction
    where transaction_type = 'CORRECT'
        and destination_type_code = 'INVENTORY'
    group by dim_purchase_order_line_pk
)

, cte_net_received_quantity as (
    select
        dim_purchase_order_line_pk
        , SUM(primary_quantity) as net_received_quantity
    from cte_fact_purchase_order_line_transaction
    where destination_type_code = 'INVENTORY'
    group by dim_purchase_order_line_pk
)

, cte_final as (
    select
        dim_po.operating_unit_name
        , fact_polt.transaction_id
        , fact_polt.transaction_type
        , TO_DATE(fact_polt.transaction_date) as transaction_date
        , fact_polt.destination_type_code as destination_type
        , fact_polt.shipment_header_id as shipment_id
        , fact_polt.shipment_line_id
        , dim_pol.src_po_line_id
        , dim_po.src_po_header_id
        , fact_polt.shipment_num
        , dim_po.po_number
        , dim_pol.po_line_number                        
        , fact_polt.quantity
        , fact_polt.unit_of_measure
        , fact_polt.primary_quantity
        , fact_polt.primary_unit_of_measure
        , fact_polt.po_unit_price
        , fact_polt.po_created_date
        , dim_po.approved_at
        , dim_i.item_number
        , dim_i.description as item_description
        , dim_pol.po_line_item_desc
        , dim_pol.quantity as ordered_quantity
        , dim_pol.closure_status
        , dim_pols.invoiced_quantity
        , dim_s.supplier_name
        , dim_s.src_supplier_bk as supplier_number
        , dim_ss.country as supplier_site_country

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
        left outer join cte_reversed_quantity as rq
            on fact_polt.dim_purchase_order_line_pk = rq.dim_purchase_order_line_pk
        left outer join cte_net_received_quantity as nrq
            on fact_polt.dim_purchase_order_line_pk = nrq.dim_purchase_order_line_pk
    --limit to 5 years of data for Tableau                   
    where fact_polt.po_created_date >= DATEADD(year, -5, CURRENT_DATE)
        and fact_polt.transaction_type = 'DELIVER'


)

select * from cte_final
