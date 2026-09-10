{{ config(alias='fact_pos_weekly') }}
select 	
      reporting_customer
	, brand
	, item_id
	, store_id
	, transaction_date
	, transaction_datekey
	, reporting_channel
    , product_dest_zip--ferguson pos destination zip 2025-09-04
	, sku
	, sku_status
	, pos_qty
	, consumer_dollars
	, gross_dollars
    , store_key
    , inv_qty
    , inv_consumer_dollars
from {{ ref('fact_pos_weekly') }}
