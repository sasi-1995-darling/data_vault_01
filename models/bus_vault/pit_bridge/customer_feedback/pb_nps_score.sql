with
sat_review__delighted_edp as (
    select * from {{ ref('sat_review__delighted_edp') }}
),
cte_sat_review__delighted_edp__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='sat_review__delighted_edp'
        ,hk_field='review_hk') }}
),
sat_product__delighted_edp as (
    select * from {{ ref('sat_product__delighted_edp') }}
),
cte_sat_product__delighted_edp__latest as (
    {{ generate_cte_satellite_latest(
        cte_name='sat_product__delighted_edp'
        ,hk_field='product_hk') }}
),
pb as (
    select
        row_number() over(order by 1) as seq_id
        , current_timestamp as snapshot_dts
        , hr.review_hk
        , hp.product_hk
        , sr.id as review_uid
        , sr.rec_src as review_source
        , to_timestamp_ntz(sr.created_at) 
            as created_at --convert epoch to timestamp
        , sp.product_name as connected_product_category_code
        , sr.comment as review_text
        , sr.score
        --, 'MOEN' as brand
        --, r.survey_type as review_type
        --, r.permalink as review_url
        
    from {{ ref('link_consumer_product_review') }} l
    inner join {{ ref('hub_review') }} hr
    on l.review_hk = hr.review_hk
    inner join {{ ref('hub_product') }} hp
    on l.product_hk = hp.product_hk   
    left join cte_sat_review__delighted_edp__latest sr
    on hr.review_hk = sr.review_hk 
    left join cte_sat_product__delighted_edp__latest sp
    on hp.product_hk = sp.product_hk
    
)

select  
        seq_id
        , snapshot_dts
        , review_hk
        , to_char(
                cast(created_at as date), 'YYYYMMDD'
        ) as review_date_key
        , product_hk as connected_product_category_hk
        
        ,'MOEN' as brand
        , connected_product_category_code
        , review_uid
        , review_source
        , score
        , review_text
from pb r
