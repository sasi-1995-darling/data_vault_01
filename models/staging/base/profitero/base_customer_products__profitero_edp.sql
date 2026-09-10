select * from {{ source('profitero__rr', 'customer_products') }}
