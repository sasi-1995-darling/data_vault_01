with
rating as (
    select
        app_id
        , created_at
        , coalesce(country, 'Unknown') as country
        , country_id
        , country_code
        , star_1 as cumulative_1_star
        , star_2 as cumulative_2_star
        , star_3 as cumulative_3_star
        , star_4 as cumulative_4_star
        , star_5 as cumulative_5_star
        , total as cumulative_reviews
        , avg as cumulative_star_rating
        , version
    from {{ source('appbot__rr', 'ratings') }}
)
--
select * from rating
