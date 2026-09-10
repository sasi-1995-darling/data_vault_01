with
sentiment_category as (
    select
        review_id
        , category_label
        , subcategory_label
        , tag
        , sentiment as sentiment_text
        , subcategory_sentence
    from {{ source('data_science__rr', 'sentiment_output') }} s
),
joins_delightedReview as 
(
    select
         review.id as review_id
        , s.category_label
        , s.subcategory_label
        , s.tag        
        , array_to_string(array_compact(
            array_construct(
                review.id
                , category_label
                , subcategory_label
                , tag
            )
        )
        , '') as link_review_sentiment
        , s.sentiment_text
        , s.subcategory_sentence
    from sentiment_category as s
        inner join {{ ref('base_review__delighted_edp') }} as review
            on s.review_id = to_char(review.id)
)

select * from joins_delightedReview