with cte_pm as (select * from {{ source("bronze_tt_e21", "partmstr") }})

select
    cte_pm.uom
    , cte_pm.part_type
    , cte_pm.part_status
    , cte_pm.long_desc1
    , cte_pm.long_desc2
    , cte_pm.long_desc3
    , cte_pm.long_desc4
    , cte_pm.long_desc5
    , cte_pm.long_desc6
    , cte_pm.long_desc7
    , cte_pm.long_desc8
    , cte_pm.long_desc9
    , cte_pm.long_desc10
    , upper(cte_pm.tt_color) as tt_color
    , cte_pm.tt_shape
    , cte_pm.tt_dimension
    , cte_pm.part_length
    , cte_pm.part_width
    , cte_pm.part_height
    , cte_pm.sellable
    , cte_pm.base_part_flag
    , cte_pm.part_grp
    , cte_pm.part_subgrp
    , cte_pm.part_subgrp2
    , cte_pm.part_subgrp3
    , trim(cte_pm.part_code) as part_code
    , cte_pm.part_desc
from cte_pm
where cte_pm._fivetran_deleted = false
    and cte_pm.part_code is not null
    and cte_pm.part_status = 'A'
qualify row_number() over (partition by trim(cte_pm.part_code) order by cte_pm._fivetran_synced desc, len(cte_pm.part_desc) desc nulls last) = 1