{{
    config(
        materialized='ephemeral'
    )
}}

select * from {{ ref('v_pos_lowes_moen') }}
union all
select * from {{ ref('v_pos_lowes_tmlc') }}