with cte_bkcc as 
(
    select * from {{ ref('ref_business_key_collision_snowflake') }}
    where rec_src = 'US.CSV.REFERENCE.BRAND'
),
ref_file_brand as (
    select
    *
from {{ source('reference__rr', 'ref_brand') }}
)

select  rb.business_unit
        , rb.brand
        , rb.sub_brand
        , rb.system_brand
        , rb.competitor
        , cte_bkcc.rec_src
from ref_file_brand rb 
inner join cte_bkcc on 1=1




