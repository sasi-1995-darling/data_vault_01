with cte_repcat as (select * from {{ source("bronze_moen_sap", "z_zrepcatgt") }})

select
    cte_repcat.zzrepcatg
    , cte_repcat.zzrepcatgd
    , cte_repcat.spras
from cte_repcat