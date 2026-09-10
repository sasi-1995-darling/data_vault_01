with
sentiment_output as (
    select  created_at
            , review_id as ukey
            , review_source_id as review_source
            , review_title as review_header
            , review_text
            , sentiment
            , subcategory_sentence
            , category_label
            , subcategory_label
            , tag 
    from {{ source('data_science__rr', 'sentiment_output') }} s
)

select * 
from sentiment_output