{{ config(alias='dim_brand_v2' + ('_competitive_pricing' if target.schema not in ['dev', 'qa', 'prod'] else '')) }}


SELECT
          brand_bk
        , full_name
        , bkcc
        , rec_src
        , owner
        , brand
        , subbrand
        , subsubbrand
        , system_brand
        , business_unit
        , competitor_ind
FROM {{ ref('dim_brand_v2') }}