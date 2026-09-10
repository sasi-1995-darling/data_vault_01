with
sat_application__appbot_api as (
    select * from {{ ref('sat_application__appbot_api') }}
),
sat_rating__appbot_api as (
    select * from {{ ref('sat_rating__appbot_api') }}
)
, cte_sat_application__appbot_api__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='sat_application__appbot_api'
        ,hk_field='application_hk') }}
)
, cte_sat_rating__appbot_api__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='sat_rating__appbot_api'
        ,hk_field='rating_hk') }}
)
,sat_brand__ref_file as (

    select * from {{ ref('sat_brand__ref_file') }}
)
, cte_sat_brand__ref_file__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='sat_brand__ref_file'
        ,hk_field='brand_hk') }}
)
, rating_application as (
    select 
         ha.application_hk
        , ha.id as application_bk
        , hb.brand_hk
        , hr.rating_hk
        , sa.store as retailer
        , hr.created_at
        , to_char(
                cast(hr.created_at as date), 'YYYYMMDD'
        ) as rating_date_bk
        , sa.app_name
        , hr.version
        , hr.country as reviewer_country_name
        , sr.country_code as reviewer_country_code
        , sb.brand as brand_bk 
        , sr.cumulative_1_star
        , sr.cumulative_2_star
        , sr.cumulative_3_star
        , sr.cumulative_4_star
        , sr.cumulative_5_star
    from {{ ref('link_rating_application_appbot') }} lra
    inner join {{ ref('hub_rating__appbot_api') }} hr
        on lra.rating_hk = hr.rating_hk
    inner join {{ ref('hub_application__appbot_api') }} ha
        on lra.application_hk = ha.application_hk
    inner join {{ ref('link_rating_brand_appbot') }} lrb
        on hr.rating_hk = lrb.rating_hk
    inner join {{ ref('hub_brand') }} hb
        on lrb.brand_hk = hb.brand_hk
    left join cte_sat_rating__appbot_api__latest sr
        on hr.rating_hk = sr.rating_hk
    left join cte_sat_application__appbot_api__latest sa
        on ha.application_hk = sa.application_hk
    left join cte_sat_brand__ref_file__latest as sb
        on hb.brand_hk = sb.brand_hk
)
,
rank_ratingapp as (
  select r.*
        , row_number() over (partition by 
                                        substr(
                                            r.created_at,1,10
                                        )
                                        , r.application_bk
                                        , r.reviewer_country_name
                                        , r.version
                                        , r.retailer
                            order by r.created_at desc
                            ) as rn
  from rating_application as r
)
,
latest_ratingapp as (
    select 
        *
    from rank_ratingapp 
    where rn=1
            and cumulative_1_star is not null
            and cumulative_2_star is not null
            and cumulative_3_star is not null
            and cumulative_4_star is not null
            and cumulative_5_star is not null
)
, corrected_ratings as (
  select r.*
        /* the avg is not needed if we have the corrected value - jamie 04/18/2024
        , avg(cumulative_1_star) over (partition by r.application_bk
                                                    , r.reviewer_country
                                                    , r.version 
                                         order by created_at rows between 29 preceding and current row
                            ) as avg30day_1_star
        */
        , max(cumulative_1_star) over (partition by r.application_bk
                                                    , r.reviewer_country_name
                                                    , r.version
                                                    , r.retailer
                                         order by created_at
                            ) as corrected_1_star
        , max(cumulative_2_star) over (partition by r.application_bk
                                                    , r.reviewer_country_name
                                                    , r.version
                                                    , r.retailer
                                         order by created_at
                            ) as corrected_2_star
        , max(cumulative_3_star) over (partition by r.application_bk
                                                    , r.reviewer_country_name
                                                    , r.version
                                                    , r.retailer
                                         order by created_at
                            ) as corrected_3_star
        , max(cumulative_4_star) over (partition by r.application_bk
                                                    , r.reviewer_country_name
                                                    , r.version
                                                    , r.retailer
                                         order by created_at
                            ) as corrected_4_star
        , max(cumulative_5_star) over (partition by r.application_bk
                                                    , r.reviewer_country_name
                                                    , r.version
                                                    , r.retailer
                                         order by created_at
                            ) as corrected_5_star
  from latest_ratingapp as r
)
, incremental_rating as (
    select
        r.*
        , cumulative_1_star - lag(cumulative_1_star,1,cumulative_1_star) 
            over (partition by  r.application_bk
                                , r.reviewer_country_name
                                , r.version
                                , r.retailer
                                order by created_at
            ) as incre_1_star
        , cumulative_2_star - lag(cumulative_2_star,1,cumulative_2_star)
            over (partition by  r.application_bk
                                , r.reviewer_country_name
                                , r.version
                                , r.retailer
                                order by created_at
            ) as incre_2_star
        , cumulative_3_star - lag(cumulative_3_star,1,cumulative_3_star)
            over (partition by  r.application_bk
                                , r.reviewer_country_name
                                , r.version
                                , r.retailer
                                order by created_at
            ) as incre_3_star
        , cumulative_4_star - lag(cumulative_4_star,1,cumulative_4_star)
            over (partition by  r.application_bk
                                , r.reviewer_country_name
                                , r.version
                                , r.retailer
                                order by created_at
            ) as incre_4_star
        , cumulative_5_star - lag(cumulative_5_star,1,cumulative_5_star)
            over (partition by  r.application_bk
                                , r.reviewer_country_name
                                , r.version
                                , r.retailer
                                order by created_at
            ) as incre_5_star
    from corrected_ratings r
)
, final as (
    select
        row_number() over(order by 1) as seq_id
        , current_timestamp as snapshot_dts
        , application_hk
        , brand_hk
        , rating_hk
        , retailer
        , application_bk
        , rating_date_bk
        , app_name
        , version
        , reviewer_country_code
        , reviewer_country_name
        , brand_bk 
        , cumulative_1_star as cumulative_1_star_rating
        , cumulative_2_star as cumulative_2_star_rating
        , cumulative_3_star as cumulative_3_star_rating
        , cumulative_4_star as cumulative_4_star_rating
        , cumulative_5_star as cumulative_5_star_rating
        , corrected_1_star as adjusted_cumulative_1_star_rating
        , corrected_2_star as adjusted_cumulative_2_star_rating
        , corrected_3_star as adjusted_cumulative_3_star_rating
        , corrected_4_star as adjusted_cumulative_4_star_rating
        , corrected_5_star as adjusted_cumulative_5_star_rating
        , incre_1_star as incremental_1_star_rating
        , incre_2_star as incremental_2_star_rating
        , incre_3_star as incremental_3_star_rating
        , incre_4_star as incremental_4_star_rating
        , incre_5_star as incremental_5_star_rating
    from incremental_rating
)
select * from final
where 
    retailer = 'iOS'
or
    (
    retailer = 'Google Play'
    and
    reviewer_country_name = 'United States'
    )