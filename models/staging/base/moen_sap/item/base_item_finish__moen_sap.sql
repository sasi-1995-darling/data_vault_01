with cte_itmfin as (select * from {{ source("bronze_moen_sap", "z_zpfint") }})

select
    cte_itmfin.zzfin
    , cte_itmfin.txt30
    , cte_itmfin.spras
from cte_itmfin