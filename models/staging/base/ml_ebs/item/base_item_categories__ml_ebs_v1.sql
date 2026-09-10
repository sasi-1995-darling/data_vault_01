with 
cte_bkcc as (select * from {{ ref('ref_business_key_collision') }}
where rec_src = 'USWIOC.ORCL.EBSPRD.SYSTEM_ITEM_CATEGORIES')

, cte_mic as (select * from {{ source("bronze_ml_ebs_inv", "mtl_item_categories") }})
, cte_ib as (select * from {{ source('bronze_ml_ebs_inv', 'mtl_system_items_b') }})

select distinct
    cte_mic.inventory_item_id
    , cte_mic.organization_id
    , cte_mic.category_set_id
    , cte_mic.category_id
    , cte_mic.last_update_date
    , cte_bkcc.rec_src
    , cte_bkcc.bkcc
    , cte_ib.segment1
from cte_mic
left join cte_ib on cte_mic.inventory_item_id = cte_ib.inventory_item_id and cte_mic.organization_id = cte_ib.organization_id
inner join cte_bkcc on 1=1
where cte_mic._fivetran_deleted = 'FALSE'
