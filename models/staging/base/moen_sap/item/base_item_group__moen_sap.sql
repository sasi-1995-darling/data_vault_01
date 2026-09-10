with cte_itmgrp as (select * from {{ source("bronze_moen_sap", "z_zptgkt") }})

select
    cte_itmgrp.zzptgk
    , cte_itmgrp.txt30
    , cte_itmgrp.spras
from cte_itmgrp