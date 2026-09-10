with cte_pitm as (select * from {{ source("bronze_lrsn_psft", "ps_prod_item") }})

select distinct
    cte_pitm.product_id
    , cte_pitm.descr
    , cte_pitm.product_kit_flag
    , cte_pitm.eff_status
    , coalesce(nullif(trim(cte_pitm.inv_item_id), ''), cte_pitm.product_id) as inv_item_id --due to nature of kit products with no item_id 
    , cte_pitm.setid
from cte_pitm
where cte_pitm._fivetran_deleted = false
