with cte_itmplt as (select * from {{ source("bronze_moen_sap", "z_zpltt") }})

select
    cte_itmplt.zzplt
    , cte_itmplt.txt30
    , cte_itmplt.spras
from cte_itmplt