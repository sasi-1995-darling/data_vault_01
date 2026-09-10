with cte_sdoctyp as (select * from {{ source("bronze_moen_sap", "z_tvakt") }})

select
    cte_sdoctyp.auart
    , cte_sdoctyp.bezei
    , cte_sdoctyp.spras
    , cte_sdoctyp.gldelflag
from cte_sdoctyp