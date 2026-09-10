with cte_pg as (select * from {{ source("bronze_tt_e21", "corp_parent") }})

select
    cte_pg.cp_code
    , cte_pg.cp_name
    , cte_pg.status_ind
    , cte_pg.status_date
    , cte_pg.add_date
    , cte_pg.add_user
    , cte_pg._fivetran_synced
from cte_pg
where cte_pg._fivetran_deleted = false
and nullif(trim(cte_pg.cp_code), '') is not null