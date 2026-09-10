{{ config(alias='dim_retailer') }}
---- SRC LAYER ----
WITH
SRC_PB             as ( SELECT * FROM {{ ref('dim_retailer') }} as SRC  )

/*
SRC_PB             as ( SELECT * FROM BUS_VAULT.DIM_RETAILER )
*/
---- LOGIC LAYER ----

, LOGIC_PB as (
    SELECT
        RETAILER_BK
      , ALIAS
      , COUNTRY
      , BKCC
      , REC_SRC
    FROM SRC_PB
)
---- RENAME LAYER ----

, RENAME_PB as (
    SELECT
        RETAILER_BK
      , ALIAS
      , COUNTRY
      , BKCC
      , REC_SRC
    FROM LOGIC_PB
)
---- FILTER LAYER ----

, FILTER_PB as (
    SELECT *
    FROM RENAME_PB
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PB
)

---- FINAL LAYER ----
SELECT
          RETAILER_BK
        , ALIAS
        , COUNTRY
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
