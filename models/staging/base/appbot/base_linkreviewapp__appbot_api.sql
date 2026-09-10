with
review_app as (
    select
        r.id as review_id
        , a.id as application_id
        , CONCAT(
            r.id
            , a.id
        ) as link_review_applist
    from {{ source('appbot__rr', 'reviews') }} as r
        left join {{ source('appbot__rr', 'applist') }} as a
            on r.app_id = a.id
)

select distinct * from review_app
