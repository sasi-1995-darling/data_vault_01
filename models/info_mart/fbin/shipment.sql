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

, moen_ship as (
    select
        a.shipment_hk
        , a.source as brand
        , a.customer_id
        , a.customer
        , a.customer_account_name
        , a.key_account_number
        , a.channel
        , a.sales_org
        , a.item_id
        , a.invoiced_qty
        , a.return_qty
        , a.date_posted
        , a.location
        , a.country
        , a.zip_code
        , a.revenue_dollars
        , a.actual_return_dollars
        , a.shipment_type
        , b.item_category
        , b.item_sub_category
        , b.item_class
        , b.item_sub_class
    from {{ ref('t_shipment__moen_sap') }} as a
        left join item_cat as b on a.item_id = b.item_id
            and a.source = b.brand
    where a.date_posted >= '2019-01-01'
)

, tmlc_ship as (
    select
        a.shipment_hk
        , b.brand
        , to_varchar(a.customer_id) as customer_id
        , a.customer
        , a.customer_account_name
        , a.key_account_number
        , a.channel
        , a.sales_org
        , a.item_id
        , a.invoiced_qty
        , null as return_qty
        , a.date_posted
        , a.location
        , a.country
        , a.zip_code
        , a.revenue_dollars
        , null as actual_return_dollars
        , a.shipment_type
        , b.item_category
        , b.item_sub_category
        , b.item_class
        , b.item_sub_class
    from {{ ref('v_shipment__ml_ebs') }} as a
        left join item_cat as b on a.item_id = b.item_id
            and b.brand = 'TMLC'
    where a.date_posted >= '2019-01-01'
)

, tt_ship as (
    select
        a.shipment_hk
        , b.brand
        , a.customer_id
        , a.customer
        , a.customer_account_name
        , a.key_account_number
        , a.channel
        , a.sales_org
        , a.item_id
        , a.invoiced_qty
        , null as return_qty
        , a.date_posted
        , a.location
        , a.country
        , a.zip_code
        , a.revenue_dollars
        , null as actual_return_dollars
        , a.shipment_type
        , b.item_category
        , b.item_sub_category
        , b.item_class
        , b.item_sub_class
    from {{ ref('v_shipment__tt_e21') }} as a
        left join item_cat as b on a.item_id = b.item_id
            and b.brand = 'THTRU'
    where a.date_posted >= '2019-01-01'
)

, all_ship as (
    select * from moen_ship
    union
    select * from tmlc_ship
    -- union
    -- select * from tt_ship
)

select * from all_ship
