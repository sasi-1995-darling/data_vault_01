with
cte_bkcc as (select * from {{ ref('ref_business_key_collision') }}
where rec_src = 'USWIOC.ORCL.EBSPRD.HZ_LOCATIONS')

select loc.*
, cte_bkcc.rec_src
, cte_bkcc.bkcc
 from {{ source('bronze_ml_ebs_ar', 'hz_locations') }} as loc 
inner join cte_bkcc on 1=1
where loc._fivetran_deleted = 'FALSE'
