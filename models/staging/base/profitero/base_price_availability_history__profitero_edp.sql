select distinct
    date
    , customer_product_id
    , product_id
    , retailer_id
    , source
    , first_party_won_buy_box
    , first_value(regular_price) over (partition by date, customer_product_id, product_id, retailer_id, source order by regular_price desc) as regular_price
    , first_value(promotion_price) over (partition by date, customer_product_id, product_id, retailer_id, source order by promotion_price desc) as promotion_price
from {{ source('profitero__rr', 'price_availability_history') }}
where is_deleted = false
and first_party_won_buy_box is not null
