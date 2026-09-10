with cte_kna1 as (select * from {{ source("bronze_moen_sap", "z_kna1") }})

, cte_knvv as (select * from {{ source("bronze_moen_sap", "z_knvv") }})

, cte_bkcc as (select * from {{ ref('ref_business_key_collision') }}
where rec_src = 'USOHNO.SAP.ECCPRD.HOFR_US_SALES')

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
    , cte_bkcc.rec_src
    , cte_bkcc.bkcc
from cte_kna1
inner join cte_bkcc on 1=1
    left join cte_knvv on cte_kna1.kunnr = cte_knvv.kunnr
