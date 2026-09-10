select
    *
from {{ source('business_key_collision__rr', 'ref_business_key_collision') }}