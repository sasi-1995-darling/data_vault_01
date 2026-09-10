---- SRC LAYER ----
WITH
SRC_PPC            as ( SELECT * FROM {{ ref('pit_stg_project__centercode') }} as SRC  )

/*
SRC_PPC            as ( SELECT * FROM BUS_VAULT.PIT_STG_PROJECT__CENTERCODE )
*/
---- LOGIC LAYER ----

, LOGIC_PPC as (
    SELECT
        PROJECT_HK
      , PROJECT_BK
      , BKCC
      , REC_SRC
    FROM SRC_PPC
)
---- RENAME LAYER ----

, RENAME_PPC as (
    SELECT
        PROJECT_HK
      , PROJECT_BK
      , BKCC
      , REC_SRC
    FROM LOGIC_PPC
)
---- FILTER LAYER ----

, FILTER_PPC as (
    SELECT *
    FROM RENAME_PPC
)
---- JOIN LAYER ----
, JOIN_RESULT as (
    SELECT * FROM FILTER_PPC
)

---- FINAL LAYER ----
SELECT
              row_number() over(order by 1)                            as SEQ_ID
        , CURRENT_DATE                                                 as SNAPSHOTDATE
        , CONVERT_TIMEZONE('UTC', CURRENT_TIMESTAMP )                  as PIT_LOAD_DTS
        , PROJECT_HK
        , PROJECT_BK
        , BKCC
        , REC_SRC
FROM JOIN_RESULT
