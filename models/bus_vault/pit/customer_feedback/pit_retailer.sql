---- SRC LAYER ----
WITH
SRC_RP             as ( SELECT ALIAS, BKCC, COUNTRY, ID, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('pit_stg_retailer__profitero') }} as SRC  ),
SRC_RA             as ( SELECT ALIAS, BKCC, COUNTRY, ID, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('pit_stg_retailer__appbot') }} as SRC  ),
SRC_RPS            as ( SELECT ALIAS, BKCC, COUNTRY, ID, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('pit_stg_retailer__profitero_share') }} as SRC  )

/*
SRC_RP             as ( SELECT * FROM bus_vault.PIT_STG_RETAILER__PROFITERO )
SRC_RA             as ( SELECT * FROM bus_vault.PIT_STG_RETAILER__APPBOT )
SRC_RPS            as ( SELECT * FROM bus_vault.PIT_STG_RETAILER__PROFITERO_SHARE )
*/
---- LOGIC LAYER ----

, LOGIC_RP as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , REC_SRC
      , ID
      , COUNTRY
      , ALIAS
      , 2 AS SRC_PRIORITY   -- old profitero: loses to share on RETAILER_HK+BKCC collision
    FROM SRC_RP
)

, LOGIC_RA as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , REC_SRC
      , ID
      , COUNTRY
      , ALIAS
      , 1 AS SRC_PRIORITY   -- appbot: no overlap with share, treated as preferred
    FROM SRC_RA
)

, LOGIC_RPS as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , REC_SRC
      , ID
      , COUNTRY
      , ALIAS
      , 1 AS SRC_PRIORITY   -- profitero_share: preferred over old profitero on collision
    FROM SRC_RPS
)
---- RENAME LAYER ----

, RENAME_RP as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , REC_SRC
      , ID
      , COUNTRY
      , ALIAS
      , SRC_PRIORITY
    FROM LOGIC_RP
)

, RENAME_RA as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , REC_SRC
      , ID
      , COUNTRY
      , ALIAS
      , SRC_PRIORITY
    FROM LOGIC_RA
)

, RENAME_RPS as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , REC_SRC
      , ID
      , COUNTRY
      , ALIAS
      , SRC_PRIORITY
    FROM LOGIC_RPS
)
---- FILTER LAYER ----

, FILTER_RP as (
    SELECT *
    FROM RENAME_RP
)

, FILTER_RA as (
    SELECT *
    FROM RENAME_RA
)

, FILTER_RPS as (
    SELECT *
    FROM RENAME_RPS
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_RP
    UNION ALL
    SELECT * FROM FILTER_RA
    UNION ALL
    SELECT * FROM FILTER_RPS
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PIT_LOAD_DTS
        , RETAILER_HK
        , RETAILER_BK
        , BKCC
        , REC_SRC
        , ID
        , COUNTRY
        , ALIAS
FROM JOIN_RESULT
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY RETAILER_HK, BKCC
    ORDER BY SRC_PRIORITY ASC
) = 1
