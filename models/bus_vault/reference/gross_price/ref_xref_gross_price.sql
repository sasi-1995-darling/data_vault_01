select distinct
    item_id as item_hk
    , item_number as item_id
    , posted_datekey as shipment_datekey
    , to_date(shipment_datekey,'YYYYMMDD') as shipment_date   --- needed for older version join
    , customer_account_name
    , key_account_number
    , source as brand
    , channel
    , avg(revenue_dollars / invoiced_qty) as gross_aup
from {{ ref('pb_shipment') }}
where invoiced_qty != 0 and (shipment_type = 'SAL' or shipment_type is null)
group by customer_account_name, key_account_number, source, channel, item_id, item_number, posted_datekey
