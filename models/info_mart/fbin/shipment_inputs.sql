with item_cat as (
    select distinct
        item_id
        , item_category
        , item_sub_category
        , item_class
        , item_sub_class
        , brand
    from {{ ref('ref_item_master') }}
)

, moen_ship_input as (
    select
        a.shipment_inputs_hk
        , a.source as brand
        , cast(a.customer_id as varchar(100)) as customer_id
        , a.customer
        , a.customer_account_name
        , a.key_account_number
        , a.channel
        , cast(a.sales_org as varchar(100)) as sales_org
        , cast(a.item_id as varchar(100)) as item_id
        , a.ordered_units as ordered_qty
        , a.order_date
        , a.location
        , a.country
        , a.zip_code
        , a.order_dollars as input_dollars
        , a.gross_input_dollars
        , a.shipment_type as input_type
        , cast(b.item_category as varchar(100)) as item_category
        , b.item_sub_category
        , b.item_class
        , b.item_sub_class
        , a.currency
        , a.sap_load_date
    from {{ ref('v_shipment_inputs__moen_sap') }} as a
        left join item_cat as b on a.item_id = b.item_id
            and a.source = b.brand
    where a.sap_load_date >= '2019-01-01'
)

select * from moen_ship_input
