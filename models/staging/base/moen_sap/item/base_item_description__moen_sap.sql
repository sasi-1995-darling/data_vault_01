with cte_itmd as (select * from {{ source("bronze_moen_sap", "z_makt") }})

select
    cte_itmd.matnr
    , cte_itmd.maktg
    , cte_itmd.spras
from cte_itmd