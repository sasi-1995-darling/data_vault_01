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
appbot_rating as (
    select 
        r.app_id
        , r.created_at
        , r.country
        , r.version
        , CONCAT(
        IFNULL(NULLIF(UPPER(TRIM(CAST(app_id AS VARCHAR))), ''), '^^'), '||',
        IFNULL(NULLIF(UPPER(TRIM(CAST(created_at AS VARCHAR))), ''), '^^'), '||',
        IFNULL(NULLIF(UPPER(TRIM(CAST(country AS VARCHAR))), ''), '^^'), '||',
        IFNULL(NULLIF(UPPER(TRIM(CAST(version AS VARCHAR))), ''), '^^')
    ) as rating_bk
    from {{ source('appbot__rr', 'ratings') }} as r
),
appbot_application as (
    select 
        a.id as app_id
        , a.name as product
    from {{ source('appbot__rr', 'applist') }} as a
)
,
link_rating_brand as (
    select
        r.rating_bk
        , b.brand_bk
        --, a.app_id
        , CONCAT(
            r.rating_bk
            ,'||'
            , b.brand_bk
        ) as link_rating_brand
    from appbot_rating as r
    inner join appbot_application as a
        on r.app_id = a.app_id
    inner join brand b 
        on a.product = b.product
)
select * from link_rating_brand
