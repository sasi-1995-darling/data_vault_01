with pit_brand as (
    select * from {{ ref('pit_brand') }}
)
select
system_brand as sub_brand_code
, sub_brand as sub_brand_name
, brand
, business_unit
, competitor_ind
from pit_brand