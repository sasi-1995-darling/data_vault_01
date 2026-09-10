with
moen_brand as (
    select
        r.ATWRT as brand_bk
        , r.rec_src
    from {{ ref('base_brand__moen_sap') }} as r
),
ebs_brand as (
    select
        r.registered_brand as brand_bk
        , r.rec_src
    from {{ ref('base_brand__ml_ebs') }} as r
),
appbot_brand as (
    select
        *
    from {{ source('reference__rr', 'ref_brand_appbot') }}    
),
brand as (
    select 
        brand_bk
        , '' as product
    from moen_brand
    union all
    select 
        brand_bk
        , '' as product
    from ebs_brand
    union all
    select 
        brand as brand_bk
        , appbot_product as product
    from appbot_brand
)
,
appbot_review as (
    select 
        r.id as review_bk
        , r.app_id
    from {{ source('appbot__rr', 'reviews') }} as r
),
appbot_application as (
    select 
        a.id as app_id
        , a.name as product
    from {{ source('appbot__rr', 'applist') }} as a
)
,
link_review_brand as (
    select
        r.review_bk
        , b.brand_bk
        --, a.app_id
        , CONCAT(
            r.review_bk
            ,'||'
            , b.brand_bk
        ) as link_review_brand
    from appbot_review as r
    inner join appbot_application as a
        on r.app_id = a.app_id
    inner join brand b 
        on a.product = b.product
)
select * from link_review_brand
