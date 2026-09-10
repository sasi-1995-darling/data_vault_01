with cte_saltyp as (select * from {{ source("bronze_moen_sap", "z_t25a1") }})

select
    cte_saltyp.wwstp
    , cte_saltyp.bezek
    , cte_saltyp.spras
    , cte_saltyp.gldelflag
from cte_saltyp