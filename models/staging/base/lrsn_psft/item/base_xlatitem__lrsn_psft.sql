with cte_xlat as (select * from {{ source("bronze_lrsn_psft", "psxlatitem") }})

select distinct
    cte_xlat.fieldname --lookup name/field used in pk 
    , cte_xlat.fieldvalue --lookup value/code used in pk  
    , cte_xlat.xlatlongname
    , cte_xlat.xlatshortname
    , cte_xlat.eff_status
    , cte_xlat.effdt --effective date used in pk 
from cte_xlat
where cte_xlat._fivetran_deleted = false