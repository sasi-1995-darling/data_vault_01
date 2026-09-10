{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HB             as ( SELECT BKCC, BRAND_BK, BRAND_HK, REC_SRC FROM {{ ref('hub_brand_v2') }} as SRC  ),
SRC_SB             as ( SELECT BRAND, BRAND_HK, BRAND_OWNER, DIM_BRAND_KEY, FULL_NAME, SUBBRAND, SUBSUBBRAND, UPDATED_AT FROM {{ ref('sat_brand__profitero_share') }} as SRC 
                        qualify 1= row_number() over(partition by BRAND_HK order by UPDATED_AT DESC) )

/*
SRC_HB             as ( SELECT * FROM RAW_VAULT.HUB_BRAND_V2 )
SRC_SB             as ( SELECT * FROM RAW_VAULT.SAT_BRAND__PROFITERO_SHARE )
*/
---- LOGIC LAYER ----

, LOGIC_HB as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , REC_SRC
      , CASE
            WHEN CONTAINS(BRAND_BK, 'Moen') THEN 'Moen'
            WHEN CONTAINS(BRAND_BK, 'MOEN') THEN 'Moen'
            WHEN CONTAINS(BRAND_BK, 'Master Lock') THEN 'Master Lock'
            WHEN CONTAINS(BRAND_BK, 'Yale') THEN 'Yale'
            WHEN CONTAINS(BRAND_BK, 'Phyn') THEN 'Phyn'
            WHEN CONTAINS(BRAND_BK, 'KOHLER') THEN 'Kohler'
            WHEN CONTAINS(BRAND_BK, 'Kohler') THEN 'Kohler'
            WHEN CONTAINS(BRAND_BK, 'ShowerMe') THEN 'ShowerMe'
            WHEN CONTAINS(BRAND_BK, 'SentrySafe') THEN 'SentrySafe'
            WHEN CONTAINS(BRAND_BK, 'August Locks') THEN 'August'
            WHEN BRAND_BK = 'August' THEN 'August'
            WHEN CONTAINS(BRAND_BK, 'Therma-Tru Benchmark Doors') THEN 'Therma-Tru'
            WHEN CONTAINS(BRAND_BK, 'Fypon') THEN 'Fypon'
            WHEN CONTAINS(BRAND_BK, 'Larson') THEN 'Larson'
            WHEN CONTAINS(BRAND_BK, 'Fiberon') THEN 'Fiberon'
            ELSE
            BRAND_BK
        END                                                          as                                       SYSTEM_BRAND
      , CASE
            WHEN CONTAINS(BRAND_BK, 'Moen') THEN 'Water'
            WHEN CONTAINS(BRAND_BK, 'MOEN') THEN 'Water'
            WHEN CONTAINS(BRAND_BK, 'Master Lock') THEN 'Security'
            WHEN CONTAINS(BRAND_BK, 'Yale') THEN 'Security'
            WHEN CONTAINS(BRAND_BK, 'SentrySafe') THEN 'Security'
            WHEN CONTAINS(BRAND_BK, 'August Locks') THEN 'Security'
            WHEN BRAND_BK = 'August' THEN 'Security'
            WHEN CONTAINS(BRAND_BK, 'Therma-Tru Benchmark Doors') THEN 'Outdoors'
            WHEN CONTAINS(BRAND_BK, 'Fypon') THEN 'Outdoors'
            WHEN CONTAINS(BRAND_BK, 'Larson') THEN 'Outdoors'
            WHEN CONTAINS(BRAND_BK, 'Fiberon') THEN 'Outdoors'
            ELSE
            'Competitor'
        END                                                          as                                      BUSINESS_UNIT
      , CASE
            WHEN CONTAINS(BRAND_BK, 'Moen') THEN 'N'
            WHEN CONTAINS(BRAND_BK, 'MOEN') THEN 'N'
            WHEN CONTAINS(BRAND_BK, 'Master Lock') THEN 'N'
            WHEN CONTAINS(BRAND_BK, 'Yale') THEN 'N'
            WHEN CONTAINS(BRAND_BK, 'Phyn') THEN 'Y'
            WHEN CONTAINS(BRAND_BK, 'KOHLER') THEN 'Y'
            WHEN CONTAINS(BRAND_BK, 'Kohler') THEN 'Y'
            WHEN CONTAINS(BRAND_BK, 'ShowerMe') THEN 'Y'
            WHEN CONTAINS(BRAND_BK, 'SentrySafe') THEN 'N'
            WHEN CONTAINS(BRAND_BK, 'August Locks') THEN 'N'
            WHEN BRAND_BK = 'August' THEN 'N'
            WHEN CONTAINS(BRAND_BK, 'Therma-Tru Benchmark Doors') THEN 'N'
            WHEN CONTAINS(BRAND_BK, 'Fypon') THEN 'N'
            WHEN CONTAINS(BRAND_BK, 'Larson') THEN 'N'
            WHEN CONTAINS(BRAND_BK, 'Fiberon') THEN 'N'
            ELSE
            'Y'
        END                                                          as                                     COMPETITOR_IND
    FROM SRC_HB
)

, LOGIC_SB as (
    SELECT
        BRAND_HK                                                     as                                        SB_BRAND_HK
      , DIM_BRAND_KEY                                                as                                                 ID
      , FULL_NAME
      , BRAND_OWNER                                                  as                                              OWNER
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
    FROM SRC_SB
)
---- RENAME LAYER ----

, RENAME_HB as (
    SELECT
        BRAND_HK
      , BRAND_BK
      , BKCC
      , REC_SRC
      , SYSTEM_BRAND
      , BUSINESS_UNIT
      , COMPETITOR_IND
    FROM LOGIC_HB
)

, RENAME_SB as (
    SELECT
        SB_BRAND_HK
      , ID
      , FULL_NAME
      , OWNER
      , BRAND
      , SUBBRAND
      , SUBSUBBRAND
    FROM LOGIC_SB
)
---- FILTER LAYER ----

, FILTER_HB as (
    SELECT *
    FROM RENAME_HB
)

, FILTER_SB as (
    SELECT *
    FROM RENAME_SB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HB
    INNER JOIN FILTER_SB
        ON FILTER_HB.BRAND_HK = SB_BRAND_HK
)

---- FINAL LAYER ----
SELECT
          BRAND_HK
        , BRAND_BK
        , BKCC
        , REC_SRC
        , ID
        , FULL_NAME
        , OWNER
        , BRAND
        , SUBBRAND
        , SUBSUBBRAND
        , SYSTEM_BRAND
        , BUSINESS_UNIT
        , COMPETITOR_IND
FROM JOIN_RESULT
