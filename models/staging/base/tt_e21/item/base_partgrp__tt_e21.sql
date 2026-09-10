with cte_pg as (select * from {{ source("bronze_tt_e21", "partgrp") }})

select
    cte_pg.part_grp
    , cte_pg.part_grp_desc
from cte_pg
where cte_pg._fivetran_deleted = false
