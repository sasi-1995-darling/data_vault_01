with cte_sprd as (select * from {{ source("bronze_lrsn_psft", "ps_l_sp_prod") }})

select distinct
    cte_sprd.product_id
    , cte_sprd.l_part_type
    , cte_sprd.l_part_class
    , cte_sprd.l_part_subcomp
    , cte_sprd.inv_item_id
    , cte_sprd.release_flag
    , cte_sprd.setid
from cte_sprd
where cte_sprd._fivetran_deleted = false
