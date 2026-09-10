with source as (select * from {{ source('ref', 'ref_country') }})

select
    alpha_2_code
    , country
    , alpha_3_code
    , numeric
from source
