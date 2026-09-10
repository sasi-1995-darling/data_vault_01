with cte_adrc as (select * from {{ source("bronze_moen_sap", "z_adrc") }})
, cte_bkcc as (select * from {{ ref('ref_business_key_collision') }}
where rec_src = 'USOHNO.SAP.ECCPRD.Z_ADRC')
select
    cte_adrc.street
    , cte_adrc.city1
    , cte_adrc.region
    , cte_adrc.post_code1
    , cte_adrc.country
    , cte_adrc.langu
    , cte_adrc.addrnumber
    , cte_adrc.nation
    , cte_bkcc.rec_src
    , cte_bkcc.bkcc
from cte_adrc
    inner join cte_bkcc on 1=1
