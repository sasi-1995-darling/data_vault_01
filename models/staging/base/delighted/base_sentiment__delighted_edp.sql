with
sentiment_output as (
    select distinct 
        category_label
        , subcategory_label
        , tag 
    from {{ source('data_science__rr', 'sentiment_output') }} s
)

select * 
from sentiment_output