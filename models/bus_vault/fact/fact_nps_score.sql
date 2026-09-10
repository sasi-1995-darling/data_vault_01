select  review_uid
        , review_source
        , review_date_key
        , brand
        , connected_product_category_code
        , score
        , review_text
from {{ ref('pb_nps_score') }}