with cte_bkcc as 
(
    select * from {{ ref('ref_business_key_collision_snowflake') }}
    where rec_src = 'US.CSV.APPBOT.BRAND'
),
appbot_brand as (
    select
        appbot_product
        , brand
    from {{ source('reference__rr', 'ref_brand_appbot') }}    
)

select distinct rb.brand
        , cte_bkcc.rec_src
from appbot_brand rb 
inner join cte_bkcc on 1=1
