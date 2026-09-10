with cte_psg3 as (select * from {{ source("bronze_tt_e21", "partsgrp3") }})

select
    cte_psg3.part_subgrp3
    , cte_psg3.part_sgrp3_desc
from cte_psg3
where cte_psg3._fivetran_deleted = false
