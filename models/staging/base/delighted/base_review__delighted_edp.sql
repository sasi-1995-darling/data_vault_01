with
hydra as (
    select
        s.id
        , s.person_id
        , s.comment
        , s.permalink
        , s.created_at
        , s.updated_at
        , s._fivetran_synced
        , s.properties_delighted_browser
        , s.properties_delighted_device_type
        , s.properties_delighted_operating_system
        , s.survey_type
        , s.score
    from {{ source('delighted_hydra__rr', 'response') }} s
),
naboo as (
    select
        s.id
        , s.person_id
        , s.comment
        , s.permalink
        , s.created_at
        , s.updated_at
        , s._fivetran_synced
        , s.properties_delighted_browser
        , s.properties_delighted_device_type
        , s.properties_delighted_operating_system
        , s.survey_type
        , s.score
    from {{ source('delighted_naboo__rr', 'response') }} s
),
sws as (
    select
        s.id
        , s.person_id
        , s.comment
        , s.permalink
        , s.created_at
        , s.updated_at
        , s._fivetran_synced
        , s.properties_delighted_browser
        , s.properties_delighted_device_type
        , s.properties_delighted_operating_system
        , s.survey_type
        , s.score
    from {{ source('delighted_sws__rr', 'response') }} s
),
vak as (
    select
        s.id
        , s.person_id
        , s.comment
        , s.permalink
        , s.created_at
        , s.updated_at
        , s._fivetran_synced
        , s.properties_delighted_browser
        , s.properties_delighted_device_type
        , s.properties_delighted_operating_system
        , s.survey_type
        , s.score
    from {{ source('delighted_vak__rr', 'response') }} s
)

select * from hydra
union
select * from naboo
union
select * from sws
union
select * from vak