{{
    config(
        materialized='view'
    )
}}


select shipment_id
        , customer_id 
        , item_id
        , posted_datekey
        , location_id
        , source as brand
        , customer 
        , key_account_number 
        , customer_account_name 
        , sales_org 
        , channel 
        , invoiced_qty
        , return_qty
        , revenue_dollars
        , actual_returns_dollars
        , shipment_type
from {{ ref('pb_shipment') }}