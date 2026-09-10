---- SRC LAYER ----
WITH
SRC_D              as ( SELECT DIVISION_BK, DIVISION_HK, LANGUAGE_KEY, DIVISION, DIVISION_NAME, REC_SRC, BKCC FROM {{ ref('pit_division') }} as SRC  )

/*
SRC_D              as ( SELECT * FROM BUS_VAULT.pit_division )
*/
---- LOGIC LAYER ----

, LOGIC_D as (
    SELECT
        DIVISION_BK
      , DIVISION_HK
      , LANGUAGE_KEY
      , DIVISION
      , DIVISION_NAME
      , REC_SRC
      , BKCC
    FROM SRC_D
)
---- RENAME LAYER ----

, RENAME_D as (
    SELECT
        DIVISION_BK
      , DIVISION_HK
      , LANGUAGE_KEY
      , DIVISION
      , DIVISION_NAME
      , REC_SRC
      , BKCC
    FROM LOGIC_D
)
---- FILTER LAYER ----

, FILTER_D as (
    SELECT *
    FROM RENAME_D
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_D
)

---- FINAL LAYER ----
SELECT
          DIVISION_BK
        , DIVISION_HK
        , LANGUAGE_KEY
        , DIVISION
        , DIVISION_NAME
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
