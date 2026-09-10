---- SRC LAYER ----
WITH
SRC_P_PR_DET       as ( SELECT * FROM {{ ref('pit_purchasing_record_details_current') }} as SRC  )

/*
SRC_P_PR_DET       as ( SELECT * FROM BUS_VAULT.PIT_PURCHASING_RECORD_DETAILS_CURRENT )
*/
---- LOGIC LAYER ----

, LOGIC_P_PR_DET as (
    SELECT
        PURCHASING_RECORD_DETAILS_HK
      , PURCHASING_RECORD_HK                                         as                           PURCHASING_REC_DETAIL_HK
      , PURCHASING_ORG_HK
      , PLANT_HK
      , PRICE_DATE
      , NET_PRICE
      , PRICE_UNIT
    FROM SRC_P_PR_DET
)
---- RENAME LAYER ----

, RENAME_P_PR_DET as (
    SELECT
        PURCHASING_RECORD_DETAILS_HK
      , PURCHASING_REC_DETAIL_HK
      , PURCHASING_ORG_HK
      , PLANT_HK
      , PRICE_DATE
      , NET_PRICE
      , PRICE_UNIT
    FROM LOGIC_P_PR_DET
)
---- FILTER LAYER ----

, FILTER_P_PR_DET as (
    SELECT *
    FROM RENAME_P_PR_DET
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_P_PR_DET
)

---- FINAL LAYER ----
SELECT
          PURCHASING_RECORD_DETAILS_HK
        , PURCHASING_REC_DETAIL_HK
        , PURCHASING_ORG_HK
        , PLANT_HK
        , PRICE_DATE
        , NET_PRICE
        , PRICE_UNIT
FROM JOIN_RESULT