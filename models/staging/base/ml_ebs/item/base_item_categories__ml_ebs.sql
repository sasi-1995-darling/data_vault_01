with cte_mic as (select * from {{ source("bronze_ml_ebs_inv", "mtl_item_categories") }})

select distinct
    cte_mic.inventory_item_id
    , cte_mic.organization_id
    , cte_mic.category_set_id
    , cte_mic.category_id
    , cte_mic.last_update_date
from cte_mic
where cte_mic._fivetran_deleted = 'FALSE'
