with cte_psg as (select * from {{ source("bronze_tt_e21", "partsgrp") }})

select
    cte_psg.part_subgrp
    , cte_psg.part_sgrp_desc
from cte_psg
where cte_psg._fivetran_deleted = false