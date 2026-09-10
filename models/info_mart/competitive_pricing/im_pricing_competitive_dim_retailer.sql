{{ config(alias='dim_retailer' + ('_competitive_pricing' if target.schema not in ['dev', 'qa', 'prod'] else '')) }}

select          
          retailer_bk
        , alias
        , country
        , bkcc
        , rec_src
FROM {{ ref('dim_retailer') }}