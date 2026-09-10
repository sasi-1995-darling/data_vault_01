with cte_area as (select * from {{ source("bronze_moen_sap", "z_zrmarea") }})

select
    cte_area.zzrmarea
    , cte_area.zzrmarea_desc
from cte_area