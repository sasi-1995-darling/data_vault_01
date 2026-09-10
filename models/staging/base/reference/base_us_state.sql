with source as (select * from {{ source('ref', 'ref_us_state') }})

select
    state_territory
    , long_abbreviation
    , short_abbreviation
from source
