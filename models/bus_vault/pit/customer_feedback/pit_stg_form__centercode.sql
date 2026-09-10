{{ config(materialized='ephemeral') }}
---- SRC LAYER ----
WITH
SRC_HF             as ( SELECT * FROM {{ ref('hub_form') }} as SRC  )

/*
SRC_HF             as ( SELECT * FROM RAW_VAULT.HUB_FORM )
*/
---- LOGIC LAYER ----

, LOGIC_HF as (
    SELECT
        FORM_HK
      , FORM_BK
      , BKCC
      , REC_SRC
    FROM SRC_HF
)
---- RENAME LAYER ----

, RENAME_HF as (
    SELECT
        FORM_HK
      , FORM_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_HF
)
---- FILTER LAYER ----

, FILTER_HF as (
    SELECT *
    FROM RENAME_HF
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_HF
)

---- FINAL LAYER ----
SELECT
          FORM_HK
        , FORM_BK
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
