select  
    app_name
    , retailer
    , rating_date_bk
    , reviewer_country_code
    , reviewer_country_name
    , brand_bk
    , application_bk
    , cumulative_1_star_rating
    , cumulative_2_star_rating
    , cumulative_3_star_rating
    , cumulative_4_star_rating
    , cumulative_5_star_rating
    , adjusted_cumulative_1_star_rating
    , adjusted_cumulative_2_star_rating
    , adjusted_cumulative_3_star_rating
    , adjusted_cumulative_4_star_rating
    , adjusted_cumulative_5_star_rating
    , incremental_1_star_rating
    , incremental_2_star_rating
    , incremental_3_star_rating
    , incremental_4_star_rating
    , incremental_5_star_rating
from {{ ref('pb_daily_cumulative_product_rating') }}