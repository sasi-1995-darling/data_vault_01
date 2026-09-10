{{ config(alias='dim_item_fbin' + ('_direct_spend' if target.name not in ['dev', 'qa', 'prod'] else '')) }}

select * from {{ ref('dim_item_fbin') }}
