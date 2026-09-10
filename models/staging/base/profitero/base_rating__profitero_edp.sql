with 
rank_rating as (
  select r.*
        , row_number() over (partition by 
                                        customer_product_id
                                        , retailer_id
                                        , cumulative_star_rating
                                        , cumulative_reviews
                                        , cumulative_5_star_reviews
                                        , cumulative_4_star_reviews
                                        , cumulative_3_star_reviews
                                        , cumulative_2_star_reviews
                                        , cumulative_1_star_reviews
                            order by date desc
                            ) as rn
  from {{ source('profitero__rr', 'products_ratings') }} as r
),
unique_rating as (
    select 
        *
    from rank_rating 
    where rn=1
            and cumulative_1_star_reviews is not null
            and cumulative_2_star_reviews is not null
            and cumulative_3_star_reviews is not null
            and cumulative_4_star_reviews is not null
            and cumulative_5_star_reviews is not null
),
corrected_ratings as (--country is always "US", sub brand matches 1:1 with customer_product_id
  select r.*
        /*
        , avg(cumulative_1_star_reviews) over (partition by customer_product_id
                                                            , retailer_id
                                         order by date rows between 29 preceding and current row
                            ) as avg30day_1_star
        */
        , max(cumulative_1_star_reviews) 
            over (partition by r.customer_product_id
                               , retailer_id
                                order by date
                ) as corrected_1_star
        , max(cumulative_2_star_reviews) 
            over (partition by  r.customer_product_id
                                , retailer_id
                                order by date
            ) as corrected_2_star
        , max(cumulative_3_star_reviews)
            over (partition by  r.customer_product_id
                                , retailer_id
                                order by date
            ) as corrected_3_star
        , max(cumulative_4_star_reviews)
            over (partition by  r.customer_product_id
                                , retailer_id
                                order by date
            ) as corrected_4_star
        , max(cumulative_5_star_reviews)
            over (partition by  r.customer_product_id
                                , retailer_id
                                order by date
            ) as corrected_5_star
  from unique_rating as r
),
incr_on_corrected_ratings as (
    select r.*
        , corrected_1_star - lag(corrected_1_star,1,corrected_1_star) 
            over (partition by  r.customer_product_id
                                , retailer_id
                                order by date
            ) as incre_1_star
        , corrected_2_star - lag(corrected_2_star,1,corrected_2_star)
            over (partition by  r.customer_product_id
                                , retailer_id
                                order by date
            ) as incre_2_star
        , corrected_3_star - lag(corrected_3_star,1,corrected_3_star)
            over (partition by  r.customer_product_id
                                , retailer_id
                                order by date
            ) as incre_3_star
        , corrected_4_star - lag(corrected_4_star,1,corrected_4_star)
            over (partition by  r.customer_product_id
                                , retailer_id
                                order by date
            ) as incre_4_star
        , corrected_5_star - lag(corrected_5_star,1,corrected_5_star)
            over (partition by  r.customer_product_id
                                , retailer_id
                                order by date
            ) as incre_5_star
    from corrected_ratings as r

)

select * from incr_on_corrected_ratings