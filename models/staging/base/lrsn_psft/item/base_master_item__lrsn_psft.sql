with cte_mitm as (select * from {{ source("bronze_lrsn_psft", "ps_master_item_tbl") }})

select distinct
    cte_mitm.inv_item_id -- used in pk
    , cte_mitm.descr
    , cte_mitm.descr60
    , cte_mitm.unit_measure_std
    , cte_mitm.inv_item_group
    , cte_mitm.category_id
    , cte_mitm.item_field_c6
    , cte_mitm.setid -- business unit/org used in pk 
from cte_mitm
where cte_mitm.setid = 'LARSN' --remove AEI01 other Larson Co. no longer used also causing dup issues on these items(10130,12414,20200087)
and cte_mitm._fivetran_deleted = false
