---- SRC LAYER ----
WITH
SRC_dc             as ( SELECT    GOODS_STORAGE_LOCATION_HK
                                , GOODS_STORAGE_LOCATION_BK
                                , BKCC
                                , REC_SRC
                                , STORAGE_LOCATION_DESCRIPTION_TEXT
                                , STORAGE_LOCATION_MRP_INDICATOR_CODE
                        FROM {{ ref('pit_storage_location') }} as SRC  )

/*
SRC_dc             as ( SELECT * FROM BUS_VAULT.pit_storage_location )
*/
---- LOGIC LAYER ----

, LOGIC_dc as (
    SELECT
          GOODS_STORAGE_LOCATION_HK
        , GOODS_STORAGE_LOCATION_BK
        , BKCC
        , REC_SRC
        , STORAGE_LOCATION_DESCRIPTION_TEXT
        , STORAGE_LOCATION_MRP_INDICATOR_CODE
    FROM SRC_dc
)
---- RENAME LAYER ----

, RENAME_dc as (
    SELECT
          GOODS_STORAGE_LOCATION_HK
        , GOODS_STORAGE_LOCATION_BK
        , BKCC
        , REC_SRC
        , STORAGE_LOCATION_DESCRIPTION_TEXT
        , STORAGE_LOCATION_MRP_INDICATOR_CODE
    FROM LOGIC_dc
)
---- FILTER LAYER ----

, FILTER_dc as (
    SELECT *
    FROM RENAME_dc
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_dc
)

---- FINAL LAYER ----
SELECT
          GOODS_STORAGE_LOCATION_HK
        , GOODS_STORAGE_LOCATION_BK
        , BKCC
        , REC_SRC
        , STORAGE_LOCATION_DESCRIPTION_TEXT
        , STORAGE_LOCATION_MRP_INDICATOR_CODE
FROM JOIN_RESULT