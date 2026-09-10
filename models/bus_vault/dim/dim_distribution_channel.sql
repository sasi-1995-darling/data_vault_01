---- SRC LAYER ----
WITH
SRC_dc             as ( SELECT BKCC, DISTRIBUTION_CHANNEL_HK, DISTRIBUTION_CHANNEL_BK, DISTRIBUTION_CHANNEL_NAME, LANGUAGE_KEY, REC_SRC FROM {{ ref('pit_distribution_channel') }} as SRC  )

/*
SRC_dc             as ( SELECT * FROM BUS_VAULT.pit_distribution_channel )
*/
---- LOGIC LAYER ----

, LOGIC_dc as (
    SELECT
        DISTRIBUTION_CHANNEL_HK                                      as                           DISTRIBUTION_CHANNEL_KEY
      , DISTRIBUTION_CHANNEL_BK
      , DISTRIBUTION_CHANNEL_NAME
      , LANGUAGE_KEY                                                 as                                  LANGUAGE_CODE_SAP
      , REC_SRC
      , BKCC
    FROM SRC_dc
)
---- RENAME LAYER ----

, RENAME_dc as (
    SELECT
        DISTRIBUTION_CHANNEL_KEY
      , DISTRIBUTION_CHANNEL_BK
      , DISTRIBUTION_CHANNEL_NAME
      , LANGUAGE_CODE_SAP
      , REC_SRC
      , BKCC
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
          DISTRIBUTION_CHANNEL_KEY
        , DISTRIBUTION_CHANNEL_BK
        , DISTRIBUTION_CHANNEL_NAME
        , LANGUAGE_CODE_SAP
        , REC_SRC
        , BKCC
FROM JOIN_RESULT
