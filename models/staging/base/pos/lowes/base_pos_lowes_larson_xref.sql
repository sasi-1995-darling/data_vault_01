with cte_map as (select
    lowes_sku
    , larson_sku
from {{ source('lowes_xref','lowes_larson_cross_reference_v_1') }}
qualify row_number() over (partition by lowes_sku,larson_sku order by _fivetran_synced desc)=1
)
, cte_bkcc as (select * from {{ ref('ref_business_key_collision') }}
where rec_src = 'US.CSV.LOWES.LOWES_LARSON_CROSS_REFERENCE')

select distinct
    cte_map.*
    , cte_bkcc.rec_src
    , cte_bkcc.bkcc
from cte_map
inner join cte_bkcc on 1=1