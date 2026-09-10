with cte_psg2 as (select * from {{ source("bronze_tt_e21", "partsgrp2") }})

select
    cte_psg2.part_subgrp2
    , cte_psg2.part_sgrp2_desc
from cte_psg2
where cte_psg2._fivetran_deleted = false
