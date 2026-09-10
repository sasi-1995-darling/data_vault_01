with cte_item as (select * from {{ source("bronze_lrsn_psft", "ps_inv_items") }})

select distinct
    cte_item.inv_item_id
    , cte_item.inv_item_type
    , cte_item.inv_item_height
    , cte_item.inv_item_length
    , cte_item.inv_item_width
    , cte_item.inv_item_weight
    , cte_item.inv_item_volume
    , cte_item.inv_item_size
    , cte_item.inv_item_color
    , cte_item.effdt --effective date used as cdk(child dependent key) for multiactive satellite
    , cte_item.upc_id
    , cte_item.setid
from cte_item
where cte_item._fivetran_deleted = false
