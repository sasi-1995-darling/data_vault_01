---- SRC LAYER ----
WITH
SRC_PFC            as ( SELECT * FROM {{ ref('pit_stg_form__centercode') }} as SRC  )

/*
SRC_PFC            as ( SELECT * FROM BUS_VAULT.PIT_STG_FORM__CENTERCODE )
*/
---- LOGIC LAYER ----

, LOGIC_PFC as (
    SELECT
        FORM_HK
      , FORM_BK
      , BKCC
      , REC_SRC
    FROM SRC_PFC
)
---- RENAME LAYER ----

, RENAME_PFC as (
    SELECT
        FORM_HK
      , FORM_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_PFC
)
---- FILTER LAYER ----

, FILTER_PFC as (
    SELECT *
    FROM RENAME_PFC
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PFC
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PIT_LOAD_DTS
        , FORM_HK
        , FORM_BK
        , BKCC
        , REC_SRC
        , CASE WHEN FORM_BK LIKE '%survey%' THEN 'Survey'
	 WHEN FORM_BK LIKE '%ticket%' THEN 'Ticket'
	 WHEN FORM_BK LIKE '%tester%' THEN 'Tester Information'
END as FORM_TYPE
FROM JOIN_RESULT
