with
sat_application__appbot_api as (
    select * from {{ ref('sat_application__appbot_api') }}
),
sat_review__appbot_api as (
    select * from {{ ref('sat_review__appbot_api') }}
)
, cte_sat_application__appbot_api__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='sat_application__appbot_api'
        ,hk_field='application_hk') }}
)
, cte_sat_review__appbot_api__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='sat_review__appbot_api'
        ,hk_field='review_hk') }}
)
,sat_brand__ref_file as (

    select * from {{ ref('sat_brand__ref_file') }}
)
, cte_sat_brand__ref_file__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='sat_brand__ref_file'
        ,hk_field='brand_hk') }}
)
, pb as (
    select
        row_number() over(order by 1) as seq_id
        , current_timestamp as snapshot_dts
        , hr.review_hk
        , hb.brand_hk
        , hr.id as review_uid
        , sr.rec_src as review_source
        , to_char(
                cast(sr.published_at as date), 'YYYYMMDD'
        ) as review_date_bk
        , sb.brand as brand_bk        
        , sa.app_name as product
        , sa.store as retailer        
        , sr.summary as review_title
        , sr.text as review_text
        , sr.permalink_url as review_url
        , sr.star_rating
        , sr.country
        , sr.country_code 
    from {{ ref('link_review_application_appbot') }} lra
    inner join {{ ref('hub_review__appbot_api') }} hr
        on lra.review_hk = hr.review_hk
    inner join {{ ref('hub_application__appbot_api') }} ha
        on lra.application_hk = ha.application_hk
    inner join {{ ref('link_review_brand_appbot') }} lrb
        on hr.review_hk = lrb.review_hk
    inner join {{ ref('hub_brand') }} hb
        on lrb.brand_hk = hb.brand_hk
    left join cte_sat_review__appbot_api__latest sr
        on hr.review_hk = sr.review_hk
    left join cte_sat_application__appbot_api__latest sa
        on ha.application_hk = sa.application_hk
    left join cte_sat_brand__ref_file__latest as sb
        on hb.brand_hk = sb.brand_hk
    
)

select  
        seq_id
        , snapshot_dts
        , review_hk
        , brand_hk
        , review_uid
        , review_source
        , review_date_bk
        , brand_bk
        , product
        , retailer      
        , review_title
        , review_text
        , review_url
        , star_rating
from pb
where retailer IN ('iOS','Google Play')