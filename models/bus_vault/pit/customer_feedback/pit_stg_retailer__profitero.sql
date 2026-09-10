{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HB             as ( SELECT BKCC, REC_SRC, RETAILER_BK, RETAILER_HK FROM {{ ref('hub_retailer') }} as SRC  ),
SRC_SB             as ( SELECT ALIAS, COUNTRY, ID, RETAILER_HK FROM {{ ref('sat_retailer__profitero') }} as SRC 
                        qualify 1= row_number() over(partition by RETAILER_HK order by UPDATED_AT DESC) )

/*
SRC_HB             as ( SELECT * FROM RAW_VAULT.HUB_RETAILER )
SRC_SB             as ( SELECT * FROM RAW_VAULT.SAT_RETAILER__PROFITERO )
*/
---- LOGIC LAYER ----

, LOGIC_HB as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , REC_SRC
    FROM SRC_HB
)

, LOGIC_SB as (
    SELECT
        RETAILER_HK                                                  as                                     SB_RETAILER_HK
      , ID
      , COUNTRY
      , ALIAS
    FROM SRC_SB
)
---- RENAME LAYER ----

, RENAME_HB as (
    SELECT
        RETAILER_HK
      , RETAILER_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_HB
)

, RENAME_SB as (
    SELECT
        SB_RETAILER_HK
      , ID
      , COUNTRY
      , ALIAS
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
        ON FILTER_HB.RETAILER_HK = SB_RETAILER_HK
)

---- FINAL LAYER ----
SELECT
          RETAILER_HK
        , RETAILER_BK
        , BKCC
        , REC_SRC
        , TO_VARCHAR(id)                                               as ID
        , COALESCE(COUNTRY,'')                                         as COUNTRY
        , COALESCE(ALIAS,'')                                           as ALIAS
FROM JOIN_RESULT
