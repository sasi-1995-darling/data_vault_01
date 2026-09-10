with cte_kna1 as (select * from {{ source("bronze_moen_sap", "z_kna1") }})

, cte_knvv as (select * from {{ source("bronze_moen_sap", "z_knvv") }})

select
    nvl(cte_kna1.kunnr, '') as kunnr
    , cte_kna1.name1
    , cte_kna1.adrnr
    , cte_kna1.spras
    , cte_knvv.zzacctname
    , cte_knvv.zzacct
    , nvl(cte_knvv.vkorg,'') as vkorg
    , nvl(cte_knvv.vtweg,'') as vtweg
    , nvl(cte_knvv.spart,'') as spart
    , cte_knvv.vkbur
    , cte_knvv.bzirk
from cte_kna1
    left join cte_knvv on cte_kna1.kunnr = cte_knvv.kunnr
