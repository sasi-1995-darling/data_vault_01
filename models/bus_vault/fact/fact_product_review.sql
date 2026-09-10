select  review_uid
        , review_source
        , review_date_bk
        , brand_bk
        , product
        , retailer
        , review_title
        , review_text
        , review_url
        , star_rating
from {{ ref('pb_product_review') }}