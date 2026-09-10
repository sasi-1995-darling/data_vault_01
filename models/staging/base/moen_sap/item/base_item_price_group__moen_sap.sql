with cte_itmprc as (select * from {{ source("bronze_moen_sap", "z_zptgt") }})

select
    cte_itmprc.zzptg
    , cte_itmprc.txt30
    , cte_itmprc.spras
from cte_itmprc