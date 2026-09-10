with
hydra as (
    select
          s._FIVETRAN_DELETED
        , s._FIVETRAN_SYNCED
        , s.EMAIL
        , s.CREATED_AT
        , s.ID
        , 'SI' as product_name --hydra
    from {{ source('delighted_hydra__rr', 'person') }} s
),
naboo as (
    select
          s._FIVETRAN_DELETED
        , s._FIVETRAN_SYNCED
        , s.EMAIL
        , s.CREATED_AT
        , s.ID
        , 'SWD' as product_name --naboo
    from {{ source('delighted_naboo__rr', 'person') }} s
),
sws as (
    select
          s._FIVETRAN_DELETED
        , s._FIVETRAN_SYNCED
        , s.EMAIL
        , s.CREATED_AT
        , s.ID
        , 'SWS' as product_name --sws
    from {{ source('delighted_sws__rr', 'person') }} s
),
vak as (
    select
          s._FIVETRAN_DELETED
        , s._FIVETRAN_SYNCED
        , s.EMAIL
        , s.CREATED_AT
        , s.ID
        , 'VAK' as product_name --vak
    from {{ source('delighted_vak__rr', 'person') }} s
)

select * from hydra
union
select * from naboo
union
select * from sws
union
select * from vak