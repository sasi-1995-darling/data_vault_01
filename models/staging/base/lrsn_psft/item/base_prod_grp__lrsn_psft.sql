with cte_pgrp as (select * from {{ source("bronze_lrsn_psft", "ps_l_prod_grp_tbl") }})

select distinct
    cte_pgrp.product_id
    , cte_pgrp.l_company
    , cte_pgrp.l_group
    , cte_pgrp.l_category
    , cte_pgrp.l_class
    , cte_pgrp.l_series
    , cte_pgrp.l_model
    , cte_pgrp.user_dim_1
    , cte_pgrp.user_dim_5
    , cte_pgrp.user_dim_8
    , cte_pgrp.user_dim_14
    , cte_pgrp.product_kit_id
    , cte_pgrp.l_sizew
    , cte_pgrp.l_sizeh
    , cte_pgrp.release_flag
    , cte_pgrp.setid
from cte_pgrp
where cte_pgrp._fivetran_deleted = false
