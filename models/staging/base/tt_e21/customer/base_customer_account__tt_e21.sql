with cte_pg as (
    select *
    from {{ source("bronze_tt_e21", "shiphead") }}
)

select distinct
    cte_pg.cust_code
    , cte_pg._fivetran_synced
from cte_pg
where --cte_pg._fivetran_deleted = false and
    nullif(trim(cte_pg.cust_code), '') is not null
qualify row_number() over (partition by cte_pg.cust_code order by cte_pg._fivetran_synced desc) = 1
