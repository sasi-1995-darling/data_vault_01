with cte_haou as (select * from {{ source('bronze_ml_ebs_hr', 'hr_all_organization_units') }})

select distinct
    cte_haou.organization_id as plant_id
    , cte_haou.name as plant_name
from cte_haou
where cte_haou._fivetran_deleted = 'FALSE'
