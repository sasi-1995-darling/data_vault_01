with
rating_app as (
    select
        r.app_id
        , r.created_at
        , r.country
        , r.version
        , a.id as application_id
        , array_to_string(array_compact(
            array_construct(
                r.app_id
                , r.created_at
                , r.country
                , r.version
                , a.id
            )
        )
        , '') as link_rating_applist
    from {{ source('appbot__rr', 'ratings') }} as r
        left join {{ source('appbot__rr', 'applist') }} as a
            on r.app_id = a.id
        where r.country != 'All'
)

select distinct * from rating_app
--