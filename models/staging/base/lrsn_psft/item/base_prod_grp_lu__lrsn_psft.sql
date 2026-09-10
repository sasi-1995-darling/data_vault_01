with cte_grpl as (select * from {{ source("bronze_lrsn_psft", "ps_l_prod_grp_lu") }})

select distinct
    cte_grpl.l_grp_type -- used in pk
    , cte_grpl.l_grp_code -- used in pk
    , cte_grpl.descr
    , cte_grpl.l_descr_sp
    , cte_grpl.l_descr_fr
    , cte_grpl.l_descr
    , cte_grpl.setid-- business unit/org used in pk 
from cte_grpl
where cte_grpl._fivetran_deleted = false