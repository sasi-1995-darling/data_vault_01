with cte_icat as (select * from {{ source("bronze_lrsn_psft", "ps_itm_cat_tbl") }})

select distinct
    cte_icat.category_type
    , cte_icat.category_cd
    , cte_icat.descr60
    , cte_icat.descrshort
    , cte_icat.category_id --used in pk
    , cte_icat.effdt --effective date used in pk 
    , cte_icat.setid --business unit/org used in pk 
from cte_icat
where cte_icat._fivetran_deleted = false