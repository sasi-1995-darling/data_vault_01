with cte_map as (select distinct 
    HD_ITEM,
    MASTER_LOCK_ITEM_DESCRIPTION as TMLC_BASE_MATERIAL
    from {{ source('homedepot_bronze_reference', 'hd_tmlc_cross_ref') }}
)
, cte_bkcc as (select * from {{ ref('ref_business_key_collision') }}
where rec_src = 'US.CSV.HOMEDEPOT.HD_TMLC_CROSS_REF')

select distinct
    cte_map.*
    , cte_bkcc.rec_src
    , cte_bkcc.bkcc
from cte_map
inner join cte_bkcc on 1=1