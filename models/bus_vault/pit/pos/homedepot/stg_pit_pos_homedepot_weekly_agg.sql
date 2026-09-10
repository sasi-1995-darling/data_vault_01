{{
    config(
        materialized='ephemeral'
    )
}}


with cte_homedepot_pos_weekly as (
    select * from {{ ref('stg_pit_pos_homedepot_weekly') }}
)

select 
item_id,
store_hk,
transaction_date,
transaction_datekey,
reporting_channel,
sku,
store_id,
sku_status_preference as sku_status,    --swapped out for preferred sku status
sum(pos_qty) as pos_qty,
sum(consumer_dollars) as consumer_dollars,
sum(gross_dollars) as gross_dollars,
sum(inv_qty) as inv_qty,
sum(inv_consumer_dollars) as inv_consumer_dollars,
reporting_customer,
brand,
bkcc,
rec_src 
from
cte_homedepot_pos_weekly f
group by all