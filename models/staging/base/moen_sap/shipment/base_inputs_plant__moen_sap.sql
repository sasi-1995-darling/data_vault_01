with cte_plant as (select * from {{ source("bronze_moen_sap", "z_t001w") }})

select
    cte_plant.werks
    , cte_plant.name1
    , cte_plant.spras
    , cte_plant.gldelflag
from cte_plant