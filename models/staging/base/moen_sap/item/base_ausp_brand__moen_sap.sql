with cte_itmbrnd as (select * from {{ source("bronze_moen_sap", "z_ausp") }})

select distinct
    cte_itmbrnd.objek
    , cte_itmbrnd.atwrt
from cte_itmbrnd
where cte_itmbrnd.atinn = '0000001608'
