with
link_product_consumer_review as (
    select
        product_and_consumer.email as person_email
        , product_and_consumer.product_name
        , review.id as review_id
        , array_to_string(array_compact(
            array_construct(
                product_and_consumer.email
                , product_and_consumer.product_name
                , review.id
            )
        )
        , '') as link_product_consumer_review
    from {{ ref('base_product_and_consumer__delighted_edp') }} as product_and_consumer
        inner join {{ ref('base_review__delighted_edp') }} as review
            on product_and_consumer.id = review.person_id
)

select distinct * from link_product_consumer_review
