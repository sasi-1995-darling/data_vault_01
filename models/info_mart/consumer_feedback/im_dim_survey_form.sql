{{ config(alias='dim_survey_form') }}
---- SRC LAYER ----
WITH
SRC_PSF            as ( SELECT * FROM {{ ref('dim_survey_form') }} as SRC  )

/*
SRC_PSF            as ( SELECT * FROM BUS_VAULT.DIM_SURVEY_FORM )
*/
---- LOGIC LAYER ----

, LOGIC_PSF as (
    SELECT
        FORM_BK
      , BKCC
      , REC_SRC
      , FORM_TYPE
    FROM SRC_PSF
)
---- RENAME LAYER ----

, RENAME_PSF as (
    SELECT
        FORM_BK
      , BKCC
      , REC_SRC
      , FORM_TYPE
    FROM LOGIC_PSF
)
---- FILTER LAYER ----

, FILTER_PSF as (
    SELECT *
    FROM RENAME_PSF
)

---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT *
    FROM FILTER_PSF
)

---- FINAL LAYER ----
SELECT
          FORM_BK
        , BKCC
        , REC_SRC
        , FORM_TYPE
FROM JOIN_RESULT
