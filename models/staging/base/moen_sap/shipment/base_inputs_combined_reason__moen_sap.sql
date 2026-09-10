with cte_cmbrsn as (select * from {{ source("bronze_moen_sap", "z_t25a0") }})

select
    cte_cmbrsn.wwrsn
    , cte_cmbrsn.bezek
    , cte_cmbrsn.spras
    , cte_cmbrsn.gldelflag
from cte_cmbrsn