with cte_cgrp as (select * from {{ source("bronze_lrsn_psft", "ps_cust_cgrp_lnk") }})

select distinct
    cte_cgrp.setid
    , cte_cgrp.cust_id
    , cte_cgrp.cust_grp_type
    , cte_cgrp.customer_group
    , cte_cgrp.default_tax_grp
    , cte_cgrp.datetime_added
    , cte_cgrp.lastupddttm
    , cte_cgrp.last_maint_oprid
from cte_cgrp
where cte_cgrp._fivetran_deleted = false