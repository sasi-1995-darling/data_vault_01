with cte_map as (select
    asin
    , model_style_number
    ,_fivetran_synced
from {{ source('amazon_xref', 'amazon_moen_catalog_hist') }}
qualify row_number() over (partition by asin,model_style_number order by _fivetran_synced desc)=1
)
, cte_bkcc as (select * from {{ ref('ref_business_key_collision') }}
where rec_src = 'US.CSV.AMAZON.AMAZON_MOEN_CATALOG_HIST')
select distinct
    cte_map.*
    , cte_bkcc.rec_src
    , cte_bkcc.bkcc
from cte_map
inner join cte_bkcc on 1=1
