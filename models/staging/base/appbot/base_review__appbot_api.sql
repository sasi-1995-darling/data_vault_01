with
review as (
    select
        app_id as customer_product_id
        , app_store_id
        , id
        , author
        , rating as star_rating
        , body as text
        , subject as summary
        , published_at as published_at
        , published_at_datetime
        , version
        , country
        , country_id
        , country_code
        , translated_subject
        , translated_body
        , reply_text as manufacturer_comment_text
        , reply_date as manufacturer_comment_datekey
        , topics
        , topic_ids
        , store_id
        , device
        , device_friendly_name
        , os_version
        , os_version_friendly_name
        , sentiment
        , detected_language
        , detected_language_id
        , permalink_url
        , reply_url
        , internal_url
    from {{ source('appbot__rr', 'reviews') }}
)

select * from review
