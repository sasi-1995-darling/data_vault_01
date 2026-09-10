with cte_map as (select
    asin
    , coalesce(base_product,item_description) as base_material
from {{ source('amazon_vc','cross_ref') }}
qualify row_number() over (partition by asin,base_material order by asin desc)=1
)
, cte_bkcc as (select * from {{ ref('ref_business_key_collision') }}
where rec_src = 'US.CSV.AMAZON.CROSS_REF')

select distinct
    cte_map.*
    , cte_bkcc.rec_src
    , cte_bkcc.bkcc
from cte_map
inner join cte_bkcc on 1=1