with cte_itmd as (select * from {{ source("bronze_moen_sap", "z_makt") }})
, cte_bkcc as (select * from {{ ref('ref_business_key_collision') }}
where rec_src = 'USOHNO.SAP.ECCPRD.Z_MAKT')

select
    cte_itmd.matnr
    , cte_itmd.maktg
    , cte_itmd.spras
    , cte_bkcc.rec_src
    , cte_bkcc.bkcc
from cte_itmd
inner join cte_bkcc on 1=1