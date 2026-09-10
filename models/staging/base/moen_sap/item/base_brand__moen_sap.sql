with cte_bkcc as 
(
    select * from {{ ref('ref_business_key_collision_snowflake') }}
    where rec_src = 'USOHNO.SAP.ECCPRD.Z_AUSP'
),
moen_brand as
(
    select distinct
            atwrt
    from {{ source("bronze_moen_sap", "z_ausp") }}
    where atinn = '0000001608'
)
select b.*
       , cte_bkcc.rec_src
from moen_brand b
inner join cte_bkcc on 1=1
