with cte_adrc as (select * from {{ source("bronze_moen_sap", "z_adrc") }})

select
    cte_adrc.street
    , cte_adrc.city1
    , cte_adrc.region
    , cte_adrc.post_code1
    , cte_adrc.country
    , cte_adrc.langu
    , cte_adrc.addrnumber
    , cte_adrc.nation
from cte_adrc
