with cte_bkcc as (
    select * from {{ ref('ref_business_key_collision') }}
)

select
    location_id
    , location_desc
    , delivery_address
    , delivery_city
    , delivery_state
    , delivery_code
    , salesfloor_footage
    , district_district
    , region_id
    , region_desc
    , division_division
    , advertising_area
    , geo_id
    , geo_desc
    , forecast_zone
    , supporting_center
    , supporting_fdc
    , supporting_transload
    , pm_snapshot_date
    , file_name
    , open_date
    , _file
    , _fivetran_synced
    , _modified
    , real_date
    , _line
    , c.bkcc
    , c.rec_src
from {{ source('lowes_us', 'location') }}
, cte_bkcc c
where c.rec_src='US.EXCEL.LOWES_US.LOCATION'
