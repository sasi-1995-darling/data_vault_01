select 
    ZIP,
    USPS_ZIP_PREF_CITY,
    USPS_ZIP_PREF_STATE,
    count(COUNTY) as NUM_COUNTIES
from 
    {{ ref('pb_zip_county')}}
group by all