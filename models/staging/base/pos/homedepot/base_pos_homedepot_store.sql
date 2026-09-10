with cte_bkcc as (
    select * from {{ ref('ref_business_key_collision') }}
)

select
    state_territory_code
    , d_all_thd
    , d_buying_office
    , d_city
    , d_country
    , d_district
    , d_division
    , d_lob
    , d_latitude
    , d_longitude
    , d_market
    , d_postal_code
    , d_region
    , d_store
    , d_store_address
    , d_store_name
    , d_store_nbr
    , d_time_zone
    , home_depot_account
    , run_date
    , c.bkcc
    , c.rec_src
from {{ source('homedepot_pos_askuity', 'hd_askuity_master_storeattributes') }}
, cte_bkcc as c
where c.rec_src = 'US.ASKUITY.HD_ASKUITY_MASTER_STOREATTRIBUTES'
