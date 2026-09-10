with
application as (
    select
        id
        , identifier
        , name as app_name
        , store
        , store_id
        , icon
        , authenticated
        , translation_supported
    from {{ source('appbot__rr', 'applist') }}
)

select * from application
--