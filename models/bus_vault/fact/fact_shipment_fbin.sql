{{
    config(
        materialized='view'
    )
}}


select
    shipment_id
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
    , sales_document --added for moen shipment enhancement 2025-09-12
    , sales_deal --added for moen shipment enhancement 2025-09-12
    , customer_purchase_order_type --added for moen shipment enhancement 2025-09-12
    , order_category	--added for moen shipment enhancement 2025-10-23
    , copa_record_type	--added for moen shipment enhancement 2025-10-23
    , fiscal_month__yyyymm
    , product_number
    , sender_cost_center
    , cost_element 
    , company_code
    , sales_quantity
    , standard_cost
    , gross_billing_price
    , order_reason
    , fiscal_year__yyyy
    , item_category
    , sales_document_type
    , invoice_hk	--added for moen shipment enhancement 2025-10-23
    , invoice_bk	--added for moen shipment enhancement 2025-10-23
    , order_header_hk	--added for moen shipment enhancement 2025-10-23
    , order_header_bk	--added for moen shipment enhancement 2025-10-23
    , order_line_hk		--added for moen shipment enhancement 2025-10-23
    , order_line_bk		--added for moen shipment enhancement 2025-10-23
    , sales_organization_hk	--added for moen shipment enhancement 2025-10-23
    , sales_organization_bk	--added for moen shipment enhancement 2025-10-23
    , distribution_channel_hk	--added for moen shipment enhancement 2025-10-23
    , distribution_channel_bk	--added for moen shipment enhancement 2025-10-23
    , division_hk		--added for moen shipment enhancement 2025-10-23
    , division_bk		--added for moen shipment enhancement 2025-10-23
    , plant_hk		--added for moen shipment enhancement 2025-10-23
    , plant_bk		--added for moen shipment enhancement 2025-10-23
    , customer_sales_attributes_key		--added for moen shipment enhancement 2025-10-23
    , rec_src --added 2025-09-12
    , bkcc  --added 2025-09-12
from {{ ref('pb_shipment') }}
