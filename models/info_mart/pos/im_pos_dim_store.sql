{{ config(alias='dim_store') }}

select
    store_key
    , store_id
    , store_name
    , address1
    , city
    , state
    , postal_code
    , reporting_customer
from
    {{ ref('dim_store') }}
